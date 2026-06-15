"""Formatters."""
from std.collections import Dict
import emberjson
from stump.context import Context
from stump.style import Styles


comptime Formatter = def(context: Context) thin -> String
"""A function that formats the context data into a log message."""


def default_formatter(context: Context) -> String:
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
    comptime default_keys = ["timestamp", "level", "message"]
    comptime for key in default_keys:
        try:
            format.write(new_context.pop(key), " ")
        except:
            pass

    # Add the rest of the context delimited by a space.
    format.write(new_context.to_logfmt())
    return format^


def json_formatter(context: Context) -> String:
    """Format the context data into a JSON string.

    Args:
        context: The context to format.

    Returns:
        The formatted JSON string.
    """
    return context.to_json_string()


def logfmt_formatter(context: Context) -> String:
    """Format the context data into a logfmt string.

    Args:
        context: The context to format.

    Returns:
        The formatted logfmt string.
    """
    # Add all the keys in the context in KV format.
    return context.to_logfmt()
