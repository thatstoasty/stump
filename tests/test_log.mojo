from stump import (
    LEVEL_MAPPING,
    DEBUG,
    JSON_FORMAT,
    DEFAULT_FORMAT,
    Processor,
    Context,
    Styles,
    Sections,
    BoundLogger,
    PrintLogger,
    add_log_level,
    add_timestamp,
    add_timestamp_with_format,
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
    levels["FATAL"] = TerminalStyle.new().background("#d4317d")
    levels["ERROR"] = TerminalStyle.new().background("#d48244")
    levels["INFO"] = TerminalStyle.new().background("#13ed84")
    levels["WARN"] = TerminalStyle.new().background("#decf2f")
    levels["DEBUG"] = TerminalStyle.new().background("#bd37db")

    var keys = Sections()
    keys["name"] = (
        TerminalStyle.new().foreground("#c9a0dc").underline()
    )

    var values = Sections()
    values["name"] = TerminalStyle.new().foreground("#d48244").bold()

    return Styles(
        levels=levels,
        key=TerminalStyle.new().faint(),
        separator=TerminalStyle.new().faint(),
        keys=keys,
        values=values,
    )


# The loggers are compiled at runtime, so we can reuse it.
alias LOG_LEVEL = DEBUG
alias logger = bound_logger()
alias default_logger = bound_default_logger()
alias json_logger = bound_json_logger()


# Build a bound logger with custom processors and styling
fn bound_logger() -> BoundLogger[PrintLogger]:
    return BoundLogger(
        PrintLogger(LOG_LEVEL), formatter=DEFAULT_FORMAT, processors=my_processors, styles=my_styles
    )


# Build a bound logger with default processors and styling
fn bound_default_logger() -> BoundLogger[PrintLogger]:
    return BoundLogger(PrintLogger(LOG_LEVEL), formatter=DEFAULT_FORMAT)


# Build a bound logger with json formatting
fn bound_json_logger() -> BoundLogger[PrintLogger]:
    return BoundLogger(PrintLogger(LOG_LEVEL), formatter=JSON_FORMAT)


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
