A helm interface to rubygems.org

Requirements:
* The helm package - https://github.com/emacs-helm/helm
* A rubygems.org account and the account's API key

Setup:
API Key management.  Choose one of the three.
* Store the rubygems.org API key in its recommended YAML file
  at ~.gem/credentials
* Add the key to the helm-rubygems-org customization group
* setq helm-rubygems-org-api-key to the key or file path

Usage:
M-x helm-rubygems-org, and then type gem name

Wait for rubygems.org response...it is sometimes slow.

Select the gem in the helm list, and press return to save
a Gemfile compatible string to the kill ring; e.g.,
"gem guard-rackunit, '~> 1.0.0'".  Or press the tab key and see
a list of other helm actions

Detailed documentation can be found here:
https://github.com/neomantic/helm-rubygems-org
