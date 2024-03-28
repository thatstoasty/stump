from external.gojo.strings import StringBuilder
from external.gojo.fmt import sprintf
from .base import Context, ContextPair

alias RED = "\033[91m"
alias GREEN = "\033[92m"
alias YELLOW = "\033[93m"
alias BLUE = "\033[94m"
alias PURPLE = "\033[95m"


fn get_level_mapping() -> List[String]:
    var mapping = List[String]()
    mapping.append("FATAL")
    mapping.append("ERROR")
    mapping.append("WARN")
    mapping.append("INFO")
    mapping.append("DEBUG")
    return mapping


alias LEVEL_MAPPING = get_level_mapping()


# Formatter options
alias Formatter = UInt8
alias DEFAULT_FORMAT: Formatter = 0
alias JSON_FORMAT: Formatter = 1


# fn default_formatter(context: Context) -> String:
#     var builder = StringBuilder()
#     var timestamp = context.find("timestamp")
#     if timestamp:
#         _ = builder.write_string(timestamp.value())

#     var level = context.find("level")
#     if level:
#         try:
#             var level_text = LEVEL_MAPPING[atol(level.value())]
#             _ = builder.write_string(level_text)
#         except:
#             print("failed to get level text")

#     var message = context.find("message")
#     if message:
#         _ = builder.write_string(message.value())

#     # timestamp then level, then message, then other context keys
#     return str(builder)


fn default_formatter(inout context: Context) raises -> String:
    var timestamp = context.pop("timestamp")
    var level = context.pop("level")
    var message = context.pop("message")

    # Add the rest of the context
    var builder = StringBuilder()
    for pair in context.items():
        _ = builder.write_string(stringify_kv_pair(pair[]))

    # timestamp then level, then message, then other context keys
    return sprintf("%s %s %s", timestamp, level, message) + str(builder)


fn json_formatter(inout context: Context) raises -> String:
    var timestamp = context.pop("timestamp")
    var level = context.pop("level")
    var message = context.pop("message")

    # timestamp then level, then message, then other context keys
    return stringify_context(context)


fn stringify_kv_pair(pair: ContextPair) raises -> String:
    return sprintf("%s=%s", pair.key.s, pair.value)


fn stringify_context(data: Context) -> String:
    var key_count = data.size
    var builder = StringBuilder()
    _ = builder.write_string("{")

    var key_index = 0
    for pair in data.items():
        _ = builder.write_string('"')
        _ = builder.write_string(pair[].key.s)
        _ = builder.write_string('"')
        _ = builder.write_string(':"')

        if pair[].key.s == "level":
            var level_text: String = ""
            try:
                level_text = LEVEL_MAPPING[atol(pair[].value)]
                _ = builder.write_string(level_text)
            except:
                _ = builder.write_string(pair[].value)
        else:
            _ = builder.write_string(pair[].value)

        _ = builder.write_string('"')

        # Add comma for all elements except last
        if key_index != key_count - 1:
            _ = builder.write_string(",")
            key_index += 1

    _ = builder.write_string("}")
    return str(builder)


fn format(formatter: Formatter, inout context: Context) raises -> String:
    if formatter == JSON_FORMAT:
        return json_formatter(context)
    return default_formatter(context)
