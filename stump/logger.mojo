"""Logger Trait and Implementations."""

from std.collections import InlineArray
from std import sys


@fieldwise_init
struct LogLevel(Comparable, ImplicitlyCopyable, Writable):
    """A log level, representing the severity of a log message."""

    var value: UInt8
    """An integer value representing the log level. Lower values indicate higher severity."""
    comptime FATAL = Self(0)
    """Fatal log level, indicating a critical error that causes the program to terminate."""
    comptime ERROR = Self(1)
    """Error log level, indicating a significant problem that should be addressed but does not cause the program to terminate."""
    comptime WARN = Self(2)
    """Warning log level, indicating a potential issue or important information that should be noted but does not indicate an error."""
    comptime INFO = Self(3)
    """Info log level, indicating general information about the program's execution that may be useful for debugging or monitoring."""
    comptime DEBUG = Self(4)
    """Debug log level, indicating detailed information about the program's execution that is typically only useful for debugging purposes."""

    def __eq__(self, other: Self) -> Bool:
        """Checks if this log level is equal to another log level.

        Args:
            other: The other log level to compare against.

        Returns:
            `True` if the log levels are equal, `False` otherwise.
        """
        return self.value == other.value

    def __lt__(self, other: Self) -> Bool:
        """Checks if this log level is less than another log level.

        Args:
            other: The other log level to compare against.

        Returns:
            `True` if this log level is less than the other log level, `False` otherwise.
        """
        return self.value < other.value

    def write_to(self, mut writer: Some[Writer]):
        """Writes the log level to a writer.

        Args:
            writer: The writer to write to.
        """
        if self.value == 0:
            writer.write("FATAL")
        elif self.value == 1:
            writer.write("ERROR")
        elif self.value == 2:
            writer.write("WARN")
        elif self.value == 3:
            writer.write("INFO")
        elif self.value == 4:
            writer.write("DEBUG")
        else:
            writer.write("UNKNOWN(", self.value, ")")


# TODO: When parametric traits are supported, this should be parametrized on the log level.
# So that BoundLogger can be parametrized on the log level of it's internal logger.
trait Logger(ImplicitlyDestructible, Movable):
    """Trait representing a logger, which can log messages at various log levels."""

    comptime level: LogLevel
    """Get the log level of the logger."""

    def info(self, message: Some[Writable]):
        """Logs an informational message.

        Args:
            message: The message to log.
        """
        ...

    def warn(self, message: Some[Writable]):
        """Logs a warning message.

        Args:
            message: The message to log.
        """
        ...

    def error(self, message: Some[Writable]):
        """Logs an error message.

        Args:
            message: The message to log.
        """
        ...

    def debug(self, message: Some[Writable]):
        """Logs a debug message.

        Args:
            message: The message to log.
        """
        ...

    def fatal(self, message: Some[Writable]):
        """Logs a fatal error message.

        Args:
            message: The message to log.
        """
        ...


@fieldwise_init
struct PrintLogger[log_level: LogLevel](Logger):
    """An implementation of the `Logger` trait that prints log messages to the console.

    Parameters:
        log_level: The log level of the logger.
    """

    comptime level = Self.log_level
    """Get the log level of the logger."""

    def _log_message[event_level: LogLevel](self, message: Some[Writable], file: FileDescriptor = sys.stdout):
        """Logs a message at a specific log level.

        Parameters:
            event_level: The log level of the message being logged.

        Args:
            message: The message to log.
            file: The file descriptor to write the log message to (default is `sys.stdout`).
        """
        comptime if Self.level.value >= event_level.value:
            print(message, file=file)

    def info(self, message: Some[Writable]):
        """Logs an informational message.

        Args:
            message: The message to log.
        """
        self._log_message[LogLevel.INFO](message)

    def warn(self, message: Some[Writable]):
        """Logs a warning message.

        Args:
            message: The message to log.
        """
        self._log_message[LogLevel.WARN](message)

    def error(self, message: Some[Writable]):
        """Logs an error message.

        Args:
            message: The message to log.
        """
        self._log_message[LogLevel.ERROR](message, file=sys.stderr)

    def debug(self, message: Some[Writable]):
        """Logs a debug message.

        Args:
            message: The message to log.
        """
        self._log_message[LogLevel.DEBUG](message)

    def fatal(self, message: Some[Writable]):
        """Logs a fatal error message.

        Args:
            message: The message to log.
        """
        self._log_message[LogLevel.FATAL](message, file=sys.stderr)


# struct FileLogger(Logger):
#     var level: Int
#     var handle: FileHandle

#     def __init__(out self, owned handle: FileHandle, level: Int = WARN):
#         self.level = level
#         self.handle = handle^

#     def __moveinit__(self, owned other: FileLogger):
#         self.level = other.level
#         self.handle = other.handle^

#     def _log_message(self, message: String, level: Int):
#         if self.level >= level:
#             # var result = stat(self.path)

#             # handle was removed, reopen and continue logging.
#             # if result.st_nlink == 0:
#             #     self.handle.close()
#             #     self.handle = open(self.path, self.mode)

#             self.handle.write(message)
#             self.handle.write(NEWLINE)

#     def info(self, message: String):
#         self._log_message(message, INFO)

#     def warn(self, message: String):
#         self._log_message(message, WARN)

#     def error(self, message: String):
#         self._log_message(message, ERROR)

#     def debug(self, message: String):
#         self._log_message(message, DEBUG)

#     def fatal(self, message: String):
#         self._log_message(message, FATAL)

#     def get_level(self) -> Int:
#         return self.level
