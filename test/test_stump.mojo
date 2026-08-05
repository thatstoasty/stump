"""Tests for stump.

Run with `pixi run tests`, or directly:
`mojo -D ASSERT=all -I . test/test_stump.mojo`.

Tests target the deterministic surface: context manipulation, argument
collection, formatter output, and log level semantics. Timestamps come from
the wall clock, so tests that touch a formatted record build the context by
hand rather than going through a processor.
"""

from std.collections.dict import OwnedKwargsDict
from std.testing import TestSuite, assert_equal, assert_false, assert_raises, assert_true

from stump import (
    Arg,
    BoundLogger,
    Context,
    LogLevel,
    PrintLogger,
    add_log_level,
    DEFAULT_FORMATTER,
    JSON_FORMATTER,
    LOGFMT_FORMATTER,
)
from stump.bound_logger import collect_kvs


def _contains(haystack: String, needle: String) -> Bool:
    """Check for a substring.

    Args:
        haystack: The string to search in.
        needle: The string to search for.

    Returns:
        `True` if `needle` occurs in `haystack`.
    """
    return haystack.find(needle) != -1


def _collect[*Ts: Writable](*args: *Ts) -> OwnedKwargsDict[Arg]:
    """Collect positional args into a dict, as the logging methods do.

    Parameters:
        Ts: The types of the positional arguments.

    Args:
        args: The positional arguments to collect.

    Returns:
        The collected key-value pairs.
    """
    var kvs = OwnedKwargsDict[Arg]()
    collect_kvs(kvs, *args)
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

    var other = OwnedKwargsDict[Arg]()
    other["added"] = "new"

    context.update(other)
    assert_equal(context["existing"], "value")
    assert_equal(context["added"], "new")


# --- argument collection ----------------------------------------------------


def test_collect_args_pairs() raises:
    """Positional args are consumed as alternating keys and values."""
    var kvs = _collect("key", "value")
    assert_equal(len(kvs), 1)
    assert_equal(String(kvs["key"]), "value")


def test_collect_args_multiple_pairs() raises:
    """Several pairs are all collected."""
    var kvs = _collect("a", "1", "b", "2")
    assert_equal(len(kvs), 2)
    assert_equal(String(kvs["a"]), "1")
    assert_equal(String(kvs["b"]), "2")


def test_collect_args_dangling_key() raises:
    """A trailing key with no value is stored with an empty value."""
    var kvs = _collect("no_value")
    assert_equal(len(kvs), 1)
    assert_equal(String(kvs["no_value"]), "")


def test_collect_args_odd_count() raises:
    """An odd argument count pairs what it can and empties the remainder."""
    var kvs = _collect("a", "1", "dangling")
    assert_equal(len(kvs), 2)
    assert_equal(String(kvs["a"]), "1")
    assert_equal(String(kvs["dangling"]), "")


def test_collect_args_non_string_values() raises:
    """Any Writable is stringified on the way in."""
    var kvs = _collect("number", 4, "flag", True)
    assert_equal(String(kvs["number"]), "4")
    assert_equal(String(kvs["flag"]), "True")


def test_collect_args_empty() raises:
    """No arguments produces no pairs."""
    var kvs = _collect()
    assert_equal(len(kvs), 0)


# --- formatters -------------------------------------------------------------


def test_logfmt_formatter_single_pair() raises:
    """A lone pair renders without a trailing separator."""
    var context = Context()
    context["key"] = "value"
    assert_equal(LOGFMT_FORMATTER(context), "key=value")


def test_logfmt_formatter_empty() raises:
    """An empty context renders as the empty string."""
    assert_equal(LOGFMT_FORMATTER(Context()), "")


def test_logfmt_formatter_multiple_pairs() raises:
    """Pairs are space delimited, with no trailing space."""
    var context = Context()
    context["a"] = "1"
    context["b"] = "2"

    var result = LOGFMT_FORMATTER(context)
    assert_true(_contains(result, "a=1"))
    assert_true(_contains(result, "b=2"))
    assert_false(result.endswith(" "))
    assert_equal(result.count(" "), 1)


