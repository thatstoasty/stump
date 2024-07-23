from collections.dict import OwnedKwargsDict
import external.gojo.io
from .logger import Logger, PrintLogger
from .base import Context, INFO, LEVEL_MAPPING
from .processor import add_timestamp, add_log_level, Processor, get_processors
from .formatter import Formatter, DEFAULT_FORMAT, JSON_FORMAT, format
from .style import Styles, get_default_styles, DEFAULT_STYLES


alias Arg = Variant[String, StringLiteral, Int, Float32, Float64, Bool]


fn collect_kvs(args: VariadicListMem[Arg, _, _], kwargs: OwnedKwargsDict[Arg]) -> Dict[String, String]:
    var message_kvs = Dict[String, String]()
    for pair in kwargs.items():
        message_kvs[pair[].key] = to_str(pair[].value)

    var index = 0
    while True:
        if index >= len(args):
            break

        var next: String = ""
        if index < len(args) - 1:
            next = to_str(args[index + 1])

        message_kvs[to_str(args[index])] = next
        index += 2

    return message_kvs^


fn to_str(arg: Arg) -> String:
    if arg.isa[StringLiteral]():
        return str(arg[StringLiteral])
    elif arg.isa[Int]():
        return str(arg[Int])
    elif arg.isa[Float32]():
        return str(arg[Float32])
    elif arg.isa[Float64]():
        return str(arg[Float64])
    elif arg.isa[Bool]():
        return str(arg[Bool])
    else:
        return arg[String]


struct BoundLogger[LoggerType: Logger]():
    var _logger: LoggerType
    var name: String
    var level: Int
    var context: Context
    var formatter: Formatter
    var processors: List[Processor]
    var styles: Styles
    var apply_styles: Bool

    fn __init__(
        inout self,
        owned logger: LoggerType,
        *,
        name: String = "",
        owned context: Context = Context(),
        formatter: Formatter = DEFAULT_FORMAT,
        apply_styles: Bool = True,
    ):
        self._logger = logger^
        self.name = name
        self.context = context^
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = List[Processor](add_timestamp, add_log_level)
        self.styles = get_default_styles()
        self.apply_styles = apply_styles

    fn __init__(
        inout self,
        owned logger: LoggerType,
        *,
        processors: List[Processor],
        styles: Styles,
        name: String = "",
        owned context: Context = Context(),
        formatter: Formatter = DEFAULT_FORMAT,
        apply_styles: Bool = True,
    ):
        self._logger = logger^
        self.name = name
        self.context = context^
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
        owned context: Context = Context(),
        formatter: Formatter = DEFAULT_FORMAT,
        apply_styles: Bool = True,
    ):
        self._logger = logger^
        self.name = name
        self.context = context^
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = List[Processor](add_timestamp, add_log_level)
        self.styles = styles
        self.apply_styles = apply_styles

    fn __init__(
        inout self,
        owned logger: LoggerType,
        *,
        processors: List[Processor],
        name: String = "",
        owned context: Context = Context(),
        formatter: Formatter = DEFAULT_FORMAT,
        apply_styles: Bool = True,
    ):
        self._logger = logger^
        self.name = name
        self.context = context^
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = processors
        self.styles = get_default_styles()
        self.apply_styles = apply_styles

    fn __moveinit__(inout self, owned other: BoundLogger[LoggerType]):
        self._logger = other._logger^
        self.name = other.name
        self.level = other.level
        self.context = other.context^
        self.formatter = other.formatter
        self.processors = other.processors
        self.styles = other.styles
        self.apply_styles = other.apply_styles

    fn _apply_processors(self, context: Context, level: String) -> Context:
        var new_context = context
        for processor in self.processors:
            new_context = processor[](new_context, level)
        return new_context

    fn _generate_formatted_message(self, context: Context) -> String:
        try:
            return format(self.formatter, context)
        except e:
            # TODO: Decide how to deal with failures in the formatting process. What should fallback be.
            # Letting error propagate up isn't too clean imo.
            print("Failed to format message.", e)

        return ""

    fn _apply_style_to_kvs(self, context: Context) -> Context:
        var new_context = Context()
        var self_styles = self.styles  # Call a function to return the styles

        for pair in context.items():
            var key = pair[].key
            var value = pair[].value

            # Check if there's a style for the log level.
            if key == "level":
                var style = self_styles.levels.find(value)
                if style:
                    value = style.value().render(value)

            # Get the style for the message.
            elif key == "message":
                var style = self_styles.message
                value = style.render(value)

            # Get the style for the timestamp.
            elif key == "timestamp":
                var style = self_styles.timestamp
                value = style.render(value)

            # Check if there's a style for a key and apply it if so, otherwise use the default style for values.
            elif key in self_styles.keys:
                var style = self_styles.keys.find(key).value()
                key = style.render(key)
            else:
                var style = self_styles.key
                key = style.render(key)

            # Check if there's a style for the value of a key and apply it if so, otherwise use the default style for values.
            if key in self_styles.values:
                var style = self_styles.values.find(key).value()
                value = style.render(value)
            else:
                var style = self_styles.value
                value = style.render(value)

            new_context[key] = value
        return new_context

    fn _transform_message(self, message: String, level: Int, message_kvs: Dict[String, String]) -> String:
        """Copy context, merge in new keys, apply processors, format message and return.

        Args:
            message: The message to log.
            level: The log level of the message.
            message_kvs: Additional key-value pairs to include in the log message.

        Returns:
            The formatted message.
        """
        # Copy context so merged changes don't affect the original
        var context = self.get_context()
        context["message"] = message

        # Add args and kwargs from logger call to context.
        for pair in message_kvs.items():
            context[pair[].key] = pair[].value

        # Enrich context data with processors.
        context = self._apply_processors(context, LEVEL_MAPPING[level])

        # Do not apply styling to JSON formatted logs or when it's turned off.
        if self.formatter != JSON_FORMAT and self.apply_styles:
            context = self._apply_style_to_kvs(context)
        return self._generate_formatted_message(context)

    fn info(self, message: String, /, *args: Arg, **kwargs: Arg):
        self._logger.info(self._transform_message(message, INFO, collect_kvs(args, kwargs)))

    fn warn(self, message: String, /, *args: Arg, **kwargs: Arg):
        self._logger.warn(self._transform_message(message, WARN, collect_kvs(args, kwargs)))

    fn error(self, message: String, /, *args: Arg, **kwargs: Arg):
        self._logger.error(self._transform_message(message, ERROR, collect_kvs(args, kwargs)))

    fn debug(self, message: String, /, *args: Arg, **kwargs: Arg):
        self._logger.debug(self._transform_message(message, DEBUG, collect_kvs(args, kwargs)))

    fn fatal(self, message: String, /, *args: Arg, **kwargs: Arg):
        self._logger.fatal(self._transform_message(message, FATAL, collect_kvs(args, kwargs)))

    fn get_context(self) -> Context:
        """Return a deepcopy of the context."""
        return self.context

    fn set_context(inout self, context: Context):
        self.context = context

    fn bind(inout self, context: Context):
        """Bind a new key value pair to the logger context.

        Args:
            context: The key value pair to bind to the logger context.
        """
        for pair in context.items():
            self.context[pair[].key] = pair[].value

    fn get_level(self) -> Int:
        return self.level


fn get_logger(name: String = "", level: Int = INFO) -> BoundLogger[PrintLogger]:
    return BoundLogger(PrintLogger(level), name=name)
