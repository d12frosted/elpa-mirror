Sail provides interactive Emacs commands for fetching real-time tide
predictions and wind conditions from the NOAA Tides and Currents API.

Usage:
  M-x sail-get-tides   Fetch the next 24 hours of high/low tides.
  M-x sail-get-wind    Fetch the latest wind conditions.

Customize the station IDs via `customize-group' sail, or set
`sail-tide-station' and `sail-wind-station' directly.  Station IDs
can be found at <https://tidesandcurrents.noaa.gov/stations.html>.
