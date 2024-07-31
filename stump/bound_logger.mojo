from collections.dict import Dict, KeyElement, DictEntry, OwnedKwargsDict
from .formatter import Formatter, default_formatter
from .style import Styles, get_default_styles


fn collect_kvs(args: VariadicListMem[Arg, _, _], kwargs: OwnedKwargsDict[Arg]) -> Dict[String, String]:
    var kvs = Dict[String, String]()
    for pair in kwargs.items():
        kvs[pair[].key] = to_str(pair[].value)

    var index = 0
    while True:
        if index >= len(args):
            break

        var next: String = ""
        if index < len(args) - 1:
            next = to_str(args[index + 1])

        kvs[to_str(args[index])] = next
        index += 2

    return kvs^


# TODO: Maybe try switching to varadic pack later.
fn to_str(arg: Arg) -> String:
    if arg.isa[StringLiteral]():
        return str(arg[StringLiteral])
    elif arg.isa[Int]():
        return str(arg[Int])
    elif arg.isa[Int8]():
        return str(arg[Int8])
    elif arg.isa[Int16]():
        return str(arg[Int16])
    elif arg.isa[Int32]():
        return str(arg[Int32])
    elif arg.isa[Int64]():
        return str(arg[Int64])
    elif arg.isa[UInt]():
        return str(arg[UInt])
    elif arg.isa[UInt8]():
        return str(arg[UInt8])
    elif arg.isa[UInt16]():
        return str(arg[UInt16])
    elif arg.isa[UInt32]():
        return str(arg[UInt32])
    elif arg.isa[UInt64]():
        return str(arg[UInt64])
    elif arg.isa[Float32]():
        return str(arg[Float32])
    elif arg.isa[Float64]():
        return str(arg[Float64])
    elif arg.isa[Bool]():
        return str(arg[Bool])

    return arg[String]


