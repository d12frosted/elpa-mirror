Require this script (and auto-complete) then add to ac-sources.

  (add-hook 'c-mode-hook
            (lambda ()
              (add-to-list 'ac-sources 'ac-source-c-headers)
              (add-to-list 'ac-sources 'ac-source-c-header-symbols t)))

then header filenames and symbols in imported headers are completed.

  #include <s[tdio.h>]   <- ac-source-c-headers
  pr[intf]               <- ac-source-c-header-symbols
