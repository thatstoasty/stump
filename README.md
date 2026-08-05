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
from stump import LogLevel, JSON_FORMATTER, BoundLogger, PrintLogger

def main():
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=JSON_FORMATTER)
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
from stump import get_logger

def main():
    var request = get_logger().bind(service="api", request_id="abc123")

    request.unbind("request_id").info("Service only")
    request.new(job="nightly").info("Fresh context")
```

Log calls below the logger's level are gated behind a `comptime if`, so they are
compiled away entirely rather than filtered at runtime. Run `pixi run benchmarks`
to see it: a suppressed `logger.debug("...")` measures at 0 ns/op. Passing
keyword arguments to a suppressed call is *not* free, because the caller still
materializes the kwargs before the call.

## The default logger

`stump.info(...)` and friends log to a process-wide logger, created on first use
and kept for the life of the process. There is nothing to construct and nothing
to thread through your call graph.

```mojo
import stump

def main() raises:
    stump.info("Information is good.", "key", "value")
    stump.warn("Warnings can be good too.")
    stump.error("An error!", code=500)
    stump.fatal("uh oh...")
    stump.debug("Debugging...")
```

The level comes from the `STUMP_LOG_LEVEL` **build-time define**, not an
environment variable:

```bash
mojo -D STUMP_LOG_LEVEL=DEBUG -I . main.mojo
```

Exporting `STUMP_LOG_LEVEL` in your shell has no effect. Keeping it a
compile-time value is what lets the level check compile suppressed calls away
entirely, exactly as it does for a logger you construct yourself.

`default()` hands back the logger, so children can be derived from it:

```mojo
from stump import default

def main() raises:
    var request = default()[].bind(request_id="abc123")
    request.info("Handling request")
```

Every level shares one global slot, so `default[LogLevel.DEBUG]()` reaches the
same logger as `default()` and gates that call at DEBUG. The parameter selects
the call site's level, not a different logger.

## Global context

Keys bound to the global context are merged into every record — from the default
logger and from loggers you construct yourself.

```mojo
import stump

def main() raises:
    stump.bind_context(service="api", region="us-east-1")
    stump.info("Started")            # service=api region=us-east-1

    stump.unbind_context("region")
    stump.info("Region dropped")     # service=api

    # Bound for the duration of the block, unbound on the way out.
    with stump.scoped_context(job="nightly"):
        stump.info("Inside the job") # service=api job=nightly
    stump.info("After the job")      # service=api

    stump.clear_context()
```

The merge is done by the `merge_global_context` processor, which is part of
`DEFAULT_PROCESSORS`. A logger built with an explicit `processors=[...]` that
leaves it out will not pick up the global context:

```mojo
import stump
from stump import BoundLogger, PrintLogger, LogLevel, add_timestamp, add_log_level

def main() raises:
    stump.bind_context(service="api")

    # Sees the global context.
    var a = BoundLogger(PrintLogger[LogLevel.INFO]())
    a.info("via default processors")   # service=api

    # Does not — `merge_global_context` is missing from the list.
    var b = BoundLogger(PrintLogger[LogLevel.INFO](), processors=[add_timestamp, add_log_level])
    b.info("via explicit processors")  # no service key

    stump.clear_context()
```

`unbind_context` raises `DictKeyError` when a key is not bound, unlike
`BoundLogger.unbind`, which ignores missing keys.

## Filtering with DropEvent

A processor can drop a record outright by raising `DropEvent`. No later
processor runs, the formatter never sees the context, and the sink never
receives the call:

```mojo
from stump import BoundLogger, PrintLogger, LogLevel, Context, DropEvent, add_timestamp, add_log_level


def drop_health_checks(mut context: Context, level: LogLevel) raises DropEvent:
    # context["path"] would raise DictKeyError, which this signature cannot
    # propagate — a processor can only raise DropEvent.
    if context.get("path", "") == "/healthz":
        raise DropEvent()


def main() raises:
    var logger = BoundLogger(
        PrintLogger[LogLevel.DEBUG](),
        processors=[add_timestamp, add_log_level, drop_health_checks],
    )
    logger.info("handled", path="/healthz")  # dropped, nothing is printed
    logger.info("handled", path="/orders")   # printed as usual
