from stump import (
    Styles,
    Sections,
    LEVEL_MAPPING,
    DEBUG,
    BoundLogger,
    PrintLogger,
    JSON_FORMAT,
    DEFAULT_FORMAT,
    add_log_level,
    add_timestamp,
    add_timestamp_with_format,
    Processor,
    Context,
)
from external.mist import TerminalStyle, Profile, TRUE_COLOR


fn add_my_name(context: Context) -> Context:
    var new_context = Context(context)
    new_context["name"] = "Mikhail"
    return new_context


fn my_processors() -> List[Processor]:
    return List[Processor](
        add_log_level, add_timestamp_with_format["YYYY"](), add_my_name
    )


fn my_styles() -> Styles:
    # Log level styles, by default just set colors
    var levels = Sections()
    levels["FATAL"] = TerminalStyle.new(Profile(TRUE_COLOR)).background("#d4317d")
    levels["ERROR"] = TerminalStyle.new(Profile(TRUE_COLOR)).background("#d48244")
    levels["INFO"] = TerminalStyle.new(Profile(TRUE_COLOR)).background("#13ed84")
    levels["WARN"] = TerminalStyle.new(Profile(TRUE_COLOR)).background("#decf2f")
    levels["DEBUG"] = TerminalStyle.new(Profile(TRUE_COLOR)).background("#bd37db")

    var keys = Sections()
    keys["name"] = (
        TerminalStyle.new(Profile(TRUE_COLOR)).foreground("#c9a0dc").underline()
    )

    var values = Sections()
    values["name"] = TerminalStyle.new(Profile(TRUE_COLOR)).foreground("#d48244").bold()

    return Styles(
        levels=levels,
        key=TerminalStyle.new(Profile(TRUE_COLOR)).faint(),
        separator=TerminalStyle.new(Profile(TRUE_COLOR)).faint(),
        keys=keys,
        values=values,
    )


# The loggers are compiled at runtime, so we can reuse it.
alias LOG_LEVEL = DEBUG
alias inner_logger = build_logger()
alias logger = bound_logger(inner_logger)
alias default_logger = bound_default_logger(inner_logger)
alias json_logger = bound_json_logger(inner_logger)


# Build a basic print logger
fn build_logger() -> PrintLogger:
    return PrintLogger(LOG_LEVEL)


# Build a bound logger with custom processors and styling
fn bound_logger(logger: PrintLogger) -> BoundLogger[PrintLogger]:
    var bound_log = BoundLogger(
        logger, formatter=DEFAULT_FORMAT, processors=my_processors, styles=my_styles
    )
    return bound_log


# Build a bound logger with default processors and styling
fn bound_default_logger(logger: PrintLogger) -> BoundLogger[PrintLogger]:
    var bound_log = BoundLogger(logger, formatter=DEFAULT_FORMAT)
    return bound_log


# Build a bound logger with json formatting
fn bound_json_logger(logger: PrintLogger) -> BoundLogger[PrintLogger]:
    var bound_log = BoundLogger(logger, formatter=JSON_FORMAT)
    return bound_log


fn print_default():
    default_logger.info("Information is good.")
    default_logger.warn("Warnings can be good too.")
    default_logger.error("An error!")
    default_logger.debug("Debugging...")
    default_logger.fatal("uh oh...\n")


fn print_json():
    json_logger.info("Information is good.")
    json_logger.warn("Warnings can be good too.")
    json_logger.error("An error!")
    print("")


fn print_custom():
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")


fn main():
    print_default()
    print_json()
    print_custom()
