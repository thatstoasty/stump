from stump import DEBUG, json_formatter, BoundLogger, PrintLogger


# The loggers are compiled at build time, so we can reuse it.
var logger = BoundLogger(PrintLogger(DEBUG), formatter=json_formatter, apply_styles=False)


fn main():
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
