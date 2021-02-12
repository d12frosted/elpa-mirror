
Minor mode for coq

You can automatically start this minor mode with following elisp
when you use Proof-General

 (add-hook 'coq-mode-hook 'coq-commenter-mode)

You can set your key with

 (define-key coq-commenter-mode-map
             (kbd "C-;")
             #'coq-commenter-comment-proof-in-region)
 (define-key coq-commenter-mode-map
             (kbd "C-x C-;")
             #'coq-commenter-comment-proof-to-cursor)
 (define-key coq-commenter-mode-map
             (kbd "C-'")
             #'coq-commenter-uncomment-proof-in-region)
 (define-key coq-commenter-mode-map
             (kbd "C-x C-'")
             #'coq-commenter-uncomment-proof-in-buffer)

or whatever you want.
