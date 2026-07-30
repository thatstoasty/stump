"""Benchmarks for stump.

Run with `pixi run benchmarks`.

Most cases log to a scratch file through a `FileLogger` so the numbers measure
the library rather than the terminal, and the file is removed afterwards.
Loggers are built outside the timed loop, so what is reported is the cost of a
log call, not of constructing a logger.

The case worth watching is `debug (suppressed)`. `BoundLogger` gates every log
method behind a `comptime if`, so a call below the logger's level is compiled
away and costs nothing at all. The kwargs variant is not free, because the
`OwnedKwargsDict` is still materialized at the call site before the suppressed
body is reached.
"""

from std.os import remove
from std.os.path import exists
from std.tempfile import gettempdir
from std.time import perf_counter_ns

from stump import BoundLogger, FileLogger, LogLevel, MultiLogger, logfmt_formatter

comptime ITERATIONS = 20_000
"""How many times to run each timed loop."""
comptime WARMUP = 1_000
"""How many untimed iterations to run first."""


def _sink_path() raises -> String:
    """Build the path of the scratch file benchmarked records are written to.

    Returns:
        The absolute path to write to.

    Raises:
        If no temp directory can be located.
    """
    var directory = gettempdir()
    if not directory:
        raise Error("could not locate a temp directory")

    return String(directory.value(), "/stump_benchmark.log")


def _report(name: String, elapsed_ns: UInt):
    """Print one benchmark result as nanoseconds per operation.

    Args:
        name: The name of the case being reported.
        elapsed_ns: The total time the timed loop took, in nanoseconds.
    """
    var per_op = Float64(Int(elapsed_ns)) / Float64(ITERATIONS)
    var padded = name.copy()
    while padded.byte_length() < 32:
        padded += " "

    print(padded, per_op, "ns/op")


def _null_logger[level: LogLevel]() raises -> BoundLogger[FileLogger[level]]:
    """Build a logger that writes formatted records to the scratch file.

    Parameters:
        level: The log level of the logger.

    Returns:
        A bound logger writing to the scratch file.

    Raises:
        If the scratch file cannot be opened.
    """
    return BoundLogger(FileLogger[level](_sink_path()), formatter=logfmt_formatter, apply_styles=False)


def bench_bare_print() raises:
    """Time a bare file write as a floor for the other cases."""
    var handle = open(_sink_path(), "a")
    for _ in range(WARMUP):
        handle.write("Testing log...\n")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        handle.write("Testing log...\n")
    _report("bare file write", perf_counter_ns() - start)


def bench_info() raises:
    """Time an `info` call with no extra key-value pairs."""
    var logger = _null_logger[LogLevel.INFO]()
    for _ in range(WARMUP):
        logger.info("Testing log...")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        logger.info("Testing log...")
    _report("info", perf_counter_ns() - start)


def bench_info_with_args() raises:
    """Time an `info` call carrying positional key-value pairs."""
    var logger = _null_logger[LogLevel.INFO]()
    for _ in range(WARMUP):
        logger.info("Testing log...", "key", "value")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        logger.info("Testing log...", "key", "value")
    _report("info + positional args", perf_counter_ns() - start)


def bench_info_with_kwargs() raises:
    """Time an `info` call carrying keyword key-value pairs."""
    var logger = _null_logger[LogLevel.INFO]()
    for _ in range(WARMUP):
        logger.info("Testing log...", key="value")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        logger.info("Testing log...", key="value")
    _report("info + kwargs", perf_counter_ns() - start)


def bench_suppressed_debug() raises:
    """Time a `debug` call on an INFO logger.

    The `comptime if` in `BoundLogger.debug` means this call has no body at all
    after compilation, so this should report zero.
    """
    var logger = _null_logger[LogLevel.INFO]()
    for _ in range(WARMUP):
        logger.debug("Testing log...")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        logger.debug("Testing log...")
    _report("debug (suppressed)", perf_counter_ns() - start)


def bench_suppressed_debug_with_kwargs() raises:
    """Time a suppressed `debug` call that still passes kwargs.

    The body is compiled away, but the caller still builds an `OwnedKwargsDict`
    before the call, so this is not free.
    """
    var logger = _null_logger[LogLevel.INFO]()
    for _ in range(WARMUP):
        logger.debug("Testing log...", key="value")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        logger.debug("Testing log...", key="value")
    _report("debug (suppressed) + kwargs", perf_counter_ns() - start)


def bench_bind() raises:
    """Time deriving a child logger from a parent."""
    var logger = _null_logger[LogLevel.INFO]()
    for _ in range(WARMUP):
        var child = logger.bind(request_id="abc123")
        _ = child^

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        var child = logger.bind(request_id="abc123")
        _ = child^
    _report("bind (child logger)", perf_counter_ns() - start)


def bench_bound_context() raises:
    """Time an `info` call on a logger that already carries bound context."""
    var logger = _null_logger[LogLevel.INFO]().bind(service="api", env="prod")
    for _ in range(WARMUP):
        logger.info("Testing log...")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        logger.info("Testing log...")
    _report("info (2 bound keys)", perf_counter_ns() - start)


def bench_buffered_file() raises:
    """Time a `FileLogger` that buffers records instead of writing each one."""
    var logger = BoundLogger(
        FileLogger[LogLevel.INFO](_sink_path(), auto_flush=False),
        formatter=logfmt_formatter,
        apply_styles=False,
    )
    for _ in range(WARMUP):
        logger.info("Testing log...")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        logger.info("Testing log...")
    _report("info (buffered file)", perf_counter_ns() - start)


def bench_multi_logger() raises:
    """Time a tee writing each record to two file sinks."""
    var logger = BoundLogger(
        MultiLogger(FileLogger[LogLevel.INFO](_sink_path()), FileLogger[LogLevel.INFO](_sink_path())),
        formatter=logfmt_formatter,
        apply_styles=False,
    )
    for _ in range(WARMUP):
        logger.info("Testing log...")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        logger.info("Testing log...")
    _report("info (tee to 2 files)", perf_counter_ns() - start)


def bench_styled() raises:
    """Time an `info` call with styling left on, as `get_logger` has it."""
    var logger = BoundLogger(FileLogger[LogLevel.INFO](_sink_path()))
    for _ in range(WARMUP):
        logger.info("Testing log...")

    var start = perf_counter_ns()
    for _ in range(ITERATIONS):
        logger.info("Testing log...")
    _report("info (styles applied)", perf_counter_ns() - start)


def main() raises:
    """Run every benchmark."""
    print("stump benchmarks -", ITERATIONS, "iterations each\n")

    bench_bare_print()
    bench_info()
    bench_info_with_args()
    bench_info_with_kwargs()
    bench_bound_context()
    bench_styled()
    bench_buffered_file()
    bench_multi_logger()
    bench_bind()
    bench_suppressed_debug()
    bench_suppressed_debug_with_kwargs()

    if exists(_sink_path()):
        remove(_sink_path())
