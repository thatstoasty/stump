from stump import get_logger


def main():
    var logger = get_logger()

    # `bind` returns a child logger. The parent is left alone, so a
    # request-scoped logger can be derived from a shared one.
    var bound = logger.bind(bound="context")

    bound.info("Information is good.", "key", "value", "🔥", True)
    bound.warn("Warnings can be good too.", "no_value")
    bound.error("An error!", erroring=True)
    bound.fatal("uh oh...", "number", 4, "mojo", "🔥")
    bound.debug("Debugging...")

    # The parent never saw `bound=context`.
    logger.info("No bound context here.")

    # `unbind` drops a key, `new` starts over with a fresh context.
    var request = bound.bind(service="api", request_id="abc123")
    request.unbind("request_id").info("Service only.")
    request.new(job="nightly").info("Fresh context.")
