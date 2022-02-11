This is a library for showing inline contextual docs above or below.

You can use this library function `inline-docs` in packages like
https://repo.or.cz/eldoc-overlay.git

```eldoc
(setq eldoc-message-function #'inline-docs)
```

```elisp
(inline-docs "FORMATED-STRING")
(inline-docs "STRING")
```
