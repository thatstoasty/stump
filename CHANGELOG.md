# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

- **Breaking:** Changed `Formatter` from a bare function alias to a struct pairing the rendering function with a `styled` flag, and `BoundLogger.apply_styles` to default to that flag rather than to `True`. A JSON record was corrupted by default: with styling on, escape sequences landed inside the JSON strings, so `"level"` came out as `"[38;2;19;237;132mINFO[0m"` unless the caller remembered `apply_styles=False`. The shipped formatters are unchanged at the call site; a custom formatter now has to be wrapped as `Formatter(my_fn, styled=False)`. Passing `apply_styles` explicitly still overrides the formatter.
- Added `exit_on_fatal` to `BoundLogger`, which terminates the process with status 1 after a `fatal` record is written. Off by default, so an existing `fatal` call keeps returning. Children inherit it.
- Added an `Arg` conversion from `Error`, so `logger.error("call failed", err=e)` compiles. `Arg` covered fifteen numeric and string types but not the one type most worth passing to `error()`.
- Added `Context.__len__`, `Context.items` and `Context.keys`. A custom `Formatter` receives a `Context` and had no way to walk it, so it had to reach into the underlying `Dict`. `items` had been commented out because the standard library's iterator gained a hasher parameter; it is spelled `ContextDict.H` now, so the signature survives that default changing again.
- Fixed the `DEFAULT_PROCESSORS` docstring claiming it adds callsite information, which no processor has ever done. Exported `DEFAULT_PROCESSORS`, which was defined but unreachable, and `Formatter` and `ContextDict`.
- Changed `examples/turn_off_styler.mojo` to demonstrate the default formatter without colour. It was a duplicate of `examples/logfmt.mojo`, and now that the structured formatters turn styling off themselves, the flag only means something for the human-facing one.
- Removed the README's stale bug note about lists of functions being broken. `processors=[...]` has worked since the 1.0 syntax migration.
- **Breaking:** Changed the `Logger` trait to require a single `log[level: LogLevel]` method instead of five level-named ones, and to require `Copyable`. The five named methods remain as default implementations that dispatch to `log`, so writing a sink is one method rather than six near-identical ones. Any downstream custom `Logger` has to be updated: replace the five methods with `log`, and share any non-copyable resource through an `ArcPointer` to satisfy `Copyable`. `PrintLogger` is unaffected at the call site.
- Changed `BoundLogger.bind` to return a child logger rather than mutating in place. The package is named after bound loggers, but the `structlog` idiom it is modeled on — `var request = log.bind(request_id=id)` producing a child that leaves the parent alone — was impossible: `bind` took a hand-built `Context`, mutated `self`, returned nothing, and `BoundLogger` was not `Copyable`, so binding request-scoped keys polluted the shared logger they came from.
- Added `bind` overloads taking positional and keyword arguments, so `log.bind(service="api")` replaces building a `Dict[String, String]` by hand. Positional pairs take precedence over a keyword of the same name, matching how the log methods already collect their arguments.
- Added `BoundLogger.unbind` to drop keys from a child, and `BoundLogger.new` to start a child with the inherited context cleared but the sink, formatter, processors and styles kept.
- Added `FileLogger`, replacing a block that had been commented out since before the 1.0 syntax migration. It shares its file handle through an `ArcPointer`, so copies — including the ones a `BoundLogger` makes when it binds a child — write to the same file in call order. `auto_flush=False` batches records in memory until `flush()`, and anything still buffered is written when the last copy is destroyed.
- Added `MultiLogger`, a pairwise tee that writes each record to two sinks and nests for three or more. Its level is the more permissive of the two, so neither sink is starved by the other's threshold.
- Fixed `benchmarks/run.mojo`, which did not compile: it imported `FileLogger` and `STDLogger` (neither existed) and used the pre-1.0 `time` and `benchmark` module paths. `STDLogger` was dropped, since `PrintLogger` already covers the standard streams. Added a `benchmarks` pixi task to run it.
- Fixed the README's JSON example, which used `from stump import DEBUG`. `DEBUG` is not exported, and the log level is a struct parameter, so the logger is `PrintLogger[LogLevel.DEBUG]()`.
- Fixed `Styles.values` never matching. The per-key value style was looked up with the already rendered key, which carries ANSI sequences, so every entry in `values` missed and the value came out unstyled. Only visible when colour is actually on: with colour off `render` is the identity, and the lookup succeeded by accident.
- Fixed a `Styles.levels` list shorter than the number of log levels indexing out of bounds, which aborted the process under `ASSERT=all` and read out of bounds in a release build. An out-of-range level is now left unstyled.
- Fixed `Styles.separator` being a dead field. It was declared, defaulted, documented and passed by `examples/custom.mojo`, but nothing read it. It now styles the `=` between a context key and its value.
- Added a test suite for the styling pass, which had no coverage at all. The styles are built with the colour profile forced on, since the auto-detected profile makes `render` an identity function under a piped test runner.
- Fixed `Context.to_logfmt` emitting unquoted values, so a value containing a space or an equals sign broke the `key=value` framing.

- Added a test suite covering log levels, `Context`, argument collection, the formatters, processors and `bind`.
- Changed the `tests` and `examples` tasks to propagate a non-zero exit status. `find -exec` always exits 0, so a failing test could not fail CI.
- Fixed `_apply_processors` failing to compile under Mojo 1.0.0b2, where iterating `List[Processor]` yields an element that does not implement `__call__`.
- Fixed the package workflow running `pixi run build`, which is not a defined task, so the step exited 127 instead of building the package.
- Changed both workflows to pin pixi v0.70.2. The version pinned in `test.yml` could not read the v7 lockfile, and `latest` cannot resolve the dependency build backends.
- Added a `push` trigger on `main` and a concurrency group to both workflows, and raised the test job timeout to 15 minutes.

## [0.1.0] - 2024-09-13

- First release with a changelog! Added rattler build and conda publish.
