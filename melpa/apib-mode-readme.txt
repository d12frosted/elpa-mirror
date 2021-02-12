apib-mode is a major mode for editing API Blueprint.  It is derived
from markdown mode as apib is a special case of markdown.  It adds
couple of usefull things when working with API Blueprint like
getting parsing the API Blueprint and validating it.  For this to
work though you need to install the drafter exectubale first,
please see https://github.com/apiaryio/drafter for more information

; Installation:

(autoload 'apib-mode "apib-mode"
       "Major mode for editing API Blueprint files" t)
(add-to-list 'auto-mode-alist '("\\.apib\\'" . apib-mode))
