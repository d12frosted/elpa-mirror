Add the following to your Emacs init file.

    (require 'web-beautify) ;; Not necessary if using ELPA package
    (eval-after-load 'js2-mode
      '(define-key js2-mode-map (kbd "C-c b") 'web-beautify-js))
    (eval-after-load 'json-mode
      '(define-key json-mode-map (kbd "C-c b") 'web-beautify-js))
    (eval-after-load 'sgml-mode
      '(define-key html-mode-map (kbd "C-c b") 'web-beautify-html))
    (eval-after-load 'css-mode
      '(define-key css-mode-map (kbd "C-c b") 'web-beautify-css))

If you want to automatically format before saving a file,
add the following hook to your Emacs configuration:

    (eval-after-load 'js2-mode
      '(add-hook 'js2-mode-hook
                 (lambda ()
                   (add-hook 'before-save-hook 'web-beautify-js-buffer t t))))

    (eval-after-load 'json-mode
      '(add-hook 'json-mode-hook
                 (lambda ()
                   (add-hook 'before-save-hook 'web-beautify-js-buffer t t))))

    (eval-after-load 'sgml-mode
      '(add-hook 'html-mode-hook
                 (lambda ()
                   (add-hook 'before-save-hook 'web-beautify-html-buffer t t))))

    (eval-after-load 'css-mode
      '(add-hook 'css-mode-hook
                 (lambda ()
                   (add-hook 'before-save-hook 'web-beautify-css-buffer t t))))

For more information, See URL https://github.com/yasuyk/web-beautify.
