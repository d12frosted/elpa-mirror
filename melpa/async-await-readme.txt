This is a simple implementation of Async/Await.
Inspired by the Async/Await implementation of TypeScript.

Usage:
See `async-await-examples.el' for details.
 https://raw.githubusercontent.com/chuntaro/emacs-async-await/master/examples/async-await-examples.el
 You can check the operation while downloading and running it interactively.

(require 'async-await)

;; Please be sure to enable it when developing.
(promise-rejection-tracking-enable '((all-rejections . t)))

(defun wait-async (n)
  (promise-new (lambda (resolve _reject)
                 (run-at-time n
                              nil
                              (lambda ()
                                (funcall resolve n))))))

(async-defun example2 ()
  (print (await (wait-async 0.5)))
  (message "---")

  (print (await (wait-async 1.0)))
  (message "---")

  (print (await (wait-async 1.5)))
  (message "---")

  (message "await done"))

(example2) =>

0.5

---

1.0

---

1.5

---
await done

The result of the execution is outputted from the top to the bottom
like the order written in the code.  However, asynchronously!
