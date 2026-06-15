"""Kwargs Arg Module."""
from std.utils import Variant


@fieldwise_init
struct Arg(ImplicitlyCopyable, Writable):
    """A single argument passed via kwargs."""

    var value: Variant[
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
    ]
    """The value of the argument. Can be one of several types."""

    @implicit
    def __init__(out self, var value: String):
        """Initializes the argument with a value.

        Args:
            value: The string value of the argument.
        """
        self.value = value^

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

    def write_to(self, mut writer: Some[Writer]):
        """Writes the argument to a writer.

        Args:
            writer: The writer to write to.
        """
        if self.value.isa[Int]():
            writer.write(self.value[Int])
        elif self.value.isa[Int8]():
            writer.write(self.value[Int8])
        elif self.value.isa[Int16]():
            writer.write(self.value[Int16])
        elif self.value.isa[Int32]():
            writer.write(self.value[Int32])
        elif self.value.isa[Int64]():
            writer.write(self.value[Int64])
        elif self.value.isa[UInt]():
            writer.write(self.value[UInt])
        elif self.value.isa[UInt8]():
            writer.write(self.value[UInt8])
        elif self.value.isa[UInt16]():
            writer.write(self.value[UInt16])
        elif self.value.isa[UInt32]():
            writer.write(self.value[UInt32])
        elif self.value.isa[UInt64]():
            writer.write(self.value[UInt64])
        elif self.value.isa[Float32]():
            writer.write(self.value[Float32])
        elif self.value.isa[Float64]():
            writer.write(self.value[Float64])
        elif self.value.isa[Bool]():
            writer.write(self.value[Bool])
        elif self.value.isa[String]():
            writer.write(self.value[String])
        else:
            writer.write("<unsupported type>")
