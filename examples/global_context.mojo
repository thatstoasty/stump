"""The process-wide default logger.

`stump.info(...)` and friends log to a single logger created on first use and
kept for the life of the process, so a module does not have to be handed one.

The level comes from the `STUMP_LOG_LEVEL` build-time define, not an environment
variable: build with `mojo -D STUMP_LOG_LEVEL=DEBUG` to change it. That is what
keeps the level a compile-time parameter, so suppressed calls cost nothing.
"""
import stump
from stump.global_context import bind_context, clear_context
from stump import default, Context


def main() raises:
    # `default()` also hands back the logger itself, for binding children.
    bind_context(request_id="abc123")
    stump.info("Handling a request.")

    var logger = stump.get_logger()
    logger.info("Information is good.", "key", "value")
