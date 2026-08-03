"""Stump is a structured logging library for Mojo.

It provides a simple and efficient way to log structured data with support for different
log levels, formatting, and styling.
"""
from stump.arg import Arg
from stump.formatter import Formatter, DEFAULT_FORMATTER, JSON_FORMATTER, LOGFMT_FORMATTER
from stump.bound_logger import BoundLogger, get_logger
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
    add_log_level,
    add_timestamp,
    add_timestamp_with_format,
    DEFAULT_PROCESSORS,
    Processor,
)
from stump.style import Styles, Sections
from stump.context import Context, ContextDict
