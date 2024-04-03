import external.gojo.io
from .base import Context, INFO
from .processor import add_timestamp, add_log_level, Processor, get_processors
from .formatter import Formatter, DEFAULT_FORMAT, JSON_FORMAT, format
from .style import Styles, get_default_styles, DEFAULT_STYLES


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
    var processors: fn () -> List[Processor]
    var styles: fn () -> Styles

    fn __init__(
        inout self,
        owned logger: L,
        *,
        name: String = "",
        owned context: Context = Context(),
        formatter: Formatter = DEFAULT_FORMAT,
        processors: fn () -> List[Processor] = get_processors,
        styles: fn () -> Styles = get_default_styles,
    ):
        self._logger = logger ^
        self.name = name
        self.context = context ^
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = processors
        self.styles = styles
    
    fn __moveinit__(inout self, owned other: BoundLogger[L]):
        self._logger = other._logger ^
        self.name = other.name
        self.level = other.level
        self.context = other.context ^
        self.formatter = other.formatter
        self.processors = other.processors
        self.styles = other.styles

    fn _apply_processors(self, context: Context) -> Context:
        var new_context = Context(context)
        for processor in self.processors():
            new_context = processor[](new_context)
        return new_context

    fn _generate_formatted_message(self, context: Context) -> String:
        var formatted_text: String = ""
        try:
            formatted_text = context.find("message").value()
            formatted_text = format(self.formatter, context)
        except e:
            # TODO: Decide how to deal with failures in the formatting process. What should fallback be.
            # Letting error propagate up isn't too clean imo.
            print("Failed to format message.", e)

        return formatted_text

    fn _apply_style_to_kvs(self, context: Context) -> Context:
        var new_context = Context()
        var self_styles = self.styles()  # Call a function to return the styles

        for pair in context.items():
            var key = pair[].key
            var value = pair[].value

            # Check if there's a style for the log level.
            if key == "level":
                var style = self_styles.levels.find(value).value()
                value = style.render(value)

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
        context["level"] = level

        # Add args and kwargs from logger call to context.
        for pair in message_kvs.items():
            context[pair[].key] = pair[].value

        # Enrich context data with processors.
        context = self._apply_processors(context)

        # Do not apply styling to JSON formatted logs
        if self.formatter != JSON_FORMAT:
            context = self._apply_style_to_kvs(context)
        return self._generate_formatted_message(context)

    fn info(self, message: String, /, *args: String, **kwargs: String):        
        # TODO: Just copying this logic until arg unpacking works
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        var arg_count = len(args)
        var index = 0
        while True:
            if index >= arg_count:
                break
            
            var next: String = ""
            if index < arg_count - 1:
                next = args[index + 1]

            kwargs[args[index]] = next
            index += 2

        self._logger.info(self._transform_message(message, INFO, kwargs))

    fn warn(self, message: String, /, *args: String, **kwargs: String):
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        var arg_count = len(args)
        var index = 0
        while True:
            if index >= arg_count:
                break
            
            var next: String = ""
            if index < arg_count - 1:
                next = args[index + 1]

            kwargs[args[index]] = next
            index += 2

        self._logger.warn(self._transform_message(message, WARN, kwargs))

    fn error(self, message: String, /, *args: String, **kwargs: String):
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        var arg_count = len(args)
        var index = 0
        while True:
            if index >= arg_count:
                break
            
            var next: String = ""
            if index < arg_count - 1:
                next = args[index + 1]

            kwargs[args[index]] = next
            index += 2
        
        self._logger.error(self._transform_message(message, ERROR, kwargs))

    fn debug(self, message: String, /, *args: String, **kwargs: String):
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        var arg_count = len(args)
        var index = 0
        while True:
            if index >= arg_count:
                break
            
            var next: String = ""
            if index < arg_count - 1:
                next = args[index + 1]

            kwargs[args[index]] = next
            index += 2

        self._logger.debug(self._transform_message(message, DEBUG, kwargs))

    fn fatal(self, message: String, /, *args: String, **kwargs: String):
        # Iterate through all args and add it to kwargs. If uneven number, last key will be empty string.
        var arg_count = len(args)
        var index = 0
        while True:
            if index >= arg_count:
                break
            
            var next: String = ""
            if index < arg_count - 1:
                next = args[index + 1]

            kwargs[args[index]] = next
            index += 2
        
        self._logger.fatal(self._transform_message(message, FATAL, kwargs))

    fn get_context(self) -> Context:
        """Return a deepcopy of the context."""
        return Context(self.context)

    fn set_context(inout self, context: Context):
        self.context = context

    fn bind(inout self, context: Context):
        for pair in context.items():
            self.context[pair[].key] = pair[].value

    fn get_level(self) -> Int:
        return self.level


fn get_logger(name: String = "", level: Int = INFO) -> BoundLogger[PrintLogger]:
    return BoundLogger(PrintLogger(level), name=name)
