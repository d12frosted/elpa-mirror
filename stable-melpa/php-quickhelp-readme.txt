The project is hosted at https://github.com/vpxyz/php-quickhelp
The latest version, and all the relevant information can be found there.

First of all you must install jq (https://stedolan.github.io/jq/).
Second run php-quickhelp-download-or-update.

php-quickhelp can be used with or without company-php, company-phpactor and company-quickhelp.
When used with company-php, company-phpactor and company-quickhelp, it works like a wrapper for company-php or company-phpactor.
As an example, for company-phpactor,  you can do:
(add-hook 'php-mode-hook (lambda ()
    ;; .... other configs
    (require 'php-quickhelp)
    (set (make-local-variable 'company-backends)
    '(php-quickhelp-company-phpactor company-web-html company-dabbrev-code company-files))
(company-mode)))

It's possible to use php-quickhelp as eldoc backend
(setq eldoc-documentation-function
      'php-quickhelp-eldoc-func)

The function php-quickhelp-at-point can be used to show in the minibuffer the documentation.
For detail see: https://github.com/vpxyz/php-quickhelp
