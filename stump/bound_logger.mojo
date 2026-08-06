"""Bound Logger Wrapper."""
from std import sys
from std.logger import Level
from std.collections.dict import OwnedKwargsDict
from stump.formatter import Formatter, DEFAULT_FORMATTER, is_reserved_key
import mist
from stump.style import Styles
from stump.processor import add_timestamp, add_log_level, merge_global_context, Processor, DropEvent
from stump.context import Context, update_context_from_kwargs


def collect_kvs[*Ts: Writable](mut kvs: OwnedKwargsDict[Arg], *args: *Ts):
    """Collects positional arguments into a dictionary of key-value pairs.

    Args are consumed as alternating keys and values. The pack is heterogeneous,
    so it can only be indexed with a compile-time constant. That is what makes a
    single pass possible: the loop strides by two at compile time and pairs `i`
    with `i + 1` directly, rather than stringifying into separate key and value
    lists and zipping them afterwards.

    Parameters:
        Ts: The types of the positional arguments to collect.

    Args:
        kvs: The dictionary to collect the key-value pairs into.
        args: The positional arguments to collect.
    """
    comptime for i in range(0, args.__len__(), 2):
        # A compile-time condition, so the trailing-key branch is only compiled
        # for an odd number of arguments.
        comptime if i + 1 < args.__len__():
            kvs[String(args[i])] = String(args[i + 1])
        else:
            # A trailing key with no value.
            kvs[String(args[i])] = ""


