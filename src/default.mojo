import stump

alias logger = stump.get_logger()


fn main():
    logger.info("Information is good.", "a", "b")
    logger.warn("Warnings can be good too.", "no_value")
    logger.error("An error!", erroring=True)
    logger.fatal("uh oh...", "number", 4, "mojo", "🔥")
    logger.debug("Debugging...")
