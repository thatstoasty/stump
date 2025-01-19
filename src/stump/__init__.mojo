from utils import Variant
from collections import Dict, InlineArray
from .formatter import default_formatter, json_formatter, logfmt_formatter
from .bound_logger import BoundLogger, get_logger
from .logger import PrintLogger, Logger
from .processor import (
    add_log_level,
    add_timestamp,
    add_timestamp_with_format,
    get_default_processors,
    Processor,
)
from .style import Styles, Sections
from .profile import TRUE_COLOR, ANSI256, ANSI, ASCII


struct LogLevel:
    alias FATAL = 0
    alias ERROR = 1
    alias WARN = 2
    alias INFO = 3
    alias DEBUG = 4
    alias VALID_LEVELS = InlineArray[Int, 5](
        LogLevel.FATAL,
        LogLevel.ERROR,
        LogLevel.WARN,
        LogLevel.INFO,
        LogLevel.DEBUG,
    )


alias LEVEL_MAPPING = InlineArray[String, 5](
    "FATAL",
    "ERROR",
    "WARN",
    "INFO",
    "DEBUG",
)

alias Arg = Variant[
    StringLiteral, String, Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64, Float32, Float64, Bool
]
alias Context = Dict[String, String]
