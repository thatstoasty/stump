from std.collections.dict import Dict, DictEntry, _DictEntryIter
import emberjson


struct Context(Writable, Copyable):
    var value: Dict[String, String]

    @implicit
    def __init__(out self, var value: Dict[String, String] = Dict[String, String]()):
        self.value = value^

    def __getitem__(ref self, key: String) raises -> String:
        return self.value[key]

    def __setitem__(mut self, key: String, value: String):
        self.value[key] = value

    def __contains__(self, key: String) -> Bool:
        return key in self.value

    def update(mut self, other: Context, /):
        self.value.update(other.value)

    def update(mut self, other: Dict[String, String], /):
        self.value.update(other)

    def pop(mut self, key: String) raises -> String:
        return self.value.pop(key)

    # def items(ref self) -> _DictEntryIter[String, String, origin_of(self.value)]:
    #     return self.value.items()

    def to_logfmt(self) -> String:
        var builder = String()
        var i = 0
        for pair in self.value.items():
            builder.write(t"{pair.key}={pair.value}")

            if i < len(self.value) - 1:
                builder.write(" ")
            i += 1

        return builder^

    def to_json(self) -> emberjson.Object:
        var new_context = Dict[String, emberjson.Value]()
        for pair in self.value.items():
            new_context[pair.key] = emberjson.Value(pair.value)

        return emberjson.Object(new_context^)

    def to_json_string(self) -> String:
        return emberjson.to_string(self.to_json())
