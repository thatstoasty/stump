"""Tests for the process-wide default logger.

Run with `pixi run tests`, or directly:
`mojo -D ASSERT=all -I . test/test_default_logger.mojo`.

These share one global, so they run in their own file — each test file is a
separate process. Within the file, only the last test mutates the default, so
ordering cannot make the others flaky.
"""

from std.testing import TestSuite, assert_equal, assert_false, assert_not_equal, assert_true

from stump import Context, LogLevel, default
from stump.global_logger import DEFAULT_LOG_LEVEL


def test_default_is_a_singleton() raises:
    """Two lookups return the same instance rather than fresh copies.

    This is the property the whole mechanism exists for. A `comptime` alias
    would materialise a new value per use and silently drop writes.
    """
    assert_equal(String(default()), String(default()))


def test_default_level_comes_from_the_build_define() raises:
    """Unset, the define leaves the default at INFO.

    `STUMP_LOG_LEVEL` is a compiler define, not an environment variable, so this
    is INFO unless the suite is built with `-D STUMP_LOG_LEVEL=...`.
    """
    assert_true(DEFAULT_LOG_LEVEL == LogLevel.INFO)


def test_level_parameter_selects_call_site_gating() raises:
    """Every level shares one slot, so the parameter picks gating, not instance.

    Pinning current behaviour: `default[DEBUG]()` reaches the same logger as
    `default()`. That is sound only because `PrintLogger[level]` holds no data
    and `BoundLogger.level` is compile-time; a sink with per-level state would
    need one slot per level.
    """
    assert_equal(String(default()), String(default[LogLevel.DEBUG]()))


def test_default_starts_with_an_empty_context() raises:
    """Nothing is bound onto the default before a caller does it."""
    assert_false("service" in default()[].context)


def test_mutation_is_visible_to_later_lookups() raises:
    """Reconfiguring the default persists, which is what makes it configurable.

    Mutates the shared global, so it runs last by convention -- see the module
    docstring.
    """
    var bound = Context()
    bound["service"] = "api"
    default()[].context.update(bound)

    assert_equal(default()[].context["service"], "api")


def main() raises:
    """Run the test suite."""
    TestSuite.discover_tests[__functions_in_module()]().run()
