from .base import Context
from .processor import add_timestamp, add_log_level, Processor, get_processors
from .formatter import LEVEL_MAPPING, Formatter, DEFAULT_FORMAT, format
from .style import Styles, get_default_styles


trait Logger(Movable, Copyable):
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
# Temporary hacky solution, but a function that returns the list of processors to run DOES work.
@value
struct BoundLogger[L: Logger](Logger):
    var _logger: L
    var level: Int
    var context: Context
    var formatter: Formatter
    var processors: fn() -> List[Processor]
    var styles: Styles

    fn __init__(
        inout self,
        owned logger: L,
        *,
        owned context: Context = Context(),
        formatter: Formatter = DEFAULT_FORMAT,
        processors: fn() -> List[Processor] = get_processors,
        styles: Styles = get_default_styles()
    ):
        self._logger = logger ^
        self.context = context ^
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = processors
        self.styles = styles

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
        for pair in context.items():
            var key = pair[].key
            var value = pair[].value

            # Check if there's a style for a given key and apply it if so.
            if key in self.styles.keys:
                var style = self.styles.keys.find(key).value()
                key = style.render(key)

            # Check if there's a style for a given value and apply it if so.
            if value in self.styles.values:
                var style = self.styles.keys.find(value).value()
                value = style.render(value)
            
            new_context[key] = value
        return new_context
    
    fn _transform_message(self, message: String, level: Int) -> String:
        """Copy context, merge in new keys, apply processors, format message and return.
        
        Args:
            message: The message to log.
            level: The log level of the message.
        
        Returns:
            The formatted message.
        """
        # Copy context so merged changes don't affect the original
        var context = self.get_context()
        context["message"] = message
        context["level"] = level
        context = self._apply_processors(context)
        context = self._apply_style_to_kvs(context)
        return self._generate_formatted_message(context)

    fn info(self, message: String):
        self._logger.info(self._transform_message(message, INFO))

    fn warn(self, message: String):
        self._logger.warn(self._transform_message(message, WARN))

    fn error(self, message: String):
        self._logger.error(self._transform_message(message, ERROR))

    fn debug(self, message: String):
        self._logger.debug(self._transform_message(message, DEBUG))

    fn fatal(self, message: String):
        self._logger.fatal(self._transform_message(message, FATAL))

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
