"""Stump is a structured logging library for Mojo.

It provides a simple and efficient way to log structured data with support for different
log levels, formatting, and styling.
"""
from stump.arg import Arg
from stump.formatter import default_formatter, json_formatter, logfmt_formatter
from stump.bound_logger import BoundLogger, get_logger
from stump.logger import PrintLogger, Logger, LogLevel
from stump.processor import (
    add_log_level,
    add_timestamp,
    add_timestamp_with_format,
    DEFAULT_TIMESTAMP_FORMAT,
    Processor,
)
from stump.style import Styles, Sections
from stump.context import Context
