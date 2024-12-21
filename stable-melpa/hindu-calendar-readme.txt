
This package provides traditional Hindu calendars (solar and lunar) using
arithmetic based on the mean motions of the Sun and Moon.  It calculates
tithi and nakshatra.  It provides both tropical (sayana) and sidereal
(nirayana/Chitrapaksha) variants.  Lunar calendar can be chosen between
amanta or purnimanta.

Usage:
    All of the functions can be called interactively or programmatically.

(require 'hindu-calendar)

Sidereal lunar:        M-x hindu-calendar-sidereal-lunar
Tropical lunar:        M-x hindu-calendar-tropical-lunar
Sidereal solar:        M-x hindu-calendar-sidereal-solar
Tropical solar:        M-x hindu-calendar-tropical-solar
Nakshatra (sidereal):  M-x hindu-calendar-asterism
Tweak variables:       M-x customize-group RET hindu-calendar

(hindu-calendar-keybindings) ; Optional
