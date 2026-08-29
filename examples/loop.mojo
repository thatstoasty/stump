from stump import get_logger
import stump
from std.time import sleep


def main():
    var logger = stump.get_logger()
    comptime for i in range(10):
        comptime if i < 5:
            logger.warning("", iteration=i)
        else:
            logger.info("", iteration=i)
