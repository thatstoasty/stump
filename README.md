# stump

![Mojo 24.3](https://img.shields.io/badge/Mojo%F0%9F%94%A5-24.3-purple)

WIP Logger! Inspired by charmbracelet's log package and the Python structlog package.

There are some things I'm ironing out around terminal color profile querying at compilation time. At the moment, the default styles assume a `TRUE_COLOR` enabled color profile. So, if your terminal only supports `ANSI` or `ANSI256`, try setting custom styles like in the `custom.mojo` example, or update the default profile in `stump/style.mojo` from `TRUE_COLOR` to `ANSI` or `ANSI256`.

See the examples directory for examples on setting up custom processors, styling, message only/json/logfmt logging, and logging with the styling turned off!

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

There's support for arbitrary arg pairs and kwargs to be merged into the log statement!

```mojo
from stump import get_logger


alias logger = get_logger()


fn main():
    logger.info("Information is good.", "key", "value")
    logger.warn("Warnings can be good too.", "no_value")
    logger.error("An error!", erroring=True)
    logger.fatal("uh oh...", "number", 4, "mojo", "🔥")
    logger.debug("Debugging...")
```

Output (no color included)

```txt
2024-04-03 14:53:56 INFO Information is good. key=value
2024-04-03 14:53:56 WARN Warnings can be good too. no_value=
2024-04-03 14:53:56 ERROR An error! erroring=True
2024-04-03 14:53:56 FATAL uh oh... number=4 mojo=🔥
```

Minimal JSON logger example:

```mojo
from stump import (
    DEBUG,
    JSON_FORMAT,
    BoundLogger,
    PrintLogger
)


# The loggers are compiled at build time, so we can reuse it.
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

```mojo
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


# The loggers are compiled at build time, so we can reuse it.
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

```mojo
from examples.default import logger


fn main():
    logger.info("Hello!")
```

## TODO

### Features

- Add more processor functions.
- Add support for logging to files via `Logger` struct that uses a writer that implement `io.Writer`.
- Add global logger support once we have file scope support.
- Make formatter flexible and composable. Right now it's only a few predefined formats.
- Exiting on fatal log calls.
- logf functions to specify a specific format for that log message.

### Bugs
