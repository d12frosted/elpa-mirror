Configuration:

Add to hook `ac-html-enable'

(add-hook 'html-mode-hook 'ac-html-enable)

If you are using web-mode:

(add-to-list 'web-mode-ac-sources-alist
             '("html" . (
                         ;; attribute-value better to be first
                         ac-source-html-attribute-value
                         ac-source-html-tag
                         ac-source-html-attribute)))

`ac-html-enable' remove from list ac-disable-faces 'font-lock-string-face,
so if you wish manually add ac-source-html-attribute-value, etc, you may need
customize ac-disable-faces too.
