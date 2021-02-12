This package provides the infrastructure for "inherited"
buffer-local variables: Those whose values are not reflected
globally but are initially shared by child buffers.

Because there is no clear-cut definition of "child" (if I start erc
from my notmuch buffer, is there a real relationship there?), this
package doesn't decide what you mean by child.  Instead, it
provides hooks for determining when inheritance might be relevant
and a function for performing the inheritance on a given buffer.

As an example, suppose you have version 1.2 of the foo compiler
installed in your PATH, but your current project depends on
features added in the experimental foo-2.0, which you have
installed in /opt/foo-2.0.  You're often working on multiple
foo-lang projects at once, and your Emacs startup time is 45
minutes, so you don't want to globally modify your PATH.  If you
just do

  (setq-local exec-path (cons "/opt/foo/bin" exec-path))
  (put 'exec-path 'permanent-local t)

then you'll run into a problem, because foo-mode calls fooc inside
a with-temp-buffer call to capture the output!  Instead, you can do

  (inherit-local-permanent exec-path
    (cons "/opt/foo/bin" exec-path))
  (defun around-generate (orig name)
    (if (eq (aref name 0) ?\s)
        (let ((buf (funcall orig name)))
          (inherit-local-inherit-child buf)
          buf)
      (funcall orig name)))
  (advice-add 'generate-new-buffer :around #'around-generate)

and your local exec-path will be inherited by internal buffers
without affecting any others.
