"""Bound Logger Wrapper."""
from std import sys
from std.collections.dict import OwnedKwargsDict
from stump.formatter import Formatter, default_formatter
from stump.style import Styles
from stump.processor import add_timestamp, add_log_level, Processor
from stump.context import Context


def collect_kwargs(kwargs: OwnedKwargsDict[Arg]) -> Dict[String, String]:
    """Collects keyword arguments into a dictionary.

    Args:
        kwargs: The keyword arguments to collect.

    Returns:
        A dictionary containing the collected keyword arguments.
    """
    var kvs = Dict[String, String](capacity=len(kwargs))
    for pair in kwargs.items():
        kvs[pair.key] = String(pair.value)

    return kvs^


def collect_args[*Ts: Writable](args: VariadicPack[False, *Ts], mut kvs: Dict[String, String]):
    """Collects positional arguments into a dictionary of key-value pairs.

    Parameters:
        Ts: The types of the positional arguments to collect.

    Args:
        args: The positional arguments to collect.
        kvs: The dictionary to collect the key-value pairs into.
    """
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


def collect_kvs[*Ts: Writable](args: VariadicPack[False, *Ts], kwargs: OwnedKwargsDict[Arg]) -> Dict[String, String]:
    """Collects both positional and keyword arguments into a single dictionary of key-value pairs.

    Parameters:
        Ts: The types of the positional arguments to collect.

    Args:
        args: The positional arguments to collect.
        kwargs: The keyword arguments to collect.

    Returns:
        A dictionary containing the collected key-value pairs from both positional and keyword arguments.
    """
    var kvs = collect_kwargs(kwargs)
    collect_args(args, kvs)

    return kvs^


