from stump import (
    DEBUG,
    Processor,
    Context,
    Styles,
    Sections,
    BoundLogger,
    PrintLogger,
)
from mist import Style, Profile, TRUE_COLOR


# The loggers are compiled at build time, so we can reuse it.
alias LOG_LEVEL = DEBUG

# Build a bound logger with custom processors and styling
alias logger = BoundLogger[profile=TRUE_COLOR](
    PrintLogger(DEBUG),
    processors=List[Processor](),
)


fn main():
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!", erroring=True)
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
