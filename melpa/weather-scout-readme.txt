
Display weather forecast from MET Norway

The command weather-scout-show-forecast displays weather forecast for a
selected location from MET Norway. The first time the command is invoked, it
will display a search prompt in the minibuffer. The next time it is invoked,
it will remember the previous selection. To select a new location, invoke the
command with a prefix argument (typically C-u) to display the search prompt
again.

Location searches use the free GeoNames service. By default, weather-scout
uses its own GeoNames account. Because of rate limits, creating you own
account is recommended. Follow the steps below to create and configure your
own account.

- Create a free account here: https://www.geonames.org/.
- Enable the new account for the free webservices on the account page:
  https://www.geonames.org/manageaccount.
- Set this variable in your Emacs configuration:
  (setq weather-scout-geonames-account-name "your-account-name-here")
