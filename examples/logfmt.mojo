from std.logger import Level
from stump import LOGFMT_FORMATTER, BoundLogger, PrintLogger


def main():
    # `LOGFMT_FORMATTER` declares itself unstyled, so `apply_styles` resolves to
    # `False` on its own.
    var logger = BoundLogger(PrintLogger[Level.DEBUG](), formatter=LOGFMT_FORMATTER)
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warning("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.critical("uh oh...")
