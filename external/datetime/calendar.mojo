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
"""`Calendar` module."""

from utils import Variant

from ._lists import leapsecs

# TODO: other calendars besides Gregorian
alias PythonCalendar = Calendar()
"""The default Python proleptic Gregorian calendar, goes from [0001-01-01,
9999-12-31]."""
alias UTCCalendar = Calendar(Gregorian(min_year=1970))
"""The leap year and leap second aware UTC calendar, goes from [1970-01-01,
9999-12-31]."""
alias UTCFastCal = Calendar(UTCFast())
"""UTC calendar for the fast module. Leap day aware, goes from [1970-01-01,
9999-12-31]."""
alias _date = (UInt16, UInt8, UInt8, UInt8, UInt8, UInt8, UInt16, UInt16)
"""Alias for the date type. Up to microsecond resolution."""


@register_passable("trivial")
struct CalendarHashes:
    """Hashing definitions. Up to microsecond resolution for
    the 64bit hash. Each calendar implementation can still
    override with its own definitions."""

    alias UINT8 = 8
    """Hash width UINT8."""
    alias UINT16 = 16
    """Hash width UINT16."""
    alias UINT32 = 32
    """Hash width UINT32."""
    alias UINT64 = 64
    """Hash width UINT64."""
    var selected: Int
    """What hash width was selected."""

    alias _17b = 0b1_1111_1111_1111_1111
    alias _12b = 0b0_0000_1111_1111_1111
    alias _10b = 0b0_0000_0011_1111_1111
    alias _9b = 0b0_0000_0001_1111_1111
    alias _6b = 0b0_0000_0000_0011_1111
    alias _5b = 0b0_0000_0000_0001_1111
    alias _4b = 0b0_0000_0000_0000_1111
    alias _3b = 0b0_0000_0000_0000_0111
    alias _2b = 0b0_0000_0000_0000_0011

    alias shift_64_y = (5 + 5 + 5 + 6 + 6 + 10 + 10)
    """Up to 131_072 years in total (-1 numeric)."""
    alias shift_64_mon = (5 + 5 + 6 + 6 + 10 + 10)
    """Up to 32 months in total (-1 numeric)."""
    alias shift_64_d = (5 + 6 + 6 + 10 + 10)
    """Up to 32 days in total (-1 numeric)."""
    alias shift_64_h = (6 + 6 + 10 + 10)
    """Up to 32 hours in total (-1 numeric)."""
    alias shift_64_m = (6 + 10 + 10)
    """Up to 64 minutes in total (-1 numeric)."""
    alias shift_64_s = (10 + 10)
    """Up to 64 seconds in total (-1 numeric)."""
    alias shift_64_ms = 10
    """Up to 1024 m_seconds in total (-1 numeric)."""
    alias shift_64_us = 0
    """Up to 1024 u_seconds in total (-1 numeric)."""
    alias mask_64_y: UInt64 = CalendarHashes._17b
    alias mask_64_mon: UInt64 = CalendarHashes._5b
    alias mask_64_d: UInt64 = CalendarHashes._5b
    alias mask_64_h: UInt64 = CalendarHashes._5b
    alias mask_64_m: UInt64 = CalendarHashes._6b
    alias mask_64_s: UInt64 = CalendarHashes._6b
    alias mask_64_ms: UInt64 = CalendarHashes._10b
    alias mask_64_us: UInt64 = CalendarHashes._10b

    alias shift_32_y = (4 + 5 + 5 + 6)
    """Up to 4096 years in total (-1 numeric)."""
    alias shift_32_mon = (5 + 5 + 6)
    """Up to 16 months in total (-1 numeric)."""
    alias shift_32_d = (5 + 6)
    """Up to 32 days in total (-1 numeric)."""
    alias shift_32_h = 6
    """Up to 32 hours in total (-1 numeric)."""
    alias shift_32_m = 0
    """Up to 64 minutes in total (-1 numeric)."""
    alias mask_32_y: UInt32 = CalendarHashes._12b
    alias mask_32_mon: UInt32 = CalendarHashes._4b
    alias mask_32_d: UInt32 = CalendarHashes._5b
    alias mask_32_h: UInt32 = CalendarHashes._5b
    alias mask_32_m: UInt32 = CalendarHashes._6b

    alias shift_16_y = (9 + 5)
    """Up to 4 years in total (-1 numeric)."""
    alias shift_16_d = 5
    """Up to 512 days in total (-1 numeric)."""
    alias shift_16_h = 0
    """Up to 32 hours in total (-1 numeric)."""
    alias mask_16_y: UInt16 = CalendarHashes._2b
    alias mask_16_d: UInt16 = CalendarHashes._9b
    alias mask_16_h: UInt16 = CalendarHashes._5b

    alias shift_8_d = 5
    """Up to 8 days in total (-1 numeric)."""
    alias shift_8_h = 0
    """Up to 32 hours in total (-1 numeric)."""
    alias mask_8_d: UInt8 = CalendarHashes._3b
    alias mask_8_h: UInt8 = CalendarHashes._5b

    fn __init__(inout self, selected: Int = 64):
        """Construct a `CalendarHashes`.

        Args:
            selected: The selected hash bit width.
        """
        debug_assert(
            selected == self.UINT8 or selected == self.UINT16 or selected == self.UINT32 or selected == self.UINT64,
            "there is no such hash size",
        )
        self.selected = selected


