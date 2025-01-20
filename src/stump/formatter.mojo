from collections import Dict
import emberjson
from .context import Context
from .style import Styles


alias Formatter = fn (context: Context) -> String
"""A function that formats the context data into a log message."""


fn default_formatter(context: Context) -> String:
    """Default formatter for log messages.

    Args:
        context: The context to format.

    Returns:
        The formatted log message.
    """
    # TODO: Probably need a better algorithm for this formatting process.
    var new_context = context.copy()
    var format = String()

    # timestamp then level, then message, then other context keys
    for key in List[String]("timestamp", "level", "message"):
        try:
            format.write(new_context.pop(key[]), " ")
        except:
            pass

    # Add the rest of the context delimited by a space.
    format.write(new_context.to_logfmt())
    return format^


fn json_formatter(context: Context) -> String:
    """Format the context data into a JSON string.

    Args:
        context: The context to format.

    Returns:
        The formatted JSON string.
    """
    return context.to_json_string()


fn logfmt_formatter(context: Context) -> String:
    """Format the context data into a logfmt string.

    Args:
        context: The context to format.

    Returns:
        The formatted logfmt string.
    """
    # Add all the keys in the context in KV format.
    return context.to_logfmt()
