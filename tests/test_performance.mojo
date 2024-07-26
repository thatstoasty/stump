from stump import get_logger, BoundLogger, FileLogger, STDLogger
from time import now


fn test_default_logger() raises:
    var print_start = now()
    print("Testing print...")
    var print_duration = now() - print_start

    var logger = get_logger()
    var logger_start = now()
    logger.info("Testing print...")
    var logger_duration = now() - logger_start

    var f = open("./log.txt", "w")
    var file = BoundLogger(FileLogger(f^, level=4), apply_styles=False)
    var file_logger_start = now()
    file.info("Testing print...")
    var file_logger_duration = now() - file_logger_start

    var std = BoundLogger(STDLogger(level=4))
    var std_logger_start = now()
    std.info("Testing print...")
    var std_logger_duration = now() - std_logger_start

    print("print:", "(", print_duration, "ns)")
    print("logger:", "(", logger_duration, "ns)")
    print("file_logger:", "(", file_logger_duration, "ns)")
    print("std_logger:", "(", std_logger_duration, "ns)")
    print(
        "Performance difference: ",
        str(logger_duration - print_duration) + "ns",
        ": Print is ",
        str(logger_duration / print_duration) + "x faster",
    )


fn main() raises:
    test_default_logger()
