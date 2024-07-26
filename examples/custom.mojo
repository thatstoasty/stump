from stump import (
    DEBUG,
    Processor,
    Context,
    Styles,
    Sections,
    BoundLogger,
    PrintLogger,
    add_log_level,
    add_timestamp,
)
import external.mist


# Define a custom processor to add a name to the log output.
fn add_my_name(context: Context, level: String) -> Context:
    var new_context = context
    new_context["name"] = "Mikhail"
    return new_context


# Define custom processors to add extra information to the log output.
fn my_processors() -> List[Processor]:
    return List[Processor](add_log_level, add_timestamp, add_my_name)


# Define custom styles to format and colorize the log output.
fn my_styles() -> Styles:
    # Log level styles, by default just set colors
    var base_style = mist.Style()
    var faint_style = mist.Style().faint()

    var levels = List[mist.Style](
        base_style.background(0xD4317D),
        base_style.background(0xD48244),
        base_style.background(0x13ED84),
        base_style.background(0xDECF2F),
        base_style.background(0xBD37DB),
    )

    var keys = Sections()
    keys["name"] = mist.Style().foreground(0xC9A0DC).underline()

    var values = Sections()
    values["name"] = mist.Style().foreground(0xD48244).bold()

    return Styles(
        timestamp=base_style,
        message=base_style,
        key=faint_style,
        value=base_style,
        separator=faint_style,
        levels=levels,
        keys=keys,
        values=values,
    )


# The loggers are compiled at build time, so we can reuse it.
alias LOG_LEVEL = DEBUG

# Build a bound logger with custom processors and styling
var logger = BoundLogger(
    PrintLogger(LOG_LEVEL),
    processors=my_processors(),
    styles=my_styles(),
)


fn main():
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!", erroring=True)
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
