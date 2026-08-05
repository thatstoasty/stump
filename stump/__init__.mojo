"""Stump is a structured logging library for Mojo.

It provides a simple and efficient way to log structured data with support for different
log levels, formatting, and styling.
"""
from stump.arg import Arg
from stump.context import Context, to_json, to_json_string, to_logfmt, update_context_from_kwargs
from stump.formatter import Formatter, DEFAULT_FORMATTER, JSON_FORMATTER, LOGFMT_FORMATTER
from stump.bound_logger import BoundLogger, get_logger
from stump.global_context import (
    clear_context,
    bind_context,
    unbind_context,
    scoped_context,
)
from stump.global_logger import (
    debug,
    default,
    error,
    fatal,
    info,
    warn,
)
from stump.logger import (
    FileLogger,
    Logger,
    LogLevel,
    MultiLogger,
    PrintLogger,
)
from stump.processor import (
    merge_global_context,
    add_log_level,
    add_timestamp,
    add_timestamp_with_format,
    DEFAULT_PROCESSORS,
    Processor,
    DropEvent,
)
from stump.style import Styles, Sections
