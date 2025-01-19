from stump import get_logger, BoundLogger, FileLogger, STDLogger
from time import perf_counter_ns
import benchmark


fn test_print[text: String]():
    print(text)


fn test_logger[text: String]():
    var logger = get_logger()
    logger.info(text)


fn test_stdlogger[text: String]():
    var std = BoundLogger(STDLogger(level=4))
    std.info(text)


fn test_file_logger[text: String]():
    try:
        var f = open("./examples/data/log.txt", "w")
        var file = BoundLogger(FileLogger(f^, level=4), apply_styles=False)
        file.info(text)
    except e:
        print("File logger test failed", e)


fn test_default_logger() raises:
    var f = open("./examples/data/log.txt", "w")
    var file = BoundLogger(FileLogger(f^, level=4), apply_styles=False)
    var file_logger_start = perf_counter_ns()
    file.info("Testing print...")
    var file_logger_duration = perf_counter_ns() - file_logger_start

    print("file_logger:", "(", file_logger_duration, "ns)")


fn main() raises:
    alias text = "Testing log..."
    print("Running test_print")
    var report = benchmark.run[test_print[text]](max_iters=5)
    report.print(benchmark.Unit.ns)

    print("Running test_logger")
    report = benchmark.run[test_logger[text]](max_iters=5)
    report.print(benchmark.Unit.ns)

    print("Running test_stdlogger")
    report = benchmark.run[test_stdlogger[text]](max_iters=5)
    report.print(benchmark.Unit.ns)

    # print("Running test_file_logger")
    # report = benchmark.run[test_file_logger[text]](max_iters=5)
    # report.print(benchmark.Unit.ns)
    test_default_logger()
