This package provides a simple weather forecast display using
sparklines.

Commands:
- `sparkweather-day': Show full day forecast with sparklines
- `sparkweather': Alias for `sparkweather-day'

Configuration:
The package uses `calendar-latitude' and `calendar-longitude' for
the forecast location.

The sparkline display highlights configurable time windows,
such as lunch and commute hours.  Customize `sparkweather-time-windows'
to add or modify highlighted periods.

Weather icons use Unicode weather glyphs from the Miscellaneous
Symbols block for broad compatibility.

Weather data is provided by Open-Meteo https://open-meteo.com,
which is free for non-commercial use with up to 10000 requests per day.
