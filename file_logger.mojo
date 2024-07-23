from stump import DEBUG, JSON_FORMAT, BoundLogger, PrintLogger, FileLogger


alias LOG_LEVEL = DEBUG


fn main() raises:
    var logger = BoundLogger(FileLogger(path="./log.txt", level=LOG_LEVEL), formatter=JSON_FORMAT)
    logger.info("Information is good.", "key", "value")
    logger.warn("Warnings can be good too.", "no_value")
    logger.error("An error!", erroring=True)
    logger.fatal("uh oh...", "number", 4, "mojo", "🔥")
    logger.debug("Debugging...")
