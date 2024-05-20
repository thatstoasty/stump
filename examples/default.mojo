from stump import get_logger


alias logger = get_logger()


fn main():
    logger.info("Information is good.", "key", "value")
    logger.warn("Warnings can be good too.", "no_value")
    logger.error("An error!", "number", 4, erroring=True, woo="🔥")
    logger.fatal("uh oh...", "number", 4, "mojo", "🔥")
    logger.debug("Debugging...")
