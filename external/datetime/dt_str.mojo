# ===----------------------------------------------------------------------=== #
# Copyright (c) 2024, Martin Vuyk Loperena
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #
"""`DateTime` and `Date` String parsing module."""

from .timezone import (
    TimeZone,
    ZoneInfo,
    ZoneInfoMem32,
    ZoneInfoMem8,
    ZoneStorageDST,
    ZoneStorageNoDST,
)


@value
# @register_passable("trivial")
struct IsoFormat:
    """Available formats to parse from and to
    [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)."""

    alias TZD_REGEX = "+|-[0-9]{2}:?[0-9]{2}"
    alias TZD = "%z"
    alias YYYYMMDD = "%4Y%m%d"
    """e.g. `19700101`"""
    alias YYYY_MM_DD = "%4Y-%m-%d"
    """e.g. `1970-01-01`"""
    alias HHMMSS = "%H%M%S"
    """e.g. `000000`"""
    alias HH_MM_SS = "%H:%M:%S"
    """e.g. `00:00:00`"""
    alias YYYYMMDDHHMMSS = Self.YYYYMMDD + Self.HHMMSS
    """e.g. `19700101000000`"""
    alias YYYYMMDDHHMMSSTZD = Self.YYYYMMDD + Self.HHMMSS + Self.TZD
    """e.g. `19700101000000+0000`"""
    alias YYYY_MM_DD___HH_MM_SS = Self.YYYY_MM_DD + " " + Self.HH_MM_SS
    """e.g. `1970-01-01 00:00:00`"""
    alias YYYY_MM_DD_T_HH_MM_SS = Self.YYYY_MM_DD + "T" + Self.HH_MM_SS
    """e.g. `1970-01-01T00:00:00`"""
    alias YYYY_MM_DD_T_HH_MM_SS_TZD = Self.YYYY_MM_DD + "T" + Self.HH_MM_SS + Self.TZD
    """e.g. `1970-01-01T00:00:00+00:00`"""
    var selected: StringLiteral
    """The selected IsoFormat."""

    fn __init__(inout self, selected: StringLiteral = self.YYYY_MM_DD_T_HH_MM_SS_TZD):
        """Construct an IsoFormat with selected fmt string.

        Args:
            selected: The selected IsoFormat.
        """
        debug_assert(
            selected == self.YYYYMMDD
            or selected == self.YYYY_MM_DD
            or selected == self.HHMMSS
            or selected == self.HH_MM_SS
            or selected == self.YYYYMMDDHHMMSS
            or selected == self.YYYYMMDDHHMMSSTZD
            or selected == self.YYYY_MM_DD___HH_MM_SS
            or selected == self.YYYY_MM_DD_T_HH_MM_SS
            or selected == self.YYYY_MM_DD_T_HH_MM_SS_TZD,
            "that ISO8601 string format is not supported yet",
        )
        self.selected = selected


@always_inline
fn _get_strings(
    year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int
) -> (String, String, String, String, String, String):
    var yyyy = str(min(year, 9999))
    if year < 1000:
        var prefix = "0"
        if year < 100:
            prefix = "00"
            if year < 10:
                prefix = "000"
        yyyy = prefix + str(year)

    var mm = str(min(month, 99)) if month > 9 else "0" + str(month)
    var dd = str(min(day, 99)) if day > 9 else "0" + str(day)
    var hh = str(min(hour, 99)) if hour > 9 else "0" + str(hour)
    var m_str = str(min(minute, 99)) if minute > 9 else "0" + str(minute)
    var ss = str(min(second, 99)) if second > 9 else "0" + str(second)
    return yyyy, mm, dd, hh, m_str, ss


