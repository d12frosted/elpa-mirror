company-mode support for `stan-mode'.
Completion keywords are obtained from `stan-mode'.

Usage
The `company-stan-backend' needs to be added to `company-backends'.
This can be done globally or buffer locally (use here).

A convenience function `company-stan-setup' can be added to the
mode-specific hook `stan-mode-hook'.
(add-hook 'stan-mode-hook #'company-stan-setup)

With the `use-package', the following can be used:
(use-package company-stan
  :hook (stan-mode . company-stan-setup))

If you already have a custom stan-mode setup function, you can add
the following to its body.
(add-to-list (make-local-variable 'company-backends)
             'company-stan-backend)

References
Writing backends for the company-mode.
 https://github.com/company-mode/company-mode/wiki/Writing-backends
 http://sixty-north.com/blog/series/how-to-write-company-mode-backends.html
Definitions
 https://github.com/company-mode/company-mode/blob/master/company.el
Example in company-math.el
 https://github.com/vspinu/company-math/blob/master/company-math.el#L210
