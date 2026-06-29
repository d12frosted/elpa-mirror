Run `M-x metar RET' to get a simple weather report from weather.noaa.gov.
The value of `calendar-latitude' and `calendar-longitude' will be used to
automatically determine a nearby station.  If these variables are not set,
you will be prompted to enter the location manually.

With `C-u M-x metar RET', country and station name need to be entered.
`C-u C-u M-x metar RET' will prompt for the METAR station code (4 letters).

Customize `metar-units' to change length, speed, temperature or pressure
units to your liking.

For programmatic access to decoded weather reports, use:

  (metar-decode (metar-get-record "CODE"))