from stump import DEBUG, JSON_FORMAT, BoundLogger, PrintLogger


# The loggers are compiled at build time, so we can reuse it.
alias LOG_LEVEL = DEBUG
alias logger = BoundLogger(PrintLogger(LOG_LEVEL), formatter=JSON_FORMAT)


fn main():
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