def test_json_formatter_shape() raises:
    """JSON output is an object containing the pair."""
    var context = Context()
    context["key"] = "value"

    var result = JSON_FORMATTER(context)
    assert_true(result.startswith("{"))
    assert_true(result.endswith("}"))
    assert_true(_contains(result, '"key"'))
    assert_true(_contains(result, '"value"'))


def test_json_formatter_empty() raises:
    """An empty context still renders a JSON object."""
    assert_equal(JSON_FORMATTER(Context()), "{}")


def test_default_formatter_orders_standard_keys() raises:
    """Timestamp, level and message lead, in that order."""
    var context = Context()
    context["extra"] = "field"
    context["message"] = "hello"
    context["level"] = "INFO"
    context["timestamp"] = "2026-01-01T00:00:00"

    var result = DEFAULT_FORMATTER(context)
    assert_true(result.startswith("2026-01-01T00:00:00 INFO hello "))
    assert_true(_contains(result, "extra=field"))


def test_default_formatter_keeps_remaining_keys() raises:
    """Non-standard keys survive as logfmt pairs."""
    var context = Context()
    context["message"] = "hello"
    context["level"] = "INFO"
    context["timestamp"] = "2026-01-01T00:00:00"
    context["request_id"] = "abc123"

    assert_true(_contains(DEFAULT_FORMATTER(context), "request_id=abc123"))


def test_default_formatter_tolerates_missing_standard_keys() raises:
    """A context with no standard keys still formats."""
    var context = Context()
    context["only"] = "field"
    assert_true(_contains(DEFAULT_FORMATTER(context), "only=field"))


# --- processors -------------------------------------------------------------


def test_add_log_level_sets_level() raises:
    """The processor writes the level name into the context."""
    var context = Context()
    add_log_level(context, LogLevel.WARN)
    assert_equal(context["level"], "WARN")


def test_add_log_level_does_not_mutate_input() raises:
    """Processors return a new context rather than editing in place."""
    var context = Context()
    _ = add_log_level(context, LogLevel.WARN)
    assert_false("level" in context)


# --- bound logger -----------------------------------------------------------


def test_bind_context_returns_child() raises:
    """Binding a context returns a child carrying the bound keys."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var bound = Context()
    bound["service"] = "api"

    var child = logger.bind(bound)
    assert_equal(child.context["service"], "api")


def test_bind_leaves_parent_unchanged() raises:
    """The parent is untouched by a child's bind.

    This is the point of the child-logger change: a request-scoped logger derived
    from a shared application logger must not leak its keys back into it.
    """
    var parent = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var child = parent.bind(request_id="abc123")

    assert_equal(child.context["request_id"], "abc123")
    assert_false("request_id" in parent.context)


def test_bind_kwargs_returns_child() raises:
    """Keyword arguments bind without building a context by hand."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var child = logger.bind(service="api", env="prod")

    assert_equal(child.context["service"], "api")
    assert_equal(child.context["env"], "prod")


def test_bind_positional_args() raises:
    """Positional arguments bind as alternating keys and values."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var child = logger.bind("region", "us-east-1")

    assert_equal(child.context["region"], "us-east-1")


def test_bind_positional_beats_kwarg_on_collision() raises:
    """Positional args win over a keyword of the same name.

    This matches how the log methods collect arguments, so a key means the same
    thing whether it is bound or passed at the call site.
    """
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var child = logger.bind("env", "from_positional", env="from_kwarg")

    assert_equal(child.context["env"], "from_positional")


def test_bind_accumulates_across_generations() raises:
    """A grandchild carries keys bound at every level above it."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var child = logger.bind(a="1")
    var grandchild = child.bind(b="2")

    assert_equal(grandchild.context["a"], "1")
    assert_equal(grandchild.context["b"], "2")
    assert_false("b" in child.context)


def test_bind_overwrites_existing_key() raises:
    """Re-binding a key replaces its value in the child."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var dev = logger.bind(env="dev")
    var prod = dev.bind(env="prod")

    assert_equal(prod.context["env"], "prod")
    assert_equal(dev.context["env"], "dev")


def test_two_children_are_independent() raises:
    """Siblings derived from one parent do not see each other's keys."""
    var parent = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var left = parent.bind(side="left")
    var right = parent.bind(side="right")

    assert_equal(left.context["side"], "left")
    assert_equal(right.context["side"], "right")


