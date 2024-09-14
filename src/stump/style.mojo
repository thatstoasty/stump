from collections import Dict, Optional
import mist


alias Sections = Dict[String, mist.Style]


@value
struct Styles:
    var timestamp: Optional[mist.Style]
    var message: Optional[mist.Style]
    var key: Optional[mist.Style]
    var value: Optional[mist.Style]
    var separator: Optional[mist.Style]
    var levels: List[mist.Style]
    var keys: Sections
    var values: Sections

    fn __init__(
        inout self,
        *,
        timestamp: Optional[mist.Style] = None,
        message: Optional[mist.Style] = None,
        key: Optional[mist.Style] = None,
        value: Optional[mist.Style] = None,
        separator: Optional[mist.Style] = None,
        levels: List[mist.Style] = List[mist.Style](),
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


fn get_default_styles[profile: Int = -1]() -> Styles:
    # Log level styles, by default just set colors
    var style: mist.Style
    if profile != -1:
        style = mist.Style(profile)
    else:
        style = mist.Style()

    var faint_style = style.faint()

    var levels = List[mist.Style](
        style.foreground(0xD4317D),
        style.foreground(0xD48244),
        style.foreground(0xDECF2F),
        style.foreground(0x13ED84),
        style.foreground(0xBD37DB),
    )

    return Styles(key=faint_style, separator=faint_style, levels=levels)


var DEFAULT_STYLES = get_default_styles()
