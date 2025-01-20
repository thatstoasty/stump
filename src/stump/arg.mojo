from utils import Variant


@value
struct Arg:
    alias _type = Variant[
        StringLiteral,
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
    var value: Self._type

    # TODO: Doesn't convert to the variant automatically as of 24.6.
    # @implicit
    # fn __init__(out self, value: Self._type):
    #     self.value = value

    @implicit
    fn __init__(out self, value: StringLiteral):
        self.value = value

    @implicit
    fn __init__(out self, value: Int):
        self.value = value

    @implicit
    fn __init__(out self, value: Int8):
        self.value = value

    @implicit
    fn __init__(out self, value: Int16):
        self.value = value

    @implicit
    fn __init__(out self, value: Int32):
        self.value = value

    @implicit
    fn __init__(out self, value: Int64):
        self.value = value

    @implicit
    fn __init__(out self, value: UInt):
        self.value = value

    @implicit
    fn __init__(out self, value: UInt8):
        self.value = value

    @implicit
    fn __init__(out self, value: UInt16):
        self.value = value

    @implicit
    fn __init__(out self, value: UInt32):
        self.value = value

    @implicit
    fn __init__(out self, value: UInt64):
        self.value = value

    @implicit
    fn __init__(out self, value: Float16):
        self.value = value

    @implicit
    fn __init__(out self, value: Float32):
        self.value = value

    @implicit
    fn __init__(out self, value: Float64):
        self.value = value

    @implicit
    fn __init__(out self, value: Bool):
        self.value = value

    fn __str__(self) -> String:
        if self.value.isa[StringLiteral]():
            return str(self.value[StringLiteral])
        elif self.value.isa[Int]():
            return str(self.value[Int])
        elif self.value.isa[Int8]():
            return str(self.value[Int8])
        elif self.value.isa[Int16]():
            return str(self.value[Int16])
        elif self.value.isa[Int32]():
            return str(self.value[Int32])
        elif self.value.isa[Int64]():
            return str(self.value[Int64])
        elif self.value.isa[UInt]():
            return str(self.value[UInt])
        elif self.value.isa[UInt8]():
            return str(self.value[UInt8])
        elif self.value.isa[UInt16]():
            return str(self.value[UInt16])
        elif self.value.isa[UInt32]():
            return str(self.value[UInt32])
        elif self.value.isa[UInt64]():
            return str(self.value[UInt64])
        elif self.value.isa[Float32]():
            return str(self.value[Float32])
        elif self.value.isa[Float64]():
            return str(self.value[Float64])
        elif self.value.isa[Bool]():
            return str(self.value[Bool])

        return self.value[String]
