A testing library that provides a virtual filesystem for Emacs Lisp tests.
Uses `file-name-handler-alist' to intercept file operations on `/mock:'
prefixed paths.

Usage:

  ;; Declarative
  (with-mock-fs '(("/path/file.txt" . "content")
                  ("/path/dir/" . nil))
    (file-exists-p "/mock:/path/file.txt"))  ; => t

  ;; Builder
  (let ((fs (mock-fs-create)))
    (mock-fs-add-file fs "/file.txt" "content")
    (with-mock-fs fs
      (insert-file-contents "/mock:/file.txt")))
