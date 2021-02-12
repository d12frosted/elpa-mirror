
; ~/.emacs.d/init.el

(with-eval-after-load 'company-ngram
  ; ~/data/ngram/*.txt are used as data
  (setq company-ngram-data-dir "~/data/ngram")
  ; company-ngram supports python 3 or newer
  (setq company-ngram-python "python3")
  (company-ngram-init)
  (cons 'company-ngram-backend company-backends)
  ; or use `M-x turn-on-company-ngram' and
  ; `M-x turn-off-company-ngram' on individual buffers
  ;
  ; save the cache of candidates
  (run-with-idle-timer 3600 t
                       (lambda ()
                         (company-ngram-command "save_cache")
                         ))
  )
(require 'company-ngram nil t)
