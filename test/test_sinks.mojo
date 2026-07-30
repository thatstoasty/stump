"""Tests for the output sinks.

Run with `pixi run tests`, or directly:
`mojo -D ASSERT=all -I . test/test_sinks.mojo`.

These tests write to files under the system temp directory and remove them
again, so they leave nothing behind. Each test uses its own path so the suite
does not care what order it runs in.
"""

from std.os import remove
from std.os.path import exists
from std.tempfile import gettempdir
from std.testing import TestSuite, assert_equal, assert_false, assert_true

from stump import (
    BoundLogger,
    FileLogger,
    LogLevel,
    MultiLogger,
    PrintLogger,
    logfmt_formatter,
)


def _temp_path(name: String) raises -> String:
    """Build a path for a scratch file in the system temp directory.

    Args:
        name: A name unique to the calling test.

    Returns:
        The absolute path to use.

    Raises:
        If no temp directory can be located.
    """
    var directory = gettempdir()
    if not directory:
        raise Error("could not locate a temp directory")

    return String(directory.value(), "/stump_test_", name, ".log")


def _read(path: String) raises -> String:
    """Read a file back in full.

    Args:
        path: The path to read.

    Returns:
        The file's contents.

    Raises:
        If the file cannot be read.
    """
    return open(path, "r").read()


def _cleanup(path: String) raises:
    """Delete a scratch file if it is still there.

    Args:
        path: The path to remove.

    Raises:
        If the file exists but cannot be removed.
    """
    if exists(path):
        remove(path)


def _contains(haystack: String, needle: String) -> Bool:
    """Check for a substring.

    Args:
        haystack: The string to search in.
        needle: The string to search for.

    Returns:
        `True` if `needle` occurs in `haystack`.
    """
    return haystack.find(needle) != -1


# --- FileLogger -------------------------------------------------------------


def test_file_logger_writes_record() raises:
    """A logged record lands in the file, newline terminated."""
    var path = _temp_path("writes_record")
    try:
        var logger = FileLogger[LogLevel.DEBUG](path, mode="w")
        logger.info("hello")
        logger.flush()

        assert_equal(_read(path), "hello\n")
    finally:
        _cleanup(path)


def test_file_logger_appends_by_default() raises:
    """The default mode appends, so a second logger does not truncate."""
    var path = _temp_path("appends")
    try:
        var first = FileLogger[LogLevel.DEBUG](path, mode="w")
        first.info("one")

        var second = FileLogger[LogLevel.DEBUG](path)
        second.info("two")

        assert_equal(_read(path), "one\ntwo\n")
    finally:
        _cleanup(path)


def test_file_logger_respects_level() raises:
    """A record below the logger's level is never written.

    The level check is a `comptime if`, so the suppressed call is compiled away
    rather than filtered at runtime.
    """
    var path = _temp_path("respects_level")
    try:
        var logger = FileLogger[LogLevel.WARN](path, mode="w")
        logger.warn("kept")
        logger.debug("dropped")
        logger.info("also dropped")

        assert_equal(_read(path), "kept\n")
    finally:
        _cleanup(path)


def test_file_logger_copies_share_one_file() raises:
    """Copies write to the same file, in call order.

    The handle lives behind an `ArcPointer`, which is what lets a `FileLogger`
    satisfy the `Copyable` requirement on `Logger` despite `FileHandle` not
    being copyable itself.
    """
    var path = _temp_path("shared_handle")
    try:
        var logger = FileLogger[LogLevel.DEBUG](path, mode="w")
        var copied = logger.copy()

        logger.info("from original")
        copied.info("from copy")
        logger.info("from original again")

        assert_equal(_read(path), "from original\nfrom copy\nfrom original again\n")
    finally:
        _cleanup(path)


def test_file_logger_buffers_until_flush() raises:
    """With auto_flush off, nothing reaches the file until flush is called."""
    var path = _temp_path("buffers")
    try:
        # Create the file so the read below has something to open.
        _ = open(path, "w")

        var logger = FileLogger[LogLevel.DEBUG](path, mode="a", auto_flush=False)
        logger.info("buffered one")
        logger.info("buffered two")
        assert_equal(_read(path), "")

        logger.flush()
        assert_equal(_read(path), "buffered one\nbuffered two\n")
    finally:
        _cleanup(path)


def test_file_logger_flush_is_idempotent() raises:
    """Flushing twice does not duplicate records."""
    var path = _temp_path("flush_twice")
    try:
        _ = open(path, "w")

        var logger = FileLogger[LogLevel.DEBUG](path, mode="a", auto_flush=False)
        logger.info("once")
        logger.flush()
        logger.flush()

        assert_equal(_read(path), "once\n")
    finally:
        _cleanup(path)


def _log_without_flushing(path: String) raises:
    """Log a buffered record and let the logger fall out of scope unflushed.

    Args:
        path: The file to log to.

    Raises:
        If the file cannot be opened.
    """
    var logger = FileLogger[LogLevel.DEBUG](path, mode="a", auto_flush=False)
    logger.info("never explicitly flushed")


def test_file_logger_flushes_when_last_copy_dies() raises:
    """Buffered records are not lost if the caller never flushes."""
    var path = _temp_path("flush_on_drop")
    try:
        _ = open(path, "w")
        _log_without_flushing(path)

        assert_equal(_read(path), "never explicitly flushed\n")
    finally:
        _cleanup(path)


