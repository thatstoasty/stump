from stump import get_logger
import stump
from time import sleep


alias logger = stump.get_logger()


fn main():
    for i in range(1000):
        if i < 500:
            logger.warn("", iteration=i)
        else:
            logger.info("", iteration=i)
