from stump import get_logger
import stump
from std.time import sleep


def main():
    var logger = stump.get_logger()
    for i in range(1000):
        if i < 500:
            logger.warn("", iteration=i)
        else:
            logger.info("", iteration=i)
