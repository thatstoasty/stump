# stump

WIP Logger! Inspired by charmbracelet's log package and the Python structlog package.

```py
from stump import LEVEL_MAPPING, DEBUG, BoundLogger, BasicLogger, JSON_FORMAT, DEFAULT_FORMAT


alias LOG_LEVEL = DEBUG
alias inner_logger = build_logger()
alias logger = bound_logger(inner_logger)


fn build_logger() -> BasicLogger:
    return BasicLogger(LOG_LEVEL)


fn bound_logger(l: BasicLogger) -> BoundLogger[BasicLogger]:
    var bound_log = BoundLogger[BasicLogger](l, formatter=DEFAULT_FORMAT)
    return bound_log


fn main() raises:
    var log = logger
    log.info("Information is good.")
    log.warn("Warnings can be good too.")
    log.error("An error!")
    log.debug("Debugging...")

    log.fatal("uh oh...")

    raise Error("dead")
```

![Example logs](https://github.com/thatstoasty/stump/blob/main/example.png)
