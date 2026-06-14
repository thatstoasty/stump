from std.reflection import source_location
from mojo_datetime import DateTime
from stump._time import now
from stump.context import Context


comptime Processor = def (context: Context, level: String) thin -> Context
"""Functions to modify the context before logging a message."""
comptime GetProcessorsFn = def () -> List[Processor]


# Built in processor functions to modify the context before logging a message.
def add_timestamp(context: Context, level: String) -> Context:
    """Adds a timestamp to the log message with the specified format.
    The default format for timestamps is `YYYY-MM-DDTHH:mm:ss`.

    Args:
        context: The current context.
        level: The log level of the message.
    """
    var new_context = context.copy()
    try:
        new_context["timestamp"] = String(now())
    except:
        new_context["timestamp"] = ""

    return new_context^


def add_log_level(context: Context, level: String) -> Context:
    """Adds the log level to the log message.

    Args:
        context: The current context.
        level: The log level of the message.
    """
    var new_context = context.copy()
    new_context["level"] = level

    return new_context^


def add_callsite(context: Context, level: String) -> Context:
    """Adds the callsite to the log message.

    Args:
        context: The current context.
        level: The log level of the message.
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

    Params:
        format: The format string for the timestamp.
    """

    def processor(context: Context, level: String) -> Context:
        var new_context = context.copy()
        try:
            var ts = String(capacity=32)
            now().write_to[fmt_str=format](ts)
            new_context["timestamp"] = ts^
        except:
            new_context["timestamp"] = ""
        return new_context^

    return processor


def get_default_processors() -> List[Processor]:
    return [add_timestamp, add_log_level]

comptime DEFAULT_PROCESSORS = [add_timestamp, add_log_level, add_callsite]
