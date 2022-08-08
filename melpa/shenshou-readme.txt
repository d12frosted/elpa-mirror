This program downloads subtitles from http://opensubtitles.org

Please note,
- You MUST register at http://opensubtitles.org first.
  That's required by opensubtitles' latest policy.
  See https://forum.opensubtitles.org/viewtopic.php?f=11&t=17110 for details.
- Command line program "curl" and "gzip" should exist.
  See `shenshou-curl-program' and `shenshou-gzip-program'.

Usage,
  - Set `shenshou-login-user-name' and `shenshou-login-password' first.
  - Run `shenshou-download-subtitle' in Dired buffer or anywhere.
  - Run `shenshou-logout-now' to logout.
  - Run `shenshou-extract-subtitle-from-zip' to extract subtitle from zip file.
    Subtitle is automatically renamed to match selected video file.

Tips,
  - Use `shenshou-language-code-list' to set up subtitle's language.
    See https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes.
     (setq shenshou-language-code-list "eng") # English
     (setq shenshou-language-code-list "eng,chi") # English, Chinese
  - See `shenshou-curl-extra-options' on how to set SOCKS5 or HTTP proxy
  - This program gives you the freedom to select the right subtitle.
