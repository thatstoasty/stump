from stump import LogLevel, BoundLogger, PrintLogger
import stump


def main():
    # The structured formatters turn styling off on their own, so the flag only
    # means something for the human-facing default formatter: same layout,
    # no colour. Useful when stdout is a file and mist's own profile detection
    # is not enough, such as behind a pipe you still want plain.
    var logger = BoundLogger(PrintLogger[LogLevel.DEBUG](), apply_styles=False)
    logger.info("Information is good.", "arbitrary", "pairs", key="value")
    logger.warn("Warnings can be good too.")
    logger.error("An error!")
    logger.debug("Debugging...")
    logger.fatal("uh oh...")
