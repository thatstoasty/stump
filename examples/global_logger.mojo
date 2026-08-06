"""The process-wide default logger.

`stump.info(...)` and friends log to a single logger created on first use and
kept for the life of the process, so a module does not have to be handed one.

The level comes from the `STUMP_LOG_LEVEL` build-time define, not an environment
variable: build with `mojo -D STUMP_LOG_LEVEL=DEBUG` to change it. That is what
keeps the level a compile-time parameter, so suppressed calls cost nothing.
"""
import stump
from stump import default, Context


def main() raises:
    # No logger to construct or thread through.
    stump.trace("Trace stuff.")
    stump.info("Information is good.", "key", "value")
    stump.warning("Warnings can be good too.", "no_value")
    stump.error("An error!", error=Error("DB Unreachable."))
    stump.critical("uh oh...", "number", 4, "mojo", "🔥")

    # Suppressed unless built with -D LOGGING_LEVEL=DEBUG.
    stump.debug("Debugging...")

    # The default is mutable, so it can be configured once at startup and every
    # later call picks the change up.
    default()[].context["service"] = "api"
    stump.info("Now carrying service context.")

    # `default()` also hands back the logger itself, for binding children.
    var request = default()[].bind(request_id="abc123")
    request.info("Handling a request.")