# TODO: once traits with attributes and impl are ready Calendar will replace
# a bunch of this file
trait _Calendarized:
    fn __init__(
        inout self,
        *,
        min_year: UInt16,
        min_month: UInt8,
        min_day: UInt8,
        max_year: UInt16,
    ):
        ...

    fn from_year(self, year: UInt16) -> Self:
        ...

    fn is_leapyear(self, year: UInt16) -> Bool:
        ...

    fn is_leapsec(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> Bool:
        ...

    fn day_of_week(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        ...

    fn day_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        ...

    fn day_of_month(self, year: UInt16, day_of_year: UInt16) -> (UInt8, UInt8):
        ...

    fn max_second(self, year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8) -> UInt8:
        ...

    fn max_days_in_month(self, year: UInt16, month: UInt8) -> UInt8:
        ...

    fn monthrange(self, year: UInt16, month: UInt8) -> (UInt8, UInt8):
        ...

    fn leapsecs_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        ...

    fn leapdays_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        ...

    fn seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> UInt64:
        ...

    fn m_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
    ) -> UInt64:
        ...

    fn n_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> UInt64:
        ...

    fn hash[
        cal_hash: CalendarHashes
    ](
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> Int:
        ...

    fn from_hash[cal_hash: CalendarHashes](self, value: Int) -> _date:
        ...


@value
# @register_passable("trivial")
struct Calendar:
    """`Calendar` interface."""

    var max_year: UInt16
    """Maximum value of years."""
    var max_typical_days_in_year: UInt16
    """Maximum typical value of days in a year (no leaps)."""
    var max_possible_days_in_year: UInt16
    """Maximum possible value of days in a year (with leaps)."""
    var max_month: UInt8
    """Maximum value of months in a year."""
    var max_hour: UInt8
    """Maximum value of hours in a day."""
    var max_minute: UInt8
    """Maximum value of minutes in an hour."""
    var max_typical_second: UInt8
    """Maximum typical value of seconds in a minute (no leaps)."""
    var max_possible_second: UInt8
    """Maximum possible value of seconds in a minute (with leaps)."""
    var max_milisecond: UInt16
    """Maximum value of miliseconds in a second."""
    var max_microsecond: UInt16
    """Maximum value of microseconds in a second."""
    var max_nanosecond: UInt16
    """Maximum value of nanoseconds in a second."""
    var min_year: UInt16
    """Default minimum year in the calendar."""
    var min_month: UInt8
    """Default minimum month."""
    var min_day: UInt8
    """Default minimum day."""
    var min_hour: UInt8
    """Default minimum hour."""
    var min_minute: UInt8
    """Default minimum minute."""
    var min_second: UInt8
    """Default minimum second."""
    var min_milisecond: UInt16
    """Default minimum milisecond."""
    var min_microsecond: UInt16
    """Default minimum microsecond."""
    var min_nanosecond: UInt16
    """Default minimum nanosecond."""
    alias _monthdays = List[UInt8]()
    """An array with the amount of days each month contains without
    leap values. It's assumed that `len(monthdays) == max_month + 1`."""
    var _implementation: Variant[Gregorian, UTCFast]

    fn __init__[
        T: Variant[Gregorian, UTCFast] = Gregorian
    ](inout self, min_year: UInt16, min_month: UInt8 = 1, min_day: UInt8 = 1):
        """Get a Calendar with min_year=year.

        Parameters:
            T: The type of Calendar.

        Args:
            min_year: Calendar year start.
            min_month: Calendar month start.
            min_day: Calendar day start.
        """

        @parameter
        if T.isa[Gregorian]():
            self = Self(Gregorian(min_year=min_year, min_month=min_month, min_day=min_day))
        elif T.isa[UTCFast]():
            self = Self(UTCFast(min_year=min_year, min_month=min_month, min_day=min_day))
        else:
            constrained[False, "that implementation isn't valid"]()
            self = Self()

    fn __init__(inout self, owned impl: Variant[Gregorian, UTCFast] = Gregorian()):
        """Construct a `Calendar`.

        Args:
            impl: Calendar implementation.
        """

        if impl.isa[Gregorian]():
            var imp = impl.unsafe_take[Gregorian]()
            self.max_year = imp.max_year
            self.max_typical_days_in_year = imp.max_typical_days_in_year
            self.max_possible_days_in_year = imp.max_possible_days_in_year
            self.max_month = imp.max_month
            self.max_hour = imp.max_hour
            self.max_minute = imp.max_minute
            self.max_typical_second = imp.max_typical_second
            self.max_possible_second = imp.max_possible_second
            self.max_milisecond = imp.max_milisecond
            self.max_microsecond = imp.max_microsecond
            self.max_nanosecond = imp.max_nanosecond
            self.min_year = imp.min_year
            self.min_month = imp.min_month
            self.min_day = imp.min_day
            self.min_hour = imp.min_hour
            self.min_minute = imp.min_minute
            self.min_second = imp.min_second
            self.min_milisecond = imp.min_milisecond
            self.min_microsecond = imp.min_microsecond
            self.min_nanosecond = imp.min_nanosecond
            self._implementation = imp
        else:  # elif impl.isa[UTCFast]():
            var imp = impl.unsafe_take[UTCFast]()
            self.max_year = imp.max_year
            self.max_typical_days_in_year = imp.max_typical_days_in_year
            self.max_possible_days_in_year = imp.max_possible_days_in_year
            self.max_month = imp.max_month
            self.max_hour = imp.max_hour
            self.max_minute = imp.max_minute
            self.max_typical_second = imp.max_typical_second
            self.max_possible_second = imp.max_possible_second
            self.max_milisecond = imp.max_milisecond
            self.max_microsecond = imp.max_microsecond
            self.max_nanosecond = imp.max_nanosecond
            self.min_year = imp.min_year
            self.min_month = imp.min_month
            self.min_day = imp.min_day
            self.min_hour = imp.min_hour
            self.min_minute = imp.min_minute
            self.min_second = imp.min_second
            self.min_milisecond = imp.min_milisecond
            self.min_microsecond = imp.min_microsecond
            self.min_nanosecond = imp.min_nanosecond
            self._implementation = imp

    fn from_year(self, year: UInt16) -> Self:
        if self._implementation.isa[Gregorian]():
            return Self(Gregorian(min_year=year))
        elif self._implementation.isa[UTCFast]():
            return Self(UTCFast(min_year=year))
        else:
            constrained[False, "that implementation isn't valid"]()
            return Self()

    @always_inline("nodebug")
    fn day_of_week(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the day of the week for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            - day: Day of the week: [0, 6] (monday - sunday).
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].day_of_week(year, month, day)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].day_of_week(year, month, day)
        else:
            return 0

    @always_inline("nodebug")
    fn day_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        """Calculates the day of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            - day: Day of the year: [1, 366] (for gregorian calendar).
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].day_of_year(year, month, day)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].day_of_year(year, month, day)
        else:
            return 0

    @always_inline("nodebug")
    fn day_of_month(self, year: UInt16, day_of_year: UInt16) -> (UInt8, UInt8):
        """Calculates the month, day of the month for a given day of the year.

        Args:
            year: Year.
            day_of_year: The day of the year.

        Returns:
            - month: Month of the year: [1, 12] (for gregorian calendar).
            - day: Day of the month: [1, 31] (for gregorian calendar).
        """

        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].day_of_month(year, day_of_year)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].day_of_month(year, day_of_year)
        else:
            return UInt8(0), UInt8(0)

    @always_inline("nodebug")
    fn max_days_in_month(self, year: UInt16, month: UInt8) -> UInt8:
        """The maximum amount of days in a given month.

        Args:
            year: Year.
            month: Month.

        Returns:
            The amount of days.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].max_days_in_month(year, month)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].max_days_in_month(year, month)
        else:
            return 0

    @always_inline("nodebug")
    fn monthrange(self, year: UInt16, month: UInt8) -> (UInt8, UInt8):
        """Returns day of the week for the first day of the month and number of
        days in month, for the specified year and month.

        Args:
            year: Year.
            month: Month.

        Returns:
            - day_of_week: Day of the week.
            - day_of_month: Day of the month.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].monthrange(year, month)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].monthrange(year, month)
        else:
            return UInt8(0), UInt8(0)

    @always_inline("nodebug")
    fn max_second(self, year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8) -> UInt8:
        """The maximum amount of seconds in a minute (usually 59).

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.

        Returns:
            The amount.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].max_second(year, month, day, hour, minute)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].max_second(year, month, day, hour, minute)
        else:
            return 0

    @always_inline("nodebug")
    fn is_leapyear(self, year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].is_leapyear(year)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].is_leapyear(year)
        else:
            return 0

    @always_inline("nodebug")
    fn is_leapsec(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> Bool:
        """Whether the second is a leap second.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            Bool.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].is_leapsec(year, month, day, hour, minute, second)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].is_leapsec(year, month, day, hour, minute, second)
        else:
            return 0

    @always_inline("nodebug")
    fn leapsecs_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative leap seconds since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].leapsecs_since_epoch(year, month, day)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].leapsecs_since_epoch(year, month, day)
        else:
            return 0

    @always_inline("nodebug")
    fn leapdays_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative leap days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """

        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].leapdays_since_epoch(year, month, day)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].leapdays_since_epoch(year, month, day)
        else:
            return 0

    @always_inline("nodebug")
    fn seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            The amount.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].seconds_since_epoch(
                year, month, day, hour, minute, second
            )
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].seconds_since_epoch(
                year, month, day, hour, minute, second
            )
        else:
            return 0

    @always_inline("nodebug")
    fn m_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
    ) -> UInt64:
        """Miliseconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: Milisecond.

        Returns:
            The amount.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].m_seconds_since_epoch(
                year, month, day, hour, minute, second, m_second
            )
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].m_seconds_since_epoch(
                year, month, day, hour, minute, second, m_second
            )
        else:
            return 0

    @always_inline("nodebug")
    fn n_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> UInt64:
        """Nanoseconds since the begining of the calendar's epoch.
        Can only represent up to ~ 580 years since epoch start.

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

        Returns:
            The amount.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].n_seconds_since_epoch(
                year,
                month,
                day,
                hour,
                minute,
                second,
                m_second,
                u_second,
                n_second,
            )
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].n_seconds_since_epoch(
                year,
                month,
                day,
                hour,
                minute,
                second,
                m_second,
                u_second,
                n_second,
            )
        else:
            return 0

    @always_inline("nodebug")
    fn hash[
        cal_hash: CalendarHashes = CalendarHashes()
    ](
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8 = 0,
        minute: UInt8 = 0,
        second: UInt8 = 0,
        m_second: UInt16 = 0,
        u_second: UInt16 = 0,
        n_second: UInt16 = 0,
    ) -> Int:
        """Hash the given values according to the calendar's bitshifted
        component lengths, BigEndian (i.e. yyyymmdd...).

        Parameters:
            cal_hash: The hashing schema (CalendarHashes).

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

        Returns:
            The hash.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].hash[cal_hash](
                year,
                month,
                day,
                hour,
                minute,
                second,
                m_second,
                u_second,
                n_second,
            )
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].hash[cal_hash](
                year,
                month,
                day,
                hour,
                minute,
                second,
                m_second,
                u_second,
                n_second,
            )
        else:
            return 0

    @always_inline("nodebug")
    fn from_hash[cal_hash: CalendarHashes = CalendarHashes()](self, value: Int) -> _date:
        """Build a date from a hashed value.

        Parameters:
            cal_hash: The hashing schema (CalendarHashes).

        Args:
            value: The Hash.

        Returns:
            Tuple containing date data.
        """
        if self._implementation.isa[Gregorian]():
            return self._implementation.unsafe_get[Gregorian]()[].from_hash[cal_hash](value)
        elif self._implementation.isa[UTCFast]():
            return self._implementation.unsafe_get[UTCFast]()[].from_hash[cal_hash](value)
        else:
            return _date(0, 0, 0, 0, 0, 0, 0, 0)


@value
# @register_passable("trivial")
struct Gregorian(_Calendarized):
    """`Gregorian` Calendar."""

    var max_year: UInt16
    """Maximum value of years."""
    alias max_typical_days_in_year: UInt16 = 365
    """Maximum typical value of days in a year (no leaps)."""
    alias max_possible_days_in_year: UInt16 = 366
    """Maximum possible value of days in a year (with leaps)."""
    alias max_month: UInt8 = 12
    """Maximum value of months in a year."""
    alias max_hour: UInt8 = 23
    """Maximum value of hours in a day."""
    alias max_minute: UInt8 = 59
    """Maximum value of minutes in an hour."""
    alias max_typical_second: UInt8 = 59
    """Maximum typical value of seconds in a minute (no leaps)."""
    alias max_possible_second: UInt8 = 60
    """Maximum possible value of seconds in a minute (with leaps)."""
    alias max_milisecond: UInt16 = 999
    """Maximum value of miliseconds in a second."""
    alias max_microsecond: UInt16 = 999
    """Maximum value of microseconds in a second."""
    alias max_nanosecond: UInt16 = 999
    """Maximum value of nanoseconds in a second."""
    var min_year: UInt16
    """Default minimum year in the calendar."""
    var min_month: UInt8
    """Default minimum month."""
    var min_day: UInt8
    """Default minimum day."""
    alias min_hour: UInt8 = 0
    """Default minimum hour."""
    alias min_minute: UInt8 = 0
    """Default minimum minute."""
    alias min_second: UInt8 = 0
    """Default minimum second."""
    alias min_milisecond: UInt16 = 0
    """Default minimum milisecond."""
    alias min_microsecond: UInt16 = 0
    """Default minimum microsecond."""
    alias min_nanosecond: UInt16 = 0
    """Default minimum nanosecond."""
    alias _monthdays: List[UInt8] = List[UInt8](0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
    """An array with the amount of days each month contains without
    leap values. It's assumed that `len(monthdays) == max_month + 1`.
    And that the first month is 1."""
    alias _days_before_month: List[UInt16] = List[UInt16](0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)

    fn __init__(
        inout self,
        *,
        min_year: UInt16 = 1,
        min_month: UInt8 = 1,
        min_day: UInt8 = 1,
        max_year: UInt16 = 9999,
    ):
        """Construct a `Gregorian` Calendar from values.

        Args:
            min_year: Min year (epoch start).
            min_month: Min month (epoch start).
            min_day: Min day (epoch start).
            max_year: Max year (epoch end).
        """
        self.max_year = max_year
        self.min_month = min_month
        self.min_day = min_day
        self.min_year = min_year

    fn from_year(self, year: UInt16) -> Self:
        return Self(min_year=year)

    fn monthrange(self, year: UInt16, month: UInt8) -> (UInt8, UInt8):
        """Returns day of the week for the first day of the month and number of
        days in month, for the specified year and month.

        Args:
            year: Year.
            month: Month.

        Returns:
            - day_of_week: Day of the week.
            - day_of_month: Day of the month.
        """

        return self.day_of_week(year, month, 1), self.max_days_in_month(year, month)

    @always_inline("nodebug")
    fn max_second(self, year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8) -> UInt8:
        """The maximum amount of seconds that a minute lasts (usually 59).
        Some years its 60 when a leap second is added. The spec also lists
        the posibility of 58 seconds but it stil hasn't ben done.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.

        Returns:
            The amount.
        """
        if self.is_leapsec(year, month, day, hour, minute, 59):
            return 60
        return 59

    @always_inline("nodebug")
    fn max_days_in_month(self, year: UInt16, month: UInt8) -> UInt8:
        """The maximum amount of days in a given month.

        Args:
            year: Year.
            month: Month.

        Returns:
            The amount of days.
        """

        var days = Self._monthdays[int(month)]
        if month == 2 and Self.is_leapyear(year):
            return days + 1
        return days

    @always_inline("nodebug")
    fn day_of_week(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the day of the week for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            - day: Day of the week: [0, 6] (monday - sunday).
        """

        var days = int(self.day_of_year(year, month, day))
        var y = int(year - 1)
        var days_before_year = y * 365 + y // 4 - y // 100 + y // 400
        return (days_before_year + days + 6) % 7

    @always_inline("nodebug")
    fn day_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        """Calculates the day of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            - day: Day of the year: [1, 366] (for gregorian calendar).
        """

        var total: UInt16 = 1 if month > 2 and self.is_leapyear(year) else 0
        total += Self._days_before_month[int(month)].cast[DType.uint16]()
        return total + day.cast[DType.uint16]()

    @always_inline("nodebug")
    fn day_of_month(self, year: UInt16, day_of_year: UInt16) -> (UInt8, UInt8):
        """Calculates the month, day of the month for a given day of the year.

        Args:
            year: Year.
            day_of_year: The day of the year.

        Returns:
            - month: Month of the year: [1, 12] (for gregorian calendar).
            - day: Day of the month: [1, 31] (for gregorian calendar).
        """

        var idx: UInt8 = 0
        for i in range(1, 13):
            if Self._days_before_month[i] > day_of_year:
                break
            idx += 1
        var rest = (day_of_year - Self._days_before_month[int(idx)])
        if idx > 2 and Self.is_leapyear(year):
            rest -= 1
        return idx, rest.cast[DType.uint8]()

    @always_inline("nodebug")
    fn is_leapyear(self, year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """

        return Self.is_leapyear(year)

    fn is_leapsec(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> Bool:
        """Whether the second is a leap second.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            Bool.
        """

        if hour == 23 and minute == 59 and second == 59 and (month == 6 or month == 12) and (day == 30 or day == 31):
            alias calh32 = CalendarHashes(CalendarHashes.UINT32)
            var h: UInt32 = self.hash[calh32](year, month, day)
            for i in range(len(leapsecs)):
                if h == leapsecs[i]:
                    return True
            return False
        return False

    fn leapsecs_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative leap seconds since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """

        if year < 1972:
            return 0
        var size = len(leapsecs)
        alias calh32 = CalendarHashes(CalendarHashes.UINT32)
        var h: UInt32 = self.hash[calh32](year, month, day)
        if h > leapsecs[size - 1]:
            return size
        var amnt = 0
        for i in range(size):
            if h < leapsecs[i]:
                return amnt
            amnt += 1
        return size

    fn leapdays_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative leap days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """

        var leapdays: UInt32 = 0
        for i in range(self.min_year, year):
            if Self.is_leapyear(i):
                leapdays += 1
        if Self.is_leapyear(year) and month >= 2:
            if not (month == 2 and day != 29):
                leapdays += 1
        return leapdays

    fn seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> UInt64:
        """Seconds since the begining of the calendar's epoch.
        Takes leap seconds added to UTC up to the given datetime into
        account.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            The amount.
        """
        alias min_to_sec: UInt64 = 60
        alias hours_to_sec: UInt64 = 60 * min_to_sec
        alias days_to_sec: UInt64 = 24 * hours_to_sec
        alias years_to_sec: UInt64 = 365 * days_to_sec

        var leaps = int(self.leapsecs_since_epoch(year, month, day))
        var leapdays = int(self.leapdays_since_epoch(year, self.min_month, self.min_day))
        var y_d = (int(year - self.min_year) * 365 + leapdays) * days_to_sec
        var doy = self.day_of_year(year, month, day).cast[DType.uint64]()
        var d_d = (doy - int(self.min_day)) * days_to_sec
        var h_d = (hour - self.min_hour).cast[DType.uint64]() * hours_to_sec
        var min_d = (minute - self.min_minute).cast[DType.uint64]() * min_to_sec
        var s_d = (second - self.min_second).cast[DType.uint64]()
        return y_d + d_d + h_d + min_d + s_d + leaps

    fn m_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
    ) -> UInt64:
        """Miliseconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: Milisecond.

        Returns:
            The amount.
        """
        alias sec_to_mili = 1000
        alias min_to_mili = 60 * sec_to_mili
        alias hours_to_mili = 60 * min_to_mili
        alias days_to_mili = 24 * hours_to_mili

        var leapsecs = int(self.leapsecs_since_epoch(year, month, day))
        var leapdays = int(self.leapdays_since_epoch(year, self.min_month, self.min_day))
        var y_d = (int(year - self.min_year) * 365 + leapdays) * days_to_mili
        var doy = self.day_of_year(year, month, day).cast[DType.uint64]()
        var d_d = (doy - int(self.min_day)) * days_to_mili
        var h_d = (hour - self.min_hour).cast[DType.uint64]() * hours_to_mili
        var min_d = (minute - self.min_minute).cast[DType.uint64]() * min_to_mili
        var s_d = (second - self.min_second).cast[DType.uint64]() * sec_to_mili
        var m_sec = (m_second - self.min_milisecond).cast[DType.uint64]()
        return m_sec + y_d + d_d + h_d + min_d + s_d + leapsecs

    fn n_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> UInt64:
        """Nanoseconds since the begining of the calendar's epoch.
        unsafe_Takes leap seconds added to UTC up to the given datetime into
        account. Can only represent up to ~ 580 years since epoch start.

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

        Returns:
            The amount.
        """
        alias sec_to_nano = 1_000_000_000
        alias min_to_nano = 60 * sec_to_nano
        alias hours_to_nano = 60 * min_to_nano
        alias days_to_nano = 24 * hours_to_nano

        var leapsecs = int(self.leapsecs_since_epoch(year, month, day))
        var leapdays = int(self.leapdays_since_epoch(year, self.min_month, self.min_day))
        var y_d = (int(year - self.min_year) * 365 + leapdays) * days_to_nano
        var doy = self.day_of_year(year, month, day).cast[DType.uint64]()
        var d_d = (doy - int(self.min_day)) * days_to_nano
        var h_d = (hour - self.min_hour).cast[DType.uint64]() * hours_to_nano
        var min_d = (minute - self.min_minute).cast[DType.uint64]() * min_to_nano
        var s_d = (second - self.min_second).cast[DType.uint64]() * sec_to_nano
        var ms_d = (m_second - self.min_milisecond).cast[DType.uint64]() * 1_000_000
        var us_d = (u_second - UInt16(self.min_microsecond)).cast[DType.uint64]() * 1_000
        var ns_d = (n_second - UInt16(self.min_nanosecond)).cast[DType.uint64]()
        return y_d + d_d + h_d + min_d + s_d + ms_d + us_d + ns_d + leapsecs

    @always_inline("nodebug")
    fn hash[
        cal_h: CalendarHashes = CalendarHashes()
    ](
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8 = 0,
        minute: UInt8 = 0,
        second: UInt8 = 0,
        m_second: UInt16 = 0,
        u_second: UInt16 = 0,
        n_second: UInt16 = 0,
    ) -> Int:
        """Hash the given values according to the calendar's bitshifted
        component lengths, BigEndian (i.e. yyyymmdd...).

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

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

        Returns:
            The hash.
        """

        _ = self, n_second
        var result: Int = 0

        @parameter
        if cal_h.selected == cal_h.UINT8:
            pass
        elif cal_h.selected == cal_h.UINT16:
            pass
        elif cal_h.selected == cal_h.UINT32:  # hash for `Date`
            result = (int(year) << (5 + 5)) | (int(month) << 5) | int(day)
        elif cal_h.selected == cal_h.UINT64:  # hash for `DateTime`
            result = (
                (int(year) << cal_h.shift_64_y)
                | (int(month) << cal_h.shift_64_mon)
                | (int(day) << cal_h.shift_64_d)
                | (int(hour) << cal_h.shift_64_h)
                | (int(minute) << cal_h.shift_64_m)
                | (int(second) << cal_h.shift_64_s)
                | (int(m_second) << cal_h.shift_64_ms)
                | (int(u_second) << cal_h.shift_64_us)
            )
        return result

    @always_inline("nodebug")
    fn from_hash[cal_h: CalendarHashes = CalendarHashes()](self, value: Int) -> _date:
        """Build a date from a hashed value.

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

        Args:
            value: The Hash.

        Returns:
            Tuple containing date data.
        """
        _ = self
        var num8 = UInt8(0)
        var num16 = UInt16(0)
        var result = (num16, num8, num8, num8, num8, num8, num16, num16)

        @parameter
        if cal_h.selected == cal_h.UINT8:
            pass
        elif cal_h.selected == cal_h.UINT16:
            pass
        elif cal_h.selected == cal_h.UINT32:  # hash for `Date`
            result[0] = int(value >> (5 + 5))
            result[1] = int((value >> 5) & 0b1_1111)
            result[2] = int(value & 0b1_1111)
        elif cal_h.selected == cal_h.UINT64:  # hash for `DateTime`
            result[0] = int((value >> cal_h.shift_64_y) & cal_h.mask_64_y)
            result[1] = int((value >> cal_h.shift_64_mon) & cal_h.mask_64_mon)
            result[2] = int((value >> cal_h.shift_64_d) & cal_h.mask_64_d)
            result[3] = int((value >> cal_h.shift_64_h) & cal_h.mask_64_h)
            result[4] = int((value >> cal_h.shift_64_m) & cal_h.mask_64_m)
            result[5] = int((value >> cal_h.shift_64_s) & cal_h.mask_64_s)
            result[6] = int((value >> cal_h.shift_64_ms) & cal_h.mask_64_ms)
            result[7] = int((value >> cal_h.shift_64_us) & cal_h.mask_64_us)
        return result^

    @staticmethod
    @always_inline("nodebug")
    fn is_leapyear(year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """

        return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


@value
# @register_passable("trivial")
struct UTCFast(_Calendarized):
    """`UTCFast` Calendar."""

    var max_year: UInt16
    """Maximum value of years."""
    alias max_typical_days_in_year: UInt16 = 365
    """Maximum typical value of days in a year (no leaps)."""
    alias max_possible_days_in_year: UInt16 = 365
    """Maximum possible value of days in a year (with leaps)."""
    alias max_month: UInt8 = 12
    """Maximum value of months in a year."""
    alias max_hour: UInt8 = 23
    """Maximum value of hours in a day."""
    alias max_minute: UInt8 = 59
    """Maximum value of minutes in an hour."""
    alias max_typical_second: UInt8 = 59
    """Maximum typical value of seconds in a minute (no leaps)."""
    alias max_possible_second: UInt8 = 59
    """Maximum possible value of seconds in a minute (with leaps)."""
    alias max_milisecond: UInt16 = 999
    """Maximum value of miliseconds in a second."""
    alias max_microsecond: UInt16 = 999
    """Maximum value of microseconds in a second."""
    alias max_nanosecond: UInt16 = 999
    """Maximum value of nanoseconds in a second."""
    var min_year: UInt16
    """Default minimum year in the calendar."""
    var min_month: UInt8
    """Default minimum month."""
    var min_day: UInt8
    """Default minimum day."""
    alias min_hour: UInt8 = 0
    """Default minimum hour."""
    alias min_minute: UInt8 = 0
    """Default minimum minute."""
    alias min_second: UInt8 = 0
    """Default minimum second."""
    alias min_milisecond: UInt16 = 0
    """Default minimum milisecond."""
    alias min_microsecond: UInt16 = 0
    """Default minimum microsecond."""
    alias min_nanosecond: UInt16 = 0
    """Default minimum nanosecond."""
    alias _monthdays: List[UInt8] = List[UInt8](0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
    """An array with the amount of days each month contains without
    leap values. It's assumed that `len(monthdays) == max_month + 1`.
    And that the first month is 1."""
    alias _days_before_month: List[UInt16] = List[UInt16](0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)

    fn __init__(
        inout self,
        *,
        min_year: UInt16 = 1970,
        min_month: UInt8 = 1,
        min_day: UInt8 = 1,
        max_year: UInt16 = 9999,
    ):
        """Construct a `UTCFast` Calendar from values.

        Args:
            min_year: Min year (epoch start).
            min_month: Min month (epoch start).
            min_day: Min day (epoch start).
            max_year: Max year (epoch end).
        """
        self.max_year = max_year
        self.min_month = min_month
        self.min_day = min_day
        self.min_year = min_year

    fn from_year(self, year: UInt16) -> Self:
        return Self(min_year=year)

    fn monthrange(self, year: UInt16, month: UInt8) -> (UInt8, UInt8):
        """Returns day of the week for the first day of the month and number of
        days in month, for the specified year and month.

        Args:
            year: Year.
            month: Month.

        Returns:
            - day_of_week: Day of the week.
            - day_of_month: Day of the month.
        """

        return self.day_of_week(year, month, 1), self._monthdays[int(month)]

    @always_inline("nodebug")
    fn max_second(self, year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8) -> UInt8:
        """The maximum amount of seconds in a minute (usually 59).

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.

        Returns:
            The amount.
        """

        _ = self, year, month, day, hour, minute
        return 59

    @always_inline("nodebug")
    fn max_days_in_month(self, year: UInt16, month: UInt8) -> UInt8:
        """The maximum amount of days in a given month.

        Args:
            year: Year.
            month: Month.

        Returns:
            The amount of days.
        """

        _ = self, year
        return Self._days_before_month[int(month)].cast[DType.uint8]()

    @always_inline("nodebug")
    fn day_of_week(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the day of the week for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            - day: Day of the week: [0, 6] (monday - sunday).
        """

        var days = int(self.day_of_year(year, month, day))
        var y = int(year - 1)
        var days_before_year = y * 365 + y // 4 - y // 100 + y // 400
        return (days_before_year + days + 6) % 7

    @always_inline("nodebug")
    fn day_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        """Calculates the day of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            - day: Day of the year: [1, 366] (for gregorian calendar).
        """

        var total: UInt16 = 1 if month > 2 and self.is_leapyear(year) else 0
        total += Self._days_before_month[int(month)].cast[DType.uint16]()
        return total + day.cast[DType.uint16]()

    @always_inline("nodebug")
    fn day_of_month(self, year: UInt16, day_of_year: UInt16) -> (UInt8, UInt8):
        """Calculates the month, day of the month for a given day of the year.

        Args:
            year: Year.
            day_of_year: The day of the year.

        Returns:
            - month: Month of the year: [1, 12] (for gregorian calendar).
            - day: Day of the month: [1, 31] (for gregorian calendar).
        """

        var idx: UInt8 = 0
        for i in range(1, 13):
            if Self._days_before_month[i] > day_of_year:
                break
            idx += 1
        var rest = (day_of_year - Self._days_before_month[int(idx)])
        if idx > 2 and Self.is_leapyear(year):
            rest -= 1
        return idx, rest.cast[DType.uint8]()

    @always_inline("nodebug")
    fn is_leapyear(self, year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """

        return Self.is_leapyear(year)

    @always_inline("nodebug")
    fn is_leapsec(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> Bool:
        """Whether the second is a leap second.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            Bool.
        """

        _ = self, year, month, day, hour, minute, second
        return False

    @always_inline("nodebug")
    fn leapsecs_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative leap seconds since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """

        _ = self, year, month, day
        return 0

    @always_inline("nodebug")
    fn leapdays_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative leap days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """

        var leapdays: UInt32 = 0
        for i in range(self.min_year, year):
            if Self.is_leapyear(i):
                leapdays += 1
        if Self.is_leapyear(year) and month >= 2:
            if not (month == 2 and day != 29):
                leapdays += 1
        return leapdays

    fn seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            The amount.
        """

        alias min_to_sec = 60
        alias hours_to_sec = 60 * min_to_sec
        alias days_to_sec = 24 * hours_to_sec

        var leapdays = int(self.leapdays_since_epoch(year, self.min_month, self.min_day))
        var y = int((year - self.min_year) * 365 + leapdays) * days_to_sec
        var doy = int(self.day_of_year(year, month, day))
        var d_d = (doy - int(self.min_day)) * days_to_sec
        var h_d = int(hour - self.min_hour) * hours_to_sec
        var min_d = int(minute - self.min_minute) * min_to_sec
        var s_d = int(second - self.min_second)
        return y + d_d + h_d + min_d + s_d

    fn m_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
    ) -> UInt64:
        """Miliseconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: Milisecond.

        Returns:
            The amount.
        """

        alias sec_to_mili = 1000
        alias min_to_mili = 60 * sec_to_mili
        alias hours_to_mili = 60 * min_to_mili
        alias days_to_mili = 24 * hours_to_mili

        var leapdays = int(self.leapdays_since_epoch(year, self.min_month, self.min_day))
        var y = (int(year - self.min_year) * 365 + leapdays) * days_to_mili
        var doy = self.day_of_year(year, month, day).cast[DType.uint64]()
        var d_d = (doy - int(self.min_day)) * days_to_mili
        var h_d = (hour - self.min_hour).cast[DType.uint64]() * hours_to_mili
        var min_d = (minute - self.min_minute).cast[DType.uint64]() * min_to_mili
        var s_d = (second - self.min_second).cast[DType.uint64]() * sec_to_mili
        var ms_d = (m_second - self.min_milisecond).cast[DType.uint64]()
        return y + d_d + h_d + min_d + s_d + ms_d

    fn n_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> UInt64:
        """Nanoseconds since the begining of the calendar's epoch.
        Assumes every year has 365 days and all months have 30 days.
        Can only represent up to ~ 580 years since epoch start.

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

        Returns:
            The amount.
        """

        alias sec_to_nano = 1_000_000_000
        alias min_to_nano = 60 * sec_to_nano
        alias hours_to_nano = 60 * min_to_nano
        alias days_to_nano = 24 * hours_to_nano

        var leapdays = int(self.leapdays_since_epoch(year, self.min_month, self.min_day))
        var y = (int(year - self.min_year) * 365 + leapdays) * days_to_nano
        var doy = self.day_of_year(year, month, day).cast[DType.uint64]()
        var d_d = (doy - int(self.min_day)) * days_to_nano
        var h_d = (hour - self.min_hour).cast[DType.uint64]() * hours_to_nano
        var min_d = (minute - self.min_minute).cast[DType.uint64]() * min_to_nano
        var s_d = (second - self.min_second).cast[DType.uint64]() * sec_to_nano
        var ms_d = (m_second - self.min_milisecond).cast[DType.uint64]() * 1_000_000
        var us_d = (u_second - self.min_microsecond).cast[DType.uint64]() * 1_000
        var ns_d = (n_second - self.min_nanosecond).cast[DType.uint64]()
        return y + d_d + h_d + min_d + s_d + ms_d + us_d + ns_d

    @always_inline("nodebug")
    fn hash[
        cal_h: CalendarHashes = CalendarHashes()
    ](
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8 = 0,
        minute: UInt8 = 0,
        second: UInt8 = 0,
        m_second: UInt16 = 0,
        u_second: UInt16 = 0,
        n_second: UInt16 = 0,
    ) -> Int:
        """Hash the given values according to the calendar's bitshifted
        component lengths, BigEndian (i.e. yyyymmdd...).

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

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

        Returns:
            The hash.
        """

        _ = self, u_second, n_second
        var result: Int = 0

        @parameter
        if cal_h.selected == cal_h.UINT8:
            result = (int(day) << cal_h.shift_8_d) | (int(hour) << cal_h.shift_8_h)
        elif cal_h.selected == cal_h.UINT16:
            result = (
                (int(year) << cal_h.shift_16_y)
                | (int(self.day_of_year(year, month, day)) << cal_h.shift_16_d)
                | (int(hour) << cal_h.shift_16_h)
            )
        elif cal_h.selected == cal_h.UINT32:
            result = (
                (int(year) << cal_h.shift_32_y)
                | (int(month) << cal_h.shift_32_mon)
                | (int(day) << cal_h.shift_32_d)
                | (int(hour) << cal_h.shift_32_h)
                | (int(minute) << cal_h.shift_32_m)
            )
        elif cal_h.selected == cal_h.UINT64:
            result = (
                (int(year) << (cal_h.shift_64_y - cal_h.shift_64_ms))
                | (int(month) << (cal_h.shift_64_mon - cal_h.shift_64_ms))
                | (int(day) << (cal_h.shift_64_d - cal_h.shift_64_ms))
                | (int(hour) << (cal_h.shift_64_h - cal_h.shift_64_ms))
                | (int(minute) << (cal_h.shift_64_m - cal_h.shift_64_ms))
                | (int(second) << (cal_h.shift_64_s - cal_h.shift_64_ms))
                | int(m_second)
            )
        return result

    @always_inline("nodebug")
    fn from_hash[cal_h: CalendarHashes = CalendarHashes()](self, value: Int) -> _date:
        """Build a date from a hashed value.

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

        Args:
            value: The Hash.

        Returns:
            Tuple containing date data.
        """
        _ = self
        var num8 = UInt8(0)
        var num16 = UInt16(0)
        var result = (num16, num8, num8, num8, num8, num8, num16, num16)

        @parameter
        if cal_h.selected == cal_h.UINT8:
            result[2] = int((value >> cal_h.shift_8_d) & cal_h.mask_8_d)
            result[3] = int((value >> cal_h.shift_8_h) & cal_h.mask_8_h)
        elif cal_h.selected == cal_h.UINT16:
            result[0] = int((value >> cal_h.shift_16_y) & cal_h.mask_16_y)
            var doy = int((value >> cal_h.shift_16_d) & cal_h.mask_16_d)
            var res = self.day_of_month(result[0], doy)
            result[1] = res[0]
            result[2] = res[1]
            result[3] = int((value >> cal_h.shift_16_h) & cal_h.mask_16_h)
        elif cal_h.selected == cal_h.UINT32:
            result[0] = int((value >> cal_h.shift_32_y) & cal_h.mask_32_y)
            result[1] = int((value >> cal_h.shift_32_mon) & cal_h.mask_32_mon)
            result[2] = int((value >> cal_h.shift_32_d) & cal_h.mask_32_d)
            result[3] = int((value >> cal_h.shift_32_h) & cal_h.mask_32_h)
            result[4] = int((value >> cal_h.shift_32_m) & cal_h.mask_32_m)
        elif cal_h.selected == cal_h.UINT64:
            result[0] = int((value >> (cal_h.shift_64_y - cal_h.shift_64_ms)) & cal_h.mask_64_y)
            result[1] = int((value >> (cal_h.shift_64_mon - cal_h.shift_64_ms)) & cal_h.mask_64_mon)
            result[2] = int((value >> (cal_h.shift_64_d - cal_h.shift_64_ms)) & cal_h.mask_64_d)
            result[3] = int((value >> (cal_h.shift_64_h - cal_h.shift_64_ms)) & cal_h.mask_64_h)
            result[4] = int((value >> (cal_h.shift_64_m - cal_h.shift_64_ms)) & cal_h.mask_64_m)
            result[5] = int((value >> (cal_h.shift_64_s - cal_h.shift_64_ms)) & cal_h.mask_64_s)
            result[6] = int(value & cal_h.mask_64_ms)
        return result^

    @staticmethod
    @always_inline("nodebug")
    fn is_leapyear(year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """

        return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