struct BoundLogger[L: Logger](Copyable):
    """A bound logger that enriches log messages with context data.

    A bound logger is immutable in the `structlog` sense: `bind`, `unbind` and
    `new` each return a *child* logger and leave the receiver untouched, so a
    request-scoped logger can be derived from a shared application logger without
    the two interfering.

    Parameters:
        L: The type of the internal logger to bind to.

    #### Examples:
    ```mojo
    from std.logger import Level
    from stump import PrintLogger, BoundLogger

    def main():
        var logger = BoundLogger(PrintLogger[Level.INFO]())
        logger.info("Hello")
        logger.warning("World")

        # `request` carries the extra key; `logger` does not.
        var request = logger.bind(request_id="abc123")
        request.info("Handling request")
    ```
    """

    comptime level: Level = Self.L.level
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
        formatter: Formatter = DEFAULT_FORMATTER,
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
                `JSON_FORMATTER` turns styling off without the caller having to.
                Pass it explicitly to override that.
            exit_on_fatal: Whether a `fatal` call terminates the process with status
                1 after the record is written. Off by default, so adding it does not
                silently change what an existing `fatal` call does.
        """
        var default_processors = [merge_global_context, add_timestamp(), add_log_level]
        self._logger = logger^
        self.context = context.copy()
        self.formatter = formatter
        self.processors = processors^ if processors else default_processors^
        self.styles = styles.take() if styles else Styles()
        self.apply_styles = apply_styles.value() if apply_styles else formatter.styled
        self.exit_on_fatal = exit_on_fatal

    def _apply_processors[level: Level](self, mut context: Context) raises DropEvent:
        """Apply processors to the context data.

        Parameters:
            level: The log level of the message.

        Args:
            context: The context data to enrich log messages with.
        """
        for i in range(len(self.processors)):
            self.processors[i](context, level)

    def _value_style(self, raw_key: String, level: Level) -> Optional[mist.Style]:
        """Pick the style for a value, or `None` to leave it bare.

        The reserved keys have dedicated styles and do not fall through to the
        per-key or default value styles.

        Args:
            raw_key: The unstyled key the value belongs to.
            level: The log level of the message.

        Returns:
            The style to render the value with, if any.
        """
        if raw_key == "level":
            # Returns no style if the level is not among the configured ones.
            return self.styles.levels.get(level._value)
        elif raw_key == "message":
            return self.styles.message
        elif raw_key == "timestamp":
            return self.styles.timestamp

        var per_key = self.styles.values.find(raw_key)
        return per_key if per_key else self.styles.value

    def _key_style(self, raw_key: String) -> Optional[mist.Style]:
        """Pick the style for a key, or `None` to leave it bare.

        Reserved keys are written by the formatter as bare text rather than as
        `key=value`, so there is no key to style.

        Args:
            raw_key: The unstyled key.

        Returns:
            The style to render the key with, if any.
        """
        if is_reserved_key(raw_key):
            return None

        var per_key = self.styles.keys.find(raw_key)
        return per_key if per_key else self.styles.key

    def _apply_style_to_kvs(self, mut context: Context, level: Level):
        """Apply styles to the key value pairs in the context data.

        Styling a key changes it, so the styled pairs are built into a fresh
        context and swapped in at the end. Writing them back during the walk
        would insert the styled key alongside the raw one instead of replacing
        it, and mutating a dictionary while iterating it is not safe anyway.

        Args:
            context: The context data to enrich log messages with.
            level: The log level of the message.
        """
        # The formatter writes the `=` between a key and its value, so the separator
        # style is carried as the sequences that go around it. See
        # `Styles.separator_sequences`.
        var separator = self.styles.separator_sequences()
        var styled = Context()

        for pair in context.items():
            # Style lookups run against the raw key. A rendered key carries ANSI
            # sequences and would match nothing in `keys` or `values`.
            var raw_key = pair.key.copy()
            var key_style = self._key_style(raw_key)
            var value_style = self._value_style(raw_key, level)

            var key = key_style.value().render(raw_key) if key_style else raw_key
            var value = value_style.value().render(pair.value) if value_style else pair.value

            if not is_reserved_key(raw_key):
                key += separator[0]
                value = separator[1] + value

            styled[key^] = value^

        context = styled^

    def _transform_message[
        T: Writable, //, level: Level, *Ts: Writable
    ](self, message: T, mut kwargs: OwnedKwargsDict[Arg], *args: *Ts) raises DropEvent -> String:
        """Copy context, merge in new keys, apply processors, format message and return.

        Parameters:
            T: The type of the message to log.
            level: The log level of the message.
            Ts: The types of the additional positional arguments to include in the log message.

        Args:
            message: The message to log.
            kwargs: Additional key-value pairs to include in the log message.
            args: Additional positional arguments to include in the log message.

        Returns:
            The formatted message.
        """
        var context = self.context.copy()
        context["message"] = String(message)

        # Add args and kwargs from logger call to context.
        comptime if args.__len__() > 0:
            collect_kvs(kwargs, *args)
        update_context_from_kwargs(context, kwargs)

        # Enrich context data with processors.
        self._apply_processors[level](context)

        # Do not apply styling to JSON formatted logs or when it's turned off.
        if self.apply_styles:
            self._apply_style_to_kvs(context, level)

        return self.formatter(context^)

    @always_inline
    @staticmethod
    def _is_disabled[target_level: Level]() -> Bool:
        """Returns True if logging at the target level is disabled.

        Parameters:
            target_level: The level to check if disabled.

        Returns:
            True if logging at the target level is disabled, False otherwise.
        """
        comptime if Self.level == Level.NOTSET:
            return True
        return Self.level > target_level

    def _log[
        T: Writable, //, level: Level, *Ts: Writable
    ](self, message: T, *args: *Ts, mut kwargs: OwnedKwargsDict[Arg]):
        """Log a message at `level`, taking already-collected keyword arguments.

        The module-level functions in `stump.logger` need this: they receive
        `**kwargs` and cannot forward it on, so they hand over the collected
        dictionary instead. The public level methods take `**kwargs` directly.

        Parameters:
            T: The type of the message to log.
            level: The log level of the message.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime if not Self._is_disabled[level]():
            try:
                self._logger.log[level](self._transform_message[level](message, kwargs, *args))
            except DropEvent:
                return

        comptime if level == Level.CRITICAL:
            if self.exit_on_fatal:
                sys.exit(1)

    def trace[T: Writable, //, *Ts: Writable](self, message: T, /, *args: *Ts, var **kwargs: Arg):
        """Log a message at the INFO level.

        Parameters:
            T: The type of the message to log.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime target_level = Level.TRACE
        comptime if not Self._is_disabled[target_level]():
            try:
                self._logger.info(self._transform_message[target_level](message, kwargs, *args))
            except DropEvent:
                pass

    def info[T: Writable, //, *Ts: Writable](self, message: T, /, *args: *Ts, var **kwargs: Arg):
        """Log a message at the INFO level.

        Parameters:
            T: The type of the message to log.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime target_level = Level.INFO
        comptime if not Self._is_disabled[target_level]():
            try:
                self._logger.info(self._transform_message[target_level](message, kwargs, *args))
            except DropEvent:
                pass

    def warning[T: Writable, //, *Ts: Writable](self, message: T, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the WARN level.

        Parameters:
            T: The type of the message to log.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime target_level = Level.WARNING
        comptime if not Self._is_disabled[target_level]():
            try:
                self._logger.warning(self._transform_message[target_level](message, kwargs, *args))
            except DropEvent:
                pass

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
        comptime target_level = Level.ERROR
        comptime if not Self._is_disabled[target_level]():
            try:
                self._logger.error(self._transform_message[target_level](message, kwargs, *args))
            except DropEvent:
                pass

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
        comptime target_level = Level.DEBUG
        comptime if not Self._is_disabled[target_level]():
            try:
                self._logger.debug(self._transform_message[target_level](message, kwargs, *args))
            except DropEvent:
                pass

    def critical[T: Writable, //, *Ts: Writable](self, message: T, /, *args: *Ts, **kwargs: Arg):
        """Log a message at the CRITICAL level.

        Parameters:
            T: The type of the message to log.
            Ts: The types of the arguments to include in the log message.

        Args:
            message: The message to log.
            args: Additional arbitrary arguments to include in the log message.
            kwargs: Additional arbitrary key-value pairs to include in the log message.
        """
        comptime target_level = Level.CRITICAL
        comptime if not Self._is_disabled[target_level]():
            try:
                self._logger.critical(self._transform_message[target_level](message, kwargs, *args))
            except DropEvent:
                return

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
        collect_kvs(kwargs, *args)
        update_context_from_kwargs(context, kwargs)
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
        for pair in self.context.items():
            var drop = False
            for key in keys:
                if pair.key == key:
                    drop = True
                    break

            if not drop:
                context[pair.key] = pair.value

        return self._child(context^)

    def new(self, var **kwargs: Arg) -> Self:
        """Return a child logger with the inherited context cleared.

        Everything else — the sink, formatter, processors and styles — is
        inherited. This is the way to start a fresh context, typically per request,
        without rebuilding the logger.

        Args:
            kwargs: Key-value pairs to bind to the otherwise empty context.

        Returns:
            A new logger whose context contains only the given pairs.
        """
        var context = Context()
        update_context_from_kwargs(context, kwargs)
        return self._child(context^)


def get_logger[level: Level = Level.INFO]() -> BoundLogger[PrintLogger[level]]:
    """Get a bound logger with a PrintLogger of the specified log level as the internal logger.

    Parameters:
        level: The log level of the internal PrintLogger.

    Returns:
        A bound logger with a PrintLogger of the specified log level as the internal logger.
    """
    return BoundLogger(PrintLogger[level]())
