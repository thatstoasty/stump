from stump import get_logger
from time import now

alias logger = get_logger()


fn test_default_logger():
    var print_start = now()
    print("Testing print...")
    var print_duration = now() - print_start

    var logger_start = now()
    logger.info("Testing print...")
    var logger_duration = now() - logger_start

    print("print:", "(", print_duration, "ns)")
    print("logger:", "(", logger_duration, "ns)")
    print(
        "Performance difference: ",
        str(logger_duration - print_duration) + "ns",
        ": Print is ",
        str(logger_duration / print_duration) + "x faster"
    )


fn main():
    test_default_logger()