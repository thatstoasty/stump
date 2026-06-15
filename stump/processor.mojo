"""Log Processors."""
from std.reflection import source_location
from mojo_datetime import DateTime
from stump._time import now
from stump.context import Context


comptime Processor = def(context: Context, level: LogLevel) thin -> Context
"""Functions to modify the context before logging a message."""


# Built in processor functions to modify the context before logging a message.
def add_timestamp(context: Context, level: LogLevel) -> Context:
    """Adds a timestamp to the log message with the specified format.
    The default format for timestamps is `YYYY-MM-DDTHH:mm:ss`.

    Args:
        context: The current context.
        level: The log level of the message.

    Returns:
        The modified context with the timestamp added.
    """
    var new_context = context.copy()
    try:
        new_context["timestamp"] = String(now())
    except:
        new_context["timestamp"] = ""

    return new_context^


def add_log_level(context: Context, level: LogLevel) -> Context:
    """Adds the log level to the log message.

    Args:
        context: The current context.
        level: The log level of the message.

    Returns:
        The modified context with the log level added.
    """
    var new_context = context.copy()
    new_context["level"] = String(level)

    return new_context^


def add_callsite(context: Context, level: LogLevel) -> Context:
    """Adds the callsite to the log message.

    Args:
        context: The current context.
        level: The log level of the message.

    Returns:
        The modified context with the callsite information added.
    """
    var new_context = context.copy()
    var callsite = source_location()
    new_context["line"] = String(callsite.line())
    new_context["col"] = String(callsite.column())
    new_context["file"] = String(callsite.file_name())

    return new_context^


# If you need to modify something within the processor function, create a function that returns a Processor
def add_timestamp_with_format[format: String = "YYYY-MM-DD HH:mm:ss ZZ"]() -> Processor:
    """Adds a timestamp to the log message with the specified format.
    The format should be a valid format string for Morrow.now().format() or "iso".

    The default format for timestamps is `YYYY-MM-DD HH:mm:ss`.

    Parameters:
        format: The format string for the timestamp.

    Returns:
        A processor function that adds a timestamp with the specified format to the log message.
    """

    def processor(context: Context, level: LogLevel) -> Context:
        """The actual processor function that will be returned.

        Parameters:
            level: The log level of the message.

        Args:
            context: The current context.

        Returns:
            The modified context with the timestamp added.
        """
        var new_context = context.copy()
        try:
            var ts = String(capacity=32)
            now().write_to[fmt_str=format](ts)
            new_context["timestamp"] = ts^
        except:
            new_context["timestamp"] = ""
        return new_context^

    return processor


comptime DEFAULT_PROCESSORS = [add_timestamp, add_log_level, add_callsite]
"""Default processors to add a timestamp, log level, and callsite information to log messages."""
