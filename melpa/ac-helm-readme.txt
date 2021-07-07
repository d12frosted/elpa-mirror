Auto Complete with Helm.  It enables us to narrow candidates
with helm interface.  If you have helm-match-plugin.el,
candidates can be narrowed many times.

Commands:

Below are complete command list:

 `ac-complete-with-helm'
   Select auto-complete candidates by `helm'.

Customizable Options:

Below are customizable option list:


Installation:

Add the following to your emacs init file:

(require 'ac-helm) ;; Not necessary if using ELPA package
(define-key ac-complete-mode-map (kbd "C-:") 'ac-complete-with-helm)

That's all.
