from std.collections import InlineArray


@fieldwise_init
struct LogLevel(Writable, Comparable, ImplicitlyCopyable):
    var value: UInt8
    comptime FATAL = Self(0)
    comptime ERROR = Self(1)
    comptime WARN = Self(2)
    comptime INFO = Self(3)
    comptime DEBUG = Self(4)

    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value

    def write_to(self, mut writer: Some[Writer]):
        if self.value == 0:
            writer.write("FATAL")
        elif self.value == 1:
            writer.write("ERROR")
        elif self.value == 2:
            writer.write("WARN")
        elif self.value == 3:
            writer.write("INFO")
        elif self.value == 4:
            writer.write("DEBUG")
        else:
            writer.write("UNKNOWN(", self.value, ")")


# TODO: When parametric traits are supported, this should be parametrized on the log level.
# So that BoundLogger can be parametrized on the log level of it's internal logger.
trait Logger(Movable, ImplicitlyDestructible):
    comptime level: LogLevel

    def info(self, message: Some[Writable]):
        ...

    def warn(self, message: Some[Writable]):
        ...

    def error(self, message: Some[Writable]):
        ...

    def debug(self, message: Some[Writable]):
        ...

    def fatal(self, message: Some[Writable]):
        ...

    # # TODO: Temporary until traits allow fields
    # def get_level(self) -> LogLevel:
    #     ...


@fieldwise_init
struct PrintLogger[log_level: LogLevel](Logger):
    comptime level = Self.log_level

    def _log_message[event_level: LogLevel](self, message: Some[Writable]):
        comptime if Self.level.value >= event_level.value:
            print(message)

    def info(self, message: Some[Writable]):
        self._log_message[LogLevel.INFO](message)

    def warn(self, message: Some[Writable]):
        self._log_message[LogLevel.WARN](message)

    def error(self, message: Some[Writable]):
        self._log_message[LogLevel.ERROR](message)

    def debug(self, message: Some[Writable]):
        self._log_message[LogLevel.DEBUG](message)

    def fatal(self, message: Some[Writable]):
        self._log_message[LogLevel.FATAL](message)

    # def get_level(self) -> LogLevel:
    #     return Self.level


# struct FileLogger(Logger):
#     var level: Int
#     var handle: FileHandle

#     def __init__(out self, owned handle: FileHandle, level: Int = WARN):
#         self.level = level
#         self.handle = handle^

#     def __moveinit__(self, owned other: FileLogger):
#         self.level = other.level
#         self.handle = other.handle^

#     def _log_message(self, message: String, level: Int):
#         if self.level >= level:
#             # var result = stat(self.path)

#             # handle was removed, reopen and continue logging.
#             # if result.st_nlink == 0:
#             #     self.handle.close()
#             #     self.handle = open(self.path, self.mode)

#             self.handle.write(message)
#             self.handle.write(NEWLINE)

#     def info(self, message: String):
#         self._log_message(message, INFO)

#     def warn(self, message: String):
#         self._log_message(message, WARN)

#     def error(self, message: String):
#         self._log_message(message, ERROR)

#     def debug(self, message: String):
#         self._log_message(message, DEBUG)

#     def fatal(self, message: String):
#         self._log_message(message, FATAL)

#     def get_level(self) -> Int:
#         return self.level
