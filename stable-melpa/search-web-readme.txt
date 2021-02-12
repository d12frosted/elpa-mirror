* Description

Post web search queries using `browse-url'.

* Installation:

(require 'search-web)

You should change following variables to fit your environment
by `M-x customize-group search-web`.
- search-web-default-browser
- search-web-in-emacs-browser
- search-web-external-browser

The default values are the same as browse-url-default-browser.
This probably points external browser of emacs if you didn't change it.

* usage:

search-web-dwim: a main function

Search selected words in a browser if you select a region.
Search at point if not.

I recommend you add following code into your .emacs
if you use `popwin and text-browser `emacs-w3m or `eww
to popup *w3m* and *eww*.

(defadvice w3m-browse-url (around w3m-browse-url-popwin activate)
   (save-window-excursion ad-do-it)
   (unless (get-buffer-window "*w3m*")
      (pop-to-buffer "*w3m*")))

(defadvice eww-render (around eww-render-popwin activate)
  (save-window-excursion ad-do-it)
  (unless (get-buffer-window "*eww*")
    (pop-to-buffer "*eww*")))

(push "*eww*" popwin:special-display-config)
(push "*w3m*" popwin:special-display-config)
