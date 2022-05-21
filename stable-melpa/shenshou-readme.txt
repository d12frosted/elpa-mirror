This program downloads subtitles from http://opensubtitles.org

Please note,
- You MUST register at http://opensubtitles.org first.
  That's required by opensubtitles' latest policy.
  See https://forum.opensubtitles.org/viewtopic.php?f=11&t=17110 for details.
- Command line program "curl" and "gzip" should exist.
  See `shenshou-curl-program' and `shenshou-gzip-program'.

Usage,
  - Set `shenshou-login-user-name' and `shenshou-login-password'.
  - Run `shenshou-download-subtitle' in Dired buffer or anywhere.
  - Run `shenshou-logout-now' to logout.

 Tips,
  - See `shenshou-curl-extra-options' on how to set SOCKS5 or HTTP proxy
  - This program gives you the freedom to select the right subtitle.
    For example, a DVD ripped video might match the DVD ripped subtitle.
