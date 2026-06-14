# from std.builtin import VariadicListMem
from std.collections.dict import Dict, KeyElement, DictEntry, OwnedKwargsDict
from stump.formatter import Formatter, default_formatter
from stump.style import Styles, get_default_styles
from stump.processor import get_default_processors
from stump.context import Context


def collect_kwargs(kwargs: OwnedKwargsDict[Arg]) -> Dict[String, String]:
    var kvs = Dict[String, String]()
    for pair in kwargs.items():
        kvs[pair.key] = String(pair.value)

    return kvs^


def collect_args[*Ts: Writable](args: VariadicPack[False, *Ts], mut kvs: Dict[String, String]):
    var keys = List[String](capacity=len(args))
    var values = List[String](capacity=len(args))

    # Split args into keys and values.
    comptime for i in range(args.__len__()):
        var value = String(args[i])
        if i % 2 == 0:
            keys.append(value^)
        else:
            values.append(value^)

    # Destructively iterate through keys and values and add them to the kvs dict.
    # If there's a remaining key, add it with an empty value.
    while len(values) > 0:
        kvs[keys.pop(0)] = values.pop(0)
    if keys:
        kvs[keys.pop()] = ""


def collect_kvs[
    *Ts: Writable
](args: VariadicPack[False, *Ts], kwargs: OwnedKwargsDict[Arg]) -> Dict[String, String]:
    var kvs = collect_kwargs(kwargs)
    collect_args(args, kvs)

    return kvs^


struct BoundLogger[LoggerType: Logger](Movable):
    """A bound logger that enriches log messages with context data.

    Example Usage:
    ```mojo
    from stump import PrintLogger, BoundLogger, LogLevel

    def main():
        var logger = BoundLogger(PrintLogger[LogLevel.INFO]())
        logger.info("Hello")
        logger.warn("World")
    ```
    """
    comptime level: LogLevel = Self.LoggerType.level

    var _logger: Self.LoggerType
    """The type of the logger to bind to."""
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

    def __init__(
        out self,
        var logger: Self.LoggerType,
        *,
        context: Context = Context(),
        formatter: Formatter = default_formatter,
        var processors: List[Processor] = [],
        var styles: Optional[Styles] = None,
        apply_styles: Bool = True,
    ):
        """Create a new bound logger.

        Args:
            logger: The logger to bind to.
            context: The context data to enrich log messages with.
            formatter: The formatter function used to format log messages.
            processors: The processors functions which will add to the context.
            styles: The styles used to format the log output.
            apply_styles: Whether to apply styles to the log output.
        """
        self._logger = logger^
        self.context = context.copy()
        self.formatter = formatter
        self.processors = processors^ if processors else get_default_processors()
        self.styles = styles.take() if styles else Styles()
        self.apply_styles = apply_styles

    def _apply_processors[level: LogLevel](self, context: Context) -> Context:
        """Apply processors to the context data.

        Parameters:
            level: The log level of the message.

        Args:
            context: The context data to enrich log messages with.

        Returns:
            The enriched context data.
        """
        var new_context = context.copy()
        for processor in self.processors:
            new_context = processor(new_context, String(level))
        return new_context^

    def _apply_style_to_kvs(self, context: Context, level: UInt8) -> Context:
        """Apply styles to the key value pairs in the context data.

        Args:
            context: The context data to enrich log messages with.
            level: The log level of the message.

        Returns:
            The enriched context data.
        """
        var new_context = Context()

        for pair in context.value.items():
            var key = pair.key
            var value = pair.value

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
                var key_style = self.styles.keys.find(key)
                if key_style:
                    key = key_style.value().render(key)
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
        return new_context^

    def _transform_message[T: Writable, //, level: LogLevel](self, message: T, kvs: Dict[String, String]) -> String:
        """Copy context, merge in new keys, apply processors, format message and return.

        Parameters:
            level: The log level of the message.

        Args:
            message: The message to log.
            kvs: Additional key-value pairs to include in the log message.

        Returns:
            The formatted message.
        """
        var context = self.context.copy()
        context["message"] = String(message)

        # Add args and kwargs from logger call to context.
        context.update(kvs)

        # Enrich context data with processors.
        context = self._apply_processors[level](context)

        # Do not apply styling to JSON formatted logs or when it's turned off.
        if self.apply_styles:
            context = self._apply_style_to_kvs(context, level.value)

        return self.formatter(context^)

    def info[T: Writable, //, *Ts: Writable](self, message: T, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the INFO level.

        Parameters:
            T: The type of the message to log.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime if Self.level >= LogLevel.INFO:
            self._logger.info(self._transform_message[LogLevel.INFO](message, collect_kvs(args, kwargs)))

    def warn[T: Writable, //, *Ts: Writable](self, message: T, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the WARN level.

        Parameters:
            T: The type of the message to log.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime if Self.level >= LogLevel.WARN:
            self._logger.warn(self._transform_message[LogLevel.WARN](message, collect_kvs(args, kwargs)))

    def error[T: Writable, //, *Ts: Writable](self, message: T, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the ERROR level.

        Parameters:
            T: The type of the message to log.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime if Self.level >= LogLevel.ERROR:
            self._logger.error(self._transform_message[LogLevel.ERROR](message, collect_kvs(args, kwargs)))

    def debug[T: Writable, //, *Ts: Writable](self, message: T, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the DEBUG level.

        Parameters:
            T: The type of the message to log.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime if Self.level >= LogLevel.DEBUG:
            self._logger.debug(self._transform_message[LogLevel.DEBUG](message, collect_kvs(args, kwargs)))

    def fatal[T: Writable, //, *Ts: Writable](self, message: T, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the FATAL level.

        Parameters:
            T: The type of the message to log.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime if Self.level >= LogLevel.FATAL:
            self._logger.fatal(self._transform_message[LogLevel.FATAL](message, collect_kvs(args, kwargs)))

    def bind(mut self, context: Context):
        """Bind a new key value pair to the logger context.

        Args:
            context: The key value pair to bind to the logger context.
        """
        self.context.update(context)


def get_logger[level: LogLevel = LogLevel.INFO]() -> BoundLogger[PrintLogger[level]]:
    return BoundLogger(PrintLogger[level]())
