Wand is an extension that allows users perform actions on a region based on
predefined patterns.  Wand is inspired by Xiki[1] and Acme[2].


; Installation:

Thanks to @yasuyk, Wand is available in MELPA.  Make sure you have MELPA
repository added to `package-archives' and simply call `package-install':

  (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/"))
  (package-initialize)
  (package-install 'wand)

Or `M-x package-install RET wand RET`.

Then `require' it:

  (require 'wand)
