# stump

![Mojo main 24.5](https://img.shields.io/badge/Mojo%F0%9F%94%A5-24.5-purple)

WIP Logger! Inspired by charmbracelet's `log` package and the Python `structlog` package.

## Installation

1. First, you'll need to configure your `mojoproject.toml` file to include my Conda channel. Add `"https://repo.prefix.dev/mojo-community"` to the list of channels.
2. Next, add `stump` to your project's dependencies by running `magic add stump`.
3. Finally, run `magic install` to install in `stump` and its dependencies. You should see the `.mojopkg` files in `$CONDA_PREFIX/lib/mojo/`.

See the examples directory for examples on setting up custom processors, styling, message only/json/logfmt logging, and logging with the styling turned off.

There's support for arbitrary arg pairs and kwargs to be merged into the log statement!

Example:

```mojo
from stump import get_logger


var logger = get_logger()


fn main():
    logger.info("Information is good.", "key", "value")
    logger.warn("Warnings can be good too.", "no_value")
    logger.error("An error!", erroring=True)
    logger.fatal("uh oh...", "number", 4, "mojo", "🔥")
    logger.debug("Debugging...")
```

![Example](https://github.com/thatstoasty/stump/blob/main/doc/tapes/default.gif)

JSON logger example:

```mojo
from stump import DEBUG, json_formatter, BoundLogger, PrintLogger


# The loggers are compiled at build time, so we can reuse it.
var logger = BoundLogger(PrintLogger(DEBUG), formatter=json_formatter, apply_styles=False)


fn main():
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")

```

![JSON Example](https://github.com/thatstoasty/stump/blob/main/doc/tapes/json.gif)

Customized style and processor logger example:

```mojo
from stump import (
    DEBUG,
    Processor,
    Context,
    Styles,
    Sections,
    BoundLogger,
    STDLogger,
    add_log_level,
    add_timestamp,
)
import external.mist


# Define a custom processor to add a name to the log output.
fn add_my_name(context: Context, level: String) -> Context:
    var new_context = context
    new_context["name"] = "Mikhail"
    return new_context


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


# Build a bound logger with custom processors and styling
var logger = BoundLogger(
    STDLogger(level=DEBUG),
    processors=List[Processor](add_log_level, add_timestamp, add_my_name),
    styles=my_styles(),
)


fn main():
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!", erroring=True)
    logger.debug("Debugging...")
    logger.fatal("uh oh...")

```

![Custom Example](https://github.com/thatstoasty/stump/blob/main/doc/tapes/custom.gif)

Importing the logger into other files works!

```mojo
from examples.default import logger


fn main():
    logger.info("Hello!")
```

## TODO

### Features

- Add more processor functions.
- Exiting on fatal log calls.
- logf functions to specify a specific format for that log message.
- Speed improvements once https://github.com/modularml/mojo/issues/2779 is resolved and enables `mist` to compile text styling at comp time instead of on each and every log call. Providing a STDOUT writer logger instead of print logger will speed it up measurably as well.
- Simple naive JSON formatter to be improved to handle escaped chars, brackets, etc correctly.

### Bugs

- There are probably tons of edge cases on JSON parsing that I haven't thought of yet. Please don't be surprised if the JSON formatter breaks on you.
