"""Tests for stump.

Run with `pixi run tests`, or directly:
`mojo -D ASSERT=all -I . test/test_stump.mojo`.

Tests target the deterministic surface: context manipulation, argument
collection, formatter output, and log level semantics. Timestamps come from
the wall clock, so tests that touch a formatted record build the context by
hand rather than going through a processor.
"""

from std.collections import Dict
from std.testing import TestSuite, assert_equal, assert_false, assert_raises, assert_true

from stump import (
    BoundLogger,
    Context,
    LogLevel,
    PrintLogger,
    add_log_level,
    default_formatter,
    json_formatter,
    logfmt_formatter,
)
from stump.bound_logger import collect_args


def _contains(haystack: String, needle: String) -> Bool:
    """Check for a substring.

    Args:
        haystack: The string to search in.
        needle: The string to search for.

    Returns:
        `True` if `needle` occurs in `haystack`.
    """
    return haystack.find(needle) != -1


def _collect[*Ts: Writable](*args: *Ts) -> Dict[String, String]:
    """Collect positional args into a dict, as the logging methods do.

    Parameters:
        Ts: The types of the positional arguments.

    Args:
        args: The positional arguments to collect.

    Returns:
        The collected key-value pairs.
    """
    var kvs = Dict[String, String]()
    collect_args(args, kvs)
    return kvs^


# --- log levels -------------------------------------------------------------


def test_log_level_ordering() raises:
    """Lower values are more severe, so FATAL sorts below DEBUG."""
    assert_true(LogLevel.FATAL < LogLevel.ERROR)
    assert_true(LogLevel.ERROR < LogLevel.WARN)
    assert_true(LogLevel.WARN < LogLevel.INFO)
    assert_true(LogLevel.INFO < LogLevel.DEBUG)


def test_log_level_values() raises:
    """The named levels have stable numeric values."""
    assert_equal(Int(LogLevel.FATAL.value), 0)
    assert_equal(Int(LogLevel.ERROR.value), 1)
    assert_equal(Int(LogLevel.WARN.value), 2)
    assert_equal(Int(LogLevel.INFO.value), 3)
    assert_equal(Int(LogLevel.DEBUG.value), 4)


def test_log_level_equality() raises:
    """Levels compare by value."""
    assert_true(LogLevel.INFO == LogLevel(3))
    assert_false(LogLevel.INFO == LogLevel.DEBUG)


def test_log_level_names() raises:
    """Each named level renders as its uppercase name."""
    assert_equal(String(LogLevel.FATAL), "FATAL")
    assert_equal(String(LogLevel.ERROR), "ERROR")
    assert_equal(String(LogLevel.WARN), "WARN")
    assert_equal(String(LogLevel.INFO), "INFO")
    assert_equal(String(LogLevel.DEBUG), "DEBUG")


def test_log_level_unknown_name() raises:
    """An out-of-range level renders with its numeric value."""
    assert_equal(String(LogLevel(9)), "UNKNOWN(9)")


# --- context ----------------------------------------------------------------


def test_context_set_and_get() raises:
    """Values round-trip through the subscript operators."""
    var context = Context()
    context["key"] = "value"
    assert_equal(context["key"], "value")


def test_context_overwrite() raises:
    """Setting an existing key replaces the value."""
    var context = Context()
    context["key"] = "first"
    context["key"] = "second"
    assert_equal(context["key"], "second")


def test_context_contains() raises:
    """Membership reflects what has been set."""
    var context = Context()
    context["present"] = "yes"
    assert_true("present" in context)
    assert_false("absent" in context)


def test_context_missing_key_raises() raises:
    """Reading an absent key raises rather than returning empty."""
    var context = Context()
    with assert_raises():
        _ = context["absent"]


def test_context_pop() raises:
    """Popping returns the value and removes the key."""
    var context = Context()
    context["key"] = "value"
    assert_equal(context.pop("key"), "value")
    assert_false("key" in context)


def test_context_pop_missing_raises() raises:
    """Popping an absent key raises."""
    var context = Context()
    with assert_raises():
        _ = context.pop("absent")


def test_context_update_from_context() raises:
    """Updating merges keys and overwrites collisions."""
    var context = Context()
    context["keep"] = "original"
    context["shared"] = "original"

    var other = Context()
    other["shared"] = "replaced"
    other["added"] = "new"

    context.update(other)
    assert_equal(context["keep"], "original")
    assert_equal(context["shared"], "replaced")
    assert_equal(context["added"], "new")


def test_context_update_from_dict() raises:
    """The dict overload behaves like the context overload."""
    var context = Context()
    context["existing"] = "value"

    var other = Dict[String, String]()
    other["added"] = "new"

    context.update(other)
    assert_equal(context["existing"], "value")
    assert_equal(context["added"], "new")


# --- argument collection ----------------------------------------------------


def test_collect_args_pairs() raises:
    """Positional args are consumed as alternating keys and values."""
    var kvs = _collect("key", "value")
    assert_equal(len(kvs), 1)
    assert_equal(kvs["key"], "value")


def test_collect_args_multiple_pairs() raises:
    """Several pairs are all collected."""
    var kvs = _collect("a", "1", "b", "2")
    assert_equal(len(kvs), 2)
    assert_equal(kvs["a"], "1")
    assert_equal(kvs["b"], "2")


