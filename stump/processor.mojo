"""Log Processors."""
from std.logger import Level
from mojo_datetime import DateTime, IsoFormat, TimeZone, TZ_UTC
from stump.context import Context
from stump.global_context import global_ctx

comptime Processor = def(mut context: Context, level: Level) thin raises DropEvent
"""Functions to modify the context before logging a message."""


@fieldwise_init
struct DropEvent(TrivialRegisterPassable, Writable):
    """An Error to indicate that a log event should be dropped."""

    pass


# Built in processor functions to modify the context before logging a message.


def add_log_level(mut context: Context, level: Level) raises DropEvent:
    """Adds the log level to the log message.

    Args:
        context: The current context.
        level: The log level of the message.

    Raises:
        DropEvent: If the log event should be dropped. This function should never raise.
    """
    context["level"] = String(level)


# If you need to modify something within the processor function, create a function that returns a Processor
def add_timestamp[format: String = IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD, time_zone: TimeZone = TZ_UTC]() -> Processor:
    """Adds a timestamp to the log message with the specified format.

    The format is a `strftime`-style string, as accepted by `mojo_datetime`'s
    `DateTime.write_to`. See its `FormatCode` for the supported codes. The
    default is `DEFAULT_TIMESTAMP_FORMAT`, which renders RFC 3339 and matches
    what `add_timestamp` produces.

    Text outside a format code is written through as-is, so a format holding
    no code at all produces that text verbatim instead of a timestamp.

    Parameters:
        format: The format string for the timestamp. Defaults to ISO format (`YYYY-MM-DDTHH:mm:ssz`).
        time_zone: The time zone for the timestamp. Defaults to UTC.

    Returns:
        A processor function that adds a timestamp with the specified format to the log message.
    """

    def processor(mut context: Context, level: Level) raises DropEvent:
        """The actual processor function that will be returned.

        Args:
            context: The current context.
            level: The log level of the message.

        Returns:
            The modified context with the timestamp added.

        Raises:
            DropEvent: If the log event should be dropped. This function should never raise.
        """
        var ts = String(capacity=32)
        DateTime[time_zone].now().write_to[fmt_str=format](ts)
        context["timestamp"] = ts^

    return processor


def merge_global_context(mut context: Context, level: Level) raises DropEvent:
    """A processor that merges in a global (context-local) context.

    Args:
        context: The current context.
        level: The log level of the message.

    Raises:
        DropEvent: If the log event should be dropped. This function should never raise.
    """
    ref ctx = global_ctx()[]
    for pair in ctx.items():
        context[pair.key] = pair.value.copy()


comptime DEFAULT_PROCESSORS = [merge_global_context, add_timestamp(), add_log_level]
"""The processors a `BoundLogger` uses when none are given: a timestamp and the log level.

Callsite information is not among them. Recording it needs the call location of the
`logger.info(...)` call itself, which is not reachable from a `Processor` — a processor
runs from inside the logger and sees only the context.
"""