fn to_iso[
    iso: IsoFormat = IsoFormat(),
    T1: Intable = Int,
    T2: Intable = Int,
    T3: Intable = Int,
    T4: Intable = Int,
    T5: Intable = Int,
    T6: Intable = Int,
](year: T1, month: T2, day: T3, hour: T4, minute: T5, second: T6, tzd: String = "+00:00",) -> String:
    """Build an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601) compliant
    `String`.

    Parameters:
        iso: The chosen IsoFormat.
        T1: An Intable Type.
        T2: An Intable Type.
        T3: An Intable Type.
        T4: An Intable Type.
        T5: An Intable Type.
        T6: An Intable Type.

    Args:
        year: Year.
        month: Month.
        day: Day.
        hour: Hour.
        minute: Minute.
        second: Second.
        tzd: Time Zone designation String (full format i.e. `+00:00`).

    Returns:
        String.
    """

    var s = _get_strings(int(year), int(month), int(day), int(hour), int(minute), int(second))
    var yyyy_mm_dd = s[0] + "-" + s[1] + "-" + s[2]
    var hh_mm_ss = s[3] + ":" + s[4] + ":" + s[5]

    @parameter
    if iso.selected == iso.YYYY_MM_DD_T_HH_MM_SS:
        return yyyy_mm_dd + "T" + hh_mm_ss
    elif iso.selected == iso.YYYY_MM_DD_T_HH_MM_SS_TZD:
        return yyyy_mm_dd + "T" + hh_mm_ss + tzd
    elif iso.selected == iso.YYYY_MM_DD___HH_MM_SS:
        return yyyy_mm_dd + " " + hh_mm_ss
    elif iso.selected == iso.YYYYMMDDHHMMSS:
        return s[0] + s[1] + s[2] + s[3] + s[4] + s[5]
    elif iso.selected == iso.YYYYMMDDHHMMSSTZD:
        return s[0] + s[1] + s[2] + s[3] + s[4] + s[5] + tzd[:3] + tzd[-2:]
    elif iso.selected == iso.YYYYMMDD:
        return s[0] + s[1] + s[2] + s[3]
    elif iso.selected == iso.HHMMSS:
        return s[3] + s[4] + s[5]
    elif iso.selected == iso.YYYY_MM_DD:
        return yyyy_mm_dd
    elif iso.selected == iso.HH_MM_SS:
        return s[3] + ":" + s[4] + ":" + s[5]
    else:
        constrained[False, "that IsoFormat is not yet supported"]()
        return ""


fn from_iso[
    iso: IsoFormat = IsoFormat(),
    dst_storage: ZoneStorageDST = ZoneInfoMem32,
    no_dst_storage: ZoneStorageNoDST = ZoneInfoMem8,
    iana: Bool = True,
    pyzoneinfo: Bool = True,
    native: Bool = False,
](s: String) raises -> (
    UInt16,
    UInt8,
    UInt8,
    UInt8,
    UInt8,
    UInt8,
    TimeZone[dst_storage, no_dst_storage, iana, pyzoneinfo, native],
):
    """Parses a string expecting given format.

    Parameters:
        iso: The chosen IsoFormat.
        dst_storage: The type of storage to use for ZoneInfo
            for zones with Dailight Saving Time. Default Memory.
        no_dst_storage: The type of storage to use for ZoneInfo
            for zones with no Dailight Saving Time. Default Memory.
        iana: Whether timezones from the [IANA database](
            http://www.iana.org/time-zones/repository/tz-link.html)
            are used. It defaults to using all available timezones,
            if getting them fails at compile time, it tries using
            python's zoneinfo if pyzoneinfo is set to True, otherwise
            it uses the offsets as is, no daylight saving or
            special exceptions. [List of TZ identifiers](
            https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
        pyzoneinfo: Whether to use python's zoneinfo and
            datetime to get full IANA support.
        native: (fast, partial IANA support) Whether to use a native Dict
            with the current timezones from the [List of TZ identifiers](
            https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
            at the time of compilation (for now they're hardcoded
            at stdlib release time, in the future it should get them
            from the OS). If it fails at compile time, it defaults to
            using the given offsets when the timezone was constructed.

    Args:
        s: The string.

    Returns:
        A tuple with the result.
    """
    alias tz = TimeZone[dst_storage, no_dst_storage, iana, pyzoneinfo, native]
    var num0 = UInt8(0)
    var result = UInt16(0), num0, num0, num0, num0, num0, tz()

    @parameter
    if iso.YYYYMMDD in iso.selected:
        result[0] = atol(s[:4])
        result[1] = atol(s[4:6])

        @parameter
        if iso.selected == iso.YYYYMMDD:
            return result^
        result[2] = atol(s[6:8])
        result[3] = atol(s[8:10])
        result[4] = atol(s[10:12])
        result[5] = atol(s[12:14])
    elif iso.YYYY_MM_DD in iso.selected:
        result[0] = atol(s[:4])
        result[1] = atol(s[5:7])

        @parameter
        if iso.selected == iso.YYYY_MM_DD:
            return result^
        result[2] = atol(s[8:10])
        result[3] = atol(s[11:13])
        result[4] = atol(s[14:16])
        result[5] = atol(s[17:19])
    elif iso.selected == iso.HH_MM_SS:
        result[3] = atol(s[:2])
        result[4] = atol(s[3:5])
        result[5] = atol(s[6:8])
    elif iso.selected == iso.HHMMSS:
        result[3] = atol(s[:2])
        result[4] = atol(s[2:4])
        result[5] = atol(s[4:6])

    @parameter
    if iso.selected == iso.YYYY_MM_DD_T_HH_MM_SS_TZD:
        var sign = 1
        if s[19] == "-":
            sign = -1
        var h = atol(s[20:22])
        var m = 0
        if s[22] == ":":
            m = atol(s[23:25])
        else:
            m = atol(s[22:24])
        result[6] = tz.from_offset(result[0], result[1], result[2], h, m, sign)
    elif iso.selected == iso.YYYYMMDDHHMMSSTZD:
        var sign = 1
        if s[14] == "-":
            sign = -1
        var h = atol(s[15:17])
        var m = 0
        if s[17] == ":":
            m = atol(s[18:20])
        else:
            m = atol(s[17:19])
        result[6] = tz.from_offset(result[0], result[1], result[2], h, m, sign)

    return result^


