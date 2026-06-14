from std.sys import get_defined_int
from std.collections import Dict, Optional
import mist


comptime Sections = Dict[String, mist.Style]


struct Styles(Copyable):
    var timestamp: Optional[mist.Style]
    var message: Optional[mist.Style]
    var key: Optional[mist.Style]
    var value: Optional[mist.Style]
    var separator: Optional[mist.Style]
    var levels: List[mist.Style]
    var keys: Sections
    var values: Sections

    def __init__(
        out self,
        *,
        timestamp: Optional[mist.Style] = None,
        message: Optional[mist.Style] = None,
        key: Optional[mist.Style] = None,
        value: Optional[mist.Style] = None,
        separator: Optional[mist.Style] = None,
        var levels: List[mist.Style] = List[mist.Style](),
        var keys: Sections = Sections(),
        var values: Sections = Sections(),
    ):
        var style = mist.Style()
        self.timestamp = timestamp
        self.message = message
        self.key = key if key else style.faint()
        self.value = value
        self.separator = separator if separator else style.faint()
        self.levels = levels^ if levels else [
            style.foreground(0xD4317D),
            style.foreground(0xD48244),
            style.foreground(0xDECF2F),
            style.foreground(0x13ED84),
            style.foreground(0xBD37DB),
        ]
        self.keys = keys^
        self.values = values^
    
    # def __init__(out self):
    #     self.timestamp = None
    #     self.message = None
    #     self.value = None
    #     self.keys = Sections()
    #     self.values = Sections()

    #     var style = mist.Style(mist.Profile())
    #     var faint_style = style.faint()
    #     self.key = faint_style
    #     self.separator = faint_style
    #     self.levels = [
    #         style.foreground(0xD4317D),
    #         style.foreground(0xD48244),
    #         style.foreground(0xDECF2F),
    #         style.foreground(0x13ED84),
    #         style.foreground(0xBD37DB),
    #     ]




def get_default_styles() -> Styles:
    """Logger level determined by the `MIST_PROFILE` param environment variable.

    When building or running the application, you can set `MIST_PROFILE` by providing the the following option:

    ```bash
    mojo build ... -D MIST_PROFILE=0
    # or
    mojo ... -D MIST_PROFILE=0
    ```
    """
    # Log level styles, by default just set colors
    var style: mist.Style
    comptime profile = get_defined_int["MIST_PROFILE", -1]()

    comptime if profile != -1:
        style = mist.Style(mist.Profile(UInt8(profile)))
    else:
        style = mist.Style()

    var faint_style = style.faint()
    var levels = [
        style.foreground(0xD4317D),
        style.foreground(0xD48244),
        style.foreground(0xDECF2F),
        style.foreground(0x13ED84),
        style.foreground(0xBD37DB),
    ]

    return Styles(key=faint_style, separator=faint_style, levels=levels^)
