from builtin.builtin_list import VariadicListMem
from collections.dict import Dict, KeyElement, DictEntry, OwnedKwargsDict
from .formatter import Formatter, default_formatter
from .style import Styles, get_default_styles
from .processor import GetProcessorsFn
from .context import Context


fn collect_kwargs(kwargs: OwnedKwargsDict[Arg]) -> Dict[String, String]:
    var kvs = Dict[String, String]()
    for pair in kwargs.items():
        kvs[pair[].key] = str(pair[].value)

    return kvs^


fn collect_args[*Ts: Stringable](args: VariadicPack[_, Stringable, *Ts], mut kvs: Dict[String, String]):
    var keys = List[String](capacity=len(args))
    var values = List[String](capacity=len(args))

    # Split args into keys and values.
    @parameter
    fn split_args[i: Int, T: Stringable](arg: T) -> None:
        var value = str(arg)
        if i % 2 == 0:
            keys.append(value)
        else:
            values.append(value)

    args.each_idx[split_args]()

    # Destructively iterate through keys and values and add them to the kvs dict.
    # If there's a remaining key, add it with an empty value.
    while len(values) > 0:
        kvs[keys.pop(0)] = values.pop(0)
    if keys:
        kvs[keys.pop()] = ""


fn collect_kvs[
    *Ts: Stringable
](args: VariadicPack[_, Stringable, *Ts], kwargs: OwnedKwargsDict[Arg]) -> Dict[String, String]:
    var kvs = collect_kwargs(kwargs)
    collect_args(args, kvs)

    return kvs


struct BoundLogger[LoggerType: Logger]():
    """A bound logger that enriches log messages with context data.

    Example Usage:
    ```mojo
    from stump import PrintLogger, BoundLogger, LogLevel

    fn main():
        var logger = BoundLogger(PrintLogger[LogLevel.INFO]())
        logger.info("Hello")
        logger.warn("World")
    ```
    """

    var _logger: LoggerType
    """The type of the logger to bind to."""
    var level: LogLevel
    """The log level of the logger."""
    var context: Context
    """The context data to enrich log messages with."""
    var formatter: Formatter
    """The formatter function used to format log messages."""
    var processors: GetProcessorsFn
    """The processors functions which will add to the context."""
    var styles: Styles
    """The styles used to format the log output."""
    var apply_styles: Bool
    """Whether to apply styles to the log output."""

    fn __init__(
        out self,
        owned logger: LoggerType,
        *,
        context: Context = Context(),
        formatter: Formatter = default_formatter,
        processors: GetProcessorsFn = get_default_processors,
        styles: Styles = get_default_styles(),
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
        self.context = context.copy()
        self.level = self._logger.get_level()
        self.formatter = formatter
        self.processors = processors
        self.styles = styles
        self.apply_styles = apply_styles

    fn __moveinit__(out self, owned other: Self):
        self._logger = other._logger^
        self.level = other.level
        self.context = other.context^
        self.formatter = other.formatter
        self.processors = other.processors
        self.styles = other.styles^
        self.apply_styles = other.apply_styles

    fn _apply_processors[level_name: String](self, context: Context) -> Context:
        """Apply processors to the context data.

        Parameters:
            level_name: The log level of the message.

        Args:
            context: The context data to enrich log messages with.

        Returns:
            The enriched context data.
        """
        var new_context = context.copy()
        for processor in self.processors():
            new_context = processor[](new_context, level_name)
        return new_context^

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
        return new_context^

    fn _transform_message[level: LogLevel](self, message: String, kvs: Dict[String, String]) -> String:
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
        context["message"] = message

        # Add args and kwargs from logger call to context.
        context.update(kvs)

        # Enrich context data with processors.
        context = self._apply_processors[level.as_name()](context)

        # Do not apply styling to JSON formatted logs or when it's turned off.
        if self.apply_styles:
            context = self._apply_style_to_kvs(context, level.value)

        return self.formatter(context^)

    fn info[*Ts: Stringable](self, message: String, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the INFO level.

        Parameters:
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        if self.level >= LogLevel.INFO:
            self._logger.info(self._transform_message[LogLevel.INFO](message, collect_kvs(args, kwargs)))

    fn warn[*Ts: Stringable](self, message: String, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the WARN level.

        Parameters:
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        if self.level >= LogLevel.WARN:
            self._logger.warn(self._transform_message[LogLevel.WARN](message, collect_kvs(args, kwargs)))

    fn error[*Ts: Stringable](self, message: String, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the ERROR level.

        Parameters:
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        if self.level >= LogLevel.ERROR:
            self._logger.error(self._transform_message[LogLevel.ERROR](message, collect_kvs(args, kwargs)))

    fn debug[*Ts: Stringable](self, message: String, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the DEBUG level.

        Parameters:
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        if self.level >= LogLevel.DEBUG:
            self._logger.debug(self._transform_message[LogLevel.DEBUG](message, collect_kvs(args, kwargs)))

    fn fatal[*Ts: Stringable](self, message: String, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the FATAL level.

        Parameters:
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        if self.level >= LogLevel.FATAL:
            self._logger.fatal(self._transform_message[LogLevel.FATAL](message, collect_kvs(args, kwargs)))

    fn bind(mut self, context: Context):
        """Bind a new key value pair to the logger context.

        Args:
            context: The key value pair to bind to the logger context.
        """
        self.context.update(context)


fn get_logger[level: LogLevel = LogLevel.INFO]() -> BoundLogger[PrintLogger[level]]:
    return BoundLogger(PrintLogger[level]())
