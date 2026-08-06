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
    logger.warning("Warnings can be good too.", "no_value")
    logger.error("An error!", erroring=True)
    logger.critical("uh oh...", "number", 4, "mojo", "🔥")
    logger.debug("Debugging...")
```

![Example](https://github.com/thatstoasty/stump/blob/main/doc/tapes/default.gif)

JSON logger example:

```mojo
from std.logger import Level
from stump import JSON_FORMATTER, BoundLogger, PrintLogger

def main():
    var logger = BoundLogger(PrintLogger[Level.DEBUG](), formatter=JSON_FORMATTER[pretty=False])
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warning("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.critical("uh oh...")
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

## Levels

Levels come from the standard library — `from std.logger import Level` — rather
than from stump. They ascend in severity:

| Level | Value |
|---|---|
| `Level.NOTSET` | 0 |
| `Level.TRACE` | 10 |
| `Level.DEBUG` | 20 |
| `Level.INFO` | 30 |
| `Level.WARNING` | 40 |
| `Level.ERROR` | 50 |
| `Level.CRITICAL` | 60 |

A logger's level is a *minimum severity*: `PrintLogger[Level.INFO]()` emits
`INFO` and everything above it, and drops `DEBUG` and `TRACE`. `Level.TRACE` is
therefore the most permissive setting — with one exception worth knowing:
**`Level.NOTSET` disables logging entirely**, so a logger built with it emits
nothing at any level rather than everything.

The level methods are named for these levels, so it is `logger.warning(...)` and
`logger.critical(...)` — not `warn` or `fatal`.

## The default logger

`stump.info(...)` and friends log to a process-wide logger, created on first use
and kept for the life of the process. There is nothing to construct and nothing
to thread through your call graph.

```mojo
import stump

def main() raises:
    stump.info("Information is good.", "key", "value")
    stump.warning("Warnings can be good too.")
    stump.error("An error!", code=500)
    stump.critical("uh oh...")
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

Every level shares one global slot, so `default[Level.DEBUG]()` reaches the
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
from std.logger import Level
from stump import BoundLogger, PrintLogger, add_timestamp, add_log_level

def main() raises:
    stump.bind_context(service="api")

    # Sees the global context.
    var a = BoundLogger(PrintLogger[Level.INFO]())
    a.info("via default processors")   # service=api

    # Does not — `merge_global_context` is missing from the list.
    var b = BoundLogger(PrintLogger[Level.INFO](), processors=[add_timestamp(), add_log_level])
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
from std.logger import Level
from stump import BoundLogger, PrintLogger, Context, DropEvent, add_timestamp, add_log_level


def drop_health_checks(mut context: Context, level: Level) raises DropEvent:
    # context["path"] would raise DictKeyError, which this signature cannot
    # propagate — a processor can only raise DropEvent.
    if context.get("path", "") == "/healthz":
        raise DropEvent()


def main() raises:
    var logger = BoundLogger(
        PrintLogger[Level.DEBUG](),
        processors=[add_timestamp(), add_log_level, drop_health_checks],
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
console, `FileLogger` appends to a file, `StdLogger` hands records to the
standard library's own logger, and `MultiLogger` tees each record to two other
sinks.

```mojo
from std.logger import Level
from stump import BoundLogger, FileLogger, MultiLogger, PrintLogger, LOGFMT_FORMATTER

def main() raises:
    # Console and file at once. Nest to fan out to three or more.
    var tee = MultiLogger(PrintLogger[Level.INFO](), FileLogger[Level.DEBUG]("app.log"))
    var logger = BoundLogger(tee^, formatter=LOGFMT_FORMATTER, apply_styles=False)
    logger.info("Goes to both")
```

### FileLogger

`FileLogger` shares its file handle through an `ArcPointer`, so copies — including
the ones made when a logger binds a child — all write to the same file in call
order. `mode` defaults to `"a"`; pass `"w"` to truncate on open.

```mojo
from std.logger import Level
from stump import BoundLogger, FileLogger, LOGFMT_FORMATTER

def main() raises:
    var logger = BoundLogger(
        FileLogger[Level.DEBUG]("app.log", mode="w"),
        formatter=LOGFMT_FORMATTER,
    )
    logger.info("Started")

    # The child appends to the same file as its parent.
    logger.bind(request_id="abc123").info("Handling request")
```

`auto_flush=False` batches records in memory instead of writing each one straight
away. Hold on to the sink to get something to call `flush()` on — because the
handle and buffer live behind an `ArcPointer`, flushing through that copy flushes
what the bound logger wrote. Anything still buffered is also flushed when the last
copy is destroyed, so records are never lost:

```mojo
from std.logger import Level
from stump import BoundLogger, FileLogger, LOGFMT_FORMATTER

def main() raises:
    var sink = FileLogger[Level.DEBUG]("app.log", auto_flush=False)
    var logger = BoundLogger(sink.copy(), formatter=LOGFMT_FORMATTER)

    logger.info("buffered")
    logger.info("also buffered")
    sink.flush()
```

### StdLogger

`StdLogger` forwards records to `std.logger.Logger`, so stump's context and
formatting sit on top of whatever the standard library does with them. The level
appears twice because the stdlib logger is itself parameterized on one — the
inner value is what actually filters:

```mojo
from std.logger import Level, Logger
from stump import BoundLogger, StdLogger

def main() raises:
    var logger = BoundLogger(StdLogger[Level.DEBUG](Logger[Level.DEBUG]()))
    logger.info("Information is good.", "key", "value")

    # The stdlib logger's own options come along, such as a prefix on every record.
    var tagged = BoundLogger(StdLogger[Level.INFO](Logger[Level.INFO](prefix="[api] ")))
    tagged.info("Prefixed by the stdlib logger")
```

One behaviour to know about: `std.logger.Logger.critical` **aborts the process**
by design, so `logger.critical(...)` on a `StdLogger` terminates where the same
call on a `PrintLogger` or `FileLogger` would merely log. That is separate from
`exit_on_fatal`, which is off by default.

### Custom sinks

Writing a custom sink means implementing one method. The six level-named methods
come with default implementations that dispatch to it:

```mojo
from std.logger import Level
from stump import Logger

@fieldwise_init
struct CountingLogger[log_level: Level](Logger):
    comptime level = Self.log_level

    def log[level: Level](self, message: Some[Writable]):
        # `BoundLogger` already gates on level before it ever calls a sink, so a
        # sink only needs its own check when it is used directly, as here.
        comptime if Self.level <= level:
            print("[", level, "] ", message, sep="")


def main():
    var logger = CountingLogger[Level.INFO]()
    logger.info("routed through the one required method")
```

A sink must be `Copyable`, which is what lets a `BoundLogger` wrapping it produce
children. A sink holding something that is not copyable should share it through
an `ArcPointer`, as `FileLogger` does.

Customized style and processor logger example:

```mojo
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
# A processor edits the context in place and returns nothing.
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
```

![Custom Example](https://github.com/thatstoasty/stump/blob/main/doc/tapes/custom.gif)

## Formatters and styling

A `Formatter` pairs a rendering function with whether its output is meant to be
styled. `apply_styles` defaults to that flag, so a structured formatter cannot be
corrupted by escape sequences unless you explicitly ask for it:

```mojo
from std.logger import Level
from stump import BoundLogger, PrintLogger, JSON_FORMATTER

def main():
    _ = BoundLogger(PrintLogger[Level.INFO](), formatter=JSON_FORMATTER[pretty=False])  # unstyled
    _ = BoundLogger(PrintLogger[Level.INFO]())                           # styled
    _ = BoundLogger(PrintLogger[Level.INFO](), apply_styles=False)       # human layout, no colour
```

A custom formatter declares its own preference:

```mojo
from std.logger import Level
from stump import BoundLogger, Formatter, Context, PrintLogger

def _render(context: Context) -> String:
    var out = String()
    for pair in context.items():
        out.write(pair.key, ": ", pair.value, "\n")
    return out^

comptime my_formatter = Formatter(_render, styled=False)

def main():
    var logger = BoundLogger(PrintLogger[Level.INFO](), formatter=my_formatter)
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
from std.logger import Level
from stump import BoundLogger, PrintLogger

def main():
    var logger = BoundLogger(PrintLogger[Level.INFO](), exit_on_fatal=True)
    logger.critical("unrecoverable")   # never returns
```

This is off by default, so adding it does not change what an existing `fatal`
call does. Children inherit the setting.

## TODO

### Features

- Add more processor functions.
- Callsite information (file and line). This needs the call location of the
  `logger.info(...)` call itself, which a `Processor` cannot see — it runs inside
  the logger. Blocked on a call-location API being reachable from this package.