def test_collect_args_dangling_key() raises:
    """A trailing key with no value is stored with an empty value."""
    var kvs = _collect("no_value")
    assert_equal(len(kvs), 1)
    assert_equal(kvs["no_value"], "")


def test_collect_args_odd_count() raises:
    """An odd argument count pairs what it can and empties the remainder."""
    var kvs = _collect("a", "1", "dangling")
    assert_equal(len(kvs), 2)
    assert_equal(kvs["a"], "1")
    assert_equal(kvs["dangling"], "")


def test_collect_args_non_string_values() raises:
    """Any Writable is stringified on the way in."""
    var kvs = _collect("number", 4, "flag", True)
    assert_equal(kvs["number"], "4")
    assert_equal(kvs["flag"], "True")


def test_collect_args_empty() raises:
    """No arguments produces no pairs."""
    var kvs = _collect()
    assert_equal(len(kvs), 0)


# --- formatters -------------------------------------------------------------


def test_logfmt_formatter_single_pair() raises:
    """A lone pair renders without a trailing separator."""
    var context = Context()
    context["key"] = "value"
    assert_equal(logfmt_formatter(context), "key=value")


def test_logfmt_formatter_empty() raises:
    """An empty context renders as the empty string."""
    assert_equal(logfmt_formatter(Context()), "")


def test_logfmt_formatter_multiple_pairs() raises:
    """Pairs are space delimited, with no trailing space."""
    var context = Context()
    context["a"] = "1"
    context["b"] = "2"

    var result = logfmt_formatter(context)
    assert_true(_contains(result, "a=1"))
    assert_true(_contains(result, "b=2"))
    assert_false(result.endswith(" "))
    assert_equal(result.count(" "), 1)


def test_json_formatter_shape() raises:
    """JSON output is an object containing the pair."""
    var context = Context()
    context["key"] = "value"

    var result = json_formatter(context)
    assert_true(result.startswith("{"))
    assert_true(result.endswith("}"))
    assert_true(_contains(result, '"key"'))
    assert_true(_contains(result, '"value"'))


def test_json_formatter_empty() raises:
    """An empty context still renders a JSON object."""
    assert_equal(json_formatter(Context()), "{}")


def test_default_formatter_orders_standard_keys() raises:
    """Timestamp, level and message lead, in that order."""
    var context = Context()
    context["extra"] = "field"
    context["message"] = "hello"
    context["level"] = "INFO"
    context["timestamp"] = "2026-01-01T00:00:00"

    var result = default_formatter(context)
    assert_true(result.startswith("2026-01-01T00:00:00 INFO hello "))
    assert_true(_contains(result, "extra=field"))


def test_default_formatter_keeps_remaining_keys() raises:
    """Non-standard keys survive as logfmt pairs."""
    var context = Context()
    context["message"] = "hello"
    context["level"] = "INFO"
    context["timestamp"] = "2026-01-01T00:00:00"
    context["request_id"] = "abc123"

    assert_true(_contains(default_formatter(context), "request_id=abc123"))


def test_default_formatter_tolerates_missing_standard_keys() raises:
    """A context with no standard keys still formats."""
    var context = Context()
    context["only"] = "field"
    assert_true(_contains(default_formatter(context), "only=field"))


# --- processors -------------------------------------------------------------


def test_add_log_level_sets_level() raises:
    """The processor writes the level name into the context."""
    var result = add_log_level(Context(), LogLevel.WARN)
    assert_equal(result["level"], "WARN")


def test_add_log_level_does_not_mutate_input() raises:
    """Processors return a new context rather than editing in place."""
    var context = Context()
    _ = add_log_level(context, LogLevel.WARN)
    assert_false("level" in context)


# --- bound logger -----------------------------------------------------------


def test_bind_adds_to_context() raises:
    """Bound keys land in the logger's context."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var bound = Context()
    bound["service"] = "api"
    logger.bind(bound)

    assert_equal(logger.context["service"], "api")


def test_bind_accumulates() raises:
    """Successive binds merge rather than replace."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)

    var first = Context()
    first["a"] = "1"
    logger.bind(first)

    var second = Context()
    second["b"] = "2"
    logger.bind(second)

    assert_equal(logger.context["a"], "1")
    assert_equal(logger.context["b"], "2")


def test_bind_overwrites_existing_key() raises:
    """Re-binding a key replaces its value."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)

    var first = Context()
    first["env"] = "dev"
    logger.bind(first)

    var second = Context()
    second["env"] = "prod"
    logger.bind(second)

    assert_equal(logger.context["env"], "prod")


def test_initial_context_is_copied() raises:
    """The logger copies the context it is constructed with."""
    var seed = Context()
    seed["seeded"] = "yes"

    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), context=seed, apply_styles=False)
    seed["late"] = "no"

    assert_equal(logger.context["seeded"], "yes")
    assert_false("late" in logger.context)


def test_logger_level_follows_internal_logger() raises:
    """The bound logger reports the level of the logger it wraps.

    The level is a compile-time alias on the type, so this reads it off the
    type rather than an instance.
    """
    assert_true(BoundLogger[PrintLogger[LogLevel.WARN]].level == LogLevel.WARN)
    assert_true(BoundLogger[PrintLogger[LogLevel.DEBUG]].level == LogLevel.DEBUG)


def main() raises:
    """Run the test suite."""
    TestSuite.discover_tests[__functions_in_module()]().run()
