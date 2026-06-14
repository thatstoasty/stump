from stump import LogLevel, logfmt_formatter, BoundLogger, PrintLogger
import stump


def main():
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=logfmt_formatter, apply_styles=False)
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
