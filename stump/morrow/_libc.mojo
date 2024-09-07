from sys import external_call

alias c_void = UInt8
alias c_char = UInt8
alias c_schar = Int8
alias c_uchar = UInt8
alias c_short = Int16
alias c_ushort = UInt16
alias c_int = Int32
alias c_uint = UInt32
alias c_long = Int64
alias c_ulong = UInt64
alias c_float = Float32
alias c_double = Float64


@value
@register_passable("trivial")
struct CTimeval:
    var tv_sec: Int  # Seconds
    var tv_usec: Int  # Microseconds

    fn __init__(inout self, tv_sec: Int = 0, tv_usec: Int = 0):
        self.tv_sec = tv_sec
        self.tv_usec = tv_usec


@value
@register_passable("trivial")
struct CTm:
    var tm_sec: Int32  # Seconds
    var tm_min: Int32  # Minutes
    var tm_hour: Int32  # Hour
    var tm_mday: Int32  # Day of the month
    var tm_mon: Int32  # Month
    var tm_year: Int32  # Year minus 1900
    var tm_wday: Int32  # Day of the week
    var tm_yday: Int32  # Day of the year
    var tm_isdst: Int32  # Daylight savings flag
    var tm_gmtoff: Int64  # localtime zone offset seconds

    fn __init__(inout self):
        self.tm_sec = 0
        self.tm_min = 0
        self.tm_hour = 0
        self.tm_mday = 0
        self.tm_mon = 0
        self.tm_year = 0
        self.tm_wday = 0
        self.tm_yday = 0
        self.tm_isdst = 0
        self.tm_gmtoff = 0


@always_inline
fn c_gettimeofday() -> CTimeval:
    var tv = CTimeval()
    external_call["gettimeofday", NoneType](Reference(tv), 0)
    return tv


@always_inline
fn c_time() -> Int:
    var time = 0
    return external_call["time", Int](Reference(time))


@always_inline
fn c_localtime(owned tv_sec: Int) -> CTm:
    var buf = CTm()
    _ = external_call["localtime_r", UnsafePointer[CTm]](Reference(tv_sec), Reference(buf))
    return buf


@always_inline
fn c_strptime(time_str: String, time_format: String) -> CTm:
    var tm = CTm()
    _ = external_call["strptime", NoneType](time_str.unsafe_ptr(), time_format.unsafe_ptr(), Reference(tm))
    return tm


@always_inline
fn c_strftime(format: String, owned time: CTm) -> String:
    """size_t strftime(char s[restrict .max], size_t max,
    const char *restrict format,
    const struct tm *restrict tm);"""
    var buf = String(List[UInt8](capacity=26))
    _ = external_call["strftime", UInt](buf.unsafe_ptr(), len(format), format.unsafe_ptr(), Reference(time))
    return buf


@always_inline
fn c_gmtime(owned tv_sec: Int) -> CTm:
    var tm = external_call["gmtime", UnsafePointer[CTm]](Reference(tv_sec)).take_pointee()
    return tm
