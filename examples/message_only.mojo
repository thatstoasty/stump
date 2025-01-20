from stump import (
    LogLevel,
    Processor,
    Context,
    Styles,
    Sections,
    BoundLogger,
    PrintLogger,
)
from mist import Style, Profile, TRUE_COLOR


fn get_processors() -> List[Processor]:
    return List[Processor]()


# Build a bound logger with custom processors and styling
alias logger = BoundLogger(
    PrintLogger[LogLevel.DEBUG](),
    processors=get_processors,
)


fn main():
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!", erroring=True)
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
