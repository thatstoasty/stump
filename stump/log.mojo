from utils.variant import Variant
import external.gojo.io
from .base import Context, INFO, LEVEL_MAPPING
from .processor import add_timestamp, add_log_level, ProcessorFn, get_processors, GetProcessorsFn
from .formatter import Formatter, DEFAULT_FORMAT, JSON_FORMAT, format
from .style import Styles, get_default_styles, DEFAULT_STYLES, GetStylesFn

alias ValidArgType = Variant[String, StringLiteral, Int, Float32, Float64, Bool]


fn valid_arg_to_string(valid_arg: ValidArgType) -> String:
    if valid_arg.isa[StringLiteral]():
        return str(valid_arg[StringLiteral])
    elif valid_arg.isa[Int]():
        return str(valid_arg[Int])
    elif valid_arg.isa[Float32]():
        return str(valid_arg[Float32])
    elif valid_arg.isa[Float64]():
        return str(valid_arg[Float64])
    elif valid_arg.isa[Bool]():
        return str(valid_arg[Bool])
    else:
        return valid_arg[String]


trait Logger(Movable):
    fn info(self, message: String):
        ...

    fn warn(self, message: String):
        ...

    fn error(self, message: String):
        ...

    fn debug(self, message: String):
        ...

    fn fatal(self, message: String):
        ...

    # TODO: Temporary until traits allow fields
    fn get_level(self) -> Int:
        ...


@value
struct PrintLogger(Logger):
    var level: Int

    fn __init__(inout self, level: Int = WARN):
        self.level = level

    fn _log_message(self, message: String, level: Int):
        if self.level >= level:
            print(message)

    fn info(self, message: String):
        self._log_message(message, INFO)

    fn warn(self, message: String):
        self._log_message(message, WARN)

    fn error(self, message: String):
        self._log_message(message, ERROR)

    fn debug(self, message: String):
        self._log_message(message, DEBUG)

    fn fatal(self, message: String):
        self._log_message(message, FATAL)

    fn get_level(self) -> Int:
        return self.level


