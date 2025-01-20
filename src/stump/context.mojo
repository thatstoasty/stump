from collections.dict import Dict, DictEntry, _DictEntryIter
import emberjson


struct Context(Stringable, Representable, Writable):
    var value: Dict[String, String]

    fn __init__(out self, value: Dict[String, String] = Dict[String, String]()):
        self.value = value

    fn __moveinit__(out self, owned other: Context):
        self.value = other.value^

    fn copy(self) -> Context:
        var ctx = self.value
        return Context(ctx^)

    fn __getitem__(ref self, key: String) raises -> String:
        return self.value[key]

    fn __setitem__(mut self, key: String, value: String):
        self.value[key] = value

    fn __contains__(self, key: String) -> Bool:
        return key in self.value

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer, //](self, mut writer: W):
        writer.write("Context(")
        for pair in self.items():
            writer.write(pair[].key, "=", pair[].value, ", ")
        writer.write(")")

    fn update(mut self, other: Context, /):
        self.value.update(other.value)

    fn update(mut self, other: Dict[String, String], /):
        self.value.update(other)

    fn pop(mut self, key: String) raises -> String:
        return self.value.pop(key)

    fn items(ref self) -> _DictEntryIter[String, String, __origin_of(self.value)]:
        return self.value.items()

    fn to_logfmt(self) -> String:
        var builder = String()
        var i = 0
        for pair in self.value.items():
            builder.write(pair[].key, "=", pair[].value)

            if i < self.value.size - 1:
                builder.write(" ")
            i += 1

        return builder

    fn to_json(self) -> emberjson.JSON:
        var new_context = Dict[String, emberjson.Value]()
        for pair in self.items():
            new_context[pair[].key] = emberjson.Value(pair[].value)

        var obj = emberjson.Object()
        obj._data = new_context
        return emberjson.JSON(obj^)

    fn to_json_string(self) -> String:
        return emberjson.to_string(self.to_json())
