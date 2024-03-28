from external.morrow import Morrow
from external.mist import TerminalStyle
from .base import Context
from .formatter import LEVEL_MAPPING
from .style import get_default_styles


fn add_timestamp(inout context: Context):
    var timestamp: String = ""
    try:
        timestamp = Morrow.now().format("YYYY-MM-DD HH:mm:ss")
        context["timestamp"] = timestamp
    except:
        print("add_timestamp: failed to get timestamp")


fn add_log_level(inout context: Context):
    var timestamp: String = ""
    try:
        var styles = get_default_styles()
        var style = TerminalStyle.new().foreground("12")
        var level = context.pop("level")
        var level_text = LEVEL_MAPPING[atol(level)]
        context["level"] = styles["levels"][level_text].render(level_text)
    except:
        print("add_log_level: failed to get log level")
