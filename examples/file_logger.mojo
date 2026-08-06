from std.logger import Level
from std.os import remove
from stump import BoundLogger, FileLogger, LOGFMT_FORMATTER


def main() raises:
    var path = "/tmp/stump_file_logger_example.log"

    # `FileLogger` shares its open handle through an `ArcPointer`, so every copy
    # of the logger — including the children `bind` produces — appends to the
    # same file in call order. `mode` defaults to "a"; "w" truncates first so
    # re-running this example does not keep growing the file.
    var logger = BoundLogger(
        FileLogger[Level.DEBUG](path, mode="w"),
        formatter=LOGFMT_FORMATTER,
    )
    logger.info("Started")

    # The child writes to the same file as its parent.
    var request = logger.bind(request_id="abc123")
    request.info("Handling request")
    logger.info("Finished")

    print("--- contents of", path, "---")
    print(open(path, "r").read(), end="")

    # `auto_flush=False` batches records in memory instead of writing each one
    # immediately. Anything still buffered is flushed by `flush()`, and also when
    # the last copy of the logger is destroyed, so records are never lost.
    #
    # Holding on to the sink gives you something to call `flush()` on. Because
    # the handle and buffer live behind an `ArcPointer`, flushing through this
    # copy flushes the records the bound logger wrote.
    var sink = FileLogger[Level.DEBUG](path, mode="w", auto_flush=False)
    var buffered = BoundLogger(sink.copy(), formatter=LOGFMT_FORMATTER)
    buffered.info("Buffered until flush")
    buffered.info("Also buffered")
    sink.flush()

    print("--- after an explicit flush ---")
    print(open(path, "r").read(), end="")

    remove(path)
