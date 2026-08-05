"""Tests for the `Formatter` wrapper and the styling it turns on or off.

Run with `pixi run tests`, or directly:
`mojo -D ASSERT=all -I . test/test_formatter.mojo`.

The point of `Formatter.styled` is that a structured formatter cannot be styled
by accident, so most of these assert on what `BoundLogger.apply_styles` resolves
to rather than on rendered output.
"""

from std.collections.dict import OwnedKwargsDict
from std.testing import TestSuite, assert_equal, assert_false, assert_true

from stump import (
    BoundLogger,
    Context,
    Formatter,
    LogLevel,
    PrintLogger,
    Styles,
    DEFAULT_FORMATTER,
    JSON_FORMATTER,
    LOGFMT_FORMATTER,
    Arg,
    to_logfmt,
)
import mist


def _contains(haystack: String, needle: String) -> Bool:
    """Check for a substring.

    Args:
        haystack: The string to search in.
        needle: The string to search for.

    Returns:
        `True` if `needle` occurs in `haystack`.
    """
    return haystack.find(needle) != -1


def _loud_styles() -> Styles:
    """Build styles with the colour profile forced on.

    The auto-detected profile makes `render` an identity function under a piped
    test runner, which would make every assertion here pass regardless.

    Returns:
        Styles that emit real escape sequences.
    """
    var base = mist.Style(mist.Profile.TRUE_COLOR)
    var levels: InlineArray[mist.Style, 5] = [
        base.foreground(0xD4317D),
        base.foreground(0xD48244),
        base.foreground(0xDECF2F),
        base.foreground(0x13ED84),
        base.foreground(0xBD37DB),
    ]
    return Styles(levels=levels^)


def _render(context: Context) -> String:
    """Render a context as logfmt, for building a custom `Formatter`.

    Args:
        context: The context to render.

    Returns:
        The context as logfmt pairs.
    """
    return to_logfmt(context)


# --- what each shipped formatter asks for -----------------------------------


def test_default_formatter_is_styled() raises:
    """The human-facing formatter wants styling."""
    assert_true(DEFAULT_FORMATTER.styled)


def test_json_formatter_is_not_styled() raises:
    """Escape sequences inside JSON strings corrupt the record."""
    assert_false(JSON_FORMATTER[pretty=False].styled)


def test_logfmt_formatter_is_not_styled() raises:
    """Escape sequences inside logfmt values corrupt the record."""
    assert_false(LOGFMT_FORMATTER.styled)


# --- how a bound logger resolves apply_styles -------------------------------


def test_apply_styles_defaults_to_the_formatter() raises:
    """A structured formatter turns styling off on its own.

    This is the regression: `apply_styles` used to default to `True` regardless,
    so `formatter=JSON_FORMATTER` emitted escape sequences inside the JSON unless
    the caller also remembered `apply_styles=False`.
    """
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=JSON_FORMATTER[pretty=False])
    assert_false(logger.apply_styles)


def test_apply_styles_defaults_on_for_the_default_formatter() raises:
    """Human-facing output still styles without being asked."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG]())
    assert_true(logger.apply_styles)


def test_apply_styles_can_be_forced_on() raises:
    """An explicit `True` overrides the formatter's preference."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=JSON_FORMATTER[pretty=False], apply_styles=True)
    assert_true(logger.apply_styles)


def test_apply_styles_can_be_forced_off() raises:
    """An explicit `False` overrides the formatter's preference."""
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=DEFAULT_FORMATTER, apply_styles=False)
    assert_false(logger.apply_styles)


def test_json_output_has_no_escape_sequences() raises:
    """End to end: a JSON record stays free of escape sequences.

    The styles here have the colour profile forced on, so anything reaching the
    styling pass would show up in the output.
    """
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=JSON_FORMATTER[pretty=False], styles=_loud_styles())
    var kwargs = OwnedKwargsDict[Arg]()
    var record = logger._transform_message[LogLevel.INFO]("hello", kwargs)

    assert_false(_contains(record, "\x1b["))
    assert_true(_contains(record, '"level":"INFO"'))


def test_forcing_styles_on_still_corrupts_json() raises:
    """Pinning the escape hatch: an explicit override is honoured, warts and all.

    Nothing stops a caller from asking for this. The point of the default is that
    they have to ask.
    """
    var logger = BoundLogger(
        PrintLogger[LogLevel.DEBUG](), formatter=JSON_FORMATTER[pretty=False], styles=_loud_styles(), apply_styles=True
    )
    var kwargs = OwnedKwargsDict[Arg]()
    var record = logger._transform_message[LogLevel.INFO]("hello", kwargs)
    assert_true(_contains(record, "\\u001b["))


# --- custom formatters ------------------------------------------------------


def test_custom_formatter_declares_its_own_preference() raises:
    """A hand-built `Formatter` carries whichever flag it was given."""
    comptime unstyled = Formatter(_render, styled=False)
    comptime styled = Formatter(_render, styled=True)

    assert_false(BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=unstyled).apply_styles)
    assert_true(BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=styled).apply_styles)


def test_formatter_is_callable() raises:
    """A `Formatter` renders a context directly, as the raw function used to."""
    var context = Context()
    context["key"] = "value"

    assert_equal(LOGFMT_FORMATTER(context), "key=value")


def test_apply_styles_survives_a_bind() raises:
    """A child inherits the resolved styling decision, not the default."""
    var parent = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=JSON_FORMATTER[pretty=False])
    assert_false(parent.bind(request_id="abc").apply_styles)


def main() raises:
    """Run the test suite."""
    TestSuite.discover_tests[__functions_in_module()]().run()
