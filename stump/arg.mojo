"""Kwargs Arg Module."""
from std.utils import Variant


@fieldwise_init
struct Arg(ImplicitlyCopyable, Writable):
    """A single argument passed via kwargs."""

    comptime _type = Variant[
        String,
        Int,
        Int8,
        Int16,
        Int32,
        Int64,
        UInt,
        UInt8,
        UInt16,
        UInt32,
        UInt64,
        Float16,
        Float32,
        Float64,
        Bool,
        Error,
    ]
    var value: Self._type
    """The value of the argument. Can be one of several types."""

    @implicit
    def __init__(out self, var value: String):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value^

    @implicit
    def __init__(out self, var value: StringLiteral):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = String(value)

    @implicit
    def __init__(out self, value: Int):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: Int8):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: Int16):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: Int32):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: Int64):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: UInt):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: UInt8):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: UInt16):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: UInt32):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: UInt64):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: Float16):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: Float32):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: Float64):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, value: Bool):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value

    @implicit
    def __init__(out self, var value: Error):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value^

    def __init__(out self, *, copy: Self):
        """Creates a copy of the argument.

        Args:
            copy: The argument to copy.

        Returns:
            A new instance of `Arg` with the same value.
        """
        self.value = copy.value.copy()

    def write_to(self, mut writer: Some[Writer]):
        """Writes the argument to a writer.

        Args:
            writer: The writer to write to.
        """
        comptime for i in range(len(Self._type.Ts)):
            comptime T = Self._type.Ts[i]
            if self.value.isa[T]():
                writer.write(trait_downcast[Writable](self.value[T]))
                return

        writer.write("<unsupported type>")
