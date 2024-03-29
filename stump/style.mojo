from collections.dict import Dict, KeyElement, DictEntry
from external.mist import TerminalStyle
from .base import StringKey, FATAL, INFO, DEBUG, WARN, ERROR


alias Sections = Dict[StringKey, TerminalStyle]


@value
struct Styles:
    var timestamp: TerminalStyle
    var message: TerminalStyle
    var key: TerminalStyle
    var value: TerminalStyle
    var separator: TerminalStyle
    var levels: Dict[StringKey, TerminalStyle]
    var keys: Dict[StringKey, TerminalStyle]
    var values: Dict[StringKey, TerminalStyle]

    fn __init__(
        inout self,
        *,
        timestamp: TerminalStyle = TerminalStyle.new(),
        message: TerminalStyle = TerminalStyle.new(),
        key: TerminalStyle = TerminalStyle.new(),
        value: TerminalStyle = TerminalStyle.new(),
        separator: TerminalStyle = TerminalStyle.new(),
        levels: Dict[StringKey, TerminalStyle] = Dict[StringKey, TerminalStyle](),
        keys: Dict[StringKey, TerminalStyle] = Dict[StringKey, TerminalStyle](),
        values: Dict[StringKey, TerminalStyle] = Dict[StringKey, TerminalStyle](),
    ):
        self.timestamp = timestamp
        self.message = message
        self.key = key
        self.value = value
        self.separator = separator
        self.levels = levels
        self.keys = keys
        self.values = values


fn get_default_styles() -> Styles:
    # Log level styles, by default just set colors
    var levels = Sections()
    levels["FATAL"] = TerminalStyle.new().foreground("#d4317d")
    levels["ERROR"] = TerminalStyle.new().foreground("#d48244")
    levels["INFO"] = TerminalStyle.new().foreground("#13ed84")
    levels["WARN"] = TerminalStyle.new().foreground("#decf2f")
    levels["DEBUG"] = TerminalStyle.new().foreground("#bd37db")
    var styles = Styles()

    return Styles(
        levels=levels,
        key=TerminalStyle.new().faint(),
        separator=TerminalStyle.new().faint(),
    )
