from stump import (
    DEBUG,
    DEFAULT_FORMAT,
    ProcessorFn,
    Context,
    Styles,
    Sections,
    BoundLogger,
    PrintLogger,
    add_log_level,
    add_timestamp,
    add_timestamp_with_format,
)
from external.mist import TerminalStyle, Profile, TRUE_COLOR


# Define custom processors to add extra information to the log output.
fn my_processors() -> List[ProcessorFn]:
    return List[ProcessorFn]()


# The loggers are compiled at build time, so we can reuse it.
alias LOG_LEVEL = DEBUG

# Build a bound logger with custom processors and styling
alias logger = BoundLogger(
    PrintLogger(LOG_LEVEL),
    formatter=DEFAULT_FORMAT,
    processors=my_processors,
)


fn main():
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!", erroring=True)
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
