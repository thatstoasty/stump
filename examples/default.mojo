import stump


def main():
    var logger = stump.get_logger()
    logger.info("Information is good.", "a", "b")
    logger.warning("Warnings can be good too.", "no_value")
    logger.error("An error!", erroring=True)
    logger.critical("uh oh...", "number", 4, "mojo", "🔥")
    logger.debug("Debugging...")
