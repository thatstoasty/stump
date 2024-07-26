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
"""Fast implementations of `DateTime` module. All assume no leap seconds.

- `DateTime64`:
    - This is a "normal" `DateTime` with milisecond resolution.
- `DateTime32`:
    - This is a "normal" `DateTime` with minute resolution.
- `DateTime16`:
    - This is a `DateTime` with hour resolution, it can be used as a
    year, dayofyear, hour representation.
- `DateTime8`:
    - This is a `DateTime` with hour resolution, it can be used as a
    dayofweek, hour representation.
- Notes:
    - The caveats of each implementation are better explained in
    each struct's docstrings.
"""
from time import time
from collections.optional import Optional

from .calendar import UTCFastCal, CalendarHashes
import .dt_str

alias _cal = UTCFastCal
alias _cal_h64 = CalendarHashes(CalendarHashes.UINT64)
alias _cal_h32 = CalendarHashes(CalendarHashes.UINT32)
alias _cal_h16 = CalendarHashes(CalendarHashes.UINT16)
alias _cal_h8 = CalendarHashes(CalendarHashes.UINT8)


trait _IntCollect(Intable, CollectionElement):
    ...


# @value
@register_passable("trivial")
struct DateTime64(Hashable, Stringable):
    """Fast `DateTime64` struct. This is a "normal"
    `DateTime` with milisecond resolution. Uses
    UTCFastCal epoch [1970-01-01, 9999-12-31] and other
    params at build time. Assumes all instances have
    the same timezone and epoch and that there are no
    leap seconds.

    - Hash Resolution:
        - year: Up to year 134_217_728 in total (-1 numeric).
        - month: Up to month 32 in total (-1 numeric).
        - day: Up to day 32 in total (-1 numeric).
        - hour: Up to hour 32 in total (-1 numeric).
        - minute: Up to minute 64 in total (-1 numeric).
        - second: Up to second 64 in total (-1 numeric).
        - m_second: Up to m_second 1024 in total (-1 numeric).

    - Milisecond Resolution (Gregorian as reference):
        - year: Up to year 584_942_417 since calendar epoch.

    - Notes:
        - Once methods that alter the underlying m_seconds
            are used, the hash and binary operations thereof
            shouldn't be used since they are invalid.
    """

    var m_seconds: UInt64
    """Miliseconds since epoch."""
    var hash: UInt64
    """Hash."""

    fn __init__(inout self, m_seconds: UInt64, hash_val: UInt64):
        """Construct a DateTime64.

        Args:
            m_seconds: The miliseconds.
            hash_val: The hash.
        """

        self.m_seconds = m_seconds
        self.hash = hash_val

    fn __init__[
        T1: _IntCollect = Int,
        T2: _IntCollect = Int,
        T3: _IntCollect = Int,
        T4: _IntCollect = Int,
        T5: _IntCollect = Int,
        T6: _IntCollect = Int,
        T7: _IntCollect = Int,
    ](
        inout self,
        owned year: Optional[T1] = None,
        owned month: Optional[T2] = None,
        owned day: Optional[T3] = None,
        owned hour: Optional[T4] = None,
        owned minute: Optional[T5] = None,
        owned second: Optional[T6] = None,
        owned m_second: Optional[T7] = None,
        owned hash_val: Optional[UInt64] = None,
    ):
        """Construct a `DateTime64` from valid values.
        UTCCalendar is the default.

        Parameters:
            T1: Any type that is Intable and CollectionElement.
            T2: Any type that is Intable and CollectionElement.
            T3: Any type that is Intable and CollectionElement.
            T4: Any type that is Intable and CollectionElement.
            T5: Any type that is Intable and CollectionElement.
            T6: Any type that is Intable and CollectionElement.
            T7: Any type that is Intable and CollectionElement.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: M_second.
            hash_val: Hash_val.
        """

        var y = int(year.take()) if year else int(_cal.min_year)
        var mon = int(month.take()) if month else int(_cal.min_month)
        var d = int(day.take()) if day else int(_cal.min_day)
        var h = int(hour.take()) if hour else int(_cal.min_hour)
        var m = int(minute.take()) if minute else int(_cal.min_minute)
        var s = int(second.take()) if second else int(_cal.min_second)
        var ms = int(m_second.take()) if m_second else int(_cal.min_milisecond)
        self.m_seconds = _cal.m_seconds_since_epoch(y, mon, d, h, m, s, ms)
        self.hash = int(hash_val.take()) if hash_val else int(_cal.hash[_cal_h64](y, mon, d, h, m, s, ms))

    # @always_inline("nodebug")
    fn __getattr__[name: StringLiteral](self) -> UInt64:
        """Get the attribute.

        Parameters:
            name: The name of the attribute.

        Returns:
            The attribute value assuming the hash is valid.
        """

        @parameter
        if name == "year":
            return (self.hash >> (_cal_h64.shift_64_y - _cal_h64.shift_64_ms)) & _cal_h64.mask_64_y
        elif name == "month":
            return (self.hash >> (_cal_h64.shift_64_mon - _cal_h64.shift_64_ms)) & _cal_h64.mask_64_mon
        elif name == "day":
            return (self.hash >> (_cal_h64.shift_64_d - _cal_h64.shift_64_ms)) & _cal_h64.mask_64_d
        elif name == "hour":
            return (self.hash >> (_cal_h64.shift_64_h - _cal_h64.shift_64_ms)) & _cal_h64.mask_64_h
        elif name == "minute":
            return (self.hash >> (_cal_h64.shift_64_m - _cal_h64.shift_64_ms)) & _cal_h64.mask_64_m
        elif name == "second":
            return (self.hash >> (_cal_h64.shift_64_s - _cal_h64.shift_64_ms)) & _cal_h64.mask_64_s
        elif name == "m_second":
            return (self.hash >> (_cal_h64.shift_64_ms - _cal_h64.shift_64_ms)) & _cal_h64.mask_64_ms
        else:
            constrained[False, "that attr does not exist"]()
            return 0

    # @always_inline
    fn replace(
        owned self,
        *,
        owned year: Optional[Int] = None,
        owned month: Optional[Int] = None,
        owned day: Optional[Int] = None,
        owned hour: Optional[Int] = None,
        owned minute: Optional[Int] = None,
        owned second: Optional[Int] = None,
        owned m_second: Optional[Int] = None,
    ) -> Self:
        """Replace values inside the hash.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: M_second.

        Returns:
            Self.
        """
        var mask: UInt64 = 0b0
        alias offset = _cal_h64.shift_64_ms
        if year:
            mask |= _cal_h64.mask_64_y << (_cal_h64.shift_64_y - offset)
        if month:
            mask |= _cal_h64.mask_64_mon << (_cal_h64.shift_64_mon - offset)
        if day:
            mask |= _cal_h64.mask_64_d << (_cal_h64.shift_64_d - offset)
        if hour:
            mask |= _cal_h64.mask_64_h << (_cal_h64.shift_64_h - offset)
        if minute:
            mask |= _cal_h64.mask_64_m << (_cal_h64.shift_64_m - offset)
        if second:
            mask |= _cal_h64.mask_64_s << (_cal_h64.shift_64_s - offset)
        if m_second:
            mask |= _cal_h64.mask_64_ms << (_cal_h64.shift_64_ms - offset)
        var h = _cal.hash[_cal_h64](
            year.or_else(0),
            month.or_else(0),
            day.or_else(0),
            hour.or_else(0),
            minute.or_else(0),
            second.or_else(0),
            m_second.or_else(0),
        )
        self.hash = (self.hash & ~mask) | h
        return self

    # @always_inline("nodebug")
    fn seconds_since_epoch(self) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Returns:
            Seconds since epoch.
        """
        return self.m_seconds // 1000

    # @always_inline("nodebug")
    fn m_seconds_since_epoch(self) -> UInt64:
        """Miliseconds since the begining of the calendar's epoch.

        Returns:
            Miliseconds since epoch.
        """
        return self.m_seconds

    # @always_inline("nodebug")
    fn __add__(owned self, owned other: Self) -> Self:
        """Add.

        Args:
            other: Other.

        Returns:
            Self.
        """
        self.m_seconds += other.m_seconds
        return self

    # @always_inline("nodebug")
    fn __sub__(owned self, owned other: Self) -> Self:
        """Subtract.

        Args:
            other: Other.

        Returns:
            Self.
        """
        self.m_seconds -= other.m_seconds
        return self

    # @always_inline("nodebug")
    fn __iadd__(inout self, owned other: Self):
        """Add Immediate.

        Args:
            other: Other.
        """
        self.m_seconds += other.m_seconds

    # @always_inline("nodebug")
    fn __isub__(inout self, owned other: Self):
        """Subtract Immediate.

        Args:
            other: Other.
        """
        self.m_seconds -= other.m_seconds

    # @always_inline("nodebug")
    fn __hash__(self) -> UInt:
        """Hash.

        Returns:
            Result.
        """
        return int(self.hash)

    # @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        """Eq.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.m_seconds == other.m_seconds

    # @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Bool:
        """Ne.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.m_seconds != other.m_seconds

    # @always_inline("nodebug")
    fn __gt__(self, other: Self) -> Bool:
        """Gt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.m_seconds > other.m_seconds

    # @always_inline("nodebug")
    fn __ge__(self, other: Self) -> Bool:
        """Ge.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.m_seconds >= other.m_seconds

    # @always_inline("nodebug")
    fn __le__(self, other: Self) -> Bool:
        """Le.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.m_seconds <= other.m_seconds

    # @always_inline("nodebug")
    fn __lt__(self, other: Self) -> Bool:
        """Lt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.m_seconds < other.m_seconds

    # @always_inline("nodebug")
    fn __invert__(self) -> Self:
        """Invert.

        Returns:
            An instance of self with inverted hash.
        """
        return Self(m_seconds=self.m_seconds, hash_val=~self.hash)

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
        return self.hash & hash(other)

    # @always_inline("nodebug")
    fn __or__[T: Hashable](self, other: T) -> UInt64:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash | hash(other)

    # @always_inline("nodebug")
    fn __xor__[T: Hashable](self, other: T) -> UInt64:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash ^ hash(other)

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

    # @always_inline("nodebug")
    fn add(
        owned self,
        years: Int = 0,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
        m_seconds: Int = 0,
    ) -> Self:
        """Add to self.

        Args:
            years: Years.
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.
            m_seconds: Miliseconds.

        Returns:
            Self.
        """

        self.m_seconds += ((((years * 365 + days) * 24 + hours) * 60 + minutes) * 60 + seconds) * 1000 + m_seconds
        return self

    # @always_inline("nodebug")
    fn subtract(
        owned self,
        years: Int = 0,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
        m_seconds: Int = 0,
    ) -> Self:
        """Subtract from self.

        Args:
            years: Years.
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.
            m_seconds: Miliseconds.

        Returns:
            Self.
        """

        self.m_seconds -= ((((years * 365 + days) * 24 + hours) * 60 + minutes) * 60 + seconds) * 1000 + m_seconds
        return self

    @staticmethod
    # @always_inline("nodebug")
    fn from_unix_epoch(seconds: Int) -> Self:
        """Construct a `DateTime64` from the seconds since the Unix Epoch
        1970-01-01.

        Args:
            seconds: Seconds.

        Returns:
            Self.

        Notes:
            This builds an instance with a hash set to default UTC epoch start.
        """
        return Self().add(seconds=seconds)

    @staticmethod
    # @always_inline("nodebug")
    fn now() -> Self:
        """Construct a `DateTime64` from `time.now()`.

        Returns:
            Self.

        Notes:
            This builds an instance with a hash set to default UTC epoch start.
        """
        var ms = time.now() // 1_000_000
        var s = ms // 1_000
        return Self.from_unix_epoch(s).add(m_seconds=ms)

    # @always_inline("nodebug")
    fn to_iso[iso: dt_str.IsoFormat = dt_str.IsoFormat()](self) -> String:
        """Return an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)
        compliant `String` e.g. `IsoFormat.YYYY_MM_DD_T_MM_HH_SS`.
        -> `1970-01-01T00:00:00` .

        Parameters:
            iso: The `IsoFormat`.

        Returns:
            String.

        Notes:
            This is done assuming the current hash is valid.
        """

        var d = _cal.from_hash[_cal_h64](int(self.hash))
        return dt_str.to_iso[iso](d[0], d[1], d[2], d[3], d[4], d[5])

    @staticmethod
    # @always_inline("nodebug")
    fn from_iso[
        iso: dt_str.IsoFormat = dt_str.IsoFormat(),
    ](s: String) -> Optional[Self]:
        """Construct a `DateTime64` from an
        [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601) compliant
        `String`.

        Parameters:
            iso: The `IsoFormat` to parse.

        Args:
            s: The `String` to parse; it's assumed that it is properly formatted
                i.e. no leading whitespaces or anything different to the selected
                IsoFormat.

        Returns:
            An Optional[Self].
        """
        try:
            var p = dt_str.from_iso[iso, iana=False, pyzoneinfo=False, native=False](s)
            var dt = Self(p[0], p[1], p[2], p[3], p[4], p[5])
            return dt
        except:
            return None

    @staticmethod
    # @always_inline("nodebug")
    fn from_hash(value: UInt64) -> Self:
        """Construct a `DateTime64` from a hash made by it.

        Args:
            value: The hash.

        Returns:
            Self.
        """
        var d = _cal.from_hash[_cal_h64](int(value))
        return Self(d[0], d[1], d[2], d[3], d[4], d[5], d[6], hash_val=value)


# @value
@register_passable("trivial")
struct DateTime32(Hashable, Stringable):
    """Fast `DateTime32 ` struct. This is a "normal" `DateTime`
    with minute resolution. Uses UTCFastCal epoch
    [1970-01-01, 9999-12-31] and other params at build time.
    Assumes all instances have the same timezone and epoch
    and that there are no leap seconds.

    - Hash Resolution:
        - year: Up to year 4_096 in total (-1 numeric).
        - month: Up to month 16 in total (-1 numeric).
        - day: Up to day 32 in total (-1 numeric).
        - hour: Up to hour 32 in total (-1 numeric).
        - minute: Up to minute 64 in total (-1 numeric).

    - Minute Resolution (Gregorian as reference):
        - year: Up to year 8_171 since calendar epoch.

    - Notes:
        - Once methods that alter the underlying minutes
            are used, the hash and binary operations thereof
            shouldn't be used since they are invalid.
    """

    var minutes: UInt32
    """Minutes since epoch."""
    var hash: UInt32
    """Hash."""

    fn __init__(inout self, minutes: UInt32, hash_val: UInt32):
        """Construct a DateTime32.

        Args:
            minutes: The minutes.
            hash_val: The hash.
        """

        self.minutes = minutes
        self.hash = hash_val

    fn __init__[
        T1: _IntCollect = Int,
        T2: _IntCollect = Int,
        T3: _IntCollect = Int,
        T4: _IntCollect = Int,
        T5: _IntCollect = Int,
        T6: _IntCollect = Int,
        T7: _IntCollect = Int,
    ](
        inout self,
        owned year: Optional[T1] = None,
        owned month: Optional[T2] = None,
        owned day: Optional[T3] = None,
        owned hour: Optional[T4] = None,
        owned minute: Optional[T5] = None,
        owned hash_val: Optional[UInt32] = None,
    ):
        """Construct a `DateTime32` from valid values.
        UTCCalendar is the default.

        Parameters:
            T1: Any type that is Intable and CollectionElement.
            T2: Any type that is Intable and CollectionElement.
            T3: Any type that is Intable and CollectionElement.
            T4: Any type that is Intable and CollectionElement.
            T5: Any type that is Intable and CollectionElement.
            T6: Any type that is Intable and CollectionElement.
            T7: Any type that is Intable and CollectionElement.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            hash_val: Hash_val.
        """
        var y = int(year.take()) if year else int(_cal.min_year)
        var mon = int(month.take()) if month else int(_cal.min_month)
        var d = int(day.take()) if day else int(_cal.min_day)
        var h = int(hour.take()) if hour else int(_cal.min_hour)
        var m = int(minute.take()) if minute else int(_cal.min_minute)
        self.minutes = (_cal.seconds_since_epoch(y, mon, d, h, m, int(_cal.min_second)) // 60).cast[DType.uint32]()
        self.hash = int(hash_val.take()) if hash_val else int(_cal.hash[_cal_h32](y, mon, d, h, m))

    # @always_inline("nodebug")
    fn __getattr__[name: StringLiteral](self) -> UInt32:
        """Get the attribute.

        Parameters:
            name: The name of the attribute.

        Returns:
            The attribute value assuming the hash is valid.
        """

        @parameter
        if name == "year":
            return (self.hash >> _cal_h32.shift_32_y) & _cal_h32.mask_32_y
        elif name == "month":
            return (self.hash >> _cal_h32.shift_32_mon) & _cal_h32.mask_32_mon
        elif name == "day":
            return (self.hash >> _cal_h32.shift_32_d) & _cal_h32.mask_32_d
        elif name == "hour":
            return (self.hash >> _cal_h32.shift_32_h) & _cal_h32.mask_32_h
        elif name == "minute":
            return (self.hash >> _cal_h32.shift_32_m) & _cal_h32.mask_32_m
        else:
            constrained[False, "that attr does not exist"]()
            return 0

    # @always_inline("nodebug")
    fn seconds_since_epoch(self) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Returns:
            Seconds since epoch.
        """
        return self.minutes.cast[DType.uint64]() * 60

    # @always_inline
    fn replace(
        owned self,
        *,
        owned year: Optional[Int] = None,
        owned month: Optional[Int] = None,
        owned day: Optional[Int] = None,
        owned hour: Optional[Int] = None,
        owned minute: Optional[Int] = None,
    ) -> Self:
        """Replace values inside the hash.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.

        Returns:
            Self.
        """

        var mask: UInt32 = 0b0
        if year:
            mask |= _cal_h32.mask_32_y << _cal_h32.shift_32_y
        if month:
            mask |= _cal_h32.mask_32_mon << _cal_h32.shift_32_mon
        if day:
            mask |= _cal_h32.mask_32_d << _cal_h32.shift_32_d
        if hour:
            mask |= _cal_h32.mask_32_h << _cal_h32.shift_32_h
        if minute:
            mask |= _cal_h32.mask_32_m << _cal_h32.shift_32_m
        var h = _cal.hash[_cal_h32](
            year.or_else(0),
            month.or_else(0),
            day.or_else(0),
            hour.or_else(0),
            minute.or_else(0),
        )
        self.hash = (self.hash & ~mask) | h
        return self

    # @always_inline("nodebug")
    fn __add__(owned self, owned other: Self) -> Self:
        """Add.

        Args:
            other: Other.

        Returns:
            Self.
        """
        self.minutes += other.minutes
        return self

    # @always_inline("nodebug")
    fn __sub__(owned self, owned other: Self) -> Self:
        """Subtract.

        Args:
            other: Other.

        Returns:
            Self.
        """
        self.minutes -= other.minutes
        return self

    # @always_inline("nodebug")
    fn __iadd__(inout self, owned other: Self):
        """Add Immediate.

        Args:
            other: Other.
        """
        self.minutes += other.minutes

    # @always_inline("nodebug")
    fn __isub__(inout self, owned other: Self):
        """Subtract Immediate.

        Args:
            other: Other.
        """
        self.minutes -= other.minutes

    # @always_inline("nodebug")
    fn __hash__(self) -> UInt:
        """Hash.

        Returns:
            Result.
        """
        return int(self.hash)

    # @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        """Eq.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.minutes == other.minutes

    # @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Bool:
        """Ne.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.minutes != other.minutes

    # @always_inline("nodebug")
    fn __gt__(self, other: Self) -> Bool:
        """Gt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.minutes > other.minutes

    # @always_inline("nodebug")
    fn __ge__(self, other: Self) -> Bool:
        """Ge.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.minutes >= other.minutes

    # @always_inline("nodebug")
    fn __le__(self, other: Self) -> Bool:
        """Le.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.minutes <= other.minutes

    # @always_inline("nodebug")
    fn __lt__(self, other: Self) -> Bool:
        """Lt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.minutes < other.minutes

    # @always_inline("nodebug")
    fn __invert__(self) -> Self:
        """Invert.

        Returns:
            An instance of self with inverted hash.
        """
        return Self(minutes=self.minutes, hash_val=~self.hash)

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
        return self.hash & hash(other)

    # @always_inline("nodebug")
    fn __or__[T: Hashable](self, other: T) -> UInt32:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash | hash(other)

    # @always_inline("nodebug")
    fn __xor__[T: Hashable](self, other: T) -> UInt32:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash ^ hash(other)

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

    # @always_inline("nodebug")
    fn add(
        owned self,
        years: Int = 0,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
    ) -> Self:
        """Add to self.

        Args:
            years: Years.
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.

        Returns:
            Self.
        """

        self.minutes += (((years * 365 + days) * 24 + hours) * 60 + minutes) + seconds // 60
        return self

    # @always_inline("nodebug")
    fn subtract(
        owned self,
        years: Int = 0,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
    ) -> Self:
        """Subtract from self.

        Args:
            years: Years.
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.

        Returns:
            Self.
        """

        self.minutes -= (((years * 365 + days) * 24 + hours) * 60 + minutes) + seconds // 60
        return self

    @staticmethod
    # @always_inline("nodebug")
    fn from_unix_epoch(seconds: Int) -> Self:
        """Construct a `DateTime32` from the seconds since the Unix Epoch
        1970-01-01.

        Args:
            seconds: Seconds.

        Returns:
            Self.

        Notes:
            This builds an instance with a hash set to default UTC epoch start.
        """
        return Self().add(seconds=seconds)

    @staticmethod
    # @always_inline("nodebug")
    fn now() -> Self:
        """Construct a `DateTime32` from `time.now()`.

        Returns:
            Self.

        Notes:
            This builds an instance with a hash set to default UTC epoch start.
        """
        return Self.from_unix_epoch(time.now() // 1_000_000_000)

    # @always_inline("nodebug")
    fn to_iso[iso: dt_str.IsoFormat = dt_str.IsoFormat()](self) -> String:
        """Return an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)
        compliant `String` e.g. `IsoFormat.YYYY_MM_DD_T_MM_HH_SS`.
        -> `1970-01-01T00:00:00` .

        Parameters:
            iso: The `IsoFormat`.

        Returns:
            String.

        Notes:
            This is done assuming the current hash is valid.
        """

        var d = _cal.from_hash[_cal_h32](int(self.hash))
        return dt_str.to_iso[iso](d[0], d[1], d[2], d[3], d[4], d[5])

    @staticmethod
    # @always_inline("nodebug")
    fn from_iso[
        iso: dt_str.IsoFormat = dt_str.IsoFormat(),
    ](s: String) -> Optional[Self]:
        """Construct a `DateTime32` time from an
        [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601) compliant
        `String`.

        Parameters:
            iso: The `IsoFormat` to parse.

        Args:
            s: The `String` to parse; it's assumed that it is properly formatted
                i.e. no leading whitespaces or anything different to the selected
                IsoFormat.

        Returns:
            An Optional[Self].
        """
        try:
            var p = dt_str.from_iso[iso, iana=False, pyzoneinfo=False, native=False](s)
            var dt = Self(p[0], p[1], p[2], p[3], p[4])
            return dt
        except:
            return None

    @staticmethod
    # @always_inline("nodebug")
    fn from_hash(value: UInt32) -> Self:
        """Construct a `DateTime32` from a hash made by it.

        Args:
            value: The hash.

        Returns:
            Self.
        """
        var d = _cal.from_hash[_cal_h32](int(value))
        return Self(d[0], d[1], d[2], d[3], d[4], value)


# @value
@register_passable("trivial")
struct DateTime16(Hashable, Stringable):
    """Fast `DateTime16` struct. This is a `DateTime` with
    hour resolution, it can be used as a year, dayofyear,
    hour representation. Uses UTCFastCal epoch
    [1970-01-01, 9999-12-31] and other params at build time.
    Assumes all instances have the same timezone and epoch
    and that there are no leap seconds.

    - Hash Resolution:
        year: Up to year 4 in total (-1 numeric).
        day: Up to day 512 in total (-1 numeric).
        hour: Up to hour 32 in total (-1 numeric).

    - Hour Resolution (Gregorian as reference):
        - year: Up to year 7 since calendar epoch.

    - Notes:
        - Once methods that alter the underlying m_seconds
            are used, the hash and binary operations thereof
            shouldn't be used since they are invalid.
    """

    var hours: UInt16
    """Hours since epoch."""
    var hash: UInt16
    """Hash."""

    fn __init__(inout self, hours: UInt16, hash_val: UInt16):
        """Construct a DateTime16.

        Args:
            hours: The hours.
            hash_val: The hash.
        """

        self.hours = hours
        self.hash = hash_val

    fn __init__[
        T1: _IntCollect = Int,
        T2: _IntCollect = Int,
        T3: _IntCollect = Int,
        T4: _IntCollect = Int,
    ](
        inout self,
        owned year: Optional[T1] = None,
        owned month: Optional[T2] = None,
        owned day: Optional[T3] = None,
        owned hour: Optional[T4] = None,
        owned hash_val: Optional[UInt16] = None,
    ):
        """Construct a `DateTime16` from valid values.
        UTCCalendar is the default.

        Parameters:
            T1: Any type that is Intable and CollectionElement.
            T2: Any type that is Intable and CollectionElement.
            T3: Any type that is Intable and CollectionElement.
            T4: Any type that is Intable and CollectionElement.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            hash_val: Hash_val.
        """
        var y = int(year.take()) if year else int(_cal.min_year)
        var mon = int(month.take()) if month else int(_cal.min_month)
        var d = int(day.take()) if day else int(_cal.min_day)
        var h = int(hour.take()) if hour else int(_cal.min_hour)
        var m = int(_cal.min_minute)
        var s = int(_cal.min_second)
        self.hours = int(_cal.seconds_since_epoch(y, mon, d, h, m, s) // (60 * 60))
        self.hash = int(hash_val.take()) if hash_val else int(_cal.hash[_cal_h16](y - _cal.min_year, mon, d, h, m, s))

    # @always_inline("nodebug")
    fn __getattr__[name: StringLiteral](self) -> UInt16:
        """Get the attribute.

        Parameters:
            name: The name of the attribute.

        Returns:
            The attribute value assuming the hash is valid.
        """

        @parameter
        if name == "year":
            return (self.hash >> _cal_h16.shift_16_y) & _cal_h16.mask_16_y + _cal.min_year
        elif name == "day":
            return (self.hash >> _cal_h16.shift_16_d) & _cal_h16.mask_16_d
        elif name == "hour":
            return (self.hash >> _cal_h16.shift_16_h) & _cal_h16.mask_16_h
        else:
            constrained[False, "that attribute does not exist"]()
            return 0

    # @always_inline
    fn replace(
        owned self,
        *,
        owned year: Optional[Int] = None,
        owned day: Optional[Int] = None,
        owned hour: Optional[Int] = None,
    ) -> Self:
        """Replace values inside the hash.

        Args:
            year: Year.
            day: Day.
            hour: Hour.

        Returns:
            Self.
        """

        var mask: UInt16 = 0b0
        if year:
            mask |= _cal_h16.mask_16_d << _cal_h16.shift_16_d
        if day:
            mask |= _cal_h16.mask_16_d << _cal_h16.shift_16_d
        if hour:
            mask |= _cal_h16.mask_16_h << _cal_h16.shift_16_h
        var h = _cal.hash[_cal_h16](
            (year.value() - _cal.min_year if year else 0),
            day.or_else(0),
            hour.or_else(0),
        )
        self.hash = (self.hash & ~mask) | h
        return self

    # @always_inline
    fn seconds_since_epoch(self) -> UInt32:
        """Seconds since the begining of the calendar's epoch.

        Returns:
            Seconds.
        """
        return self.hours.cast[DType.uint32]() * 60 * 60

    # @always_inline("nodebug")
    fn __add__(owned self, owned other: Self) -> Self:
        """Add.

        Args:
            other: Other.

        Returns:
            Self.
        """
        self.hours += other.hours
        return self

    # @always_inline("nodebug")
    fn __sub__(owned self, owned other: Self) -> Self:
        """Subtract.

        Args:
            other: Other.

        Returns:
            Self.
        """
        self.hours -= other.hours
        return self

    # @always_inline("nodebug")
    fn __iadd__(inout self, owned other: Self):
        """Add Immediate.

        Args:
            other: Other.
        """
        self.hours += other.hours

    # @always_inline("nodebug")
    fn __isub__(inout self, owned other: Self):
        """Subtract Immediate.

        Args:
            other: Other.
        """
        self.hours -= other.hours

    # @always_inline("nodebug")
    fn __hash__(self) -> UInt:
        """Hash.

        Returns:
            Result.
        """
        return int(self.hash)

    # @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        """Eq.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours == other.hours

    # @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Bool:
        """Ne.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours != other.hours

    # @always_inline("nodebug")
    fn __gt__(self, other: Self) -> Bool:
        """Gt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours > other.hours

    # @always_inline("nodebug")
    fn __ge__(self, other: Self) -> Bool:
        """Ge.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours >= other.hours

    # @always_inline("nodebug")
    fn __le__(self, other: Self) -> Bool:
        """Le.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours <= other.hours

    # @always_inline("nodebug")
    fn __lt__(self, other: Self) -> Bool:
        """Lt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours < other.hours

    # @always_inline("nodebug")
    fn __invert__(self) -> Self:
        """Invert.

        Returns:
            An instance of self with inverted hash.
        """
        return Self(hours=self.hours, hash_val=~self.hash)

    # @always_inline("nodebug")
    fn __and__[T: Hashable](self, other: T) -> UInt16:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash & hash(other)

    # @always_inline("nodebug")
    fn __or__[T: Hashable](self, other: T) -> UInt16:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash | hash(other)

    # @always_inline("nodebug")
    fn __xor__[T: Hashable](self, other: T) -> UInt16:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash ^ hash(other)

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

    # @always_inline("nodebug")
    fn add(
        owned self,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
    ) -> Self:
        """Add to self.

        Args:
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.

        Returns:
            Self.
        """

        self.hours += days * 24 + hours + minutes // 60 + seconds // (60 * 60)
        return self

    # @always_inline("nodebug")
    fn subtract(
        owned self,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
    ) -> Self:
        """Subtract from self.

        Args:
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.

        Returns:
            Self.
        """

        self.hours -= days * 24 + hours + minutes // 60 + seconds // (60 * 60)
        return self

    @staticmethod
    # @always_inline("nodebug")
    fn from_unix_epoch(seconds: Int) -> Self:
        """Construct a `DateTime16` from the seconds since the Unix Epoch
        1970-01-01.

        Args:
            seconds: Seconds.

        Returns:
            Self.

        Notes:
            This builds an instance with a hash set to default UTC epoch start.
        """
        return Self().add(seconds=seconds)

    @staticmethod
    # @always_inline("nodebug")
    fn now() -> Self:
        """Construct a `DateTime16` from `time.now()`.

        Returns:
            Self.

        Notes:
            This builds an instance with a hash set to default UTC epoch start.
        """
        return Self.from_unix_epoch(time.now() // 1_000_000_000)

    # @always_inline("nodebug")
    fn to_iso[iso: dt_str.IsoFormat = dt_str.IsoFormat()](self) -> String:
        """Return an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)
        compliant `String` e.g. `IsoFormat.YYYY_MM_DD_T_MM_HH_SS`.
        -> `1970-01-01T00:00:00` .

        Parameters:
            iso: The `IsoFormat`.

        Returns:
            String.

        Notes:
            This is done assuming the current hash is valid.
        """

        var d = _cal.from_hash[_cal_h16](int(self.hash))
        var y = d[0] + _cal.min_year
        return dt_str.to_iso[iso](y, d[1], d[2], d[3], d[4], d[5])

    @staticmethod
    # @always_inline("nodebug")
    fn from_iso[
        iso: dt_str.IsoFormat = dt_str.IsoFormat(),
    ](s: String) -> Optional[Self]:
        """Construct a `DateTime16` time from an
        [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601) compliant
        `String`.

        Parameters:
            iso: The `IsoFormat` to parse.

        Args:
            s: The `String` to parse; it's assumed that it is properly formatted
                i.e. no leading whitespaces or anything different to the selected
                IsoFormat.

        Returns:
            An Optional[Self].
        """
        try:
            var p = dt_str.from_iso[iso, iana=False, pyzoneinfo=False, native=False](s)
            var dt = Self(p[0], p[1], p[2], p[3])
            return dt
        except:
            return None

    @staticmethod
    # @always_inline("nodebug")
    fn from_hash(value: UInt16) -> Self:
        """Construct a `DateTime16` from a hash made by it.

        Args:
            value: The hash.

        Returns:
            Self.
        """
        var d = _cal.from_hash[_cal_h16](int(value))
        var y = d[0] + _cal.min_year
        return Self(year=y, month=d[1], day=d[2], hour=d[3], hash_val=value)


# @value
@register_passable("trivial")
struct DateTime8(Hashable, Stringable):
    """Fast `DateTime8` struct. This is a `DateTime`
    with hour resolution, it can be used as a dayofweek,
    hour representation. Uses UTCFastCal epoch
    [1970-01-01, 9999-12-31] and other params at build time.
    Assumes all instances have the same timezone and epoch
    and that there are no leap seconds.

    - Hash Resolution:
        - day: Up to day 8 in total (-1 numeric).
        - hour: Up to hour 32 in total (-1 numeric).

    - Hour Resolution (Gregorian as reference):
        - hour: Up to hour 256 (~ 10 days) since calendar epoch.

    - Notes:
        - Once methods that alter the underlying m_seconds
            are used, the hash and binary operations thereof
            shouldn't be used since they are invalid.
    """

    var hours: UInt8
    """Hours since epoch."""
    var hash: UInt8
    """Hash."""

    fn __init__(inout self, hours: UInt8, hash_val: UInt8):
        """Construct a DateTime8.

        Args:
            hours: The hours.
            hash_val: The hash.
        """

        self.hours = hours
        self.hash = hash_val

    fn __init__[
        T1: _IntCollect = Int,
        T2: _IntCollect = Int,
        T3: _IntCollect = Int,
        T4: _IntCollect = Int,
    ](
        inout self,
        owned year: Optional[T1] = None,
        owned month: Optional[T2] = None,
        owned day: Optional[T3] = None,
        owned hour: Optional[T4] = None,
        owned hash_val: Optional[UInt8] = None,
    ):
        """Construct a `DateTime8` from valid values.
        UTCCalendar is the default.

        Parameters:
            T1: Any type that is Intable and CollectionElement.
            T2: Any type that is Intable and CollectionElement.
            T3: Any type that is Intable and CollectionElement.
            T4: Any type that is Intable and CollectionElement.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            hash_val: Hash_val.
        """
        var y = int(year.take()) if year else int(_cal.min_year)
        var mon = int(month.take()) if month else int(_cal.min_month)
        var d = int(day.take()) if day else int(_cal.min_day)
        var h = int(hour.take()) if hour else int(_cal.min_hour)
        var m = int(_cal.min_minute)
        var s = int(_cal.min_second)
        self.hours = (_cal.seconds_since_epoch(y, mon, d, h, m, s) // (60 * 60)).cast[DType.uint8]()
        self.hash = int(hash_val.take()) if hash_val else int(_cal.hash[_cal_h8](y, mon, d, h, m, s))

    # @always_inline("nodebug")
    fn __getattr__[name: StringLiteral](self) -> UInt8:
        """Get the attribute.

        Parameters:
            name: The name of the attribute.

        Returns:
            The attribute value assuming the hash is valid.
        """

        @parameter
        if name == "day":
            return (self.hash >> _cal_h8.shift_8_d) & _cal_h8.mask_8_d
        elif name == "hour":
            return (self.hash >> _cal_h8.shift_8_h) & _cal_h8.mask_8_h
        else:
            constrained[False, "that attr does not exist"]()
            return 0

    # @always_inline
    fn replace(
        owned self,
        *,
        owned day: Optional[Int] = None,
        owned hour: Optional[Int] = None,
    ) -> Self:
        """Replace values inside the hash.

        Args:
            day: Day.
            hour: Hour.

        Returns:
            Self.
        """

        var mask: UInt8 = 0b0
        if day:
            mask |= _cal_h8.mask_8_d << _cal_h8.shift_8_d
        if hour:
            mask |= _cal_h8.mask_8_h << _cal_h8.shift_8_h
        var h = _cal.hash[_cal_h8](
            0,
            day.or_else(0),
            hour.or_else(0),
        )
        self.hash = (self.hash & ~mask) | h
        return self

    # @always_inline("nodebug")
    fn seconds_since_epoch(self) -> UInt16:
        """Seconds since the begining of the calendar's epoch.

        Returns:
            Seconds.
        """
        return self.hour.cast[DType.uint16]() * 60 * 60

    # @always_inline("nodebug")
    fn __add__(owned self, owned other: Self) -> Self:
        """Add.

        Args:
            other: Other.

        Returns:
            Self.
        """
        self.hours += other.hours
        return self

    # @always_inline("nodebug")
    fn __sub__(owned self, owned other: Self) -> Self:
        """Subtract.

        Args:
            other: Other.

        Returns:
            Self.
        """
        self.hours -= other.hours
        return self

    # @always_inline("nodebug")
    fn __iadd__(inout self, owned other: Self):
        """Add Immediate.

        Args:
            other: Other.
        """
        self.hours += other.hours

    # @always_inline("nodebug")
    fn __isub__(inout self, owned other: Self):
        """Subtract Immediate.

        Args:
            other: Other.
        """
        self.hours -= other.hours

    # @always_inline("nodebug")
    fn __hash__(self) -> UInt:
        """Hash.

        Returns:
            Result.
        """
        return int(self.hash)

    # @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        """Eq.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours == other.hours

    # @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Bool:
        """Ne.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours != other.hours

    # @always_inline("nodebug")
    fn __gt__(self, other: Self) -> Bool:
        """Gt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours > other.hours

    # @always_inline("nodebug")
    fn __ge__(self, other: Self) -> Bool:
        """Ge.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours >= other.hours

    # @always_inline("nodebug")
    fn __le__(self, other: Self) -> Bool:
        """Le.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours <= other.hours

    # @always_inline("nodebug")
    fn __lt__(self, other: Self) -> Bool:
        """Lt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.hours < other.hours

    # @always_inline("nodebug")
    fn __invert__(self) -> Self:
        """Invert.

        Returns:
            An instance of self with inverted hash.
        """
        return Self(hours=self.hours, hash_val=~self.hash)

    # @always_inline("nodebug")
    fn __and__[T: Hashable](self, other: T) -> UInt8:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash & hash(other)

    # @always_inline("nodebug")
    fn __or__[T: Hashable](self, other: T) -> UInt8:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash | hash(other)

    # @always_inline("nodebug")
    fn __xor__[T: Hashable](self, other: T) -> UInt8:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.hash ^ hash(other)

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

    # @always_inline("nodebug")
    fn add(
        owned self,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
    ) -> Self:
        """Add to self.

        Args:
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.

        Returns:
            Self.
        """

        self.hours += days * 24 + hours + minutes // 60 + seconds // (60 * 60)
        return self

    # @always_inline("nodebug")
    fn subtract(
        owned self,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
    ) -> Self:
        """Subtract from self.

        Args:
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.

        Returns:
            Self.
        """

        self.hours -= days * 24 + hours + minutes // 60 + seconds // (60 * 60)
        return self

    @staticmethod
    # @always_inline("nodebug")
    fn from_unix_epoch(seconds: Int) -> Self:
        """Construct a `DateTime8` from the seconds since the Unix Epoch
        1970-01-01.

        Args:
            seconds: Seconds.

        Returns:
            Self.

        Notes:
            This builds an instance with a hash set to default UTC epoch start.
        """
        return Self().add(seconds=seconds)

    @staticmethod
    # @always_inline("nodebug")
    fn now() -> Self:
        """Construct a `DateTime8` from `time.now()`.

        Returns:
            Self.

        Notes:
            This builds an instance with a hash set to default UTC epoch start.
        """
        return Self.from_unix_epoch(time.now() // 1_000_000_000)

    # @always_inline("nodebug")
    fn to_iso[iso: dt_str.IsoFormat = dt_str.IsoFormat()](self) -> String:
        """Return an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)
        compliant `String` e.g. `IsoFormat.YYYY_MM_DD_T_MM_HH_SS`.
        -> `1970-01-01T00:00:00` .

        Parameters:
            iso: The `IsoFormat`.

        Returns:
            String.

        Notes:
            This is done assuming the current hash is valid.
        """

        var s = dt_str.to_iso[iso](1970, 1, self.day, self.hour, 0, 0)
        return s

    @staticmethod
    # @always_inline("nodebug")
    fn from_iso[
        iso: dt_str.IsoFormat = dt_str.IsoFormat(),
    ](s: String) -> Optional[Self]:
        """Construct a `DateTime8` time from an
        [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601) compliant
        `String`.

        Parameters:
            iso: The `IsoFormat` to parse.

        Args:
            s: The `String` to parse; it's assumed that it is properly formatted
                i.e. no leading whitespaces or anything different to the
                selected IsoFormat.

        Returns:
            An Optional[Self].
        """

        try:
            var p = dt_str.from_iso[iso, iana=False, pyzoneinfo=False, native=False](s)
            var dt = Self(p[0], p[1], p[2], p[3])
            return dt
        except:
            return None

    @staticmethod
    # @always_inline("nodebug")
    fn from_hash(value: UInt8) -> Self:
        """Construct a `DateTime8` from a hash made by it.

        Args:
            value: The hash.

        Returns:
            Self.
        """

        var d = _cal.from_hash[_cal_h8](int(value))
        return Self(day=int(d[2]), hash_val=value).add(hours=int(d[3]))
