"""Logger Trait and Implementations."""

from std import sys
from std.logger import Level, Logger as _StdLogger
from std.memory import ArcPointer
from std.sys.defines import get_defined_string
from std.ffi import _get_global, external_call


# TODO: When parametric traits are supported, this should be parametrized on the log level.
# So that BoundLogger can be parametrized on the log level of it's internal logger.
trait Logger(Copyable, ImplicitlyDestructible):
    """Trait representing a sink, which can write log messages at various log levels.

    An implementation only has to provide `log`, which receives the level as a
    compile-time parameter. The five level-named methods are supplied as default
    implementations that dispatch to it, so a custom sink is one method rather
    than six. An implementation may still override a named method to special-case
    a level.

    Loggers are `Copyable` so that a `BoundLogger` wrapping one can produce child
    loggers. A sink holding a resource that is not itself copyable should share it
    through an `ArcPointer`, as `FileLogger` does.
    """

    comptime level: Level
    """Get the log level of the logger."""

    def log[level: Level](self, message: Some[Writable]):
        """Logs a message at the given log level.

        This is the only method an implementation is required to define.

        Parameters:
            level: The log level to log the message at.

        Args:
            message: The message to log.
        """
        ...

    def trace(self, message: Some[Writable]):
        """Logs a trace message.

        Args:
            message: The message to log.
        """
        self.log[Level.TRACE](message)

    def info(self, message: Some[Writable]):
        """Logs an informational message.

        Args:
            message: The message to log.
        """
        self.log[Level.INFO](message)

    def warning(self, message: Some[Writable]):
        """Logs a warning message.

        Args:
            message: The message to log.
        """
        self.log[Level.WARNING](message)

    def error(self, message: Some[Writable]):
        """Logs an error message.

        Args:
            message: The message to log.
        """
        self.log[Level.ERROR](message)

    def debug(self, message: Some[Writable]):
        """Logs a debug message.

        Args:
            message: The message to log.
        """
        self.log[Level.DEBUG](message)

    def critical(self, message: Some[Writable]):
        """Logs a critical error message.

        Args:
            message: The message to log.
        """
        self.log[Level.CRITICAL](message)


@fieldwise_init
struct PrintLogger[log_level: Level](Logger):
    """An implementation of the `Logger` trait that prints log messages to the console.

    Parameters:
        log_level: The log level of the logger.
    """

    comptime level = Self.log_level
    """Get the log level of the logger."""

    def log[level: Level](self, message: Some[Writable]):
        """Logs a message at the given log level.

        `ERROR` and `FATAL` are written to `sys.stderr`, every other level to
        `sys.stdout`. Both the level check and the stream choice are resolved at
        compile time, so a suppressed call compiles away entirely.

        Parameters:
            level: The log level to log the message at.

        Args:
            message: The message to log.
        """
        comptime if level >= Level.ERROR:
            print(message, file=sys.stderr)
        else:
            print(message, file=sys.stdout)


struct _FileSink(ImplicitlyDestructible, Movable):
    """The shared state behind a `FileLogger`: the open file and its pending buffer.

    This is the payload of the `ArcPointer` a `FileLogger` holds. Keeping it
    separate means the flush-on-last-reference behaviour lives in this type's
    destructor, so `FileLogger` itself stays trivially copyable.
    """

    var handle: FileHandle
    """The open file that records are written to."""
    var buffer: String
    """Records written while buffering, waiting to be flushed."""

    def __init__(out self, var handle: FileHandle):
        """Takes ownership of an open file handle.

        Args:
            handle: The open file handle to write records to.
        """
        self.handle = handle^
        self.buffer = String()

    def flush(mut self):
        """Writes any buffered records to the file and empties the buffer."""
        if self.buffer.byte_length() == 0:
            return

        self.handle.write(self.buffer)
        self.buffer = String()

    def __del__(deinit self):
        """Flushes any records still buffered when the last reference goes away."""
        self.flush()


