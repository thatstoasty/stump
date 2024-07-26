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
"""`Date` module.

- Notes:
    - IANA is supported: [`TimeZone` and DST data sources](
        http://www.iana.org/time-zones/repository/tz-link.html).
        [List of TZ identifiers (`tz_str`)](
        https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
"""
from time import time
from collections.optional import Optional

from .timezone import (
    TimeZone,
    ZoneInfo,
    ZoneInfoMem32,
    ZoneInfoMem8,
    ZoneStorageDST,
    ZoneStorageNoDST,
)
from .calendar import Calendar, UTCCalendar, PythonCalendar, CalendarHashes
import .dt_str


alias _calendar = PythonCalendar
alias _cal_hash = CalendarHashes(32)


trait _IntCollect(Intable, CollectionElement):
    ...


@value
# @register_passable("trivial")
struct Date[
    dst_storage: ZoneStorageDST = ZoneInfoMem32,
    no_dst_storage: ZoneStorageNoDST = ZoneInfoMem8,
    iana: Bool = True,
    pyzoneinfo: Bool = True,
    native: Bool = False,
](Hashable, Stringable):
    """Custom `Calendar` and `TimeZone` may be passed in.
    By default uses `PythonCalendar` which is a proleptic
    Gregorian calendar with its given epoch and max years:
    from [0001-01-01, 9999-12-31]. Default `TimeZone`
    is UTC.

    Parameters:
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

    - Max Resolution:
        - year: Up to year 65_536.
        - month: Up to month 256.
        - day: Up to day 256.
        - hash: 32 bits.

    - Notes:
        - By default, PythonCalendar has min_hour set to 0,
            that means if you have timezones that have one or more
            hours less than UTC they will be set a day before
            in most calculations. If that is a problem, a custom
            Gregorian calendar with min_hour=12 can be passed
            in the constructor and most timezones will be inside
            the same day.
    """

    var year: UInt16
    """Year."""
    var month: UInt8
    """Month."""
    var day: UInt8
    """Day."""
    # TODO: tz and calendar should be references
    alias _tz = TimeZone[dst_storage, no_dst_storage, iana, pyzoneinfo, native]
    var tz: Self._tz
    """Tz."""
    var calendar: Calendar
    """Calendar."""

    fn __init__[
        T1: _IntCollect = Int, T2: _IntCollect = Int, T3: _IntCollect = Int
    ](
        inout self,
        year: Optional[T1] = None,
        month: Optional[T2] = None,
        day: Optional[T3] = None,
        tz: Optional[Self._tz] = None,
        calendar: Calendar = _calendar,
    ):
        """Construct a `DateTime` from valid values.

        Parameters:
            T1: Any type that is Intable and CollectionElement.
            T2: Any type that is Intable and CollectionElement.
            T3: Any type that is Intable and CollectionElement.

        Args:
            year: Year.
            month: Month.
            day: Day.
            tz: Tz.
            calendar: Calendar.
        """

        self.year = int(year.value()) if year else int(calendar.min_year)
        self.month = int(month.value()) if month else int(calendar.min_month)
        self.day = int(day.value()) if day else int(calendar.min_day)
        self.tz = tz.value() if tz else Self._tz()
        self.calendar = calendar

    fn replace(
        owned self,
        *,
        year: Optional[UInt16] = None,
        month: Optional[UInt8] = None,
        day: Optional[UInt8] = None,
        tz: Optional[Self._tz] = None,
        calendar: Optional[Calendar] = None,
    ) -> Self:
        """Replace with give value/s.

        Args:
            year: Year.
            month: Month.
            day: Day.
            tz: Tz.
            calendar: Calendar to change to, distance from epoch
                is calculated and the new Self has that same
                distance from the new Calendar's epoch.

        Returns:
            Self.
        """
        var new_self = self
        if year:
            new_self.year = year.value()
        if month:
            new_self.month = month.value()
        if day:
            new_self.day = day.value()
        if tz:
            new_self.tz = tz.value()
        if calendar:
            new_self.calendar = calendar.value()
        return new_self

    fn to_calendar(owned self, calendar: Calendar) -> Self:
        """Translates the `Date`'s values to be on the same
        offset since it's current calendar's epoch to the new
        calendar's epoch.

        Args:
            calendar: The new calendar.

        Returns:
            Self.
        """
        var s = self.seconds_since_epoch()
        self.year = calendar.min_year
        self.month = calendar.min_month
        self.day = calendar.min_day
        self.calendar = calendar
        return self.add(seconds=int(s))

    fn to_utc(owned self) -> Self:
        """Returns a new instance of `Self` transformed to UTC. If
        `self.tz` is UTC it returns early. All dates are assumed to be at
        midday with respect to UTC (UTC is at 12:00 and add/subtract offset).

        Returns:
            Self with tz casted to UTC.
        """

        var TZ_UTC = Self._tz()
        if self.tz == TZ_UTC:
            return self^
        var offset = self.tz.offset_at(self.year, self.month, self.day, 0, 0, 0)
        var beyond_day = 12 + offset.hour + offset.minute / 60 > 24
        if beyond_day and offset.sign == -1:
            self = self.add(days=1)
        elif beyond_day and offset.sign == 1:
            self = self.subtract(days=1)

        self.tz = TZ_UTC
        return self^

    fn from_utc(owned self, tz: Self._tz) -> Self:
        """Translate `TimeZone` from UTC. If `self.tz` is UTC
        it returns early.

        Args:
            tz: `TimeZone` to cast to.

        Returns:
            Self with tz casted to given tz.
        """
        var TZ_UTC = Self._tz()
        if tz == TZ_UTC:
            return self^
        var maxmin = self.calendar.max_minute
        var maxsec = self.calendar.max_typical_second
        var offset = tz.offset_at(self.year, self.month, self.day, 0, 0, 0)
        var of_h = int(offset.hour)
        var of_m = int(offset.minute)
        var amnt = int(of_h * maxmin * maxsec + of_m * maxsec)
        if offset.sign == 1:
            self = self.add(seconds=amnt)
        else:
            self = self.subtract(seconds=amnt)
        var leapsecs = int(self.calendar.leapsecs_since_epoch(self.year, self.month, self.day))
        return self.add(seconds=leapsecs).replace(tz=tz)

    fn seconds_since_epoch(self) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Returns:
            The amount.
        """
        return self.calendar.seconds_since_epoch(self.year, self.month, self.day, 0, 0, 0)

    fn delta_s(self, other: Self) -> UInt64:
        """Calculates the difference in seconds between `self` and other.

        Args:
            other: Other.

        Returns:
            `self.seconds_since_epoch() - other.seconds_since_epoch()`.
        """

        var s = self
        var o = other.replace(calendar=self.calendar)

        if s.tz != o.tz:
            s = s.to_utc()
            o = o.to_utc()
        return s.seconds_since_epoch() - o.seconds_since_epoch()

    fn add(
        owned self,
        *,
        years: Int = 0,
        months: Int = 0,
        days: Int = 0,
        seconds: Int = 0,
    ) -> Self:
        """Recursively evaluated function to build a valid `Date`
        according to its calendar. Values are added in BigEndian order i.e.
        `years, months, ...` .

        Args:
            years: Amount of years to add.
            months: Amount of months to add.
            days: Amount of days to add.
            seconds: Amount of seconds to add.

        Returns:
            Self.

        Notes:
            On overflow, the `Date` starts from the beginning of the
            calendar's epoch and keeps evaluating until valid.
        """

        var y = int(self.year) + years
        var mon = int(self.month) + months
        var d = (
            int(self.day)
            + days
            + seconds
            // (
                (int(self.calendar.max_hour) + 1)
                * (int(self.calendar.max_minute) + 1)
                * (int(self.calendar.max_typical_second) + 1)
            )
        )
        var minyear = self.calendar.min_year
        var maxyear = int(self.calendar.max_year)
        if y > maxyear:
            var delta = y - (maxyear + 1)
            self = self.replace(year=minyear).add(years=delta)
        else:
            self.year = y
        var minmon = self.calendar.min_month
        var maxmon = int(self.calendar.max_month)
        if mon > maxmon:
            var delta = mon - (maxmon + int(minmon))
            self = self.replace(month=minmon).add(years=1, months=delta)
        else:
            self.month = mon
        var minday = self.calendar.min_day
        var maxday = int(self.calendar.max_days_in_month(self.year, self.month))
        if d > maxday:
            var delta = d - (maxday + int(minday))
            self = self.replace(day=minday).add(months=1, days=delta)
        else:
            self.day = d
        return self^

    fn subtract(
        owned self,
        *,
        years: Int = 0,
        months: Int = 0,
        days: Int = 0,
        seconds: Int = 0,
    ) -> Self:
        """Recursively evaluated function to build a valid `Date`
        according to its calendar. Values are subtracted in LittleEndian order
        i.e. `seconds, days, ...` .

        Args:
            years: Amount of years to add.
            months: Amount of months to add.
            days: Amount of days to add.
            seconds: Amount of seconds to add.

        Returns:
            Self.

        Notes:
            On overflow, the `Date` goes to the end of the
            calendar's epoch and keeps evaluating until valid.
        """

        var d = (
            int(self.day)
            - days
            - seconds
            // (
                int(self.calendar.max_hour + 1)
                * int(self.calendar.max_minute + 1)
                * int(self.calendar.max_typical_second + 1)
            )
        )
        var minday = int(self.calendar.min_day)
        if d < minday:
            self = self.subtract(months=1)
            var max_day = self.calendar.max_days_in_month(self.year, self.month)
            var delta = abs(d - minday + 1)
            self = self.replace(day=max_day).subtract(days=delta)
        else:
            self.day = d
        var minmonth = int(self.calendar.min_month)
        var maxmonth = self.calendar.max_month
        var mon = int(self.month) - months
        if mon < minmonth:
            var delta = abs(mon - minmonth + 1)
            self = self.replace(month=maxmonth).subtract(years=1, months=delta)
        else:
            self.month = mon
        var minyear = int(self.calendar.min_year)
        var maxyear = self.calendar.max_year
        var y = int(self.year) - years
        if y < minyear:
            var delta = abs(y - minyear + 1)
            self = self.replace(year=maxyear).subtract(years=delta)
        else:
            self.year = y
        self = self.add(days=0)  #  to correct days and months
        return self^

    # @always_inline("nodebug")
    fn add(owned self, other: Self) -> Self:
        """Adds another `Date`.

        Args:
            other: Other.

        Returns:
            A `Date` with the `TimeZone` and `Calendar` of `self`.
        """
        return self.add(years=int(other.year), months=int(other.month), days=int(other.day))

    # @always_inline("nodebug")
    fn subtract(owned self, other: Self) -> Self:
        """Subtracts another `Date`.

        Args:
            other: Other.

        Returns:
            A `Date` with the `TimeZone` and `Calendar` of `self`.
        """
        return self.subtract(years=int(other.year), months=int(other.month), days=int(other.day))

    # @always_inline("nodebug")
    fn __add__(owned self, other: Self) -> Self:
        """Add.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.add(other)

    # @always_inline("nodebug")
    fn __sub__(owned self, other: Self) -> Self:
        """Subtract.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.subtract(other)

    # @always_inline("nodebug")
    fn __iadd__(inout self, owned other: Self):
        """Add Immediate.

        Args:
            other: Other.
        """
        self = self.add(other)

    # @always_inline("nodebug")
    fn __isub__(inout self, owned other: Self):
        """Subtract Immediate.

        Args:
            other: Other.
        """
        self = self.subtract(other)

    # @always_inline("nodebug")
    fn day_of_week(self) -> UInt8:
        """Calculates the day of the week for a `Date`.

        Returns:
            - day: Day of the week: [0, 6] (monday - sunday) (default).
        """

        return self.calendar.day_of_week(self.year, self.month, self.day)

    # @always_inline("nodebug")
    fn day_of_year(self) -> UInt16:
        """Calculates the day of the year for a `Date`.

        Returns:
            - day: Day of the year: [1, 366] (for gregorian calendar).
        """

        return self.calendar.day_of_year(self.year, self.month, self.day)

    # @always_inline("nodebug")
    fn day_of_month(self, day_of_year: Int) -> (UInt8, UInt8):
        """Calculates the month, day of the month for a given day of the year.

        Args:
            day_of_year: The day of the year.

        Returns:
            - month: Month of the year: [1, 12] (for gregorian calendar).
            - day: Day of the month: [1, 31] (for gregorian calendar).
        """

        return self.calendar.day_of_month(self.year, day_of_year)

    fn leapsecs_since_epoch(self) -> UInt32:
        """Cumulative leap seconds since the calendar's epoch start.

        Returns:
            The amount.
        """

        var dt = self.to_utc()
        return dt.calendar.leapsecs_since_epoch(dt.year, dt.month, dt.day)

    fn __hash__(self) -> UInt:
        """Hash.

        Returns:
            The hash.
        """
        return self.calendar.hash[_cal_hash](self.year, self.month, self.day)

    # @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        """Eq.

        Args:
            other: Other.

        Returns:
            Bool.
        """

        if self.tz != other.tz:
            return hash(self.to_utc()) == hash(other.to_utc())
        return hash(self) == hash(other)

    # @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Bool:
        """Ne.

        Args:
            other: Other.

        Returns:
            Bool.
        """

        if self.tz != other.tz:
            return hash(self.to_utc()) != hash(other.to_utc())
        return hash(self) != hash(other)

    # @always_inline("nodebug")
    fn __gt__(self, other: Self) -> Bool:
        """Gt.

        Args:
            other: Other.

        Returns:
            Bool.
        """

        if self.tz != other.tz:
            return hash(self.to_utc()) > hash(other.to_utc())
        return hash(self) > hash(other)

    # @always_inline("nodebug")
    fn __ge__(self, other: Self) -> Bool:
        """Ge.

        Args:
            other: Other.

        Returns:
            Bool.
        """

        if self.tz != other.tz:
            return hash(self.to_utc()) >= hash(other.to_utc())
        return hash(self) >= hash(other)

    # @always_inline("nodebug")
    fn __le__(self, other: Self) -> Bool:
        """Le.

        Args:
            other: Other.

        Returns:
            Bool.
        """

        if self.tz != other.tz:
            return hash(self.to_utc()) <= hash(other.to_utc())
        return hash(self) <= hash(other)

    # @always_inline("nodebug")
    fn __lt__(self, other: Self) -> Bool:
        """Lt.

        Args:
            other: Other.

        Returns:
            Bool.
        """

        if self.tz != other.tz:
            return hash(self.to_utc()) < hash(other.to_utc())
        return hash(self) < hash(other)

    # @always_inline("nodebug")
    fn __and__[T: Hashable](self, other: T) -> UInt32:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return hash(self) & hash(other)

    # @always_inline("nodebug")
    fn __or__[T: Hashable](self, other: T) -> UInt32:
        """Or.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return hash(self) | hash(other)

    # @always_inline("nodebug")
    fn __xor__[T: Hashable](self, other: T) -> UInt32:
        """Xor.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return hash(self) ^ hash(other)

    # @always_inline("nodebug")
    fn __int__(self) -> Int:
        """Int.

        Returns:
            Int.
        """
        return hash(self)

    # @always_inline("nodebug")
    fn __str__(self) -> String:
        """Str.

        Returns:
            String.
        """
        return self.to_iso()

    @staticmethod
    fn from_unix_epoch[add_leap: Bool = False](seconds: Int, tz: Optional[Self._tz] = None) -> Self:
        """Construct a `Date` from the seconds since the Unix Epoch
        1970-01-01. Adding the cumulative leap seconds since 1972
        to the given date.

        Parameters:
            add_leap: Whether to add the leap seconds and leap days
                since the start of the calendar's epoch.

        Args:
            seconds: Seconds.
            tz: Tz.

        Returns:
            Self.
        """

        var zone = tz.value() if tz else Self._tz()
        var dt = Self(tz=zone, calendar=UTCCalendar).add(seconds=seconds)

        @parameter
        if add_leap:
            dt = dt.add(seconds=int(dt.leapsecs_since_epoch()))
        return dt^

    @staticmethod
    fn now(tz: Optional[Self._tz] = None, calendar: Calendar = _calendar) -> Self:
        """Construct a date from `time.now()`.

        Args:
            tz: The tz to cast the result to.
            calendar: The Calendar to cast the result to.

        Returns:
            Self.
        """

        var zone = tz.value() if tz else Self._tz()
        var s = time.now() // 1_000_000_000
        return Date.from_unix_epoch[False](s, zone).replace(calendar=calendar)

    fn strftime(self, fmt: String) -> String:
        """Formats time into a `String`.

        Args:
            fmt: The chosen format.

        Returns:
            String.
        """

        return dt_str.strftime(fmt, self.year, self.month, self.day, 0, 0, 0, 0, 0)

    # @always_inline("nodebug")
    fn to_iso[iso: dt_str.IsoFormat = dt_str.IsoFormat()](self) -> String:
        """Return an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)
        compliant formatted`String` e.g. `IsoFormat.YYYY_MM_DD` ->
         `1970-01-01` .

        Parameters:
            iso: The IsoFormat.

        Returns:
            String.
        """

        var offset = self.tz.offset_at(self.year, self.month, self.day, 0, 0, 0)
        return dt_str.to_iso[iso](self.year, self.month, self.day, 0, 0, 0, offset.to_iso())

    @staticmethod
    fn strptime(
        s: String,
        format_str: StringLiteral,
        tz: Optional[Self._tz] = None,
        calendar: Calendar = _calendar,
    ) -> Optional[Self]:
        """Parse a `Date` from a  `String`.

        Args:
            s: The string.
            format_str: The format string.
            tz: The `TimeZone` to cast the result to.
            calendar: The Calendar to cast the result to.

        Returns:
            An Optional Self.
        """

        var zone = tz.value() if tz else Self._tz()
        var parsed = dt_str.strptime(s, format_str)
        if not parsed:
            return None
        var p = parsed.value()
        var dt = Self(p.year, p.month, p.day, zone, calendar)
        return dt^

    @staticmethod
    @parameter
    fn from_iso[
        iso: dt_str.IsoFormat = dt_str.IsoFormat(),
    ](s: String, tz: Optional[Self._tz] = None, calendar: Calendar = _calendar) -> Optional[Self]:
        """Construct a date from an
        [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601) compliant
        `String`.

        Parameters:
            iso: The IsoFormat to parse.

        Args:
            s: The `String` to parse; it's assumed that it is properly formatted
                i.e. no leading whitespaces or anything different to the
                selected IsoFormat.
            tz: Optional timezone to transform the result into (taking into
                account that the format may return with a `TimeZone`).
            calendar: The calendar to which the result will belong.

        Returns:
            An Optional Self.
        """

        try:
            var p = dt_str.from_iso[iso, dst_storage, no_dst_storage, iana, pyzoneinfo, native](s)
            var year = p[0]
            var month = p[1]
            var day = p[2]

            @parameter
            if iso.selected in (iso.HHMMSS, iso.HH_MM_SS):
                year = calendar.min_year
                month = calendar.min_month
                day = calendar.min_day

            var dt = Self(year, month, day, tz=p[6], calendar=calendar)
            if tz:
                var t = tz.value()
                if t != dt.tz:
                    return dt.to_utc().from_utc(t)
            return dt
        except:
            return None

    @staticmethod
    fn from_hash(
        value: UInt32,
        tz: Optional[Self._tz] = None,
        calendar: Calendar = _calendar,
    ) -> Self:
        """Construct a `Date` from a hash made by it.

        Args:
            value: The value to parse.
            tz: The `TimeZone` to designate to the result.
            calendar: The Calendar to designate to the result.

        Returns:
            Self.
        """

        var zone = tz.value() if tz else Self._tz()
        var d = calendar.from_hash[_cal_hash](int(value))
        return Self(d[0], d[1], d[2], zone, calendar)
