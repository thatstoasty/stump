from .base import Context
from .processor import add_timestamp
from .formatter import LEVEL_MAPPING, Formatter, DEFAULT_FORMAT, format


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
struct BasicLogger(Logger):
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


@value
struct BoundLogger[L: Logger](Logger):
    var logger: L
    var context: Context
    var level: Int
    var formatter: Formatter

    fn __init__(
        inout self, 
        owned logger: L,
        *, 
        owned context: Context = Context(),
        formatter: Formatter = DEFAULT_FORMAT,
    ):
        self.logger = logger ^
        self.context = context ^
        self.level = self.logger.get_level()
        self.formatter = formatter
    
    fn apply_processors(self, inout context: Context):
        # TODO: Should run a list of processors that modify the context
        add_timestamp(context)
    
    fn generate_formatted_message(self, context: Context) -> String:
        var formatted_text: String = ""
        try:
            formatted_text = context.find("message").value()
            formatted_text = format(self.formatter, context)
        except e:
            # TODO: Decide how to deal with failures in the formatting process. What should fallback be.
            # Letting error propagate up isn't too clean imo.
            print("Failed to format message.")

        return formatted_text

    fn info(self, message: String):
        # Copy context so merged changes don't affect the original
        var context = self.get_context()
        context["message"] = message
        context["level"] = INFO
        self.apply_processors(context)
        self.logger.info(self.generate_formatted_message(context))
    
    fn warn(self, message: String):
        var context = self.get_context()
        context["message"] = message
        context["level"] = WARN
        self.apply_processors(context)
        self.logger.warn(self.generate_formatted_message(context))
    
    fn error(self, message: String):
        var context = self.get_context()
        context["message"] = message
        context["level"] = ERROR
        self.apply_processors(context)
        self.logger.error(self.generate_formatted_message(context))
    
    fn debug(self, message: String):
        var context = self.get_context()
        context["message"] = message
        context["level"] = DEBUG
        self.apply_processors(context)
        self.logger.debug(self.generate_formatted_message(context))
    
    fn fatal(self, message: String):
        var context = self.get_context()
        context["message"] = message
        context["level"] = FATAL
        self.apply_processors(context)
        self.logger.fatal(self.generate_formatted_message(context))
    
    fn get_context(self) -> Context:
        """Return a copy of the context."""
        var context = Context()
        for pair in self.context.items():
            context[pair[].key] = pair[].value
        return context
    
    fn set_context(inout self, context: Context):
        self.context = context

    fn bind(inout self, context: Context):
        for pair in context.items():
            self.context[pair[].key] = pair[].value
        
    fn get_level(self) -> Int:
        return self.level