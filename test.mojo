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


import time
from external.datetime import DateTime, IsoFormat, Calendar
import testing
from external.morrow import Morrow

alias DateT = DateTime[iana=False, pyzoneinfo=False, native=False]


fn forge_dt():
    var dt = DateT.now().to_iso()
    print(dt)


fn dt() raises:
    var dt = Morrow.now()
    var timestamp = dt.isoformat()
    print(str(dt), timestamp)


fn main() raises:
    dt()
    # forge_dt()
    # dict_bug()
    # var d = Dummy()
    # for func in d.funcs:
    #     func[]()
