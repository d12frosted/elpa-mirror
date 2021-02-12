 Emacs karma integration that support mode line report!

 To enable, use:
    (add-hook javascript-mode-hook 'upbo-mode)
 or
    (add-hook js2-mode-hook 'upbo-mode)

 Test Setup Usage:
(upbo-define-test
 :path "~/tui.chart/"
 :browsers "ChromeHeadless"
 :conf-file "~/tui.chart/karma.conf.js")
