from collections.dict import Dict, KeyElement, DictEntry

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

alias Context = Dict[String, String]
alias ContextPair = DictEntry[String, String]
