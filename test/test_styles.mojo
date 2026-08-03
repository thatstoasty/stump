"""Tests for the styling pass.

Run with `pixi run tests`, or directly:
`mojo -D ASSERT=all -I . test/test_styles.mojo`.

Every style here is built on `mist.Style(mist.Profile.TRUE_COLOR)`. The default
profile is auto-detected, and under a piped test runner that detection lands on
`Profile.ASCII`, where `render` is the identity function. Styling bugs are
invisible against an identity `render`, so the profile is forced and the
assertions pin the exact escape sequences.

`_apply_style_to_kvs` is called directly rather than through a logging method,
so the assertions do not depend on a wall clock timestamp.
"""

from std.testing import TestSuite, assert_equal, assert_false, assert_true

import mist

from stump import (
    BoundLogger,
    Context,
    LogLevel,
    PrintLogger,
    Sections,
    Styles,
    DEFAULT_FORMATTER,
    LOGFMT_FORMATTER,
)
from stump.style import SEPARATOR

# --- expected escape sequences ----------------------------------------------

comptime RESET = "\x1b[0m"
"""The sequence mist writes after styled text."""
comptime FAINT = "\x1b[2m"
"""The opening sequence of `mist.Style.faint`."""
comptime PURPLE_UNDERLINE = "\x1b[38;2;201;160;220;4m"
"""The opening sequence of `foreground(0xC9A0DC).underline()`."""
comptime ORANGE_BOLD = "\x1b[38;2;212;130;68;1m"
"""The opening sequence of `foreground(0xD48244).bold()`."""
comptime PINK_BACKGROUND = "\x1b[48;2;212;49;125m"
"""The opening sequence of `background(0xD4317D)`."""
comptime PURPLE_BACKGROUND = "\x1b[48;2;189;55;219m"
"""The opening sequence of `background(0xBD37DB)`."""


def _style() -> mist.Style:
    """Build a style with the colour profile forced on.

    Returns:
        An empty style that renders escape sequences regardless of whether the
        test runner is attached to a terminal.
    """
    return mist.Style(mist.Profile.TRUE_COLOR)


def _apply(var styles: Styles, context: Context, level: LogLevel) -> Context:
    """Run the styling pass over a context.

    Args:
        styles: The styles to apply.
        context: The context to style.
        level: The level of the record being styled.

    Returns:
        The styled context.
    """
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), styles=styles^)
    return logger._apply_style_to_kvs(context, level.value)


def _one_pair(var styles: Styles, key: String, value: String, level: LogLevel) -> String:
    """Style a single-pair context and render it as logfmt.

    Args:
        styles: The styles to apply.
        key: The key of the single pair.
        value: The value of the single pair.
        level: The level of the record being styled.

    Returns:
        The styled pair, formatted as `key=value`.
    """
    var context = Context()
    context[key] = value
    return LOGFMT_FORMATTER(_apply(styles^, context, level))


def _contains(haystack: String, needle: String) -> Bool:
    """Check for a substring.

    Args:
        haystack: The string to search in.
        needle: The string to search for.

    Returns:
        `True` if `needle` occurs in `haystack`.
    """
    return haystack.find(needle) != -1


def _plain_styles() -> Styles:
    """Build styles that render nothing, for the unstyled baseline.

    `Styles` substitutes a faint default for `key` and `separator` when they are
    left unset, so an explicitly empty ASCII style is the only way to ask for
    output with no escape sequences at all.

    Returns:
        Styles whose every member is a no-op.
    """
    var plain = mist.Style(mist.Profile.ASCII)
    var levels: List[mist.Style] = [plain, plain, plain, plain, plain]
    return Styles(
        timestamp=plain,
        message=plain,
        key=plain,
        value=plain,
        separator=plain,
        levels=levels^,
    )


# --- per-key value styles ---------------------------------------------------