def test_file_logger_takes_an_open_handle() raises:
    """A caller can hand over a file handle it opened itself."""
    var path = _temp_path("open_handle")
    try:
        var logger = FileLogger[LogLevel.DEBUG](open(path, "w"))
        logger.info("from handle")
        logger.flush()

        assert_equal(_read(path), "from handle\n")
    finally:
        _cleanup(path)


def test_file_logger_named_levels_route_to_log() raises:
    """The defaulted trait wrappers all dispatch to `log`."""
    var path = _temp_path("named_levels")
    try:
        var logger = FileLogger[LogLevel.DEBUG](path, mode="w")
        logger.fatal("f")
        logger.error("e")
        logger.warn("w")
        logger.info("i")
        logger.debug("d")

        assert_equal(_read(path), "f\ne\nw\ni\nd\n")
    finally:
        _cleanup(path)


def test_file_logger_under_bound_logger() raises:
    """A bound logger formats the record before the sink writes it."""
    var path = _temp_path("bound")
    try:
        var logger = BoundLogger(
            FileLogger[LogLevel.DEBUG](path, mode="w"),
            formatter=logfmt_formatter,
            apply_styles=False,
        )
        logger.info("hello", "key", "value")

        var contents = _read(path)
        assert_true(_contains(contents, 'message=hello'))
        assert_true(_contains(contents, "key=value"))
    finally:
        _cleanup(path)


def test_bound_child_shares_the_sink() raises:
    """A child logger writes to the same file as its parent."""
    var path = _temp_path("child_sink")
    try:
        var parent = BoundLogger(
            FileLogger[LogLevel.DEBUG](path, mode="w"),
            formatter=logfmt_formatter,
            apply_styles=False,
        )
        var child = parent.bind(service="api")

        parent.info("from parent")
        child.info("from child")

        var contents = _read(path)
        assert_true(_contains(contents, "from parent"))
        assert_true(_contains(contents, "from child"))
        assert_true(_contains(contents, "service=api"))
    finally:
        _cleanup(path)


# --- MultiLogger ------------------------------------------------------------


def test_multi_logger_writes_to_both() raises:
    """A teed record reaches both sinks."""
    var first = _temp_path("tee_first")
    var second = _temp_path("tee_second")
    try:
        var tee = MultiLogger(
            FileLogger[LogLevel.DEBUG](first, mode="w"),
            FileLogger[LogLevel.DEBUG](second, mode="w"),
        )
        tee.info("teed")
        tee.first.flush()
        tee.second.flush()

        assert_equal(_read(first), "teed\n")
        assert_equal(_read(second), "teed\n")
    finally:
        _cleanup(first)
        _cleanup(second)


def test_multi_logger_level_is_the_more_permissive() raises:
    """The tee's level is the higher of the two, so neither sink is starved."""
    assert_true(MultiLogger[PrintLogger[LogLevel.WARN], PrintLogger[LogLevel.DEBUG]].level == LogLevel.DEBUG)
    assert_true(MultiLogger[PrintLogger[LogLevel.DEBUG], PrintLogger[LogLevel.WARN]].level == LogLevel.DEBUG)
    assert_true(MultiLogger[PrintLogger[LogLevel.ERROR], PrintLogger[LogLevel.ERROR]].level == LogLevel.ERROR)


def test_multi_logger_each_sink_filters_itself() raises:
    """A record can reach one sink and be dropped by the other."""
    var verbose = _temp_path("tee_verbose")
    var quiet = _temp_path("tee_quiet")
    try:
        var tee = MultiLogger(
            FileLogger[LogLevel.DEBUG](verbose, mode="w"),
            FileLogger[LogLevel.ERROR](quiet, mode="w"),
        )
        tee.error("serious")
        tee.debug("chatty")

        assert_equal(_read(verbose), "serious\nchatty\n")
        assert_equal(_read(quiet), "serious\n")
    finally:
        _cleanup(verbose)
        _cleanup(quiet)


def test_multi_logger_nests_for_three_sinks() raises:
    """Nesting composes the pairwise tee into a three-way fan-out."""
    var a = _temp_path("nest_a")
    var b = _temp_path("nest_b")
    var c = _temp_path("nest_c")
    try:
        var tee = MultiLogger(
            FileLogger[LogLevel.DEBUG](a, mode="w"),
            MultiLogger(
                FileLogger[LogLevel.DEBUG](b, mode="w"),
                FileLogger[LogLevel.DEBUG](c, mode="w"),
            ),
        )
        tee.info("three ways")

        assert_equal(_read(a), "three ways\n")
        assert_equal(_read(b), "three ways\n")
        assert_equal(_read(c), "three ways\n")
    finally:
        _cleanup(a)
        _cleanup(b)
        _cleanup(c)


def test_multi_logger_under_bound_logger() raises:
    """A tee works as the sink of a bound logger."""
    var first = _temp_path("tee_bound_first")
    var second = _temp_path("tee_bound_second")
    try:
        var logger = BoundLogger(
            MultiLogger(
                FileLogger[LogLevel.DEBUG](first, mode="w"),
                FileLogger[LogLevel.DEBUG](second, mode="w"),
            ),
            formatter=logfmt_formatter,
            apply_styles=False,
        )
        logger.bind(service="api").info("teed record")

        assert_true(_contains(_read(first), "service=api"))
        assert_true(_contains(_read(second), "service=api"))
    finally:
        _cleanup(first)
        _cleanup(second)


def main() raises:
    """Run the test suite."""
    TestSuite.discover_tests[__functions_in_module()]().run()
