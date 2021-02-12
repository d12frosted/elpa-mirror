You should always be able to find the latest version here:

          <URL:http://github.com/hober/google-el/>

A really bare-bones first hack at Google API support for Emacs.
Note that you need a Google license key to use this; you can
get one by following the instructions here:

     <URL:http://code.google.com/apis/ajaxsearch/signup.html>

Usage:

(require 'google)
(setq google-license-key "my license key" ; optional
      google-referer "my url")            ; required!
(google-search-video "rickroll")
