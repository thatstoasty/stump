# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

- Fixed `_apply_processors` failing to compile under Mojo 1.0.0b2, where iterating `List[Processor]` yields an element that does not implement `__call__`.

## [0.1.0] - 2024-09-13

- First release with a changelog! Added rattler build and conda publish.
