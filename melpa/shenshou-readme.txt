This program downloads subtitles from http://opensubtitles.com

Please note,
- You MUST register an account at http://opensubtitles.com first.
- Command line program "curl" should exist.
  See `shenshou-curl-program'.

Usage,
  - Set `shenshou-login-user-name' and `shenshou-login-password' first.
  - Run `shenshou-download-subtitle' in Dired buffer or anywhere.
  - Run `shenshou-logout-now' to logout.
  - Run `shenshou-extract-subtitle-from-zip' to extract subtitle from zip file.
    Subtitle is automatically renamed to match selected video file.

Tips,
  - Use `shenshou-language-code-list' to set up subtitle's language.
    See https://en.wikipedia.org/wiki/ISO_639-1.
     (setq shenshou-language-code-list "en") # English
     (setq shenshou-language-code-list "en,zh") # English, Chinese
  - See `shenshou-curl-extra-options' on how to set SOCKS5 or HTTP proxy
  - This program gives you the freedom to select the right subtitle.
