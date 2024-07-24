from collections.dict import Dict, KeyElement, DictEntry, OwnedKwargsDict
import external.gojo.io
from .logger import Logger, PrintLogger
from .processor import add_timestamp, add_log_level, Processor, DEFAULT_PROCESSORS
from .formatter import Formatter, default_formatter
from .style import Styles, get_default_styles, DEFAULT_STYLES


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
    var _logger: LoggerType
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
        context: Context = Context(),
        formatter: Formatter = default_formatter,
        apply_styles: Bool = True,
    ):
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
        var new_context = context
        for processor in self.processors:
            new_context = processor[](new_context, level)
        return new_context

    fn _apply_style_to_kvs(self, context: Context, level: Int) -> Context:
        var new_context = Context()

        for pair in context.items():
            var key = pair[].key
            var value = pair[].value

            # Check if there's a style for the key and apply it if so
            # otherwise use the default style for values.
            if key == "level":
                value = self.styles.levels[level].render(value)
            elif key == "message":
                value = self.styles.message.render(value)
            elif key == "timestamp":
                value = self.styles.timestamp.render(value)
            elif key in self.styles.keys:
                key = self.styles.keys.find(key).value().render(key)
            else:
                key = self.styles.key.render(key)

            # Check if there's a style for the value of a key and apply it if so,
            # otherwise use the default style for values.
            if key in self.styles.values:
                value = self.styles.values.find(key).value().render(value)
            else:
                value = self.styles.value.render(value)

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
        self._logger.info(self._transform_message(message, INFO, collect_kvs(args, kwargs)))

    fn warn(self, message: String, /, *args: Arg, **kwargs: Arg):
        self._logger.warn(self._transform_message(message, WARN, collect_kvs(args, kwargs)))

    fn error(self, message: String, /, *args: Arg, **kwargs: Arg):
        self._logger.error(self._transform_message(message, ERROR, collect_kvs(args, kwargs)))

    fn debug(self, message: String, /, *args: Arg, **kwargs: Arg):
        self._logger.debug(self._transform_message(message, DEBUG, collect_kvs(args, kwargs)))

    fn fatal(self, message: String, /, *args: Arg, **kwargs: Arg):
        self._logger.fatal(self._transform_message(message, FATAL, collect_kvs(args, kwargs)))

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


fn get_logger(level: Int = INFO) -> BoundLogger[STDLogger]:
    return BoundLogger(STDLogger(level=level))
