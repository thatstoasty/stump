# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

- **Breaking:** Changed the `Logger` trait to require a single `log[level: LogLevel]` method instead of five level-named ones, and to require `Copyable`. The five named methods remain as default implementations that dispatch to `log`, so writing a sink is one method rather than six near-identical ones. Any downstream custom `Logger` has to be updated: replace the five methods with `log`, and share any non-copyable resource through an `ArcPointer` to satisfy `Copyable`. `PrintLogger` is unaffected at the call site.
- Changed `BoundLogger.bind` to return a child logger rather than mutating in place. The package is named after bound loggers, but the `structlog` idiom it is modeled on — `var request = log.bind(request_id=id)` producing a child that leaves the parent alone — was impossible: `bind` took a hand-built `Context`, mutated `self`, returned nothing, and `BoundLogger` was not `Copyable`, so binding request-scoped keys polluted the shared logger they came from.
- Added `bind` overloads taking positional and keyword arguments, so `log.bind(service="api")` replaces building a `Dict[String, String]` by hand. Positional pairs take precedence over a keyword of the same name, matching how the log methods already collect their arguments.
- Added `BoundLogger.unbind` to drop keys from a child, and `BoundLogger.new` to start a child with the inherited context cleared but the sink, formatter, processors and styles kept.
- Added `FileLogger`, replacing a block that had been commented out since before the 1.0 syntax migration. It shares its file handle through an `ArcPointer`, so copies — including the ones a `BoundLogger` makes when it binds a child — write to the same file in call order. `auto_flush=False` batches records in memory until `flush()`, and anything still buffered is written when the last copy is destroyed.
- Added `MultiLogger`, a pairwise tee that writes each record to two sinks and nests for three or more. Its level is the more permissive of the two, so neither sink is starved by the other's threshold.
- Fixed `benchmarks/run.mojo`, which did not compile: it imported `FileLogger` and `STDLogger` (neither existed) and used the pre-1.0 `time` and `benchmark` module paths. `STDLogger` was dropped, since `PrintLogger` already covers the standard streams. Added a `benchmarks` pixi task to run it.
- Fixed the README's JSON example, which used `from stump import DEBUG`. `DEBUG` is not exported, and the log level is a struct parameter, so the logger is `PrintLogger[LogLevel.DEBUG]()`.
- Fixed `Context.to_logfmt` emitting unquoted values, so a value containing a space or an equals sign broke the `key=value` framing.

- Added a test suite covering log levels, `Context`, argument collection, the formatters, processors and `bind`.
- Changed the `tests` and `examples` tasks to propagate a non-zero exit status. `find -exec` always exits 0, so a failing test could not fail CI.
- Fixed `_apply_processors` failing to compile under Mojo 1.0.0b2, where iterating `List[Processor]` yields an element that does not implement `__call__`.
- Fixed the package workflow running `pixi run build`, which is not a defined task, so the step exited 127 instead of building the package.
- Changed both workflows to pin pixi v0.70.2. The version pinned in `test.yml` could not read the v7 lockfile, and `latest` cannot resolve the dependency build backends.
- Added a `push` trigger on `main` and a concurrency group to both workflows, and raised the test job timeout to 15 minutes.

## [0.1.0] - 2024-09-13

- First release with a changelog! Added rattler build and conda publish.