def test_unbind_removes_key() raises:
    """Unbinding drops a key from the child but keeps the rest."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var child = logger.bind(keep="yes", drop="no")
    var unbound = child.unbind("drop")

    assert_equal(unbound.context["keep"], "yes")
    assert_false("drop" in unbound.context)
    assert_true("drop" in child.context)


def test_unbind_ignores_missing_key() raises:
    """Unbinding a key that was never bound is not an error."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var child = logger.bind(keep="yes").unbind("never_bound")

    assert_equal(child.context["keep"], "yes")


def test_unbind_multiple_keys() raises:
    """Several keys can be dropped in one call."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var child = logger.bind(a="1", b="2", c="3").unbind("a", "c")

    assert_false("a" in child.context)
    assert_equal(child.context["b"], "2")
    assert_false("c" in child.context)


def test_new_clears_inherited_context() raises:
    """`new` starts a fresh context rather than inheriting the parent's."""
    var parent = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    var child = parent.bind(service="api", env="prod")
    var fresh = child.new(request_id="xyz")

    assert_equal(fresh.context["request_id"], "xyz")
    assert_false("service" in fresh.context)
    assert_false("env" in fresh.context)


def test_new_leaves_parent_unchanged() raises:
    """`new` is a child operation, so the parent keeps its context."""
    var parent = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False).bind(service="api")
    var fresh = parent.new()

    assert_equal(parent.context["service"], "api")
    assert_equal(len(fresh.context.value), 0)


def test_child_inherits_settings() raises:
    """A child keeps the parent's formatter, processors and styling flags."""
    var parent = BoundLogger(
        PrintLogger[LogLevel.DEBUG](),
        formatter=JSON_FORMATTER,
        processors=[add_log_level],
        apply_styles=False,
    )
    var child = parent.bind(service="api")

    assert_false(child.apply_styles)
    assert_equal(len(child.processors), 1)


