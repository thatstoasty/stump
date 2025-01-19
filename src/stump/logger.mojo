from os import stat
from sys import stderr, os_is_windows, external_call, sizeof


# TODO: When parametric traits are supported, this should be parametrized on the log level.
# So that BoundLogger can be parametrized on the log level of it's internal logger.
trait Logger(Movable):
    fn info(self, message: String):
        ...

    fn warn(self, message: String):
        ...

    fn error(self, message: String):
        ...

    fn debug(self, message: String):
        ...

    fn fatal(self, message: String):
        ...

    # TODO: Temporary until traits allow fields
    fn get_level(self) -> Int:
        ...


@value
struct PrintLogger[level: Int](Logger):
    fn _log_message[event_level: Int](self, message: String):
        @parameter
        if level >= event_level:
            print(message)

    fn info(self, message: String):
        self._log_message[LogLevel.INFO](message)

    fn warn(self, message: String):
        self._log_message[LogLevel.WARN](message)

    fn error(self, message: String):
        self._log_message[LogLevel.ERROR](message)

    fn debug(self, message: String):
        self._log_message[LogLevel.DEBUG](message)

    fn fatal(self, message: String):
        self._log_message[LogLevel.FATAL](message)

    fn get_level(self) -> Int:
        return level


# struct FileLogger(Logger):
#     var level: Int
#     var handle: FileHandle

#     fn __init__(out self, owned handle: FileHandle, level: Int = WARN):
#         self.level = level
#         self.handle = handle^

#     fn __moveinit__(self, owned other: FileLogger):
#         self.level = other.level
#         self.handle = other.handle^

#     fn _log_message(self, message: String, level: Int):
#         if self.level >= level:
#             # var result = stat(self.path)

#             # handle was removed, reopen and continue logging.
#             # if result.st_nlink == 0:
#             #     self.handle.close()
#             #     self.handle = open(self.path, self.mode)

#             self.handle.write(message)
#             self.handle.write(NEWLINE)

#     fn info(self, message: String):
#         self._log_message(message, INFO)

#     fn warn(self, message: String):
#         self._log_message(message, WARN)

#     fn error(self, message: String):
#         self._log_message(message, ERROR)

#     fn debug(self, message: String):
#         self._log_message(message, DEBUG)

#     fn fatal(self, message: String):
#         self._log_message(message, FATAL)

#     fn get_level(self) -> Int:
#         return self.level
