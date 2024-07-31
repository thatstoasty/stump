from .formatter import default_formatter, json_formatter, logfmt_formatter
from .bound_logger import BoundLogger, get_logger
from .logger import FileLogger, STDLogger, PrintLogger, Logger
from .processor import (
    add_log_level,
    add_timestamp,
    # add_timestamp_with_format,
    get_default_processors,
    Processor,
)
from .style import Styles, Sections


alias FATAL = 0
alias ERROR = 1
alias WARN = 2
alias INFO = 3
alias DEBUG = 4

alias LEVEL_MAPPING = InlineArray[String, 5](
    "FATAL",
    "ERROR",
    "WARN",
    "INFO",
    "DEBUG",
)

alias Arg = Variant[
    String, StringLiteral, Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64, Float32, Float64, Bool
]
alias Context = Dict[String, String]
