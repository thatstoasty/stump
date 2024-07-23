from stump import get_logger


var logger = get_logger()


fn main():
    var additional = Dict[String, String]()
    additional["bound"] = "context"
    logger.bind(additional)
    logger.info("Information is good.", "key", "value", "🔥", True)
    logger.warn("Warnings can be good too.", "no_value")
    logger.error("An error!", erroring=True)
    logger.fatal("uh oh...", "number", 4, "mojo", "🔥")
    logger.debug("Debugging...")
