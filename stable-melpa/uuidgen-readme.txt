
This is a naive implementation of RFC4122 Universally Unique
IDentifier generation in elisp.  Currently implemented are UUID v1
v3, v4 and v5 generation.  The resolution of the time based UUID is
microseconds, which is 10 times of the suggested 100-nanosecond
resolution, but should be enough for general usage.

Get development version from git:

    git clone git://github.com/kanru/uuidgen-el.git
