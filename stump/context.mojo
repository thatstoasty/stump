"""Bound Logger Context."""
from std.collections.dict import DictEntry, _DictEntryIter, DictKeyError, OwnedKwargsDict
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


comptime ContextDict = Dict[String, String]
"""The mapping a `Context` wraps."""


struct Context(Copyable, Sized, Writable):
    """A context for a log message, containing key-value pairs of data to include in the log message."""

    var value: ContextDict
    """Dictionary containing the key-value pairs of data in the context."""

    def __init__(out self, value: OwnedKwargsDict[Arg]):
        """Initializes the context with an optional dictionary of key-value pairs.

        Args:
            value: An optional dictionary of key-value pairs to initialize the context with. Defaults to an empty dictionary.
        """
        self.value = ContextDict(capacity=len(value))
        self.update(value)

    @implicit
    def __init__(out self, var value: ContextDict = ContextDict()):
        """Initializes the context with an optional dictionary of key-value pairs.

        Args:
            value: An optional dictionary of key-value pairs to initialize the context with. Defaults to an empty dictionary.
        """
        self.value = value^

    def __getitem__(ref self, ref key: String) raises DictKeyError[String] -> ref[self.value] String:
        """Retrieve a value out of the context.

        Args:
            key: The key to retrieve.

        Returns:
            The value associated with the key, if it's present.

        Raises:
            `DictKeyError` if the key isn't present.
        """
        return self.value[key]

    def __setitem__(mut self, var key: String, var value: String):
        """Set a value in the context by key.

        Args:
            key: The key to associate with the specified value.
            value: The data to store in the context.
        """
        self.value[key^] = value^

    def __contains__(self, key: String) -> Bool:
        """Check if a key is present in the context.

        Args:
            key: The key to check for.

        Returns:
            `True` if the key is present in the context, `False` otherwise.
        """
        return key in self.value

    def clear(mut self):
        """Clear all key-value pairs from the context."""
        self.value.clear()

    def update(mut self, other: Context):
        """Update the context with key-value pairs from another context.

        Args:
            other: The other context to update from.
        """
        self.value.update(other.value)

    def update(mut self, other: Dict[String, String]):
        """Update the context with key-value pairs from a dictionary.

        Args:
            other: The dictionary to update from.
        """
        self.value.update(other)

    def update(mut self, other: OwnedKwargsDict[Arg]):
        """Update the context with key-value pairs from a dictionary.

        Args:
            other: The dictionary to update from.
        """
        for pair in other.items():
            self.value[pair.key] = String(pair.value)

    def pop(mut self, key: String) raises DictKeyError[String] -> String:
        """Remove a key from the context and return its value.

        Args:
            key: The key to remove and return the value of.

        Returns:
            The value associated with the key that was removed.

        Raises:
            `DictKeyError` if the key isn't present in the context.
        """
        return self.value.pop(key)

    def __len__(self) -> Int:
        """Count the key-value pairs in the context.

        Returns:
            The number of pairs.
        """
        return len(self.value)

    def items(ref self) -> _DictEntryIter[String, String, ContextDict.H, origin_of(self.value)]:
        """Iterate the key-value pairs in the context.

        A custom `Formatter` receives a `Context` and needs a way to walk it. The
        hasher is spelled `ContextDict.H` rather than named outright so this
        signature survives the standard library changing its default.

        Returns:
            An iterator over the pairs, in insertion order.
        """
        return self.value.items()

    def keys(self) -> List[String]:
        """Collect the context's keys.

        Returns:
            The keys, in insertion order.
        """
        var result = List[String](capacity=len(self.value))
        for pair in self.value.items():
            result.append(pair.key)

        return result^

    def to_logfmt(self) -> String:
        """Format the context as a logfmt string.

        Values are quoted and escaped when they contain a delimiter. Keys are
        written as-is, so a key containing a space or an equals sign still
        produces output a decoder cannot split, the same as logfmt itself.

        Returns:
            The context formatted as a logfmt string.
        """
        var builder = String()
        var i = 0
        for pair in self.value.items():
            builder.write(pair.key, "=", _escape_logfmt_value(pair.value))

            if i < len(self.value) - 1:
                builder.write(" ")
            i += 1

        return builder^

    def to_json(self) -> emberjson.Object:
        """Convert the context to an `emberjson.Object`.

        Returns:
            The context converted to an `emberjson.Object`.
        """
        var new_context = Dict[String, emberjson.Value]()
        for pair in self.value.items():
            new_context[pair.key] = emberjson.Value(pair.value)

        return emberjson.Object(new_context^)

    def to_json_string(self) -> String:
        """Convert the context to a JSON string.

        Returns:
            The context converted to a JSON string.
        """
        return emberjson.to_string(self.to_json())
