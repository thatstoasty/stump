"""Bound Logger Context."""
from std.collections.dict import OwnedKwargsDict
import emberjson


def _logfmt_needs_quoting(value: StringSlice) -> Bool:
    """Check whether a logfmt value has to be quoted.

    Args:
        value: The value to check.

    Returns:
        `True` if the value is empty or contains a character that would break
        the `key=value` framing.
    """
    if value.byte_length() == 0:
        return True

    return (
        value.find(" ") != -1
        or value.find("=") != -1
        or value.find('"') != -1
        or value.find("\\") != -1
        or value.find("\n") != -1
        or value.find("\r") != -1
        or value.find("\t") != -1
    )


def _escape_logfmt_value(value: StringSlice) -> String:
    """Quote and escape a value so it survives a logfmt round trip.

    Values that need no quoting are returned unchanged. Others are wrapped in
    double quotes with backslashes, quotes, newlines, carriage returns and
    tabs escaped.

    Other control characters are passed through as-is. Strict decoders reject
    them inside a quoted value, so callers writing machine-read logs should
    keep them out of the context in the first place.

    Args:
        value: The value to escape.

    Returns:
        The value, quoted and escaped if it needed it.
    """
    if not _logfmt_needs_quoting(value):
        return String(value)

    var escaped = (
        value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
    )

    var result = String(capacity=escaped.byte_length() + 2)
    result.write('"', escaped, '"')
    return result^


comptime Context = Dict[String, String]
"""A log record's key-value pairs.

An alias for `Dict[String, String]` rather than a wrapping type: every operation
a context needs — `context[key]`, `context[key] = value`, `key in context`,
`.pop`, `.update`, `.items`, `.keys`, `.copy`, `len(context)` — is already `Dict`'s
own API, so there was nothing left for a wrapper to add. `to_logfmt`, `to_json`
and `to_json_string` are free functions rather than methods for the same reason:
they are stump-specific renderings of a plain mapping, not part of what a
context fundamentally is.
"""


def update_context_from_kwargs(mut context: Context, kwargs: OwnedKwargsDict[Arg]):
    """Merge keyword arguments into a context, stringifying each value.

    `Dict.update` only accepts another `Dict` of the same type, not an
    `OwnedKwargsDict[Arg]`, so this covers the one conversion a context needs
    that the alias does not get for free.

    Args:
        context: The context to merge the pairs into.
        kwargs: The key-value pairs to merge in.
    """
    for pair in kwargs.items():
        context[pair.key] = String(pair.value)


def to_logfmt(context: Context) -> String:
    """Format the context as a logfmt string.

    Values are quoted and escaped when they contain a delimiter. Keys are
    written as-is, so a key containing a space or an equals sign still
    produces output a decoder cannot split, the same as logfmt itself.

    Args:
        context: The context to format.

    Returns:
        The context formatted as a logfmt string.
    """
    var builder = String()
    var i = 0
    for pair in context.items():
        builder.write(pair.key, "=", _escape_logfmt_value(pair.value))

        if i < len(context) - 1:
            builder.write(" ")
        i += 1

    return builder^


def _to_json(context: Context) -> emberjson.Object:
    """Convert the context to an `emberjson.Object`.

    Args:
        context: The context to convert.

    Returns:
        The context converted to an `emberjson.Object`.
    """
    var fields = Dict[String, emberjson.Value]()
    for pair in context.items():
        fields[pair.key] = emberjson.Value(pair.value)

    return emberjson.Object(fields^)


def to_json_string[pretty: Bool](context: Context) -> String:
    """Convert the context to a JSON string.

    Parameters:
        pretty: Whether to pretty-print the JSON string.

    Args:
        context: The context to convert.

    Returns:
        The context converted to a JSON string.
    """
    return emberjson.to_string[pretty=pretty](_to_json(context))
