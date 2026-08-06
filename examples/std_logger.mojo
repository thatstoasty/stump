from std.logger import Level, Logger
from stump import BoundLogger, StdLogger


def main() raises:
    # `StdLogger` sends records through the standard library's own logger, so
    # stump's structured context and formatting sit on top of whatever the
    # stdlib does with them. The level is given twice because the stdlib logger
    # is itself parameterized on one: the inner value is what actually filters.
    var logger = BoundLogger(StdLogger[Level.DEBUG]())
    logger.debug("Debugging...")
    logger.info("Information is good.", "key", "value")
    logger.warning("Warnings can be good too.")
    logger.error("An error!", erroring=True)

    # `critical` is deliberately not called here: the stdlib logger aborts the
    # process on a critical record, which would stop this example short.

    # The stdlib logger carries its own options. A prefix tags every record, and
    # `source_location` makes it report the call site.
    var tagged = BoundLogger(StdLogger[Level.INFO](Logger[Level.INFO](prefix="[api] ")))
    tagged.info("Prefixed by the stdlib logger")

    # Records below the inner logger's level are dropped by the stdlib logger,
    # the same rule `BoundLogger` uses: a level is a minimum severity.
    var quiet = BoundLogger(StdLogger[Level.WARNING](Logger[Level.WARNING]()))
    quiet.info("not shown — INFO is below WARNING")
    quiet.warning("shown — WARNING meets the threshold")