struct BoundLogger[LoggerType: Logger]():
    """A bound logger that enriches log messages with context data.

    Example Usage:
    ```mojo
    from stump import STDLogger, BoundLogger, INFO

    fn main():
        var logger = BoundLogger(STDLogger(level=INFO))
        logger.info("Hello")
        logger.warn("World")
    ```
    """

    var _logger: LoggerType
    """The type of the logger to bind to."""
    var level: Int
    """The log level of the logger."""
    var context: Context
    """The context data to enrich log messages with."""
    var formatter: Formatter
    """The formatter function used to format log messages."""
    var processors: List[Processor]
    """The processors functions which will add to the context."""
    var styles: Styles
    """The styles used to format the log output."""
    var apply_styles: Bool
    """Whether to apply styles to the log output."""

    fn __init__(
        inout self,
        owned logger: LoggerType,
        *,
        context: Context = Context(),
        formatter: Formatter = default_formatter,
        apply_styles: Bool = True,
    ):
        """Create a new bound logger.

        Args:
            logger: The logger to bind to.
            context: The context data to enrich log messages with.
            formatter: The formatter function used to format log messages.
            apply_styles: Whether to apply styles to the log output.
        """
        self._logger = logger^
        self.context = context
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = get_default_processors()
        self.styles = get_default_styles()
        self.apply_styles = apply_styles

    fn __init__(
        inout self,
        owned logger: LoggerType,
        *,
        processors: List[Processor],
        styles: Styles,
        name: String = "",
        context: Context = Context(),
        formatter: Formatter = default_formatter,
        apply_styles: Bool = True,
    ):
        """Create a new bound logger.

        Args:
            logger: The logger to bind to.
            processors: The processors functions which will add to the context.
            styles: The styles used to format the log output.
            name: The name of the logger.
            context: The context data to enrich log messages with.
            formatter: The formatter function used to format log messages.
            apply_styles: Whether to apply styles to the log output.
        """

        self._logger = logger^
        self.context = context
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = processors
        self.styles = styles
        self.apply_styles = apply_styles

    fn __init__(
        inout self,
        owned logger: LoggerType,
        *,
        styles: Styles,
        name: String = "",
        context: Context = Context(),
        formatter: Formatter = default_formatter,
        apply_styles: Bool = True,
    ):
        """Create a new bound logger.

        Args:
            logger: The logger to bind to.
            styles: The styles used to format the log output.
            name: The name of the logger.
            context: The context data to enrich log messages with.
            formatter: The formatter function used to format log messages.
            apply_styles: Whether to apply styles to the log output.
        """

        self._logger = logger^
        self.context = context
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = get_default_processors()
        self.styles = styles
        self.apply_styles = apply_styles

    fn __init__(
        inout self,
        owned logger: LoggerType,
        *,
        processors: List[Processor],
        name: String = "",
        context: Context = Context(),
        formatter: Formatter = default_formatter,
        apply_styles: Bool = True,
    ):
        """Create a new bound logger.

        Args:
            logger: The logger to bind to.
            processors: The processors functions which will add to the context.
            name: The name of the logger.
            context: The context data to enrich log messages with.
            formatter: The formatter function used to format log messages.
            apply_styles: Whether to apply styles to the log output.
        """
        self._logger = logger^
        self.context = context
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = processors
        self.styles = get_default_styles()
        self.apply_styles = apply_styles

    fn __moveinit__(inout self, owned other: BoundLogger[LoggerType]):
        self._logger = other._logger^
        self.level = other.level
        self.context = other.context^
        self.formatter = other.formatter
        self.processors = other.processors^
        self.styles = other.styles^
        self.apply_styles = other.apply_styles

    fn _apply_processors(self, context: Context, level: String) -> Context:
        """Apply processors to the context data.

        Args:
            context: The context data to enrich log messages with.
            level: The log level of the message.

        Returns:
            The enriched context data.
        """
        var new_context = context
        for processor in self.processors:
            new_context = processor[](new_context, level)
        return new_context

    fn _apply_style_to_kvs(self, context: Context, level: Int) -> Context:
        """Apply styles to the key value pairs in the context data.

        Args:
            context: The context data to enrich log messages with.
            level: The log level of the message.

        Returns:
            The enriched context data.
        """
        var new_context = Context()

        for pair in context.items():
            var key = pair[].key
            var value = pair[].value

            # Check if there's a style for the key and apply it if so
            # otherwise use the default style for values.
            if key == "level":
                value = self.styles.levels[level].render(value)
            elif key == "message":
                if self.styles.message:
                    value = self.styles.message.value().render(value)
            elif key == "timestamp":
                if self.styles.timestamp:
                    value = self.styles.timestamp.value().render(value)
            elif key in self.styles.keys:
                key = self.styles.keys.find(key).value().render(key)
            else:
                if self.styles.key:
                    key = self.styles.key.value().render(key)

            # Check if there's a style for the value of a key and apply it if so,
            # otherwise use the default style for values.
            var value_style = self.styles.values.find(key)
            if value_style:
                value = value_style.value().render(value)
            else:
                if self.styles.value:
                    value = self.styles.value.value().render(value)

            new_context[key] = value
        return new_context

    fn _transform_message(self, message: String, level: Int, kvs: Dict[String, String]) -> String:
        """Copy context, merge in new keys, apply processors, format message and return.

        Args:
            message: The message to log.
            level: The log level of the message.
            kvs: Additional key-value pairs to include in the log message.

        Returns:
            The formatted message.
        """
        var context = self.context
        context["message"] = message

        # Add args and kwargs from logger call to context.
        for pair in kvs.items():
            context[pair[].key] = pair[].value

        # Enrich context data with processors.
        context = self._apply_processors(context, LEVEL_MAPPING[level])

        # Do not apply styling to JSON formatted logs or when it's turned off.
        if self.apply_styles:
            context = self._apply_style_to_kvs(context, level)

        return self.formatter(context)

    fn info(self, message: String, /, *args: Arg, **kwargs: Arg):
        """Log a message at the INFO level.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        self._logger.info(self._transform_message(message, INFO, collect_kvs(args, kwargs)))

    fn warn(self, message: String, /, *args: Arg, **kwargs: Arg):
        """Log a message at the WARN level.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        self._logger.warn(self._transform_message(message, WARN, collect_kvs(args, kwargs)))

    fn error(self, message: String, /, *args: Arg, **kwargs: Arg):
        """Log a message at the ERROR level.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        self._logger.error(self._transform_message(message, ERROR, collect_kvs(args, kwargs)))

    fn debug(self, message: String, /, *args: Arg, **kwargs: Arg):
        """Log a message at the DEBUG level.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        self._logger.debug(self._transform_message(message, DEBUG, collect_kvs(args, kwargs)))

    fn fatal(self, message: String, /, *args: Arg, **kwargs: Arg):
        """Log a message at the FATAL level.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        self._logger.fatal(self._transform_message(message, FATAL, collect_kvs(args, kwargs)))

    fn bind(inout self, context: Context):
        """Bind a new key value pair to the logger context.

        Args:
            context: The key value pair to bind to the logger context.
        """
        self.context.update(context)

    fn get_level(self) -> Int:
        """Get the log level of the logger. Temporary until traits support variables."""
        return self.level


fn get_logger(level: Int = INFO) -> BoundLogger[STDLogger]:
    return BoundLogger(STDLogger(level=level))
