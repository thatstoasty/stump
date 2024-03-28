from collections.dict import Dict, KeyElement, DictEntry
from external.mist import TerminalStyle
from .base import StringKey, FATAL, INFO, DEBUG, WARN, ERROR


alias Styles = Dict[StringKey, Sections]
alias Sections = Dict[StringKey, TerminalStyle]

fn get_default_styles() raises -> Styles:
    var styles = Styles()

    # Log level styles, by default just set colors
    var levels = Sections()
    levels["FATAL"] = TerminalStyle.new().foreground("#d4317d")
    levels["ERROR"] = TerminalStyle.new().foreground("#d48244")
    levels["INFO"] = TerminalStyle.new().foreground("#13ed84")
    levels["WARN"] = TerminalStyle.new().foreground("#decf2f")
    levels["DEBUG"] = TerminalStyle.new().foreground("#bd37db")

    styles["levels"] = levels
    return styles
