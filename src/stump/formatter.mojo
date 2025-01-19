from collections.dict import Dict, KeyElement, DictEntry
from .style import Styles


alias ContextPair = DictEntry[String, String]
alias BAD_ARG_COUNT = "(BAD ARG COUNT)"
"""If the number of arguments does not match the number of format specifiers"""
alias SPACE = " "


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
    var new_context = context
    var format = String()
    # var args = List[String](capacity=3)

    # timestamp then level, then message, then other context keys
    if "timestamp" in new_context:
        try:
            format.write(new_context.pop("timestamp"), " ")
            # args.append(new_context.pop("timestamp"))
            # format.append("%s")
        except:
            pass

    if "level" in new_context:
        try:
            format.write(new_context.pop("level"), " ")
            # args.append(new_context.pop("level"))
            # format.append("%s")
        except:
            pass

    if "message" in new_context:
        try:
            format.write(new_context.pop("message"), " ")
            # args.append(new_context.pop("message"))
            # format.append("%s")
        except:
            pass

    # Add the rest of the context delimited by a space.
    var builder = String.write(format)
    # builder.write(sprintf(SPACE.join(format), args=args), SPACE)
    var i = 0
    for pair in new_context.items():
        builder.write(stringify_kv_pair(pair[]))

        if i < new_context.size - 1:
            builder.write(SPACE)
        i += 1

    return builder


fn json_formatter(context: Context) -> String:
    """Format the context data into a JSON string.

    Args:
        context: The context to format.

    Returns:
        The formatted JSON string.
    """
    var builder = String.write("{")

    var i = 0
    for pair in context.items():
        builder.write('"', pair[].key, '":"', pair[].value, '"')

        # Add comma for all elements except last
        if i != context.size - 1:
            builder.write(", ")
            i += 1

    builder.write("}")
    return builder


fn logfmt_formatter(context: Context) -> String:
    """Format the context data into a logfmt string.

    Args:
        context: The context to format.

    Returns:
        The formatted logfmt string.
    """
    # Add all the keys in the context in KV format.
    var builder = String()
    var i = 0
    for pair in context.items():
        builder.write(stringify_kv_pair(pair[]))

        if i < context.size - 1:
            builder.write(SPACE)
        i += 1

    return builder
