Installation:

From MELPA or Marmalade.

Just run `M-x package-install RET google-translate RET`

Manual installation.

Assuming that the file `google-translate.el' and other files which
relates to this package is somewhere on the load path, add the
following lines to your `.emacs' file:

(require 'google-translate)
(require 'google-translate-default-ui)
(global-set-key "\C-ct" 'google-translate-at-point)
(global-set-key "\C-cT" 'google-translate-query-translate)

or

(require 'google-translate)
(require 'google-translate-smooth-ui)
(global-set-key "\C-ct" 'google-translate-smooth-translate)

Change the key bindings to your liking.

The difference between these configurations is in UI which will be
used: Default UI or Smooth UI.

Please read the source of `google-translate-default-ui.el' and
`google-translate-smooth-ui.el' for more details.

Customization:

Variables which are available for customization are depends on UI
package which is selected for the google-translate
package. google-translate-default-ui - is UI which is selected by
default. It loads by default and is available right after
google-translate installation and its initialization. Please read
documentation for the `google-translate-core-ui.el' and
`google-translate-default-ui.el' packages for more info about
customization.
