
Usage:
  Install via package or copy this file to a location of your load path
  (e.g. ~/.emacs.d) and add the following to your .emacs (or
  .emacs.d/init.el):

;-----------------
; mode Cubicle
;-----------------
(setq auto-mode-alist
      (cons '("\\.cub\\'" . cubicle-mode) auto-mode-alist))
(autoload 'cubicle-mode "cubicle-mode" "Major mode for Cubicle." t)


You can also use Cubicle in org-mode through babel by adding the following
to your .emacs:

(defun org-babel-execute:cubicle (body params)
  "Execute a block of Cubicle code with org-babel."
  (message "executing Cubicle source code block")
  (let ((brab (cdr (assoc :brab (org-babel-process-params params)))))
    (if brab
        (org-babel-eval (format "cubicle -brab %S" brab) body)
        (org-babel-eval "cubicle" body)
      )))

In this case you can define Cubicle source blocks and evaluate them with
#+begin_src cubicle :brab 2
#+end_src
where :brab is an optional argument that will be passed on to cubicle when
executed.
