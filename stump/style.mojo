"""Styles for log output."""
import mist


comptime Sections = Dict[String, mist.Style]
"""A mapping of context keys to styles."""

comptime SEPARATOR: StaticString = "="
"""The character the formatters write between a context key and its value."""


struct Styles(Copyable):
    """Styles for log output, including styles for different log levels and context keys."""

    var timestamp: Optional[mist.Style]
    """Style for the log message itself."""
    var message: Optional[mist.Style]
    """Style for the log message itself."""
    var key: Optional[mist.Style]
    """Style for context keys."""
    var value: Optional[mist.Style]
    """Style for context values."""
    var separator: Optional[mist.Style]
    """Style for separators between context key-value pairs."""
    var levels: InlineArray[mist.Style, 5]
    """Styles for different log levels, indexed by the log level enum value."""
    var keys: Sections
    """Styles for specific context keys."""
    var values: Sections
    """Styles for specific context values."""

    def __init__(
        out self,
        *,
        timestamp: Optional[mist.Style] = None,
        message: Optional[mist.Style] = None,
        key: Optional[mist.Style] = None,
        value: Optional[mist.Style] = None,
        separator: Optional[mist.Style] = None,
        var levels: Optional[InlineArray[mist.Style, 5]] = None,
        var keys: Sections = Sections(),
        var values: Sections = Sections(),
    ):
        """Initializes the styles for log output.

        Args:
            timestamp: Style for the log message itself.
            message: Style for the log message itself.
            key: Style for context keys.
            value: Style for context values.
            separator: Style for separators between context key-value pairs.
            levels: Styles for different log levels, indexed by the log level enum value.
            keys: Styles for specific context keys.
            values: Styles for specific context values.
        """
        var style = mist.Style()
        self.timestamp = timestamp
        self.message = message
        self.key = key if key else style.faint()
        self.value = value
        self.separator = separator if separator else style.faint()

        if levels:
            self.levels = levels.take()
        else:
            self.levels = [
                style.foreground(0xD4317D),
                style.foreground(0xD48244),
                style.foreground(0xDECF2F),
                style.foreground(0x13ED84),
                style.foreground(0xBD37DB),
            ]
        self.keys = keys^
        self.values = values^

    def separator_sequences(self) -> Tuple[String, String]:
        """Split the styled separator into the sequences that surround the `=`.

        The formatters write the `=` between a key and its value themselves, so the
        separator style cannot be applied by rendering the character here. Rendering
        `=` and splitting the result on it yields the opening sequence, which belongs
        at the end of the key, and the closing sequence, which belongs at the start of
        the value. The `=` the formatter writes then lands between the two.

        Returns:
            The sequence to append to the key, and the sequence to prepend to the
            value. Both are empty when no separator style is set, or when the style
            renders nothing because it is empty or its profile has color turned off.
        """
        if not self.separator:
            return String(), String()

        var parts = self.separator.value().render(SEPARATOR).split(SEPARATOR)
        if len(parts) != 2:
            return String(), String()

        return String(parts[0]), String(parts[1])
