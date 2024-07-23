from os import stat
from sys import stderr


alias NEWLINE = String("\n")


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
struct PrintLogger(Logger):
    var level: Int

    fn __init__(inout self, level: Int = WARN):
        self.level = level

    fn _log_message(self, message: String, level: Int):
        if self.level >= level:
            print(message)

    fn info(self, message: String):
        self._log_message(message, INFO)

    fn warn(self, message: String):
        self._log_message(message, WARN)

    fn error(self, message: String):
        self._log_message(message, ERROR)

    fn debug(self, message: String):
        self._log_message(message, DEBUG)

    fn fatal(self, message: String):
        self._log_message(message, FATAL)

    fn get_level(self) -> Int:
        return self.level


struct FileLogger(Logger):
    var level: Int
    var path: String
    var mode: String
    var _file: FileHandle

    fn __init__(inout self, path: String, mode: String = "w", level: Int = WARN) raises:
        self.level = level
        self.path = path
        self.mode = mode
        self._file = open(path, mode)

    fn __moveinit__(inout self, owned other: FileLogger):
        self.level = other.level
        self._file = other._file^
        self.mode = other.mode^
        self.path = other.path^

    fn __del__(owned self):
        try:
            self._file.close()
        except e:
            print("Failed to close file.", e, file=stderr)

    fn _log_message(self, message: String, level: Int):
        if self.level >= level:
            try:
                # var result = stat(self.path)

                # file was removed, reopen and continue logging.
                # if result.st_nlink == 0:
                #     self._file.close()
                #     self._file = open(self.path, self.mode)

                self._file.write(message)
                self._file.write(NEWLINE)
            except e:
                print("Failed to write to file.", e)

    fn info(self, message: String):
        self._log_message(message, INFO)

    fn warn(self, message: String):
        self._log_message(message, WARN)

    fn error(self, message: String):
        self._log_message(message, ERROR)

    fn debug(self, message: String):
        self._log_message(message, DEBUG)

    fn fatal(self, message: String):
        self._log_message(message, FATAL)

    fn get_level(self) -> Int:
        return self.level


from builtin.io import _dup


@value
struct stdout:
    """A read only file handle to the stdin stream."""

    alias file_descriptor = 1
    alias mode = "a"
    var handle: UnsafePointer[NoneType]
    """The file handle to the stdin stream."""

    @always_inline
    fn __init__(inout self):
        """Creates a file handle to the stdin stream."""
        var handle: UnsafePointer[NoneType]

        @parameter
        if os_is_windows():
            handle = external_call["_fdopen", UnsafePointer[NoneType]](
                _dup(Self.file_descriptor), Self.mode.unsafe_ptr()
            )
        else:
            handle = external_call["fdopen", UnsafePointer[NoneType]](
                _dup(Self.file_descriptor), Self.mode.unsafe_ptr()
            )
        self.handle = handle

    fn write(self, data: List[UInt8]):
        _ = external_call[
            "fwrite",
            Int,
            UnsafePointer[UInt8],
            Int,
            Int,
            UnsafePointer[NoneType],
        ](data.unsafe_ptr(), sizeof[UInt8](), data.size, self.handle)


struct STDLogger(Logger):
    var level: Int
    var mode: String
    var _file: stdout

    fn __init__(inout self, mode: String = "w", level: Int = WARN) raises:
        self.level = level
        self.mode = mode
        self._file = stdout()

    fn __moveinit__(inout self, owned other: STDLogger):
        self.level = other.level
        self._file = other._file^
        self.mode = other.mode^

    fn _log_message(self, message: String, level: Int):
        if self.level >= level:
            self._file.write(message.as_bytes())
            self._file.write(NEWLINE.as_bytes())

    fn info(self, message: String):
        self._log_message(message, INFO)

    fn warn(self, message: String):
        self._log_message(message, WARN)

    fn error(self, message: String):
        self._log_message(message, ERROR)

    fn debug(self, message: String):
        self._log_message(message, DEBUG)

    fn fatal(self, message: String):
        self._log_message(message, FATAL)

    fn get_level(self) -> Int:
        return self.level
