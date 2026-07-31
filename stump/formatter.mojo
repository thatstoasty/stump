"""Formatters."""
import emberjson
from stump.context import Context
from stump.style import Styles


comptime FormatterFn = def(context: Context) thin -> String
"""The function a `Formatter` wraps, rendering a context into a log record."""


@fieldwise_init
struct Formatter(ImplicitlyCopyable, Movable):
    """A rendering function paired with whether its output is meant to carry styling.

    The `styled` flag is what keeps ANSI escape sequences out of machine-read
    records. A `BoundLogger` defaults `apply_styles` to this flag, so choosing
    `json_formatter` turns styling off on its own rather than relying on the
    caller to remember `apply_styles=False`.

    A custom formatter is wrapped alongside its flag:

    ```mojo
    from stump import Formatter, Context

    def _render(context: Context) -> String:
        return context.to_logfmt()

    comptime my_formatter = Formatter(_render, styled=False)
    ```
    """

    var _fn: FormatterFn
    """The function that renders a context into a log record."""
    var styled: Bool
    """Whether records from this formatter are meant to carry ANSI styling.

    `True` for human-facing output, `False` for anything a machine parses. Styling
    a structured record corrupts it: the escape sequences land inside JSON strings
    and logfmt values.
    """

    def __call__(self, context: Context) -> String:
        """Render a context into a log record.

        Args:
            context: The context to format.

        Returns:
            The formatted log record.
        """
        return self._fn(context)


def _default_format(context: Context) -> String:
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


def _json_format(context: Context) -> String:
    """Format the context data into a JSON string.

    Args:
        context: The context to format.

    Returns:
        The formatted JSON string.
    """
    return context.to_json_string()


def _logfmt_format(context: Context) -> String:
    """Format the context data into a logfmt string.

    Args:
        context: The context to format.

    Returns:
        The formatted logfmt string.
    """
    # Add all the keys in the context in KV format.
    return context.to_logfmt()


comptime default_formatter = Formatter(_default_format, styled=True)
"""Human-facing records: timestamp, level and message first, then the remaining keys as logfmt."""

comptime json_formatter = Formatter(_json_format, styled=False)
"""The context as a JSON object. Unstyled, since escape sequences would land inside the JSON strings."""

comptime logfmt_formatter = Formatter(_logfmt_format, styled=False)
"""The context as logfmt pairs. Unstyled, since escape sequences would corrupt the values."""
