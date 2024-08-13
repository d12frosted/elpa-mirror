Helm UI for bm.el (https://github.com/joodland/bm).

Basically bm.el allow bookmarking positions in buffers, helm-bm
list these positions and allow jumping to them easily.  This is
particularly useful when working on a set of functions distributed
in various places of a large buffer or in several different buffers.

Installation:

Add this file in your `load-path' and the following to your Emacs init file:

(autoload 'helm-bm "helm-bm" nil t) ;; Not necessary if using ELPA package.

Settings:

Bind helm-bm to a key of your choice, e.g.
(global-set-key (kbd "C-c b") 'helm-bm)

Show bookmarks from all buffers or only from current buffer according
to `bm-cycle-all-buffers' value.
