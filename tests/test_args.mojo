from utils.variant import Variant

alias ValidKwargType = Variant[String, StringLiteral, Int, Float64, Bool]


fn info[T: Stringable](*args: T, **kwargs: ValidKwargType):
    for arg in args:
        print("arg: ", arg[])

    for pair in kwargs.items():
        print("key: ", pair[].key)
        print("value: ", pair[].value)


fn main():
    info("Hello", "world", "foo", "bar", key1="value1", key2="value2")
