import external.mist
from .base import FATAL, INFO, DEBUG, WARN, ERROR


alias Sections = Dict[String, mist.Style]


# TODO: For now setting profile each time, it doesn't seem like os.getenv works at comp time?
@value
struct Styles:
    var timestamp: mist.Style
    var message: mist.Style
    var key: mist.Style
    var value: mist.Style
    var separator: mist.Style
    var levels: Sections
    var keys: Sections
    var values: Sections

    fn __init__(
        inout self,
        *,
        timestamp: mist.Style = mist.Style(mist.TRUE_COLOR),
        message: mist.Style = mist.Style(mist.TRUE_COLOR),
        key: mist.Style = mist.Style(mist.TRUE_COLOR),
        value: mist.Style = mist.Style(mist.TRUE_COLOR),
        separator: mist.Style = mist.Style(mist.TRUE_COLOR),
        levels: Sections = Sections(),
        keys: Sections = Sections(),
        values: Sections = Sections(),
    ):
        self.timestamp = timestamp
        self.message = message
        self.key = key
        self.value = value
        self.separator = separator
        self.levels = levels
        self.keys = keys
        self.values = values


fn get_default_styles[profile: Int = mist.TRUE_COLOR]() -> Styles:
    # Log level styles, by default just set colors
    var base_style = mist.Style(profile)
    var faint_style = mist.Style(profile).faint()

    var levels = Sections()
    levels["FATAL"] = base_style.foreground(0xD4317D)
    levels["ERROR"] = base_style.foreground(0xD48244)
    levels["INFO"] = base_style.foreground(0x13ED84)
    levels["WARN"] = base_style.foreground(0xDECF2F)
    levels["DEBUG"] = base_style.foreground(0xBD37DB)

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


var DEFAULT_STYLES = get_default_styles()
