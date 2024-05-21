from collections.dict import Dict, KeyElement, DictEntry
from external.mist import TerminalStyle, Profile, TRUE_COLOR, ANSI, ANSI256, ASCII
from .base import FATAL, INFO, DEBUG, WARN, ERROR


alias Sections = Dict[String, TerminalStyle]
alias GetStylesFn = fn () -> Styles


# TODO: For now setting profile each time, it doesn't seem like os.getenv works at comp time?
@value
struct Styles:
    var timestamp: TerminalStyle
    var message: TerminalStyle
    var key: TerminalStyle
    var value: TerminalStyle
    var separator: TerminalStyle
    var levels: Dict[String, TerminalStyle]
    var keys: Dict[String, TerminalStyle]
    var values: Dict[String, TerminalStyle]

    fn __init__(
        inout self,
        *,
        timestamp: TerminalStyle = TerminalStyle.new(Profile(ASCII)),
        message: TerminalStyle = TerminalStyle.new(Profile(ASCII)),
        key: TerminalStyle = TerminalStyle.new(Profile(ASCII)),
        value: TerminalStyle = TerminalStyle.new(Profile(ASCII)),
        separator: TerminalStyle = TerminalStyle.new(Profile(ASCII)),
        levels: Dict[String, TerminalStyle] = Dict[String, TerminalStyle](),
        keys: Dict[String, TerminalStyle] = Dict[String, TerminalStyle](),
        values: Dict[String, TerminalStyle] = Dict[String, TerminalStyle](),
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
    alias base_style = TerminalStyle.new(Profile(TRUE_COLOR))
    alias faint_style = base_style.copy().faint()

    # Log level styles, by default just set colors
    var levels = Sections()
    levels["FATAL"] = base_style.copy().foreground("#d4317d")
    levels["ERROR"] = base_style.copy().foreground("#d48244")
    levels["INFO"] = base_style.copy().foreground("#13ed84")
    levels["WARN"] = base_style.copy().foreground("#decf2f")
    levels["DEBUG"] = base_style.copy().foreground("#bd37db")

    return Styles(
        timestamp=base_style,
        message=base_style,
        key=faint_style,
        value=base_style,
        separator=faint_style,
        levels=levels,
        keys=Sections(),
        values=Sections(),
    )


alias DEFAULT_STYLES = get_default_styles()
