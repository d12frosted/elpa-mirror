Same as ac-html, but for `company' completion framework.

Configuration:

  (add-to-list 'company-backends 'company-web-html)
  (add-to-list 'company-backends 'company-web-jade)
  (add-to-list 'company-backends 'company-web-slim)

or, for example, setup web-mode-hook:

  (define-key web-mode-map (kbd "C-'") 'company-web-html)
  (add-hook 'web-mode-hook (lambda ()
                            (set (make-local-variable 'company-backends) '(company-web-html company-files))
                            (company-mode t)))

When you use `emmet-mode' (with `web-mode' and `html-mode')
you may autocomplete as well as regular html complete.

P.S: You may be interested in next packages:

`ac-html-bootstrap' - Twitter:Bootstrap completion data for company-web (and ac-html as well)
`ac-html-csswatcher' - Watch your project CSS/Less files for classes and ids
`ac-html-angular' - Angular 1.5 completion data;
