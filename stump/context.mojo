"""Bound Logger Context."""
from std.collections.dict import Dict, DictEntry, _DictEntryIter, DictKeyError
import emberjson


struct Context(Copyable, Writable):
    """A context for a log message, containing key-value pairs of data to include in the log message."""

    var value: Dict[String, String]
    """Dictionary containing the key-value pairs of data in the context."""

    @implicit
    def __init__(out self, var value: Dict[String, String] = Dict[String, String]()):
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

    def update(mut self, other: Context, /):
        """Update the context with key-value pairs from another context.

        Args:
            other: The other context to update from.
        """
        self.value.update(other.value)

    def update(mut self, other: Dict[String, String], /):
        """Update the context with key-value pairs from a dictionary.

        Args:
            other: The dictionary to update from.
        """
        self.value.update(other)

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

    # def items(ref self) -> _DictEntryIter[String, String, origin_of(self.value)]:
    #     return self.value.items()

    def to_logfmt(self) -> String:
        """Format the context as a logfmt string.

        Returns:
            The context formatted as a logfmt string.
        """
        var builder = String()
        var i = 0
        for pair in self.value.items():
            builder.write(t"{pair.key}={pair.value}")

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
