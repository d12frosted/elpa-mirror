
Below 2 files represent the same structure.
I call the S expression representation of the markup language
(especially with HTML) SEML and this package provides
the major mode and utility for that file.

SEML is *short* and *easy to understand* for Lisp hacker.

#+begin_src html
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8"/>
      <title>sample page</title>
      <link rel="stylesheet" href="sample1.css"/>
    </head>
    <body>
      <h1>sample</h1>
      <p>
        text sample
      </p>
    </body>
  </html>
#+end_src

#+begin_src seml
  (html ((lang . "en"))
    (head nil
      (meta ((charset . "utf-8")))
      (title nil "sample page")
      (link ((rel . "stylesheet") (href . "sample1.css"))))
    (body nil
      (h1 nil "sample")
      (p nil "text sample")))
#+end_src

More information at [[https://github.com/conao3/seml-mode][github]]

Sample configuration with [[https://github.com/conao3/leaf.el][leaf.el]]

(leaf real-auto-save
  :ensure t
  :custom ((real-auto-save-interval . 0.3))
  :hook (find-file-hook . real-auto-save-mode))

(leaf seml-mode
  :config (require 'seml-mode)
  :custom ((seml-live-refresh-interval . 0.35)))
