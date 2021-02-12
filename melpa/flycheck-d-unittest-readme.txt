This library adds D unittest support to flycheck.

Requirements:
  * DMD 2.063 or later
  * flycheck.el (https://github.com/flycheck/flycheck)
  * dash.el (https://github.com/magnars/dash.el)

To use this package, add the following line to your .emacs file:
    (require 'flycheck-d-unittest)
    (setup-flycheck-d-unittest)
It detects any compile errors, warnings and deprecated features during unittest.

Note: flycheck-d-unittest runs DMD with -unittest and -main option for unittesting.
Please enclose main function in version(!unittest) block as follows:

---
import std.stdio;

version(unittest) {}
else
void main()
{
    writeln("Hello!");
}

unittest
{
    assert(1+2 == 3);
}
---