```

`DropEvent` is why every built-in processor, and `Processor` itself, declares
`raises DropEvent` even though only a filtering processor actually raises it.

Order matters: a processor placed before `drop_health_checks` in the list still
runs and any context it wrote survives, since only the *record* is discarded,
not the work already done. A processor placed after it does not run at all.

## Sinks

A sink is anything implementing the `Logger` trait. `PrintLogger` writes to the
console, `FileLogger` appends to a file, and `MultiLogger` tees each record to
two other sinks.

```mojo
from stump import BoundLogger, FileLogger, LogLevel, MultiLogger, PrintLogger, LOGFMT_FORMATTER

def main() raises:
    # Console and file at once. Nest to fan out to three or more.
    var tee = MultiLogger(PrintLogger[LogLevel.INFO](), FileLogger[LogLevel.DEBUG]("app.log"))
    var logger = BoundLogger(tee^, formatter=LOGFMT_FORMATTER, apply_styles=False)
    logger.info("Goes to both")
```

`FileLogger` shares its file handle through an `ArcPointer`, so copies — including
the ones made when a logger binds a child — all write to the same file in call
order. Pass `auto_flush=False` to batch records in memory and write them on
`flush()`; anything still buffered is flushed when the last copy goes away.

```mojo
from stump import FileLogger, LogLevel

def main() raises:
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


def main():
    var logger = CountingLogger[LogLevel.INFO]()
    logger.info("routed through the one required method")
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
# A processor edits the context in place and returns nothing.
def add_my_name(mut context: Context, level: LogLevel):
    context["name"] = "Mikhail"


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

## Formatters and styling

A `Formatter` pairs a rendering function with whether its output is meant to be
styled. `apply_styles` defaults to that flag, so a structured formatter cannot be
corrupted by escape sequences unless you explicitly ask for it:

```mojo
from stump import BoundLogger, PrintLogger, LogLevel, JSON_FORMATTER

def main():
    _ = BoundLogger(PrintLogger[LogLevel.INFO](), formatter=JSON_FORMATTER)  # unstyled
    _ = BoundLogger(PrintLogger[LogLevel.INFO]())                           # styled
    _ = BoundLogger(PrintLogger[LogLevel.INFO](), apply_styles=False)       # human layout, no colour
```

A custom formatter declares its own preference:

```mojo
from stump import BoundLogger, Formatter, Context, PrintLogger, LogLevel

def _render(context: Context) -> String:
    var out = String()
    for pair in context.items():
        out.write(pair.key, ": ", pair.value, "\n")
    return out^

comptime my_formatter = Formatter(_render, styled=False)

def main():
    var logger = BoundLogger(PrintLogger[LogLevel.INFO](), formatter=my_formatter)
    logger.info("via a custom formatter")
```

`Context` is an alias for `Dict[String, String]`, so a formatter has the whole
`Dict` API to work with — `len()`, `items()`, `keys()`, and the rest — rather
than a separate wrapper type with its own smaller surface. `to_logfmt`,
`to_json` and `to_json_string` are free functions for the same reason: they are
stump-specific renderings of a plain mapping, not something a generic context
needs to know how to do itself.

## Errors and fatal calls

An `Error` can be logged directly, which is the type most worth passing to
`error()`:

```mojo
from stump import get_logger

def risky() raises:
    raise Error("db unreachable")

def main():
    var logger = get_logger()
    try:
        risky()
    except e:
        logger.error("call failed", err=e^)
```

`fatal` writes the record and, if asked, terminates the process with status 1:

```mojo
from stump import BoundLogger, PrintLogger, LogLevel

def main():
    var logger = BoundLogger(PrintLogger[LogLevel.INFO](), exit_on_fatal=True)
    logger.fatal("unrecoverable")   # never returns
```

This is off by default, so adding it does not change what an existing `fatal`
call does. Children inherit the setting.

## TODO

### Features

- Add more processor functions.
- Callsite information (file and line). This needs the call location of the
  `logger.info(...)` call itself, which a `Processor` cannot see — it runs inside
  the logger. Blocked on a call-location API being reachable from this package.
