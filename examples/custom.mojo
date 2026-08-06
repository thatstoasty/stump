from std.logger import Level
from stump import (
    Processor,
    Context,
    Styles,
    Sections,
    BoundLogger,
    PrintLogger,
    add_log_level,
    add_timestamp,
)
import mist
from mojo_datetime import TimeZone

# Define a custom processor to add a name to the log output.
def add_my_name(mut context: Context, level: Level):
    context["name"] = "Mikhail"

# Define custom styles to format and colorize the log output.
def my_styles() -> Styles:
    # Log level styles, by default just set colors
    var base_style = mist.Style(mist.Profile.TRUE_COLOR)
    var faint_style = base_style.faint()
    var levels: Dict[Int, mist.Style] = {
        Level.TRACE._value: base_style.background(0xD4317D),
        Level.DEBUG._value: base_style.background(0xD48244),
        Level.INFO._value: base_style.background(0x13ED84),
        Level.WARNING._value: base_style.background(0xDECF2F),
        Level.ERROR._value: base_style.background(0xBD37DB),
        Level.CRITICAL._value: base_style.background(0x8B0000),
    }

    var keys = Sections()
    keys["name"] = base_style.foreground(0xC9A0DC).underline()

    var values = Sections()
    values["name"] = base_style.foreground(0xD48244).bold()

    return Styles(
        timestamp=base_style,
        message=base_style,
        key=faint_style,
        value=base_style,
        separator=faint_style,
        levels=levels^,
        keys=keys^,
        values=values^,
    )


def main():
    var logger = BoundLogger(
        PrintLogger[Level.DEBUG](),
        processors=[add_timestamp["%I:%M:%S%p", TimeZone("EST")](), add_log_level, add_my_name],
        styles=my_styles(),
    )

    logger.info("Information is good.")
    logger.warning("Warnings can be good too.")
    logger.error("An error!", erroring=True)
    logger.debug("Debugging...")
    logger.critical("uh oh...")
