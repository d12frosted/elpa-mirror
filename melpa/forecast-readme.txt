
forecast.el generates a _weather forecast report_ and displays it
in a buffer.  It uses data from Dark Sky (http://darksky.net), and
thus one needs to acquire an api key from them in order to use this
package.  They allow 1000 requests a day in their free plan, which
should be enough for any user.

See Installation section for installation and setup instructions.

Report bugs to the Issues page in the Github repo:

https://github.com/cadadr/elisp/issues


; Installation:

See also «Example configuration».

forecast.el is available on Melpa with the package name `forecast'.

Otherwise, put the forecast.el file somewhere in your path, then
`require' it.   Then set these variables either in your
configuration, or via the customisation group `forecast':

`calendar-latitude'      Latitude of your location        float
`calendar-longitude'     Longitude of your location       float
`forecast-api-key'       The API key from Dark Sky        string
`calendar-location-name' Name of your location/city       string
`forecast-language'      Language to use                  symbol
`forecast-units'         Units standard to use            symbol

Only the first three variables above are mandatory.  The first four have
*non-sane* defaults, and if `forecast-api-key' is absent, this program
will not run.

See the documentation for these variables for more detail.

The API key can be obtained via registering oneself through their
developer website:

https://darksky.net/dev/

See also the docstring for the face `forecast-moon-phase', which
governs the face for the moon phase visualisation.  Most fonts will
not have defined the necessary characters, thus one may need to
install a special font, e.g. Quivira (http://quivira-font.com/).

Then on, you may run the command `forecast' to get the forecast
buffer.  The forecast buffer uses `org-level-*' faces,  so it will
look like your org files.  It is called «*Weather Forecast*».

; Example configuration:

(require 'forecast)
(setq calendar-latitude 41.168602
      calendar-longitude 29.047024
      calendar-location-name "İstanbul, Türkiye"
      forecast-api-key "<deduced>")

Or, for the privacy of the API key:

(require 'forecast)
(setq calendar-latitude 41.168602
      calendar-longitude 29.047024
      calendar-location-name "İstanbul, Türkiye"
      forecast-city "İstanbul")

(load (locate-user-emacs-file "forecast-api-key.el"))

And in the file ~/.emacs.d/forecast-api-key.el:

(setq forecast-api-key "<deduced>")
