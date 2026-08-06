from std.logger import Level
from stump import (
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
        PrintLogger[Level.DEBUG](),
        processors=[],
    )
    logger.info("Information is good.")
    logger.warning("Warnings can be good too.")
    logger.error("An error!", erroring=True)
    logger.debug("Debugging...")
    logger.critical("uh oh...")