struct FileLogger[log_level: Level](Logger):
    """An implementation of the `Logger` trait that appends log records to a file.

    The file handle is shared through an `ArcPointer`, so copies of a
    `FileLogger` — including the copies a `BoundLogger` makes when it binds a
    child — all write to the same file, in call order, and the file is closed
    once the last copy is gone.

    Parameters:
        log_level: The log level of the logger.

    #### Examples:
    ```mojo
    from stump import BoundLogger, FileLogger
    from std.logger import Level

    def main() raises:
        var logger = BoundLogger(FileLogger[Level.INFO]("app.log"), apply_styles=False)
        logger.info("Started")
    ```
    """

    comptime level = Self.log_level
    """Get the log level of the logger."""

    var _sink: ArcPointer[_FileSink]
    """The shared file handle and pending buffer."""
    var auto_flush: Bool
    """Whether each record is written straight to the file, or buffered until `flush` is called."""

    def __init__(out self, var handle: FileHandle, *, auto_flush: Bool = True):
        """Creates a file logger from an already open file handle.

        Args:
            handle: The open file handle to write records to.
            auto_flush: Whether to write each record immediately. When `False`,
                records accumulate in memory until `flush` is called.
        """
        self._sink = ArcPointer(_FileSink(handle^))
        self.auto_flush = auto_flush

    def __init__(out self, path: StringSlice, *, mode: StringSlice = "a", auto_flush: Bool = True) raises:
        """Creates a file logger by opening `path`.

        Args:
            path: The path of the file to write records to.
            mode: The mode to open the file in. Defaults to appending.
            auto_flush: Whether to write each record immediately. When `False`,
                records accumulate in memory until `flush` is called.

        Raises:
            If the file cannot be opened.
        """
        self._sink = ArcPointer(_FileSink(open(String(path), String(mode))))
        self.auto_flush = auto_flush

    def flush(self):
        """Writes any buffered records to the file.

        This is a no-op when `auto_flush` is set, since nothing is ever buffered.
        Buffered records are also flushed when the last copy of the logger is
        destroyed, so calling this is about *when* records land, not *whether*.
        """
        self._sink[].flush()

    def log[level: Level](self, message: Some[Writable]):
        """Logs a message at the given log level, followed by a newline.

        Parameters:
            level: The log level to log the message at.

        Args:
            message: The message to log.
        """
        if self.auto_flush:
            self._sink[].handle.write(message, "\n")
        else:
            self._sink[].buffer.write(message, "\n")


@fieldwise_init
struct StdLogger[log_level: Level](Logger):
    """An implementation of the `Logger` trait that wraps the stdlib logger.

    Parameters:
        log_level: The log level of the logger.
    """

    comptime level = Self.log_level
    """Get the log level of the logger."""
    var _logger: _StdLogger[Self.log_level]
    """The stdlib logger to wrap."""

    def log[level: Level](self, message: Some[Writable]):
        """Logs a message at the given log level.

        `ERROR` and `FATAL` are written to `sys.stderr`, every other level to
        `sys.stdout`. Both the level check and the stream choice are resolved at
        compile time, so a suppressed call compiles away entirely.

        Parameters:
            level: The log level to log the message at.

        Args:
            message: The message to log.
        """
        comptime if Self.level >= level:
            comptime if level == Level.TRACE:
                self._logger.trace(message)
            elif level == Level.DEBUG:
                self._logger.debug(message)
            elif level == Level.INFO:
                self._logger.info(message)
            elif level == Level.WARNING:
                self._logger.warning(message)
            elif level == Level.ERROR:
                self._logger.error(message)
            elif level == Level.CRITICAL:
                self._logger.critical(message)


@fieldwise_init
struct MultiLogger[A: Logger, B: Logger](Logger):
    """An implementation of the `Logger` trait that tees each record to two other loggers.

    This is pairwise rather than variadic; tee to three or more sinks by nesting,
    e.g. `MultiLogger(a, MultiLogger(b, c))`.

    The level is the more permissive of the two, so neither sink is starved by the
    other's threshold. Each wrapped logger still applies its own level check, so a
    record can reach one sink and be dropped by the other.

    Parameters:
        A: The type of the first logger to write to.
        B: The type of the second logger to write to.

    #### Examples:
    ```mojo
    from std.logger import Level
    from stump import BoundLogger, FileLogger, MultiLogger, PrintLogger

    def main() raises:
        var tee = MultiLogger(PrintLogger[Level.INFO](), FileLogger[Level.DEBUG]("app.log"))
        var logger = BoundLogger(tee^, apply_styles=False)
        logger.info("Goes to both the console and the file")
    ```
    """

    comptime level = Self.A.level if Self.A.level >= Self.B.level else Self.B.level
    """Get the log level of the logger, the more permissive of the two wrapped loggers."""

    var first: Self.A
    """The first logger to write each record to."""
    var second: Self.B
    """The second logger to write each record to."""

    def log[level: Level](self, message: Some[Writable]):
        """Logs a message at the given log level to both wrapped loggers.

        Parameters:
            level: The log level to log the message at.

        Args:
            message: The message to log.
        """
        self.first.log[level](message)
        self.second.log[level](message)
