from stump import LEVEL_MAPPING, DEBUG, BoundLogger, PrintLogger, JSON_FORMAT, DEFAULT_FORMAT, add_log_level, add_timestamp, add_timestamp_with_format, Processor, Context


alias LOG_LEVEL = DEBUG
alias inner_logger = build_logger()
alias logger = bound_logger(inner_logger)


fn add_my_name(context: Context) -> Context:
    var new_context = Context(context)
    new_context["name"] = "Mikhail"
    return new_context


fn my_processors() -> List[Processor]:
    return List[Processor](add_log_level, add_timestamp_with_format["YYYY"](), add_my_name)


fn build_logger() -> PrintLogger:
    return PrintLogger(LOG_LEVEL)


fn bound_logger(logger: PrintLogger) -> BoundLogger[PrintLogger]:
    var bound_log = BoundLogger(logger, formatter=DEFAULT_FORMAT, processors=my_processors)
    return bound_log


fn main() raises:
    # var log = logger
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")

    logger.fatal("uh oh...")

    raise Error("dead")
