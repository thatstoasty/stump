from stump import DEBUG, FileLogger, BoundLogger, json_formatter


alias LOG_LEVEL = DEBUG


fn main() raises:
    var handle = open("/Users/mikhailtavarez/Git/mojo/stump/log.txt", "w")
    var logger = BoundLogger(FileLogger(handle^, level=DEBUG), formatter=json_formatter, apply_styles=False)
    logger.info("Information is good.", "key", "value")
    logger.warn("Warnings can be good too.", "no_value")
    logger.error("An error!", erroring=True)
    logger.fatal("uh oh...", "number", 4, "mojo", "🔥")
    logger.debug("Debugging...")
