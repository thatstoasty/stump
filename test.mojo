fn dict_bug() raises:
    var context = Dict[String, String]()
    context["a"] = "b"
    var item = context.pop("a")

    print(item)


fn test() -> None:
    return None


struct Dummy:
    var funcs: List[fn () -> None]

    fn __init__(inout self, funcs: List[fn () -> None] = List[fn () -> None](test)):
        self.funcs = funcs


fn main() raises:
    # dict_bug()
    var d = Dummy()
    for func in d.funcs:
        func[]()
