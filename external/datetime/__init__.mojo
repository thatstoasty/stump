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
"""The datetime package.

- `DateTime`
    - A structure aware of TimeZone, Calendar, and leap days and seconds.
    - Nanosecond resolution, though when using dunder methods (e.g.
        `dt1 == dt2`) it has only Microsecond resolution.
- `Date`
    - A structure aware of TimeZone, Calendar, and leap days and seconds.
- `DateTime64`, `DateTime32`, `DateTime16`, `DateTime8`
    - Fast implementations of DateTime, no leap seconds or years,
        and some have much lower resolutions but better performance.
- `TimeZone`
    - By default UTC, highly customizable and options for full or partial
        IANA timezones support.
- Notes:
    - The caveats of each implementation are better explained in each struct's docstrings.

Examples:

```mojo
from testing import assert_equal, assert_true
from forge_tools.datetime import DateTime, Calendar, IsoFormat
from forge_tools.datetime.calendar import PythonCalendar, UTCCalendar

alias DateT = DateTime[iana=False, pyzoneinfo=False, native=False]
var dt = DateT(2024, 6, 18, 22, 14, 7)
print(dt) # 2024-06-18T22:14:07+00:00
alias fstr = IsoFormat(IsoFormat.HH_MM_SS)
var iso_str = dt.to_iso[fstr]()
dt = (
    DateT.from_iso[fstr](iso_str, calendar=Calendar(2024, 6, 18))
    .value()
    .replace(calendar=Calendar()) # Calendar() == PythonCalendar
)
print(dt) # 2024-06-18T22:14:07+00:00


# TODO: current mojo limitation. Parametrized structs need to be bound to an
# alias and used for interoperability
# var customtz = TimeZone[False, False, False]("my_str", 1, 0)
var tz_0 = DateT._tz("my_str", 0, 0)
var tz_1 = DateT._tz("my_str", 1, 0)
assert_equal(DateT(2024, 6, 18, 0, tz=tz_0), DateT(2024, 6, 18, 1, tz=tz_1))


# using python and unix calendar should have no difference in results
alias pycal = PythonCalendar
alias unixcal = UTCCalendar
var tz_0_ = DateT._tz("Etc/UTC", 0, 0)
tz_1 = DateT._tz("Etc/UTC-1", 1, 0)
var tz1_ = DateT._tz("Etc/UTC+1", 1, 0, -1)

dt = DateT(2022, 6, 1, tz=tz_0_, calendar=pycal) + DateT(
    2, 6, 31, tz=tz_0_, calendar=pycal
)
offset_0 = DateT(2025, 1, 1, tz=tz_0_, calendar=unixcal)
offset_p_1 = DateT(2025, 1, 1, hour=1, tz=tz_1, calendar=unixcal)
offset_n_1 = DateT(2024, 12, 31, hour=23, tz=tz1_, calendar=unixcal)
assert_equal(dt, offset_0)
assert_equal(dt, offset_p_1)
assert_equal(dt, offset_n_1)


var fstr = "mojo: %Y🔥%m🤯%d"
assert_equal("mojo: 0009🔥06🤯01", DateT(9, 6, 1).strftime(fstr))
fstr = "%Y-%m-%d %H:%M:%S.%f"
var ref1 = DateT(2024, 9, 9, 9, 9, 9, 9, 9)
assert_equal("2024-09-09 09:09:09.009009", ref1.strftime(fstr))


fstr = "mojo: %Y🔥%m🤯%d"
var vstr = "mojo: 0009🔥06🤯01"
ref1 = DateT(9, 6, 1)
var parsed = DateT.strptime(vstr, fstr)
assert_true(parsed)
assert_equal(ref1, parsed.value())
fstr = "%Y-%m-%d %H:%M:%S.%f"
vstr = "2024-09-09 09:09:09.009009"
ref1 = DateT(2024, 9, 9, 9, 9, 9, 9, 9)
parsed = DateT.strptime(vstr, fstr)
assert_true(parsed)
assert_equal(ref1, parsed.value())
```
.
"""

from .calendar import Calendar
from .date import Date
from .datetime import DateTime
from .dt_str import IsoFormat
from .fast import DateTime64, DateTime32, DateTime16, DateTime8
from .timezone import TimeZone
from .zoneinfo import get_zoneinfo
