;;; weak-ref.el --- Weak references for Emacs Lisp -*- lexical-binding: t; -*-

;; This is free and unencumbered software released into the public domain.

;; Author: Christopher Wellons <wellons@nullprogram.com>
;; Homepage: https://github.com/skeeto/elisp-weak-ref
;; Package-Requires: ((emacs "24.3"))
;; Package-Version: 20200217.2200
;; Package-Commit: 24e8c37da6465e65ce9f866267bd3fa53c8899c6
;; Version: 2.0

;;; Commentary:

;; The Emacs Lisp environment supports weak references, but only for
;; hash table keys and values. This can be exploited to generalize
;; weak references into two convenient macros:

;;   * `weak-ref'   : create a weak reference to an object
;;   * `weak-ref-deref' : access the object behind a weak reference

;; The weakness can be demonstrated like so:

;;     (setq ref (weak-ref (list 1 2 3)))
;;     (weak-ref-deref ref) ; => (1 2 3)
;;     (garbage-collect)
;;     (weak-ref-deref ref) ; => nil

;; See also: https://github.com/melpa/melpa/pull/6670

;;; Code:

(defsubst weak-ref (thing)
  "Return a new weak reference to THING.
The referenced object will not be protected from garbage
collection by this reference."
  (let ((ref (make-hash-table :size 1 :weakness t :test 'eq)))
    (prog1 ref
      (puthash t thing ref))))

(defsubst weak-ref-deref (ref)
  "Return the object referenced by REF.
Return NIL if the object no longer exists (garbage collected)."
  (gethash t ref))

(provide 'weak-ref)

;;; weak-ref.el ends here
