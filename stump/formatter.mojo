"""Formatters."""
from stump.context import Context, to_json_string, to_logfmt
from stump.style import Styles


comptime FormatterFn = def(context: Context) thin -> String
"""The function a `Formatter` wraps, rendering a context into a log record."""

comptime RESERVED_KEYS = ["timestamp", "level", "message"]
"""The context keys the default formatter writes as bare text, in the order it writes them.

Everything else is rendered as a `key=value` pair. The styling pass reads this too:
a reserved key takes no key style and no separator, because neither is written for
it. The two have to agree, so they share one list.
"""


def is_reserved_key(key: String) -> Bool:
    """Check whether a context key is written as bare text by the default formatter.

    The list is a compile-time value, so membership is an unrolled comparison
    rather than a runtime container lookup.

    Args:
        key: The unstyled context key to check.

    Returns:
        `True` if the key is one of `RESERVED_KEYS`.
    """
    comptime for reserved in RESERVED_KEYS:
        if key == reserved:
            return True

    return False


@fieldwise_init
struct Formatter(ImplicitlyCopyable):
    """A rendering function paired with whether its output is meant to carry styling.

    The `styled` flag is what keeps ANSI escape sequences out of machine-read
    records. A `BoundLogger` defaults `apply_styles` to this flag, so choosing
    `JSON_FORMATTER` turns styling off on its own rather than relying on the
    caller to remember `apply_styles=False`.

    A custom formatter is wrapped alongside its flag:

    ```mojo
    from stump import Formatter, Context, to_logfmt

    def _render(context: Context) -> String:
        return to_logfmt(context)

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
    comptime for key in RESERVED_KEYS:
        try:
            format.write(new_context.pop(key), " ")
        except:
            pass

    # Add the rest of the context delimited by a space.
    format.write(to_logfmt(new_context))
    return format^


comptime DEFAULT_FORMATTER = Formatter(_default_format, styled=True)
"""Human-facing records: timestamp, level and message first, then the remaining keys as logfmt."""

comptime JSON_FORMATTER[pretty: Bool] = Formatter(to_json_string[pretty=pretty], styled=False)
"""The context as a JSON object. Unstyled, since escape sequences would land inside the JSON strings.

Parameters:
    pretty: Whether to pretty-print the JSON string.
"""

comptime LOGFMT_FORMATTER = Formatter(to_logfmt, styled=False)
"""The context as logfmt pairs. Unstyled, since escape sequences would corrupt the values."""
