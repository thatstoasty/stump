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
"""Nanosecond resolution `DateTime` module.

Notes:
    - IANA is supported: [`TimeZone` and DST data sources](
        http://www.iana.org/time-zones/repository/tz-link.html).
        [List of TZ identifiers (`tz_str`)](
        https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
"""
from time import time
from utils import Variant
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
alias _cal_hash = CalendarHashes(64)
alias _max_delta = (~UInt64(0) // (365 * 24 * 60 * 60 * 1_000_000_000)).cast[DType.uint16]()
"""Maximum year delta that fits in a UInt64 for a
Gregorian calendar with year = 365 d * 24 h, 60 min, 60 s, 10^9 ns"""


trait _IntCollect(Intable, CollectionElement):
    ...


@value
# @register_passable("trivial")
struct DateTime[
    dst_storage: ZoneStorageDST = ZoneInfoMem32,
    no_dst_storage: ZoneStorageNoDST = ZoneInfoMem8,
    iana: Bool = True,
    pyzoneinfo: Bool = True,
    native: Bool = False,
](Hashable, Stringable):
    """Custom `Calendar` and `TimeZone` may be passed in.
    By default, it uses `PythonCalendar` which is a Gregorian
    calendar with its given epoch and max year:
    [0001-01-01, 9999-12-31]. Default `TimeZone` is UTC.

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
        - hour: Up to hour 256.
        - minute: Up to minute 256.
        - second: Up to second 256.
        - m_second: Up to m_second 65_536.
        - u_second: Up to u_second 65_536.
        - n_second: Up to n_second 65_536.
        - hash: 64 bits.

    - Notes:
        - The default hash that is used for logical and bitwise
            operations has only microsecond resolution.
        - The Default `DateTime` hash has only Microsecond resolution.
    """

    var year: UInt16
    """Year."""
    var month: UInt8
    """Month."""
    var day: UInt8
    """Day."""
    var hour: UInt8
    """Hour."""
    var minute: UInt8
    """Minute."""
    var second: UInt8
    """Second."""
    var m_second: UInt16
    """M_second."""
    var u_second: UInt16
    """U_second."""
    var n_second: UInt16
    """N_second."""
    # TODO: tz and calendar should be references
    alias _tz = TimeZone[dst_storage, no_dst_storage, iana, pyzoneinfo, native]
    var tz: Self._tz
    """Tz."""
    var calendar: Calendar
    """Calendar."""

    fn __init__[
        T1: _IntCollect = Int,
        T2: _IntCollect = Int,
        T3: _IntCollect = Int,
        T4: _IntCollect = Int,
        T5: _IntCollect = Int,
        T6: _IntCollect = Int,
        T7: _IntCollect = Int,
        T8: _IntCollect = Int,
        T9: _IntCollect = Int,
    ](
        inout self,
        year: Optional[T1] = None,
        month: Optional[T2] = None,
        day: Optional[T3] = None,
        hour: Optional[T4] = None,
        minute: Optional[T5] = None,
        second: Optional[T6] = None,
        m_second: Optional[T7] = None,
        u_second: Optional[T8] = None,
        n_second: Optional[T9] = None,
        tz: Optional[Self._tz] = None,
        calendar: Calendar = _calendar,
    ):
        """Construct a `DateTime` from valid values.

        Parameters:
            T1: Any type that is Intable and CollectionElement.
            T2: Any type that is Intable and CollectionElement.
            T3: Any type that is Intable and CollectionElement.
            T4: Any type that is Intable and CollectionElement.
            T5: Any type that is Intable and CollectionElement.
            T6: Any type that is Intable and CollectionElement.
            T7: Any type that is Intable and CollectionElement.
            T8: Any type that is Intable and CollectionElement.
            T9: Any type that is Intable and CollectionElement.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: M_second.
            u_second: U_second.
            n_second: N_second.
            tz: Tz.
            calendar: Calendar.
        """

        self.year = int(year.value()) if year else int(calendar.min_year)
        self.month = int(month.value()) if month else int(calendar.min_month)
        self.day = int(day.value()) if day else int(calendar.min_day)
        self.hour = int(hour.value()) if hour else int(calendar.min_hour)
        self.minute = int(minute.value()) if minute else int(calendar.min_minute)
        self.second = int(second.value()) if second else int(calendar.min_second)
        self.m_second = int(m_second.value()) if m_second else int(calendar.min_milisecond)
        self.u_second = int(u_second.value()) if u_second else int(calendar.min_microsecond)
        self.n_second = int(n_second.value()) if n_second else int(calendar.min_nanosecond)
        self.tz = tz.value() if tz else Self._tz()
        self.calendar = calendar

    fn replace(
        owned self,
        *,
        year: Optional[UInt16] = None,
        month: Optional[UInt8] = None,
        day: Optional[UInt8] = None,
        hour: Optional[UInt8] = None,
        minute: Optional[UInt8] = None,
        second: Optional[UInt8] = None,
        m_second: Optional[UInt16] = None,
        u_second: Optional[UInt16] = None,
        n_second: Optional[UInt16] = None,
        tz: Optional[Self._tz] = None,
        calendar: Optional[Calendar] = None,
    ) -> Self:
        """Replace with give value/s.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: Milisecond.
            u_second: Microsecond.
            n_second: Nanosecond.
            tz: Tz.
            calendar: Calendar to change to, distance from epoch
                is calculated and the new Self has that same
                distance from the new Calendar's epoch.

        Returns:
            Self.
        """

        if year:
            self.year = year.value()
        if month:
            self.month = month.value()
        if day:
            self.day = day.value()
        if hour:
            self.hour = hour.value()
        if minute:
            self.minute = minute.value()
        if second:
            self.second = second.value()
        if m_second:
            self.m_second = m_second.value()
        if u_second:
            self.u_second = u_second.value()
        if n_second:
            self.n_second = n_second.value()
        if tz:
            self.tz = tz.value()
        if calendar:
            self.calendar = calendar.value()
        return self

    fn to_calendar(owned self, calendar: Calendar) -> Self:
        """Translates the `DateTime`'s values to be on the same
        offset since it's current calendar's epoch to the new
        calendar's epoch.

        Args:
            calendar: The new calendar.

        Returns:
            Self.
        """

        var year = self.year
        var tmpcal = self.calendar.from_year(year)
        self.calendar = tmpcal
        var ns = self.n_seconds_since_epoch()
        self.year = calendar.min_year
        self.month = calendar.min_month
        self.day = calendar.min_day
        self.hour = calendar.min_hour
        self.minute = calendar.min_minute
        self.second = calendar.min_second
        self.calendar = calendar
        return self.add(years=int(year), n_seconds=int(ns))

    fn to_utc(owned self) -> Self:
        """Returns a new instance of `Self` transformed to UTC. If
        `self.tz` is UTC it returns early.

        Returns:
            Self.
        """

        var TZ_UTC = Self._tz()
        if self.tz == TZ_UTC:
            return self
        var offset = self.tz.offset_at(self.year, self.month, self.day, self.hour, self.minute, self.second)
        var of_h = int(offset.hour)
        var of_m = int(offset.minute)
        if offset.sign == -1:
            self = self.add(hours=of_h, minutes=of_m)
        else:
            self = self.subtract(hours=of_h, minutes=of_m)
        self.tz = TZ_UTC
        return self^

    fn from_utc(owned self, tz: Self._tz) -> Self:
        """Translate `TimeZone` from UTC. If `self.tz` is UTC
        it returns early.

        Args:
            tz: Timezone to cast to.

        Returns:
            Self.
        """

        var TZ_UTC = Self._tz()
        if tz == TZ_UTC:
            return self
        var offset = tz.offset_at(self.year, self.month, self.day, self.hour, self.minute, self.second)
        var h = int(offset.hour)
        var m = int(offset.minute)
        var new_self: Self
        if offset.sign == 1:
            new_self = self.add(hours=h, minutes=m)
        else:
            new_self = self.subtract(hours=h, minutes=m)
        var leapsecs = int(new_self.calendar.leapsecs_since_epoch(new_self.year, new_self.month, new_self.day))
        return new_self.add(seconds=leapsecs).replace(tz=tz)

    fn n_seconds_since_epoch(self) -> UInt64:
        """Nanoseconds since the begining of the calendar's epoch.
        Can only represent up to ~ 580 years since epoch start.

        Returns:
            The amount.
        """
        return self.calendar.n_seconds_since_epoch(
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.m_second,
            self.u_second,
            self.n_second,
        )

    fn seconds_since_epoch(self) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Returns:
            The amount.
        """
        return self.calendar.seconds_since_epoch(self.year, self.month, self.day, self.hour, self.minute, self.second)

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

    fn delta_ns(self, other: Self) -> (UInt64, UInt64, UInt16, UInt8):
        """Calculates the nanoseconds for `self` and other, creating
        a reference calendar to keep nanosecond resolution.

        Args:
            other: Other.

        Returns:
            - self_ns: Nanoseconds from `self` to created temp calendar.
            - other_ns: Nanoseconds from other to created temp calendar.
            - overflow: the amount of years added / subtracted from `self`
                to make the temp calendar. This occurs if the difference
                in years is bigger than ~ 580 (Gregorian years).
            - sign: {1, -1} if the overflow was added or subtracted.
        """
        var s = self
        var o = other
        if s.tz != o.tz:
            s = s.to_utc()
            o = o.to_utc()

        var overflow: UInt16 = 0
        var sign: UInt8 = 1
        var year = s.year
        if s.year < o.year:
            sign = -1
            while o.year - year > _max_delta:
                year -= _max_delta
                overflow += _max_delta
        else:
            while year - o.year > _max_delta:
                year -= _max_delta
                overflow += _max_delta

        var cal = self.calendar.from_year(year)
        var self_ns = s.replace(calendar=cal).n_seconds_since_epoch()
        var other_ns = o.replace(calendar=cal).n_seconds_since_epoch()
        return self_ns, other_ns, overflow, sign

    fn add(
        owned self,
        *,
        years: Int = 0,
        months: Int = 0,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
        m_seconds: Int = 0,
        u_seconds: Int = 0,
        n_seconds: Int = 0,
    ) -> Self:
        """Recursively evaluated function to build a valid `DateTime`
        according to its calendar. Values are added in BigEndian order i.e.
        `years, months, ...` .

        Args:
            years: Years.
            months: Months.
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.
            m_seconds: Miliseconds.
            u_seconds: Microseconds.
            n_seconds: Nanoseconds.

        Returns:
            Self.

        Notes:
            On overflow, the `DateTime` starts from the beginning of the
            calendar's epoch and keeps evaluating until valid.
        """

        var y = int(self.year) + years
        var mon = int(self.month) + months
        var d = int(self.day) + days
        var h = int(self.hour) + hours
        var mi = int(self.minute) + minutes
        var s = int(self.second) + seconds
        var ms = int(self.m_second) + m_seconds
        var us = int(self.u_second) + u_seconds
        var ns = int(self.n_second) + n_seconds

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
        var minhour = self.calendar.min_hour
        var maxhour = int(self.calendar.max_hour)
        if h > maxhour:
            var delta = h - (maxhour + int(minhour) + 1)
            self = self.replace(hour=minhour).add(days=1, hours=delta)
        else:
            self.hour = h
        var minmin = self.calendar.min_minute
        var maxmin = int(self.calendar.max_minute)
        if mi > maxmin:
            var delta = mi - (maxmin + int(minmin) + 1)
            self = self.replace(minute=minmin).add(hours=1, minutes=delta)
        else:
            self.minute = mi
        var minsec = self.calendar.min_second
        var maxsec = self.calendar.max_second(self.year, self.month, self.day, self.hour, self.minute)
        if s > int(maxsec):
            var delta = s - (int(maxsec) + int(minsec) + 1)
            self = self.replace(second=minsec).add(minutes=1, seconds=delta)
        else:
            self.second = s
        var minmsec = self.calendar.min_milisecond
        var maxmsec = int(self.calendar.max_milisecond)
        if ms > maxmsec:
            var delta = ms - (maxmsec + int(minmsec) + 1)
            self = self.replace(m_second=minmsec).add(seconds=1, m_seconds=delta)
        else:
            self.m_second = ms
        var minusec = self.calendar.min_microsecond
        var maxusec = int(self.calendar.max_microsecond)
        if us > maxusec:
            var delta = us - (maxusec + int(minusec) + 1)
            self = self.replace(u_second=minusec).add(m_seconds=1, u_seconds=delta)
        else:
            self.u_second = us
        var minnsec = self.calendar.min_nanosecond
        var maxnsec = int(self.calendar.max_nanosecond)
        if ns > maxnsec:
            var delta = ns - (maxnsec + int(minnsec) + 1)
            self = self.replace(n_second=minnsec).add(u_seconds=1, n_seconds=delta)
        else:
            self.n_second = ns
        return self^

    fn subtract(
        owned self,
        *,
        years: Int = 0,
        months: Int = 0,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
        m_seconds: Int = 0,
        u_seconds: Int = 0,
        n_seconds: Int = 0,
    ) -> Self:
        """Recursively evaluated function to build a valid `DateTime`
        according to its calendar. Values are subtracted in LittleEndian order
        i.e. `n_seconds, u_seconds, ...` .

        Args:
            years: Years.
            months: Months.
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.
            m_seconds: Miliseconds.
            u_seconds: Microseconds.
            n_seconds: Nanoseconds.

        Returns:
            Self.

        Notes:
            On overflow, the `DateTime` goes to the end of the
            calendar's epoch and keeps evaluating until valid.
        """

        var ns = int(self.n_second) - n_seconds
        var minnsec = int(self.calendar.min_nanosecond)
        var maxnsec = self.calendar.max_nanosecond
        if ns < minnsec:
            var delta = abs(ns - minnsec + 1)
            self = self.replace(n_second=maxnsec).subtract(u_seconds=1, n_seconds=delta)
        else:
            self.n_second = ns
        var us = int(self.u_second) - u_seconds
        var minusec = int(self.calendar.min_microsecond)
        var maxusec = self.calendar.max_microsecond
        if us < minusec:
            var delta = abs(us - minusec + 1)
            self = self.replace(u_second=maxusec).subtract(m_seconds=1, u_seconds=delta)
        else:
            self.u_second = us
        var ms = int(self.m_second) - m_seconds
        var minmsec = int(self.calendar.min_milisecond)
        var maxmsec = self.calendar.max_milisecond
        if ms < minmsec:
            var delta = abs(ms - minmsec + 1)
            self = self.replace(m_second=maxmsec).subtract(seconds=1, m_seconds=delta)
        else:
            self.m_second = ms
        var s = int(self.second) - seconds
        var minsec = int(self.calendar.min_second)
        if s < minsec:
            var delta = abs(s - minsec + 1)
            var sec = self.calendar.max_second(self.year, self.month, self.day, self.hour, self.minute)
            self = self.replace(second=sec).subtract(minutes=1, seconds=delta)
        else:
            self.second = s
        var mi = int(self.minute) - minutes
        var minmin = int(self.calendar.min_minute)
        var maxmin = self.calendar.max_minute
        if mi < minmin:
            var delta = abs(mi - minmin + 1)
            self = self.replace(minute=maxmin).subtract(hours=1, minutes=delta)
        else:
            self.minute = mi
        var h = int(self.hour) - hours
        var minhour = int(self.calendar.min_hour)
        var maxhour = self.calendar.max_hour
        if h < minhour:
            var delta = abs(h - minhour + 1)
            self = self.replace(hour=maxhour).subtract(days=1, hours=delta)
        else:
            self.hour = h
        var d = int(self.day) - days
        var minday = int(self.calendar.min_day)
        if d < minday:
            self = self.subtract(months=1)
            var max_day = self.calendar.max_days_in_month(self.year, self.month)
            var delta = abs(d - minday + 1)
            self = self.replace(day=max_day).subtract(days=delta)
        else:
            self.day = d
        var mon = int(self.month) - months
        var minmonth = int(self.calendar.min_month)
        var maxmonth = self.calendar.max_month
        if mon < minmonth:
            var delta = abs(mon - minmonth + 1)
            self = self.replace(month=maxmonth).subtract(years=1, months=delta)
        else:
            self.month = mon
        var y = int(self.year) - years
        var minyear = int(self.calendar.min_year)
        var maxyear = self.calendar.max_year
        if y < minyear:
            var delta = abs(y - minyear + 1)
            self = self.replace(year=maxyear).subtract(years=delta)
        else:
            self.year = y
        self = self.add(days=0)  #  to correct days and months
        return self^

    # @always_inline("nodebug")
    fn add(owned self, other: Self) -> Self:
        """Adds another `DateTime`.

        Args:
            other: Other.

        Returns:
            A `DateTime` with the `TimeZone` and `Calendar` of `self`.
        """
        return self.add(
            years=int(other.year),
            months=int(other.month),
            days=int(other.day),
            hours=int(other.hour),
            minutes=int(other.minute),
            seconds=int(other.second),
            m_seconds=int(other.m_second),
            u_seconds=int(other.u_second),
            n_seconds=int(other.n_second),
        )

    # @always_inline("nodebug")
    fn subtract(owned self, other: Self) -> Self:
        """Subtracts another `DateTime`.

        Args:
            other: Other.

        Returns:
            A `DateTime` with the `TimeZone` and `Calendar` of `self`.
        """
        return self.subtract(
            years=int(other.year),
            months=int(other.month),
            days=int(other.day),
            hours=int(other.hour),
            minutes=int(other.minute),
            seconds=int(other.second),
            m_seconds=int(other.m_second),
            u_seconds=int(other.u_second),
            n_seconds=int(other.n_second),
        )

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
        """Calculates the day of the week for a `DateTime`.

        Returns:
            - day: Day of the week: [0, 6] (monday - sunday) (default).
        """

        return self.calendar.day_of_week(self.year, self.month, self.day)

    # @always_inline("nodebug")
    fn day_of_year(self) -> UInt16:
        """Calculates the day of the year for a `DateTime`.

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
            Result.
        """
        return self.calendar.hash[_cal_hash](
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.m_second,
            self.u_second,
            self.n_second,
        )

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
    fn __and__[T: Hashable](self, other: T) -> UInt64:
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
    fn __or__[T: Hashable](self, other: T) -> UInt64:
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
    fn __xor__[T: Hashable](self, other: T) -> UInt64:
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
            Result.
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
    # @always_inline("nodebug")
    fn from_unix_epoch[add_leap: Bool = False](seconds: Int, tz: Optional[Self._tz] = None) -> Self:
        """Construct a `DateTime` from the seconds since the Unix Epoch
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
    # @always_inline("nodebug")
    fn now(
        tz: Optional[Self._tz] = None,
        calendar: Calendar = _calendar,
    ) -> Self:
        """Construct a datetime from `time.now()`.

        Args:
            tz: `TimeZone` to replace UTC.
            calendar: Calendar to replace the UTCCalendar with.

        Returns:
            Self.
        """

        var zone = tz.value() if tz else Self._tz()
        var ns = time.now()
        var us: UInt16 = ns // 1_000
        var ms: UInt16 = ns // 1_000_000
        var s = ns // 1_000_000_000
        var dt = Self.from_unix_epoch(s, zone).replace(calendar=calendar)
        return dt.replace(m_second=ms, u_second=us, n_second=UInt16(ns))

    # @always_inline("nodebug")
    fn strftime(self, fmt: String) -> String:
        """Formats time into a `String`.

        Args:
            fmt: Format string.

        Returns:
            The formatted string.
        """

        return dt_str.strftime(
            fmt,
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.m_second,
            self.u_second,
        )

    # @always_inline("nodebug")
    fn __format__(self, fmt: String) -> String:
        """Format.

        Args:
            fmt: Format string.

        Returns:
            String.
        """
        return self.strftime(fmt)

    # @always_inline("nodebug")
    fn to_iso[iso: dt_str.IsoFormat = dt_str.IsoFormat()](self) -> String:
        """Return an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)
        compliant formatted `String` e.g. `IsoFormat.YYYY_MM_DD_T_MM_HH_TZD`
        -> `1970-01-01T00:00:00+00:00` .

        Parameters:
            iso: The IsoFormat.

        Returns:
            String.
        """

        var offset = self.tz.offset_at(self.year, self.month, self.day, self.hour, self.minute, self.second)
        return dt_str.to_iso[iso](
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            offset.to_iso(),
        )

    @staticmethod
    # @always_inline("nodebug")
    fn strptime(
        s: String,
        format_str: StringLiteral,
        tz: Optional[Self._tz] = None,
        calendar: Calendar = _calendar,
    ) -> Optional[Self]:
        """Parse a `DateTime` from a  `String`.

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
        return Self(
            p.year,
            p.month,
            p.day,
            p.hour,
            p.minute,
            p.second,
            p.m_second,
            p.u_second,
            p.n_second,
            zone,
            calendar,
        )

    @staticmethod
    # @always_inline("nodebug")
    fn from_iso[
        iso: dt_str.IsoFormat = dt_str.IsoFormat()
    ](s: String, tz: Optional[Self._tz] = None, calendar: Calendar = _calendar) -> Optional[Self]:
        """Construct a datetime from an
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

            var dt = Self(year, month, day, p[3], p[4], p[5], tz=p[6], calendar=calendar)
            if tz:
                var t = tz.value()
                if t != dt.tz:
                    return dt.to_utc().from_utc(t)
            return dt
        except:
            return None

    @staticmethod
    # @always_inline("nodebug")
    fn from_hash(
        value: Int,
        tz: Optional[Self._tz] = None,
        calendar: Calendar = _calendar,
    ) -> Self:
        """Construct a `DateTime` from a hash made by it.
        Nanoseconds are set to the calendar's minimum.

        Args:
            value: The value to parse.
            tz: The `TimeZone` to designate to the result.
            calendar: The Calendar to designate to the result.

        Returns:
            Self.
        """

        var zone = tz.value() if tz else Self._tz()
        var d = calendar.from_hash(value)
        var ns = calendar.min_nanosecond
        return Self(d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], ns, zone, calendar)
