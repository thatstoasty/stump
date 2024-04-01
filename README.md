# stump

WIP Logger! Inspired by charmbracelet's log package and the Python structlog package.

Lots of TODOs, will list later. If you're using the JSON_FORMAT, I know the log level is still colorful. You can remove the log level styling in the meantime.

![Example logs](https://github.com/thatstoasty/stump/blob/main/logger.png)

Minimal default logger example:

```py
from stump import get_logger


alias logger = get_logger()


fn main():
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
```

Minimal JSON logger example:

```py
from stump import (
    DEBUG,
    JSON_FORMAT,
    BoundLogger,
    PrintLogger
)


# The loggers are compiled at runtime, so we can reuse it.
alias LOG_LEVEL = DEBUG
alias logger = BoundLogger(PrintLogger(LOG_LEVEL), formatter=JSON_FORMAT)


fn main():
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")

```

Customized style and processor logger example:

```py
from stump import (
    DEBUG,
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


# Define a custom processor to add a name to the log output.
fn add_my_name(context: Context) -> Context:
    var new_context = Context(context)
    new_context["name"] = "Mikhail"
    return new_context


# Define custom processors to add extra information to the log output.
fn my_processors() -> List[Processor]:
    return List[Processor](
        add_log_level, add_timestamp_with_format["YYYY"](), add_my_name
    )


# Define custom styles to format and colorize the log output.
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

# Build a bound logger with custom processors and styling
alias logger = BoundLogger(
    PrintLogger(LOG_LEVEL), formatter=DEFAULT_FORMAT, processors=my_processors, styles=my_styles
)

fn main():
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
```

Importing the logger into other files works!

```py
from examples.default import logger


fn main():
    logger.info("Hello!")
```
