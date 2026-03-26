
This package provides traditional Hindu calendars (solar and lunar) using
analytic equations (Meeus-style) based on astronomical motions of the Sun and
Moon.  It calculates tithi and nakshatra.  It provides both tropical (sayana)
and sidereal (nirayana/Chitrapaksha) variants.  Lunar calendar can be chosen
between amanta or purnimanta.  Default location is Ujjain, which can be
customized via `calendar-latitude', `calendar-longitude' and
`calendar-time-zone'

Usage:
    All of the functions can be called interactively or programmatically.

(require 'hindu-calendar)

Sidereal lunar:        M-x hindu-calendar-sidereal-lunar
Tropical lunar:        M-x hindu-calendar-tropical-lunar
Sidereal solar:        M-x hindu-calendar-sidereal-solar
Tropical solar:        M-x hindu-calendar-tropical-solar
Indian National:       M-x hindu-calendar-indian-national
Nakshatra (sidereal):  M-x hindu-calendar-asterism
Tweak variables:       M-x customize-group RET hindu-calendar

(hindu-calendar-keybindings) ; Optional