def test_value_style_applies_alongside_a_key_style() raises:
    """A `values` entry is found even when the same key has a `keys` entry.

    The lookup used to run against the already rendered key, so a key carrying
    escape sequences never matched its own entry in `values` and the value came
    out unstyled. This is the configuration in `examples/custom.mojo`.
    """
    var keys = Sections()
    keys["name"] = _style().foreground(0xC9A0DC).underline()

    var values = Sections()
    values["name"] = _style().foreground(0xD48244).bold()

    var result = _one_pair(Styles(keys=keys^, values=values^), "name", "Mikhail", LogLevel.INFO)
    assert_true(_contains(result, ORANGE_BOLD + "Mikhail" + RESET))


def test_value_style_applies_under_the_default_key_style() raises:
    """A `values` entry is found for a key with no `keys` entry.

    `Styles.key` defaults to faint and cannot be set to `None`, so the fallback
    branch renders the key too. The value lookup has to survive that as well.
    """
    var values = Sections()
    values["name"] = _style().foreground(0xD48244).bold()

    var result = _one_pair(Styles(key=_style().faint(), values=values^), "name", "Mikhail", LogLevel.INFO)
    assert_true(_contains(result, ORANGE_BOLD + "Mikhail" + RESET))
    assert_true(_contains(result, FAINT + "name" + RESET))


def test_key_style_applies_to_the_raw_key() raises:
    """A `keys` entry styles the key text itself, not a pre-rendered key."""
    var keys = Sections()
    keys["name"] = _style().foreground(0xC9A0DC).underline()

    var result = _one_pair(Styles(keys=keys^), "name", "Mikhail", LogLevel.INFO)
    assert_true(_contains(result, PURPLE_UNDERLINE + "name" + RESET))


def test_default_value_style_applies_when_no_entry_matches() raises:
    """A key with no `values` entry falls back to the blanket `value` style."""
    var result = _one_pair(Styles(value=_style().faint()), "other", "data", LogLevel.INFO)
    assert_true(_contains(result, FAINT + "data" + RESET))


def test_value_style_is_not_applied_to_a_different_key() raises:
    """A `values` entry stays scoped to its own key."""
    var values = Sections()
    values["name"] = _style().foreground(0xD48244).bold()

    var result = _one_pair(Styles(values=values^), "other", "data", LogLevel.INFO)
    assert_false(_contains(result, ORANGE_BOLD))


# --- level styles -----------------------------------------------------------


def test_short_levels_list_does_not_crash() raises:
    """A `levels` list shorter than the level being logged is not indexed.

    `Styles` accepts any list length, so a caller supplying one style used to
    index out of bounds on DEBUG: an assertion failure under `ASSERT=all` and an
    out-of-bounds read in a release build.
    """
    var context = Context()
    context["level"] = "DEBUG"

    var styles = Styles(levels=[_style().background(0xD4317D)])
    assert_equal(LOGFMT_FORMATTER(_apply(styles^, context, LogLevel.DEBUG)), "level=DEBUG")


def test_short_levels_list_still_styles_an_in_range_level() raises:
    """Falling back out of range does not disable the entries that do exist."""
    var context = Context()
    context["level"] = "FATAL"

    var styles = Styles(levels=[_style().background(0xD4317D)])
    var result = LOGFMT_FORMATTER(_apply(styles^, context, LogLevel.FATAL))
    assert_equal(result, "level=" + PINK_BACKGROUND + "FATAL" + RESET)


def test_levels_are_indexed_by_level_value() raises:
    """Each record picks the `levels` entry at its own level value.

    The bounds check must not shift the mapping: DEBUG is index 4 and FATAL is
    index 0.
    """
    var levels: List[mist.Style] = [
        _style().background(0xD4317D),
        _style().background(0xD48244),
        _style().background(0x13ED84),
        _style().background(0xDECF2F),
        _style().background(0xBD37DB),
    ]

    var context = Context()
    context["level"] = "DEBUG"
    assert_equal(
        LOGFMT_FORMATTER(_apply(Styles(levels=levels.copy()), context, LogLevel.DEBUG)),
        "level=" + PURPLE_BACKGROUND + "DEBUG" + RESET,
    )

    context["level"] = "FATAL"
    assert_equal(
        LOGFMT_FORMATTER(_apply(Styles(levels=levels^), context, LogLevel.FATAL)),
        "level=" + PINK_BACKGROUND + "FATAL" + RESET,
    )


