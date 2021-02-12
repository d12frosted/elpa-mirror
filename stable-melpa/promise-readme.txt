This is a simple implementation of Promises/A+.

This implementation ported the following Promises/A+ implementation faithfully.
https://github.com/then/promise

* The same API as JavaScript version Promise can be used.
 * then, catch, resolve, reject, all, race, etc...
* supports "thenable"
* supports "Inheritance of Promise"
* supports "rejection-tracking"

Usage:
See `promise-examples.el' for details.
 https://raw.githubusercontent.com/chuntaro/emacs-promise/master/examples/promise-examples.el
 You can check the operation while downloading and running it interactively.

(require 'promise)

;; Please be sure to enable it when developing.
(promise-rejection-tracking-enable '((all-rejections . t)))

(defun do-something-async (delay-sec value)
  "Return `Promise' to resolve the value asynchronously."
  (promise-new (lambda (resolve _reject)
                 (run-at-time delay-sec
                              nil
                              (lambda ()
                                (funcall resolve value))))))

(defun example4 ()
  "All processes are asynchronous Promise chain."
  (promise-chain (do-something-async 1 33)
    (then (lambda (result)
            (message "first result: %s" result)
            (do-something-async 1 (* result 2))))

    (then (lambda (second-result)
            (message "second result: %s" second-result)
            (do-something-async 1 (* second-result 2))))

    (then (lambda (third-result)
            (message "third result: %s" third-result)))))
