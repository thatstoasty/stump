import external.mist


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
    )


var DEFAULT_STYLES = get_default_styles()
