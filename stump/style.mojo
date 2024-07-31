import external.mist


alias Sections = Dict[String, mist.Style]


@value
struct Styles:
    var timestamp: mist.Style
    var message: mist.Style
    var key: mist.Style
    var value: mist.Style
    var separator: mist.Style
    var levels: List[mist.Style]
    var keys: Sections
    var values: Sections

    fn __init__(
        inout self,
        *,
        timestamp: mist.Style = mist.Style(),
        message: mist.Style = mist.Style(),
        key: mist.Style = mist.Style(),
        value: mist.Style = mist.Style(),
        separator: mist.Style = mist.Style(),
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


fn get_default_styles() -> Styles:
    # Log level styles, by default just set colors
    var base_style = mist.Style()
    var faint_style = mist.Style().faint()

    var levels = List[mist.Style](
        base_style.foreground(0xD4317D),
        base_style.foreground(0xD48244),
        base_style.foreground(0xDECF2F),
        base_style.foreground(0x13ED84),
        base_style.foreground(0xBD37DB),
    )

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
