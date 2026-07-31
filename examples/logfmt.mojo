from stump import LogLevel, logfmt_formatter, BoundLogger, PrintLogger


def main():
    # `logfmt_formatter` declares itself unstyled, so `apply_styles` resolves to
    # `False` on its own.
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), formatter=logfmt_formatter)
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
