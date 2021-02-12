yari.el provides an Emacs frontend to Ruby's `ri' documentation
tool. It offers lookup and completion.

This version will load all completion targets the first time it's
invoked. This can be a significant startup time, but it will not
have to look up anything after that point.

This library tries to be compatible with any version of `rdoc' gem.
Self-testing covers all versions from 1.0.1 to 2.5.8 (current).

The main function you should use as interface to ri is M-x yari
(yari-helm is a variant using Helm input framework). I recommend to
bind it on some key local when you are ruby-mode. Here is the example:

(defun ri-bind-key ()
  (local-set-key [f1] 'yari))

 or

(defun ri-bind-key ()
  (local-set-key [f1] 'yari-helm))

(add-hook 'ruby-mode-hook 'ri-bind-key)

You can use C-u M-x yari to reload all completion targets.
