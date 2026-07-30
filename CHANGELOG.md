# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

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
