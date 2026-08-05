"""Global default logger and convenience functions."""
from std.sys.defines import get_defined_string
from std.ffi import _get_global
from stump.logger import LogLevel, PrintLogger
from stump.bound_logger import BoundLogger


def _get_log_level() -> LogLevel:
    """Reads the default log level from the `STUMP_LOG_LEVEL` build-time define.

    This is a compiler define, not an environment variable: it is set with
    `mojo -D STUMP_LOG_LEVEL=DEBUG`, and exporting `STUMP_LOG_LEVEL` in the shell
    has no effect. That is what keeps the level a compile-time parameter, so the
    level check still compiles suppressed calls away entirely.

    Returns:
        The configured log level, or `LogLevel.INFO` if unset or unrecognised.
    """
    var level = get_defined_string["STUMP_LOG_LEVEL", "INFO"]()
    if level == "INFO":
        return LogLevel.INFO
    elif level == "WARN":
        return LogLevel.WARN
    elif level == "ERROR":
        return LogLevel.ERROR
    elif level == "FATAL":
        return LogLevel.FATAL
    elif level == "DEBUG":
        return LogLevel.DEBUG
    else:
        # Shouldn't be reachable, but just in case, default to INFO
        return LogLevel.INFO


comptime DEFAULT_LOG_LEVEL = _get_log_level()
"""The level the default logger gates at, from the `STUMP_LOG_LEVEL` build-time define.

Set with `mojo -D STUMP_LOG_LEVEL=DEBUG`; an environment variable of the same name
has no effect. Defaults to `LogLevel.INFO`.
"""


def _init_global[level: LogLevel]() -> Optional[UnsafePointer[NoneType, MutUntrackedOrigin]]:
    """Allocates and constructs the process-wide default logger.

    Parameters:
        level: The log level of the default logger.

    Returns:
        An erased pointer to the constructed logger.
    """
    var ptr = alloc[BoundLogger[PrintLogger[level]]](1)

    # `ptr[] = ...` would run the destructor of whatever `alloc` left in this
    # memory, which is garbage rather than a logger. Move into it instead.
    ptr.init_pointee_move(BoundLogger(PrintLogger[level]()))
    return ptr.bitcast[NoneType]()


def _destroy_global[level: LogLevel](lib: Optional[UnsafePointer[NoneType, MutUntrackedOrigin]]):
    """Destroys the process-wide default logger at exit.

    Parameters:
        level: The log level of the default logger.

    Args:
        lib: The erased pointer handed back by `_init_global`.
    """
    if not lib:
        return

    # The cast has to name the type that was allocated. `free` alone only needs
    # the address, but `destroy_pointee` runs that type's destructor, and running
    # the wrong one would be worse than leaking. Without it the logger's context,
    # processors and styles are never released -- and a buffered sink would never
    # get the chance to flush.
    var ptr = lib.value().bitcast[BoundLogger[PrintLogger[level]]]()
    ptr.destroy_pointee()
    ptr.free()


@always_inline
def default[
    level: LogLevel = DEFAULT_LOG_LEVEL
]() -> UnsafePointer[BoundLogger[PrintLogger[level]], MutUntrackedOrigin]:
    """Gets the process-wide default logger, constructing it on first use.

    The logger is created once and lives until the process exits. The pointer is
    mutable, so the default can be reconfigured in place -- binding context onto
    it, or replacing it outright -- and every later lookup sees the change.

    Note that `level` selects the *call site's* gating, not the stored logger's:
    every level shares one global slot, so `default[LogLevel.DEBUG]()` reaches the
    same instance as `default()` and logs at DEBUG regardless of how the default
    was configured. This is sound only because `PrintLogger[level]` holds no data
    and `BoundLogger.level` is a compile-time property; a sink carrying per-level
    state would need one slot per level.

    Parameters:
        level: The log level to gate calls at. Defaults to the `STUMP_LOG_LEVEL` define.

    Returns:
        A mutable pointer to the default logger.
    """
    return (
        _get_global["default", _init_global[level], _destroy_global[level]]()
        .value()
        .bitcast[BoundLogger[PrintLogger[level]]]()
    )


def info[T: Writable, //, *Ts: Writable](message: T, /, *args: *Ts, **kwargs: Arg):
    """Logs a message at the INFO level to the default logger.

    Parameters:
        T: The type of the message to log.
        Ts: The types of the arguments to include in the log message.

    Args:
        message: The message to log.
        args: Additional arbitrary arguments to include in the log message.
        kwargs: Additional arbitrary key-value pairs to include in the log message.
    """
    default()[]._log[LogLevel.INFO](message, kwargs=kwargs, *args)


def warn[T: Writable, //, *Ts: Writable](message: T, /, *args: *Ts, **kwargs: Arg):
    """Logs a message at the WARN level to the default logger.

    Parameters:
        T: The type of the message to log.
        Ts: The types of the arguments to include in the log message.

    Args:
        message: The message to log.
        args: Additional arbitrary arguments to include in the log message.
        kwargs: Additional arbitrary key-value pairs to include in the log message.
    """
    default()[]._log[LogLevel.WARN](message, kwargs=kwargs, *args)


def error[T: Writable, //, *Ts: Writable](message: T, /, *args: *Ts, **kwargs: Arg):
    """Logs a message at the ERROR level to the default logger.

    Parameters:
        T: The type of the message to log.
        Ts: The types of the arguments to include in the log message.

    Args:
        message: The message to log.
        args: Additional arbitrary arguments to include in the log message.
        kwargs: Additional arbitrary key-value pairs to include in the log message.
    """
    default()[]._log[LogLevel.ERROR](message, kwargs=kwargs, *args)


def debug[T: Writable, //, *Ts: Writable](message: T, /, *args: *Ts, **kwargs: Arg):
    """Logs a message at the DEBUG level to the default logger.

    Parameters:
        T: The type of the message to log.
        Ts: The types of the arguments to include in the log message.

    Args:
        message: The message to log.
        args: Additional arbitrary arguments to include in the log message.
        kwargs: Additional arbitrary key-value pairs to include in the log message.
    """
    default()[]._log[LogLevel.DEBUG](message, kwargs=kwargs, *args)


def fatal[T: Writable, //, *Ts: Writable](message: T, /, *args: *Ts, **kwargs: Arg):
    """Logs a message at the FATAL level to the default logger.

    Terminates the process with status 1 if the default logger has `exit_on_fatal`
    set, which it does not by default.

    Parameters:
        T: The type of the message to log.
        Ts: The types of the arguments to include in the log message.

    Args:
        message: The message to log.
        args: Additional arbitrary arguments to include in the log message.
        kwargs: Additional arbitrary key-value pairs to include in the log message.
    """
    default()[]._log[LogLevel.FATAL](message, kwargs=kwargs, *args)
