from stump import LogLevel, JSON_FORMATTER, BoundLogger, PrintLogger
import stump


def main():
    # `JSON_FORMATTER` declares itself unstyled, so `apply_styles` resolves to
    # `False` on its own. Passing it is no longer needed to keep escape
    # sequences out of the JSON. `pretty` is a required comptime parameter,
    # not an optional one — every use site has to say which it wants.
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=JSON_FORMATTER[pretty=False])
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")

    # `pretty=True` indents and newlines the same JSON object, which is easier
    # to read at a terminal but slower and bulkier for a log pipeline that
    # parses one record per line. Pick per formatter, not per call.
    var pretty_logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=JSON_FORMATTER[pretty=True])
    pretty_logger.info("Information is good.", "arbitrary", "pairs", key="value")
