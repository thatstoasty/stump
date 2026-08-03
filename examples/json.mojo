from stump import LogLevel, JSON_FORMATTER, BoundLogger, PrintLogger
import stump


def main():
    # `JSON_FORMATTER` declares itself unstyled, so `apply_styles` resolves to
    # `False` on its own. Passing it is no longer needed to keep escape
    # sequences out of the JSON.
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=JSON_FORMATTER)
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
