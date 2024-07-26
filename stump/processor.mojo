import time
from external.morrow import Morrow
from .style import get_default_styles

# TODO: Included `escaping` in the Processor alias for now. It enables the use of functions that generate processors (ie passing args to the processor function)
# Need to understanding closures a bit more, but this works with existing processors.
alias Processor = fn (context: Context, level: String) -> Context


# Built in processor functions to modify the context before logging a message.
fn add_timestamp(context: Context, level: String) -> Context:
    """Adds a timestamp to the log message with the specified format.
    The default format for timestamps is `YYYY-MM-DD HH:mm:ss`.

    Args:
        context: The current context.
        level: The log level of the message.
    """
    var new_context = context
    try:
        new_context["timestamp"] = Morrow.now().isoformat()
    except:
        new_context["timestamp"] = ""

    return new_context


fn add_log_level(context: Context, level: String) -> Context:
    """Adds the log level to the log message.

    Args:
        context: The current context.
        level: The log level of the message.
    """
    var new_context = context
    new_context["level"] = level

    return new_context


# If you need to modify something within the processor function, create a function that returns a Processor
fn add_timestamp_with_format[format: String]() -> Processor:
    """Adds a timestamp to the log message with the specified format.
    The format should be a valid format string for Morrow.now().format() or "iso".

    The default format for timestamps is `YYYY-MM-DD HH:mm:ss`.

    Params:
        format: The format string for the timestamp.
    """

    fn processor(context: Context, level: String) -> Context:
        var new_context = context
        new_context["timestamp"] = DateT.now().strftime(format)
        return new_context

    return processor


fn get_default_processors() -> List[Processor]:
    return List[Processor](add_timestamp, add_log_level)
