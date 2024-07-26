from collections.dict import Dict, KeyElement, DictEntry
from external.gojo.strings import StringBuilder
from external.gojo.fmt.fmt import format_string
from .style import Styles


alias ContextPair = DictEntry[String, String]
alias BAD_ARG_COUNT = "(BAD ARG COUNT)"
"""If the number of arguments does not match the number of format specifiers"""


fn sprintf(formatting: String, args: List[String]) -> String:
    """Format a string with the given arguments.

    Args:
        formatting: The format string.
        args: The arguments to format the string with.

    Returns:
        The formatted string.
    """
    var text = formatting
    var raw_percent_count = formatting.count("%%") * 2
    var formatter_count = formatting.count("%") - raw_percent_count

    if formatter_count != len(args):
        return BAD_ARG_COUNT

    for i in range(len(args)):
        var argument = args[i]
        text = format_string(text, argument)

    return text


fn stringify_kv_pair(pair: ContextPair) -> String:
    return pair.key + "=" + pair.value


alias Formatter = fn (context: Context) -> String
"""A function that formats the context data into a log message."""


fn default_formatter(context: Context) -> String:
    """Default formatter for log messages.

    Args:
        context: The context to format.

    Returns:
        The formatted log message.
    """
    # TODO: Probably need a better algorithm for this formatting process.
    var new_context = Dict[String, String]()
    var format = List[String]()
    var args = List[String]()
    alias main_keys = InlineArray[String, 3]("timestamp", "level", "message")
    for pair in context.items():
        if pair[].key not in main_keys:
            new_context[pair[].key] = pair[].value

    # timestamp then level, then message, then other context keys
    var timestamp = context.get("timestamp")
    if timestamp:
        args.append(timestamp.value())
        format.append("%s")

    var level = context.get("level")
    if level:
        args.append(level.value())
        format.append("%s")

    var message = context.get("message")
    if message:
        args.append(message.value())
        format.append("%s")

    # Add the rest of the context delimited by a space.
    alias delimiter: String = " "
    var builder = StringBuilder()
    _ = builder.write_string(sprintf(delimiter.join(format), args=args))
    _ = builder.write_string(delimiter)
    var current_index = 0
    for pair in new_context.items():
        _ = builder.write_string(stringify_kv_pair(pair[]))

        if current_index < new_context.size - 1:
            _ = builder.write_string(delimiter)
        current_index += 1

    return str(builder)


fn json_formatter(context: Context) -> String:
    """Format the context data into a JSON string.

    Args:
        context: The context to format.

    Returns:
        The formatted JSON string.
    """
    var key_count = context.size
    var builder = StringBuilder()
    _ = builder.write_string("{")

    var key_index = 0
    for pair in context.items():
        _ = builder.write_string('"')
        _ = builder.write_string(pair[].key)
        _ = builder.write_string('"')
        _ = builder.write_string(':"')

        if pair[].key == "level":
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
            _ = builder.write_string(", ")
            key_index += 1

    _ = builder.write_string("}")
    return str(builder)


fn logfmt_formatter(context: Context) -> String:
    """Format the context data into a logfmt string.

    Args:
        context: The context to format.

    Returns:
        The formatted logfmt string.
    """
    # Add all the keys in the context in KV format.
    var delimiter = " "
    var builder = StringBuilder()
    var pair_count = context.size
    var current_index = 0
    for pair in context.items():
        _ = builder.write_string(stringify_kv_pair(pair[]))

        if current_index < pair_count - 1:
            _ = builder.write_string(delimiter)
        current_index += 1

    # timestamp then level, then message, then other context keys
    return str(builder)