def test_bound_logger_is_copyable() raises:
    """A bound logger can be copied, which is what makes children possible."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False).bind(service="api")
    var copied = logger.copy()

    assert_equal(copied.context["service"], "api")


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


# --- logfmt escaping --------------------------------------------------------


def test_logfmt_plain_value_is_not_quoted() raises:
    """Values with no delimiters stay bare, keeping the common case clean."""
    var context = Context()
    context["key"] = "value"
    assert_equal(LOGFMT_FORMATTER(context), "key=value")


def test_logfmt_quotes_value_with_space() raises:
    """A space would otherwise split one pair into several tokens."""
    var context = Context()
    context["message"] = "hello world"
    assert_equal(LOGFMT_FORMATTER(context), 'message="hello world"')


def test_logfmt_quotes_value_with_equals() raises:
    """An equals sign would otherwise look like a second delimiter."""
    var context = Context()
    context["query"] = "a=b"
    assert_equal(LOGFMT_FORMATTER(context), 'query="a=b"')


def test_logfmt_quotes_empty_value() raises:
    """An empty value needs quotes to survive a round trip."""
    var context = Context()
    context["empty"] = ""
    assert_equal(LOGFMT_FORMATTER(context), 'empty=""')


def test_logfmt_escapes_double_quote() raises:
    """Embedded quotes are backslash escaped inside the quoted value."""
    var context = Context()
    context["said"] = 'he said "hi"'
    assert_equal(LOGFMT_FORMATTER(context), 'said="he said \\"hi\\""')


def test_logfmt_escapes_backslash() raises:
    """Backslashes are doubled so escaping is unambiguous."""
    var context = Context()
    context["path"] = "C:\\logs"
    assert_equal(LOGFMT_FORMATTER(context), 'path="C:\\\\logs"')


def test_logfmt_escapes_newline() raises:
    """A newline would otherwise terminate the record early."""
    var context = Context()
    context["trace"] = "line1\nline2"
    assert_equal(LOGFMT_FORMATTER(context), 'trace="line1\\nline2"')


def test_logfmt_escapes_tab() raises:
    """Tabs are escaped rather than emitted raw."""
    var context = Context()
    context["cols"] = "a\tb"
    assert_equal(LOGFMT_FORMATTER(context), 'cols="a\\tb"')


def test_logfmt_escaping_survives_multiple_pairs() raises:
    """Escaping applies per value, and the pair separator still works."""
    var context = Context()
    context["message"] = "hello world"
    context["level"] = "INFO"

    var result = LOGFMT_FORMATTER(context)
    assert_true(_contains(result, 'message="hello world"'))
    assert_true(_contains(result, "level=INFO"))


def test_logfmt_message_with_spaces_stays_one_pair() raises:
    """A quoted message keeps its internal spaces without splitting the pair.

    This is the case `examples/logfmt.mojo` hits: before quoting, the spaces
    in a message read as additional bare tokens.
    """
    var context = Context()
    context["message"] = "Information is good."
    assert_equal(LOGFMT_FORMATTER(context), 'message="Information is good."')


def test_logfmt_key_is_not_quoted() raises:
    """Keys are written as-is, matching logfmt itself.

    Pinning current behaviour: quoting keys would produce output that strict
    decoders reject, so a caller must keep delimiters out of key names.
    """
    var context = Context()
    context["plain_key"] = "hello world"
    assert_equal(LOGFMT_FORMATTER(context), 'plain_key="hello world"')


# --- context iteration ------------------------------------------------------


def test_context_len() raises:
    """A context reports how many pairs it holds."""
    var context = Context()
    assert_equal(len(context), 0)

    context["a"] = "1"
    context["b"] = "2"
    assert_equal(len(context), 2)


def test_context_len_after_pop() raises:
    """Removing a key is reflected in the count."""
    var context = Context()
    context["a"] = "1"
    _ = context.pop("a")
    assert_equal(len(context), 0)


def test_context_items_walks_every_pair() raises:
    """A custom formatter can walk a context without reaching into `.value`."""
    var context = Context()
    context["a"] = "1"
    context["b"] = "2"

    var seen = String()
    for pair in context.items():
        seen.write(pair.key, "=", pair.value, ";")

    assert_equal(seen, "a=1;b=2;")


def test_context_items_is_empty_for_an_empty_context() raises:
    """Iterating an empty context yields nothing rather than failing."""
    var count = 0
    for _ in Context().items():
        count += 1

    assert_equal(count, 0)


def test_context_keys() raises:
    """Keys come back in insertion order."""
    var context = Context()
    context["first"] = "1"
    context["second"] = "2"

    var keys = context.keys()
    assert_equal(len(keys), 2)
    assert_equal(keys[0], "first")
    assert_equal(keys[1], "second")


# --- errors as arguments ----------------------------------------------------


def test_error_is_accepted_as_a_keyword_argument() raises:
    """An `Error` logs as its message, which is the point of `error()`.

    `Arg` covered fifteen numeric and string types but not `Error`, so
    `logger.error("failed", err=e)` did not compile.
    """
    var kvs = Dict[String, String]()
    kvs["err"] = String(Arg(Error("db unreachable")))
    assert_equal(kvs["err"], "db unreachable")


def test_error_argument_keeps_an_empty_message() raises:
    """An error with no message stringifies to empty rather than failing."""
    assert_equal(String(Arg(Error(""))), "")


# --- exit on fatal ----------------------------------------------------------


def test_exit_on_fatal_is_off_by_default() raises:
    """Adding the option does not change what an existing `fatal` call does."""
    assert_false(BoundLogger(PrintLogger[LogLevel.DEBUG]()).exit_on_fatal)


def test_exit_on_fatal_is_stored() raises:
    """The opt-in is recorded on the logger."""
    assert_true(BoundLogger(PrintLogger[LogLevel.DEBUG](), exit_on_fatal=True).exit_on_fatal)


def test_exit_on_fatal_survives_a_bind() raises:
    """A child terminates on fatal if its parent would have.

    The exit itself is not exercised anywhere in the suite — it would take the
    test runner down with it, and an example that exits 1 would fail the
    `examples` task. Verified by hand: the record is written, then the process
    exits 1.
    """
    var parent = BoundLogger(PrintLogger[LogLevel.DEBUG](), exit_on_fatal=True)
    assert_true(parent.bind(request_id="abc").exit_on_fatal)


def main() raises:
    """Run the test suite."""
    TestSuite.discover_tests[__functions_in_module()]().run()
