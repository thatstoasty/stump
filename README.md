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
from stump import LogLevel, json_formatter, BoundLogger, PrintLogger

def main():
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=json_formatter, apply_styles=False)
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
```

![JSON Example](https://github.com/thatstoasty/stump/blob/main/doc/tapes/json.gif)

## Child loggers

`bind` returns a *child* logger carrying extra context. The logger it was called
on is left alone, so a request-scoped logger can be derived from a shared
application logger without the two interfering.

```mojo
from stump import get_logger

def main():
    var logger = get_logger().bind(service="api")

    # `request` carries both keys. `logger` still carries only `service`.
    var request = logger.bind(request_id="abc123")
    request.info("Handling request")

    # Positional pairs work too, and take precedence over a keyword of the
    # same name, matching how the log methods collect their arguments.
    logger.bind("region", "us-east-1").info("Started")
```

`unbind` drops keys, and `new` starts a fresh context while inheriting the sink,
formatter, processors and styles:

```mojo
    request.unbind("request_id").info("Service only")
    request.new(job="nightly").info("Fresh context")
```

Log calls below the logger's level are gated behind a `comptime if`, so they are
compiled away entirely rather than filtered at runtime. Run `pixi run benchmarks`
to see it: a suppressed `logger.debug("...")` measures at 0 ns/op. Passing
keyword arguments to a suppressed call is *not* free, because the caller still
materializes the kwargs before the call.

## Sinks

A sink is anything implementing the `Logger` trait. `PrintLogger` writes to the
console, `FileLogger` appends to a file, and `MultiLogger` tees each record to
two other sinks.

```mojo
from stump import BoundLogger, FileLogger, LogLevel, MultiLogger, PrintLogger, logfmt_formatter

def main() raises:
    # Console and file at once. Nest to fan out to three or more.
    var tee = MultiLogger(PrintLogger[LogLevel.INFO](), FileLogger[LogLevel.DEBUG]("app.log"))
    var logger = BoundLogger(tee^, formatter=logfmt_formatter, apply_styles=False)
    logger.info("Goes to both")
```

`FileLogger` shares its file handle through an `ArcPointer`, so copies — including
the ones made when a logger binds a child — all write to the same file in call
order. Pass `auto_flush=False` to batch records in memory and write them on
`flush()`; anything still buffered is flushed when the last copy goes away.

```mojo
    var logger = FileLogger[LogLevel.INFO]("app.log", auto_flush=False)
    logger.info("buffered")
    logger.flush()
```

Writing a custom sink means implementing one method. The five level-named methods
come with default implementations that dispatch to it:

```mojo
from stump import Logger, LogLevel

@fieldwise_init
struct CountingLogger[log_level: LogLevel](Logger):
    comptime level = Self.log_level

    def log[level: LogLevel](self, message: Some[Writable]):
        comptime if Self.level.value >= level.value:
            print("[", level, "] ", message, sep="")
```

A sink must be `Copyable`, which is what lets a `BoundLogger` wrapping it produce
children. A sink holding something that is not copyable should share it through
an `ArcPointer`, as `FileLogger` does.

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
