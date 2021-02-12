This library uses OS X CoreLocation services to put useful
information into variables `osx-location-latitude' and
`osx-location-longitude'.

To use, run `osx-location-watch', which starts monitoring the
location asynchronously.

To add code which responds to location changes, use
`osx-location-changed-hook'.  For example, you might add a hook
function which updates `calendar-latitude' and `calendar-longitude'
(defined in the built-in library `solar').

Hook functions take no arguments; when your hook function runs, it
can use the freshly-updated values of `osx-location-latitude' and
`osx-location-longitude'.

Here's an example:

(eval-after-load 'osx-location
  '(when (eq system-type 'darwin)
     (add-hook 'osx-location-changed-hook
               (lambda ()
                 (setq calendar-latitude osx-location-latitude
                       calendar-longitude osx-location-longitude
                       calendar-location-name (format "%s, %s" osx-location-latitude osx-location-longitude))))))

Comes bundled with a required executable called
EmacsLocationHelper, which does the communication with
CoreServices; if you don't trust me, you can build it yourself from
the instructions at https://gist.github.com/1416248 or using the
bundled Makefile.