# TODO: Trying to store processors as a variable struct blows up the compiler. Pulling them out into a function for now.
# Temporary hacky solution, but a function that returns the list of processors to run DOES work. Same with Styles, it blows up the compiler.
struct BoundLogger[L: Logger]():
    var _logger: L
    var name: String
    var level: Int
    var context: Context
    var formatter: Formatter
    var processors: GetProcessorsFn
    var styles: GetStylesFn
    # var styles: Styles
    var apply_styles: Bool

    fn __init__(
        inout self,
        owned logger: L,
        *,
        name: String = "",
        owned context: Context = Context(),
        formatter: Formatter = DEFAULT_FORMAT,
        processors: GetProcessorsFn = get_processors,
        styles: GetStylesFn = get_default_styles,
        # styles: Styles = DEFAULT_STYLES,
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

    fn __moveinit__(inout self, owned other: BoundLogger[L]):
        self._logger = other._logger^
        self.name = other.name
        self.level = other.level
        self.context = other.context^
        self.formatter = other.formatter
        self.processors = other.processors
        self.styles = other.styles
        self.apply_styles = other.apply_styles

    fn _apply_processors(self, context: Context, level: String) -> Context:
        var new_context = Context(context)
        for processor in self.processors():
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
        var self_styles = self.styles()

        for pair in context.items():
            var key = str(pair[].key)
            var value = str(pair[].value)

            # Check if there's a style for the log level.
            if key == "level":
                value = self_styles.levels.find(value).value()[].render(value)

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
                key = self_styles.keys.find(key).value()[].render(key)
            else:
                key = self_styles.key.render(key)

            # Check if there's a style for the value of a key and apply it if so, otherwise use the default style for values.
            if key in self_styles.values:
                value = self_styles.values.find(key).value()[].render(value)
            else:
                value = self_styles.value.render(value)

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

    fn info[T: Stringable, *Ts: Stringable](self, message: T, /, *args: *Ts, **kwargs: ValidArgType):
        # TODO: Just copying this logic until arg unpacking works
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        var message_kvs = Dict[String, String]()
        for pair in kwargs.items():
            message_kvs[pair[].key] = valid_arg_to_string(pair[].value)

        var index = 0
        var keys = List[String]()
        var values = List[String]()

        @parameter
        fn pair_args[T: Stringable](arg: T) -> None:
            if index == 0 or index % 2 == 0:
                keys.append(str(arg))
            else:
                values.append(str(arg))

            index += 1

        args.each[pair_args]()

        for i in range(len(keys)):
            var value = String("")
            if i < len(values):
                value = values[i]

            message_kvs[keys[i]] = value

        self._logger.info(self._transform_message(message, INFO, message_kvs))

    fn warn[T: Stringable, *Ts: Stringable](self, message: T, /, *args: *Ts, **kwargs: ValidArgType):
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        # TODO: kwargs aren't just a dict anymore, need to copy the values over.
        var message_kvs = Dict[String, String]()
        for pair in kwargs.items():
            message_kvs[pair[].key] = valid_arg_to_string(pair[].value)

        var index = 0
        var keys = List[String]()
        var values = List[String]()

        @parameter
        fn pair_args[T: Stringable](arg: T) -> None:
            if index == 0 or index % 2 == 0:
                keys.append(str(arg))
            else:
                values.append(str(arg))

            index += 1

        args.each[pair_args]()

        for i in range(len(keys)):
            var value = String("")
            if i < len(values):
                value = values[i]

            message_kvs[keys[i]] = value

        self._logger.warn(self._transform_message(message, WARN, message_kvs))

    fn error[T: Stringable, *Ts: Stringable](self, message: T, /, *args: *Ts, **kwargs: ValidArgType):
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        var message_kvs = Dict[String, String]()
        for pair in kwargs.items():
            message_kvs[pair[].key] = valid_arg_to_string(pair[].value)

        var index = 0
        var keys = List[String]()
        var values = List[String]()

        @parameter
        fn pair_args[T: Stringable](arg: T) -> None:
            if index == 0 or index % 2 == 0:
                keys.append(str(arg))
            else:
                values.append(str(arg))

            index += 1

        args.each[pair_args]()

        for i in range(len(keys)):
            var value = String("")
            if i < len(values):
                value = values[i]

            message_kvs[keys[i]] = value

        self._logger.error(self._transform_message(message, ERROR, message_kvs))

    fn debug[T: Stringable, *Ts: Stringable](self, message: T, /, *args: *Ts, **kwargs: ValidArgType):
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        var message_kvs = Dict[String, String]()
        for pair in kwargs.items():
            message_kvs[pair[].key] = valid_arg_to_string(pair[].value)

        var index = 0
        var keys = List[String]()
        var values = List[String]()

        @parameter
        fn pair_args[T: Stringable](arg: T) -> None:
            if index == 0 or index % 2 == 0:
                keys.append(str(arg))
            else:
                values.append(str(arg))

            index += 1

        args.each[pair_args]()

        for i in range(len(keys)):
            var value = String("")
            if i < len(values):
                value = values[i]

            message_kvs[keys[i]] = value

        self._logger.debug(self._transform_message(message, DEBUG, message_kvs))

    fn fatal[T: Stringable, *Ts: Stringable](self, message: T, /, *args: *Ts, **kwargs: ValidArgType):
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        var message_kvs = Dict[String, String]()
        for pair in kwargs.items():
            message_kvs[pair[].key] = valid_arg_to_string(pair[].value)

        var index = 0
        var keys = List[String]()
        var values = List[String]()

        @parameter
        fn pair_args[T: Stringable](arg: T) -> None:
            if index == 0 or index % 2 == 0:
                keys.append(str(arg))
            else:
                values.append(str(arg))

            index += 1

        args.each[pair_args]()

        for i in range(len(keys)):
            var value = String("")
            if i < len(values):
                value = values[i]

            message_kvs[keys[i]] = value

        self._logger.fatal(self._transform_message(message, FATAL, message_kvs))

    fn get_context(self) -> Context:
        """Return a deepcopy of the context."""
        return Context(self.context)

    fn set_context(inout self, context: Context):
        self.context = context

    fn bind(inout self, context: Context):
        """Bind a new key value pair to the logger context.
        NOT USABLE until Mojo adds support for file level scope.
        Usable if the logger is built at runtime as a variable, but not as an alias.

        Args:
            context: The key value pair to bind to the logger context.
        """
        for pair in context.items():
            self.context[pair[].key] = pair[].value

    fn get_level(self) -> Int:
        return self.level


fn get_logger(name: String = "", level: Int = INFO) -> BoundLogger[PrintLogger]:
    return BoundLogger(PrintLogger(level), name=name)
