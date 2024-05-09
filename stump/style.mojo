from collections.dict import Dict, KeyElement, DictEntry
from external.mist import TerminalStyle, Profile, TRUE_COLOR, ANSI, ANSI256, ASCII
from .base import StringKey, FATAL, INFO, DEBUG, WARN, ERROR


alias Sections = Dict[StringKey, TerminalStyle]


# TODO: For now setting profile each time, it doesn't seem like os.getenv works at comp time?
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
        timestamp: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
        message: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
        key: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
        value: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
        separator: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
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


fn get_default_styles[default_profile: Int = TRUE_COLOR]() -> Styles:
    alias profile = Profile(default_profile)
    alias base_style = TerminalStyle.new(profile)
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