struct BoundLogger[L: Logger](Copyable, Movable):
    """A bound logger that enriches log messages with context data.

    A bound logger is immutable in the `structlog` sense: `bind`, `unbind` and
    `new` each return a *child* logger and leave the receiver untouched, so a
    request-scoped logger can be derived from a shared application logger without
    the two interfering.

    Parameters:
        L: The type of the internal logger to bind to.

    #### Examples:
    ```mojo
    from stump import PrintLogger, BoundLogger, LogLevel

    def main():
        var logger = BoundLogger(PrintLogger[LogLevel.INFO]())
        logger.info("Hello")
        logger.warn("World")

        # `request` carries the extra key; `logger` does not.
        var request = logger.bind(request_id="abc123")
        request.info("Handling request")
    ```
    """

    comptime level: LogLevel = Self.L.level
    """The log level of the logger, determined by the log level of the internal logger type."""

    var _logger: Self.L
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
    var exit_on_fatal: Bool
    """Whether a `fatal` call terminates the process once the record is written."""

    def __init__(
        out self,
        var logger: Self.L,
        *,
        context: Context = Context(),
        formatter: Formatter = default_formatter,
        var processors: List[Processor] = [],
        var styles: Optional[Styles] = None,
        apply_styles: Optional[Bool] = None,
        exit_on_fatal: Bool = False,
    ):
        """Create a new bound logger.

        Args:
            logger: The logger to bind to.
            context: The context data to enrich log messages with.
            formatter: The formatter function used to format log messages.
            processors: The processors functions which will add to the context.
            styles: The styles used to format the log output.
            apply_styles: Whether to apply styles to the log output. Defaults to
                whatever the formatter asks for, so a structured formatter such as
                `json_formatter` turns styling off without the caller having to.
                Pass it explicitly to override that.
            exit_on_fatal: Whether a `fatal` call terminates the process with status
                1 after the record is written. Off by default, so adding it does not
                silently change what an existing `fatal` call does.
        """
        var default_processors = [add_timestamp, add_log_level]
        self._logger = logger^
        self.context = context.copy()
        self.formatter = formatter
        self.processors = processors^ if processors else default_processors^
        self.styles = styles.take() if styles else Styles()
        self.apply_styles = apply_styles.value() if apply_styles else formatter.styled
        self.exit_on_fatal = exit_on_fatal

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
        for i in range(len(self.processors)):
            new_context = self.processors[i](new_context, level)
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

        # The formatter writes the `=` between a key and its value, so the separator
        # style is carried as the sequences that go around it. See
        # `Styles.separator_sequences`.
        var separator = self.styles.separator_sequences()

        for pair in context.value.items():
            # Style lookups run against the raw key. `key` picks up ANSI sequences as
            # soon as it is rendered, and a rendered key matches nothing in `values`.
            var raw_key = pair.key
            var key = raw_key
            var value = pair.value

            # The reserved keys are rendered by the formatter as bare text rather than
            # as `key=value`, so they take neither a key style nor the separator.
            var is_reserved = True

            # Check if there's a style for the key and apply it if so
            # otherwise use the default style for values.
            if raw_key == "level":
                # A caller-supplied `levels` list may be shorter than the number of log
                # levels. Leave the level unstyled rather than reading out of bounds.
                if Int(level) < len(self.styles.levels):
                    value = self.styles.levels[Int(level)].render(value)
            elif raw_key == "message":
                if self.styles.message:
                    value = self.styles.message.value().render(value)
            elif raw_key == "timestamp":
                if self.styles.timestamp:
                    value = self.styles.timestamp.value().render(value)
            else:
                is_reserved = False
                var key_style = self.styles.keys.find(raw_key)
                if key_style:
                    key = key_style.value().render(raw_key)
                elif self.styles.key:
                    key = self.styles.key.value().render(raw_key)

            # Check if there's a style for the value of a key and apply it if so,
            # otherwise use the default style for values.
            var value_style = self.styles.values.find(raw_key)
            if value_style:
                value = value_style.value().render(value)
            elif self.styles.value:
                value = self.styles.value.value().render(value)

            if not is_reserved:
                key += separator[0]
                value = separator[1] + value

            new_context[key^] = value^
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

        # Outside the level check on purpose. FATAL is level 0, so no logger can
        # filter it out today, but if that ever changes, dropping the record is not
        # a reason to keep running.
        if self.exit_on_fatal:
            sys.exit(1)

    def _child(self, var context: Context) -> Self:
        """Build a child logger carrying `context`, inheriting everything else.

        Args:
            context: The context the child should carry.

        Returns:
            A new logger, identical to this one apart from its context.
        """
        return Self(
            self._logger.copy(),
            context=context^,
            formatter=self.formatter,
            processors=self.processors.copy(),
            styles=self.styles.copy(),
            apply_styles=self.apply_styles,
            exit_on_fatal=self.exit_on_fatal,
        )

    def bind[*Ts: Writable](self, *args: *Ts, **kwargs: Arg) -> Self:
        """Return a child logger with additional key-value pairs bound to its context.

        This logger is left unchanged. Positional arguments are read as alternating
        keys and values, and take precedence over a keyword argument of the same
        name, matching how the log methods collect their arguments.

        Parameters:
            Ts: The types of the positional arguments to bind.

        Args:
            args: Additional arbitrary arguments to bind to the child's context.
            kwargs: Additional arbitrary key-value pairs to bind to the child's context.

        Returns:
            A new logger carrying this logger's context plus the given pairs.
        """
        var context = self.context.copy()
        context.update(collect_kvs(args, kwargs))
        return self._child(context^)

    def bind(self, context: Context) -> Self:
        """Return a child logger with the pairs in `context` bound to its context.

        This logger is left unchanged. Keys already present are overwritten by the
        incoming ones.

        Args:
            context: The key-value pairs to bind to the child's context.

        Returns:
            A new logger carrying this logger's context merged with `context`.
        """
        var new_context = self.context.copy()
        new_context.update(context)
        return self._child(new_context^)

    def unbind(self, *keys: String) -> Self:
        """Return a child logger with the given keys removed from its context.

        This logger is left unchanged. Keys that are not bound are ignored rather
        than raising, so unbinding is safe to do speculatively.

        Args:
            keys: The keys to remove from the child's context.

        Returns:
            A new logger carrying this logger's context without the given keys.
        """
        var context = Context()
        for pair in self.context.value.items():
            var drop = False
            for key in keys:
                if pair.key == key:
                    drop = True
                    break

            if not drop:
                context[pair.key] = pair.value

        return self._child(context^)

    def new(self, **kwargs: Arg) -> Self:
        """Return a child logger with the inherited context cleared.

        Everything else — the sink, formatter, processors and styles — is
        inherited. This is the way to start a fresh context, typically per request,
        without rebuilding the logger.

        Args:
            kwargs: Key-value pairs to bind to the otherwise empty context.

        Returns:
            A new logger whose context contains only the given pairs.
        """
        return self._child(Context(collect_kwargs(kwargs)))


def get_logger[level: LogLevel = LogLevel.INFO]() -> BoundLogger[PrintLogger[level]]:
    """Get a bound logger with a PrintLogger of the specified log level as the internal logger.

    Parameters:
        level: The log level of the internal PrintLogger.

    Returns:
        A bound logger with a PrintLogger of the specified log level as the internal logger.
    """
    return BoundLogger(PrintLogger[level]())
