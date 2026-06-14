from stump import (
    LogLevel,
    Processor,
    Context,
    Styles,
    Sections,
    BoundLogger,
    PrintLogger,
)
from mist import Style, Profile


def main():
    var logger = BoundLogger(
        PrintLogger[LogLevel.DEBUG](),
        processors=[],
    )
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!", erroring=True)
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
