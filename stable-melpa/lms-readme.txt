`lms.el' is a frontend for Squeezebox / Logitech Media Server.

More information on what a "squeezebox controller" is at
https://inigo.katxi.org/blog/2017/07/31/lms_el.html

Quick instructions: customize some basic parameters `lms-url'
and run it with `lms' or `lms-ui'.
Then, you could read complete documentation after pressing 'h' key.
You can also run 'emacsclient -e "(lms-float)"' to display an independent
small frame.

; Major updates:

2017/07/29 Initial version.
2018/12/09 Added library browsing features from current track.
2018/12/10 Added library browsing features.
2018/12/16 Colorize lists, prev/next in TrackInfo, clean code, bugs fixed.
2020/06/14 Complete rewrite to use HTTP requests to LMS instead of telnet.
