from collections.dict import Dict, KeyElement
from external.morrow import Morrow


alias FATAL = 0
alias ERROR = 1
alias WARN = 2
alias INFO = 3
alias DEBUG = 4


alias LOG_LEVEL = DEBUG

alias RED = "\033[91m"
alias GREEN = "\033[92m"
alias YELLOW = "\033[93m"
alias BLUE = "\033[94m"
alias PURPLE = "\033[95m"


@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s ^

    fn __init__(inout self, s: StringLiteral):
        self.s = String(s)

    fn __hash__(self) -> Int:
        return hash(self.s)

    fn __eq__(self, other: Self) -> Bool:
        return self.s == other.s
    
    fn __str__(self) -> String:
        return self.s


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


alias Context = Dict[StringKey, String]
alias Preprocessor = fn() -> String
alias morrow = Morrow


@value
struct BoundLogger[L: Logger](Logger):
    var logger: L
    var context: Context
    var level: Int

    fn __init__(
        inout self, 
        owned logger: L,
        *, 
        owned context: Context = Context(),
    ):
        self.logger = logger ^
        self.context = context ^
        self.level = self.logger.get_level()
    
    fn _preprocess_message(self, context: Context) -> String:
        var timestamp: String = ""
        try:
            timestamp = morrow.now().format("YYYY-MM-DD HH:mm:ss")
        except:
            pass

        var message: String = ""
        try:
            message = context["message"]
        except:
            print("No message in context")
        
        var level: Int = ERROR
        try:
            level = atol(context["level"])
        except:
            print("Unable to parse context, setting to ERROR level.")

        return timestamp + " " + level_mapping[level] + " " + message

    fn info(self, message: String):
        # Copy context so merged changes don't affect the original
        var context = self.get_context()
        context["message"] = message
        context["level"] = INFO
        self.logger.info(self._preprocess_message(context))
    
    fn warn(self, message: String):
        var context = self.get_context()
        context["message"] = message
        context["level"] = WARN
        self.logger.warn(self._preprocess_message(context))
    
    fn error(self, message: String):
        var context = self.get_context()
        context["message"] = message
        context["level"] = ERROR
        self.logger.error(self._preprocess_message(context))
    
    fn debug(self, message: String):
        var context = self.get_context()
        context["message"] = message
        context["level"] = DEBUG
        self.logger.debug(self._preprocess_message(context))
    
    fn fatal(self, message: String):
        var context = self.get_context()
        context["message"] = message
        context["level"] = FATAL
        self.logger.debug(self._preprocess_message(context))
    
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


fn build_logger() -> BasicLogger:
    return BasicLogger(LOG_LEVEL)


fn bound_logger[L: Logger](l: L) -> BoundLogger[L]:
    var bound_log = BoundLogger[L](l)
    return bound_log


fn get_level_mapping() -> DynamicVector[String]:
    var mapping = DynamicVector[String]()
    mapping.append(String(PURPLE) + String("FATAL") + String("\033[0m"))
    mapping.append(String(RED) + String("ERROR") + String("\033[0m"))
    mapping.append(String(YELLOW) + String("WARN") + String("\033[0m"))
    mapping.append(String(GREEN) + String("INFO") + String("\033[0m"))
    mapping.append(String(BLUE) + String("DEBUG") + String("\033[0m"))
    return mapping


alias inner_logger = build_logger()
alias logger = bound_logger(inner_logger)
alias level_mapping = get_level_mapping()


fn main() raises:
    var log = logger
    log.info("This shouldn't print")
    log.warn("This should")
    log.error("An error!")
    log.debug("Debugging...")

    log.fatal("uh oh...")
    raise Error("ded")

