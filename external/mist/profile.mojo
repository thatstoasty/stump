import os
from .color import (
    NoColor,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    AnyColor,
    hex_to_ansi256,
    ansi256_to_ansi,
    hex_to_rgb,
)


fn contains(vector: List[String], value: String) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False


# TODO: UNIX systems only for now. Need to add Windows, POSIX, and SOLARIS support.
fn get_color_profile() raises -> Profile:
    """Queries the terminal to determine the color profile it supports.
    ASCII, ANSI, ANSI256, or TrueColor.
    """
    # if not o.isTTY():
    # 	return Ascii

    if os.getenv("GOOGLE_CLOUD_SHELL") == "true":
        return Profile("TrueColor")

    var term = os.getenv("TERM").lower()
    var color_term = os.getenv("COLORTERM").lower()

    # COLORTERM is used by some terminals to indicate TrueColor support.
    if color_term == "24bit":
        pass
    elif color_term == "truecolor":
        if term.startswith("screen"):
            # tmux supports TrueColor, screen only ANSI256
            if os.getenv("TERM_PROGRAM") != "tmux":
                return Profile("ANSI256")
            return Profile("TrueColor")
    elif color_term == "yes":
        pass
    elif color_term == "true":
        return Profile("ANSI256")

    # TERM is used by most terminals to indicate color support.
    if term == "xterm-kitty" or term == "wezterm" or term == "xterm-ghostty":
        return Profile("TrueColor")
    elif term == "linux":
        return Profile("ANSI")

    if "256color" in term:
        return Profile("ANSI256")

    if "color" in term:
        return Profile("ANSI")

    if "ansi" in term:
        return Profile("ANSI")

    return Profile("ASCII")


@value
struct Profile:
    var value: String

    fn __init__(inout self, value: String = "TrueColor") raises:
        """
        Initialize a new profile with the given profile type.

        Args:
            value: The setting to use for this profile. Valid values: ["TrueColor", "ANSI256", "ANSI", "ASCII"].
        """
        self.value = value
        self.validate_value(value)

    fn validate_value(self, value: String) raises -> None:
        var valid = List[String]()
        valid.append("TrueColor")
        valid.append("ANSI256")
        valid.append("ANSI")
        valid.append("ASCII")
        if not contains(valid, value):
            raise Error(
                "Invalid setting, valid values are ['TrueColor', 'ANSI256', 'ANSI',"
                " 'ASCII']"
            )

    fn set_value(inout self, value: String) raises:
        self.validate_value(value)
        self.value = value

    fn convert(self, color: AnyColor) raises -> AnyColor:
        """Degrades a color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.
        """
        if self.value == "ASCII":
            return NoColor()

        if color.isa[NoColor]():
            return color.get[NoColor]()[]
        elif color.isa[ANSIColor]():
            return color.get[ANSIColor]()[]
        elif color.isa[ANSI256Color]():
            if self.value == "ANSI":
                return ansi256_to_ansi(color.get[ANSIColor]()[].value)

            return color.get[ANSI256Color]()[]
        elif color.isa[RGBColor]():
            var h = hex_to_rgb(color.get[RGBColor]()[].value)

            if self.value != "TrueColor":
                var ansi256 = hex_to_ansi256(h)
                if self.value == "ANSI":
                    return ansi256_to_ansi(ansi256.value)

                return ansi256

            return color.get[RGBColor]()[]

        # If it somehow gets here, just return No Color until I can figure out how to just return whatever color was passed in.
        return color.get[NoColor]()[]

    fn color(self, value: String) raises -> AnyColor:
        """Color creates a Color from a string. Valid inputs are hex colors, as well as
        ANSI color codes (0-15, 16-255).

        Args:
            value: The string to convert to a color.
        """
        if len(value) == 0:
            raise Error("No string passed to color function for formatting!")

        if self.value == "ASCII":
            return NoColor()

        if value[0] == "#":
            var c = RGBColor(value)
            return self.convert(c)
        else:
            var i = atol(value)
            if i < 16:
                var c = ANSIColor(i)
                return self.convert(c)
            elif i < 256:
                var c = ANSI256Color(i)
                return self.convert(c)
            else:
                raise Error("Invalid color code, must be between 0 and 255")
