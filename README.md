# stump

A Structured Logger for Mojo! Inspired by charmbracelet's `log` package and the Python `structlog` package.
This is not production ready, but more of an experiment. But feel free to use it for your projects!

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-1.0.0b2-orange)
![Build Status](https://github.com/thatstoasty/stump/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/stump/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Adding the `stump` package to your project

First, you'll need to enable the `pixi-build` preview by adding this to the `workspace` section of your `pixi.toml` file.

```bash
preview = ["pixi-build"]
```

### Building it from source

There's two ways to build `stump` from source: directly from the Git repository or by cloning the repository locally.

#### Building from source: Git

Run the following commands in your terminal:

```bash
pixi add stump --git "https://github.com/thatstoasty/stump.git" --tag v0.1.1 && pixi install
```

#### Building from source: Local

```bash
# Clone the repository to your local machine
git clone https://github.com/thatstoasty/stump.git

# Add the package to your project from the local path
pixi add -s ./path/to/stump && pixi install
```

## Examples

```mojo
from stump import get_logger

def main():
    var logger = get_logger()
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

def main():
    var logger = BoundLogger(PrintLogger(DEBUG), formatter=json_formatter, apply_styles=False)
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
    LogLevel,
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


# Define a custom processor to add a name to the log output.
def add_my_name(context: Context, level: LogLevel) -> Context:
    var new_context = context.copy()
    new_context["name"] = "Mikhail"
    return new_context^


# Define custom styles to format and colorize the log output.
def my_styles() -> Styles:
    # Log level styles, by default just set colors
    var base_style = mist.Style(mist.Profile.TRUE_COLOR)
    var faint_style = base_style.faint()
    var levels: List[mist.Style] = [
        base_style.background(0xD4317D),
        base_style.background(0xD48244),
        base_style.background(0x13ED84),
        base_style.background(0xDECF2F),
        base_style.background(0xBD37DB),
    ]

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
        PrintLogger[LogLevel.DEBUG](),
        processors=[add_timestamp, add_log_level, add_my_name],
        styles=my_styles(),
    )
    logger.info("Information is good.")
    logger.warn("Warnings can be good too.")
    logger.error("An error!", erroring=True)
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
```

![Custom Example](https://github.com/thatstoasty/stump/blob/main/doc/tapes/custom.gif)

## TODO

### Features

- Add more processor functions.
- Exiting on fatal log calls.
- logf functions to specify a specific format for that log message.

### Bugs

- Lists of functions are broken. In the meantime, the library uses a function that returns a list of functions instead. This will be changed when modular fixes https://github.com/modular/mojo/issues/3285.