def test_empty_levels_list_uses_the_defaults() raises:
    """An unset `levels` list is replaced by one built-in style per log level."""
    assert_equal(len(Styles().levels), 5)


# --- separator --------------------------------------------------------------


def test_separator_sequences_split_around_the_equals() raises:
    """The separator style is exposed as the sequences that wrap the `=`.

    The formatter writes the `=` itself, so the style is carried as an opening
    sequence for the key and a closing sequence for the value.
    """
    var sequences = Styles(separator=_style().faint()).separator_sequences()
    assert_equal(sequences[0], FAINT)
    assert_equal(sequences[1], RESET)


def test_separator_sequences_are_empty_for_a_no_op_style() raises:
    """A style that renders nothing contributes no sequences."""
    var sequences = Styles(separator=mist.Style(mist.Profile.ASCII)).separator_sequences()
    assert_equal(sequences[0], "")
    assert_equal(sequences[1], "")


def test_separator_style_wraps_the_equals() raises:
    """The separator style reaches the `=` between a key and its value.

    `Styles.separator` was declared, defaulted, documented and passed by
    `examples/custom.mojo`, but nothing read it.
    """
    var styles = Styles(key=mist.Style(mist.Profile.ASCII), separator=_style().faint())
    assert_equal(_one_pair(styles^, "name", "Mikhail", LogLevel.INFO), "name" + FAINT + SEPARATOR + RESET + "Mikhail")


def test_separator_style_does_not_reach_the_reserved_keys() raises:
    """`timestamp`, `level` and `message` keep their bare key names.

    `DEFAULT_FORMATTER` pops those three by name to order them ahead of the rest
    of the record, so appending a sequence to them would break the ordering.
    """
    var context = Context()
    context["message"] = "hello"
    context["level"] = "INFO"
    context["timestamp"] = "2026-01-01T00:00:00"
    context["name"] = "Mikhail"

    var styles = Styles(key=mist.Style(mist.Profile.ASCII), separator=_style().faint())
    var result = DEFAULT_FORMATTER(_apply(styles^, context, LogLevel.INFO))
    assert_true(result.startswith("2026-01-01T00:00:00 "))
    assert_true(_contains(result, " hello "))
    assert_true(_contains(result, "name" + FAINT + SEPARATOR + RESET + "Mikhail"))


# --- unstyled baseline ------------------------------------------------------


def test_no_op_styles_leave_the_record_unchanged() raises:
    """Styles that render nothing produce byte-identical logfmt output."""
    var context = Context()
    context["name"] = "Mikhail"
    context["count"] = "3"

    assert_equal(LOGFMT_FORMATTER(_apply(_plain_styles(), context, LogLevel.INFO)), "name=Mikhail count=3")


def test_no_op_styles_leave_the_reserved_keys_unchanged() raises:
    """The reserved keys survive a no-op styling pass and stay ordered."""
    var context = Context()
    context["message"] = "hello"
    context["level"] = "INFO"
    context["timestamp"] = "2026-01-01T00:00:00"

    var result = DEFAULT_FORMATTER(_apply(_plain_styles(), context, LogLevel.INFO))
    assert_equal(result, "2026-01-01T00:00:00 INFO hello ")


def test_styling_does_not_drop_or_merge_pairs() raises:
    """Every pair in the input context appears once in the output."""
    var context = Context()
    context["a"] = "1"
    context["b"] = "2"
    context["c"] = "3"

    var styled = _apply(Styles(), context, LogLevel.INFO)
    assert_equal(len(styled.value), 3)


def main() raises:
    """Run the test suite."""
    TestSuite.discover_tests[__functions_in_module()]().run()
