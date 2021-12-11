Table of Contents
─────────────────

1. Webpaste.el – Paste text to pastebin-like services
2. Table of Contents
3. Installation
.. 1. The interactive way
.. 2. A declarative way (Using [use-package])
4. Configuration
.. 1. Choosing providers / provider priority
.. 2. Only paste plaintext pastes
.. 3. Confirm pasting with a yes/no confirmation before pasting
.. 4. Max retries on failure
.. 5. View recently created pastes
..... 1. Send the returned URL to the killring
..... 2. Copy URL to the clipboard
..... 3. Open the recently created paste in the browser
..... 4. Use a custom hook
.. 6. Custom providers
5. TODO Providers to implement [7/14]


[https://img.shields.io/badge/license-GPL_3-green.svg]
[https://elpa.nongnu.org/nongnu/webpaste.svg]
[https://melpa.org/packages/webpaste-badge.svg]
[https://stable.melpa.org/packages/webpaste-badge.svg]
[https://github.com/etu/webpaste.el/workflows/Unit%20tests/badge.svg]
[https://github.com/etu/webpaste.el/workflows/Integration%20tests/badge.svg]
[https://coveralls.io/repos/github/etu/webpaste.el/badge.svg?branch=main]


[https://img.shields.io/badge/license-GPL_3-green.svg]
<https://www.gnu.org/licenses/gpl-3.0.txt>

[https://elpa.nongnu.org/nongnu/webpaste.svg]
<https://elpa.nongnu.org/nongnu/webpaste.html>

[https://melpa.org/packages/webpaste-badge.svg]
<https://melpa.org/#/webpaste>

[https://stable.melpa.org/packages/webpaste-badge.svg]
<https://stable.melpa.org/#/webpaste>

[https://github.com/etu/webpaste.el/workflows/Unit%20tests/badge.svg]
<https://github.com/etu/webpaste.el/actions?query=workflow%3A%22Unit+tests%22>

[https://github.com/etu/webpaste.el/workflows/Integration%20tests/badge.svg]
<https://github.com/etu/webpaste.el/actions?query=workflow%3A%22Integration+tests%22>

[https://coveralls.io/repos/github/etu/webpaste.el/badge.svg?branch=main]
<https://coveralls.io/github/etu/webpaste.el?branch=main>


1 Webpaste.el – Paste text to pastebin-like services
════════════════════════════════════════════════════

  This mode allows to paste whole buffers or parts of buffers to
  pastebin-like services. It supports more than one service and will
  failover if one service fails. More services can easily be added over
  time and preferred services can easily be configured.


2 Table of Contents
═══════════════════

  • 
  • 

    • 
    • 
  • 

    • 
    • 
    • 
    • 
    • 

      • 
      • 
      • 
      • 
    • 
  • 


3 Installation
══════════════

  The package is available on [NonGNU ELPA], which is part of the
  default set of repositories starting in Emacs 28. For information on
  how to add this repository if you're on an older Emacs, check the
  [NonGNU ELPA] instructions.


[NonGNU ELPA] <https://elpa.nongnu.org/>

3.1 The interactive way
───────────────────────

  You can install `webpaste' using the interactive `package-install'
  command like the following:
  M-x package-install RET webpaste RET


3.2 A declarative way (Using [use-package])
───────────────────────────────────────────

  This requires that you have [use-package] set up. But it's in my
  opinion the easiest way to install and configure packages.

  ┌────
  │ (use-package webpaste
  │   :ensure t
  │   :bind (("C-c C-p C-b" . webpaste-paste-buffer)
  │ 	 ("C-c C-p C-r" . webpaste-paste-region)
  │ 	 ("C-c C-p C-p" . webpaste-paste-buffer-or-region)))
  └────


[use-package] <https://github.com/jwiegley/use-package>


4 Configuration
═══════════════

4.1 Choosing providers / provider priority
──────────────────────────────────────────

  To select which providers to use in which order you need to set the
  variable `webpaste-provider-priority' which is a list of strings
  containing the providers names.

  Examples:
  ┌────
  │ ;; Choosing githup gist only
  │ (setq webpaste-provider-priority '("gist.github.com"))
  │ 
  │ ;; Choosing ix.io as first provider and dpaste.org as second
  │ (setq webpaste-provider-priority '("ix.io" "dpaste.org"))
  │ 
  │ ;; Choosing 1) ix.io, 2) dpaste.org, 3) dpaste.com
  │ (setq webpaste-provider-priority '("ix.io" "dpaste.org" "dpaste.com"))
  │ 
  │ ;; You can always append this list as much as you like, and which providers
  │ ;; that exists is documented below in the readme.
  └────

  This can be added to the `:config' section of use-package:
  ┌────
  │ (use-package webpaste
  │   :ensure t
  │   :bind (("C-c C-p C-b" . webpaste-paste-buffer)
  │ 	 ("C-c C-p C-r" . webpaste-paste-region)
  │ 	 ("C-c C-p C-p" . webpaste-paste-buffer-or-region))
  │   :config
  │   (progn
  │     (setq webpaste-provider-priority '("ix.io" "dpaste.org"))))
  └────


4.2 Only paste plaintext pastes
───────────────────────────────

  If you don't want language detection you can define the following
  parameter that will tell the language detection to not check what
  language it is and not return anything to make it fallback to
  plaintext.

  Example:
  ┌────
  │ ;; Only paste raw pastes
  │ (setq webpaste-paste-raw-text t)
  └────


4.3 Confirm pasting with a yes/no confirmation before pasting
─────────────────────────────────────────────────────────────

  To enable a confirmation dialog to always pop up and require you to
  confirm pasting before text is actually sent to a paste-provider you
  just need to set the variable `webpaste-paste-confirmation' to a value
  that is non-nil.

  Example:
  ┌────
  │ ;; Require confirmation before doing paste
  │ (setq webpaste-paste-confirmation t)
  └────

  Can also be put in the `:config' section of `use-package' the same way
  as the provider definitions above.


4.4 Max retries on failure
──────────────────────────

  To prevent infinite loops of retries there's an option named
  `webpaste-max-retries', it's default value is `10'. Webpaste shouldn't
  try more than 10 times against remote services.

  This can be changed:
  ┌────
  │ ;; Do maximum 13 retries instead of standard 10
  │ (setq webpaste-max-retries 13)
  └────


4.5 View recently created pastes
────────────────────────────────

  Webpaste gives you several options to view your successful paste.


4.5.1 Send the returned URL to the killring
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This is webpaste's default behavior. After a successful paste, the
  returned URL from the provider will be sent to the killring. You can
  disable this with

  ┌────
  │ (setq webpaste-add-to-killring nil)
  └────


4.5.2 Copy URL to the clipboard
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you have [simpleclip] installed, you can copy the returned URL to
  the clipboard. You can enable this with

  ┌────
  │ ;; To build your own hook to use simpleclip, you could do like this:
  │ (add-hook 'webpaste-return-url-hook
  │ 	  (lambda (url)
  │ 	    (message "Copied URL to clipboard: %S" url)
  │ 	    (simpleclip-set-contents url)))
  └────


[simpleclip] <https://github.com/rolandwalker/simpleclip>


4.5.3 Open the recently created paste in the browser
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  To enable opening of recently created pastes in an external browser,
  you can enable the option `webpaste-open-in-browser' by setting this
  value to a non-nil value.

  Example:
  ┌────
  │ ;; Open recently created pastes in an external browser
  │ (setq webpaste-open-in-browser t)
  └────

  Can also be put in the `:config' section of `use-package' the same way
  as the provider definitions above.


4.5.4 Use a custom hook
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can define a custom hook to send your URL's to when returning them
  from the paste provider. This is just like regular hooks for major
  modes etc. You can have several hooks as well if you want it to do
  several custom things.

  ┌────
  │ ;; Simple hook to just message the URL, this is more or less the default
  │ ;; already. But if you disable the default and still want a message, this
  │ ;; would work fine.
  │ (add-hook 'webpaste-return-url-hook 'message)
  │ 
  │ ;; To build your own send-to-browser hook, you could do like this:
  │ (add-hook 'webpaste-return-url-hook
  │ 	  (lambda (url)
  │ 	    (message "Opened URL in browser: %S" url)
  │ 	    (browse-url-generic url)))
  │ 
  │ ;; Simple hook to replicate the `webpaste-copy-to-clipboard' option
  │ (add-hook 'webpaste-return-url-hook 'simpleclip-set-contents)
  └────


4.6 Custom providers
────────────────────

  The example of one of the simplest providers possible to write:
  ┌────
  │ (require 'webpaste)
  │ (add-to-list
  │  'webpaste-providers-alist
  │  '("example.com"
  │    :uri "https://example.com/"
  │    :post-field "content"
  │    :success-lambda webpaste-providers-success-location-header))
  └────

  Options available are the options used in webpaste–provider. These
  docs are available within emacs documentation. To read this you need
  to require webpaste first and then just read the documentation by
  running this:
  ┌────
  │ (require 'webpaste)
  │ (describe-function 'webpaste--provider)
  └────


5 TODO Providers to implement [7/14]
════════════════════════════════════

  • ☐ clbin.com
  • ☐ 0x0.st
  • ☑ ix.io
  • ☑ paste.rs
  • ☑ dpaste.com
  • ☑ dpaste.org
  • ☑ gist.github.com
  • ☑ paste.mozilla.org
  • ☑ bpa.st
  • ☐ paste.debian.net
  • ☐ bpaste.net
  • ☐ eval.in
  • ☐ ptpb.pw (RIP due to [ptpb/pb#245] & [ptpb/pb#240])
  • ☐ sprunge.us (removed due to [sprunge#45] that yields 500s)


[ptpb/pb#245] <https://github.com/ptpb/pb/issues/245>

[ptpb/pb#240] <https://github.com/ptpb/pb/issues/240>

[sprunge#45] <https://github.com/rupa/sprunge/issues/45>
