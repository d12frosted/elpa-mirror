The following documentation sources were used:
https://gitlab.com/apparmor/apparmor/wikis/QuickProfileLanguage
https://gitlab.com/apparmor/apparmor/wikis/ProfileLanguage

TODO:
- do smarter completion syntactically via regexps
- decide if to use entire line regexp for statements or
- not (ie just a subset?)  if we use regexps above then
- should probably keep full regexps here so can reuse
- expand highlighting of mount rules (options=...) similar to dbus
- add flymake support via "apparmor_parser -Q -K </path/to/profile>"
- add tests via ert etc

;; Setup

(require 'apparmor-mode)