@value
struct _DateTime:
    var year: UInt16
    var month: UInt8
    var day: UInt8
    var hour: UInt8
    var minute: UInt8
    var second: UInt8
    var m_second: UInt16
    var u_second: UInt16
    var n_second: UInt16


fn strptime(s: String, format_str: StringLiteral) -> Optional[_DateTime]:
    """Parses time from a `String`.

    Args:
        s: The string.
        format_str: The chosen format.

    Returns:
        An Optional tuple with the result.
    """

    # TODO: native
    try:
        from python import Python

        var dt = Python.import_module("datetime")
        var date = dt.datetime.strptime(s, format_str)
        return _DateTime(
            UInt16(int(date.year)),
            UInt8(int(date.month)),
            UInt8(int(date.day)),
            UInt8(int(date.hour)),
            UInt8(int(date.minute)),
            UInt8(int(date.second)),
            UInt16(int(date.microsecond) // 1000),
            UInt16(int(date.microsecond) % 1000),
            UInt16(0),
        )
    except:
        pass
    return None


fn strftime[
    T1: Intable = Int,
    T2: Intable = Int,
    T3: Intable = Int,
    T4: Intable = Int,
    T5: Intable = Int,
    T6: Intable = Int,
    T7: Intable = Int,
    T8: Intable = Int,
](
    format_str: String,
    year: T1,
    month: T2,
    day: T3,
    hour: T4,
    minute: T5,
    second: T6,
    m_second: T7,
    u_second: T8,
) -> String:
    """Formats time into a `String`.

    Args:
        format_str: Format_str.
        year: Year.
        month: Month.
        day: Day.
        hour: Hour.
        minute: Minute.
        second: Second.
        m_second: Milisecond.
        u_second: Microsecond.

    Returns:
        String.
    """

    # TODO: native
    # TODO: localization
    try:
        from python import Python

        var dt = Python.import_module("datetime")
        var date = dt.datetime(
            int(year),
            int(month),
            int(day),
            int(hour),
            int(minute),
            int(second),
            microsecond=(int(m_second) * 1000 + int(u_second)),
        )
        # FIXME: python issue https://github.com/python/cpython/issues/120713
        # remove after EOL of 3.11 (2027-10)
        return str(date.strftime(format_str.replace("%Y", "%4Y")))
    except:
        pass
    return ""
