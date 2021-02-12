
This package use `helm' as an interface to find tag with Etags.

 it support multiple tag files.
 and it can recursively searches each parent directory for a file named
 'TAGS'. so you needn't add this special file to `tags-table-list'

 if you use GNU/Emacs ,you can set `tags-table-list' like this.
 (setq tags-table-list '("/path/of/TAGS1" "/path/of/TAG2"))

 (global-set-key "\M-." 'helm-etags-plus-select)
      `M-.' default use symbol under point as tagname
      `C-uM-.' use pattern you typed as tagname

helm-etags-plus.el also support history go back ,go forward and list tag
histories you have visited.(must use commands list here:)
 `helm-etags-plus-history'
   List all tag you have visited with `helm'.
 `helm-etags-plus-history-go-back'
   Go back cyclely.
 `helm-etags-plus-history-go-forward'
   Go Forward cyclely.

if you want to work with `etags-table.el' ,you just need
add this line to to init file after loading etags-table.el

    (add-hook 'helm-etags-plus-select-hook 'etags-table-recompute)
   (setq etags-table-alist
    (list
       '("/home/me/Projects/foo/.*\\.[ch]$" "/home/me/Projects/lib1/TAGS" "/home/me/Projects/lib2/TAGS")
       '("/home/me/Projects/bar/.*\\.py$" "/home/me/Projects/python/common/TAGS")
       '(".*\\.[ch]$" "/usr/local/include/TAGS")
       ))

; Installation:

Just put helm-etags-plus.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name "~/elisp"))

And the following to your ~/.emacs startup file.

(require 'helm-etags-plus)

No need more.

I use GNU/Emacs,and this is my config file about etags
(require 'helm-etags-plus)
(global-set-key "\M-." 'helm-etags-plus-select)
;;list all visited tags
(global-set-key "\M-*" 'helm-etags-plus-history)
;;go back directly
(global-set-key "\M-," 'helm-etags-plus-history-go-back)
;;go forward directly
(global-set-key "\M-/" 'helm-etags-plus-history-go-forward)

 if you do not want use bm.el for navigating history
 you could
(autoload 'bm-bookmark-add "bm" "add bookmark")
     (add-hook 'helm-etags-plus-before-jump-hook 'bm-bookmark-add)
or   (add-hook 'helm-etags-plus-before-jump-hook '(lambda()(bm-bookmark-add nil nil t)))
(setq bm-in-lifo-order t)
 then use bm-previous bm-next


and how to work with etags-table.el
(require 'etags-table)
(setq etags-table-alist
      (list
       '("/home/me/Projects/foo/.*\\.[ch]$" "/home/me/Projects/lib1/TAGS" "/home/me/Projects/lib2/TAGS")
       '("/home/me/Projects/bar/.*\\.py$" "/home/me/Projects/python/common/TAGS")
       '("/tmp/.*\\.c$"  "/java/tags/linux.tag" "/tmp/TAGS" )
       '(".*\\.java$"  "/opt/sun-jdk-1.6.0.22/src/TAGS" )
       '(".*\\.[ch]$"  "/java/tags/linux.ctags")
       ))
(add-hook 'helm-etags-plus-select-hook 'etags-table-recompute)
