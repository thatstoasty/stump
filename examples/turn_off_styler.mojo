from stump import LogLevel, logfmt_formatter, BoundLogger, PrintLogger
import stump

# The loggers are compiled at build time, so we can reuse it.
alias logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=logfmt_formatter, apply_styles=False)


fn main():
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
