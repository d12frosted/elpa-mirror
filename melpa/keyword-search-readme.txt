This is based on the code snippets at
http://www.emacswiki.org/emacs/BrowseAproposURL
(maybe if a complete file had been posted there
I would not have forked this off).

It provides 3 functions `keyword-search', `keyword-search-at-point'
and `keyword-search-quick'.

`keyword-search': provides completion on keywords and then reads
a search term defaulting to the symbol at point.

`keyword-search-at-point': reads a keyword with completion and then
searchs with the symbol at point.

`keyword-search-quick': reads a query in one line if it does not
start with a keyword it uses `keyword-search-default'.

To use:

(load "keyword-search")
(define-key mode-specific-map [?b] 'keyword-search)
(define-key mode-specific-map [?B] 'keyword-search-quick)

Example of a direct search binding:

(eval-after-load 'haskell-mode
  '(define-key haskell-mode-map (kbd "C-c h")
     (lambda ()
       (interactive)
       (keyword-search "hayoo"))))
