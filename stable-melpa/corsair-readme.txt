Corsair provides enhancements for GPTel, allowing for context accumulation
and file expansion within Emacs projects.

Suggested Key bindings:
(global-set-key (kbd "C-c g c") #'corsair-open-chat-buffer)                    ;; Open chat buffer
(global-set-key (kbd "C-c g a c") #'corsair-accumulate-file-path-and-contents) ;; Accumulate file path and contents
(global-set-key (kbd "C-c g a n") #'corsair-accumulate-file-name)              ;; Accumulate file name
(global-set-key (kbd "C-c g a v") #'corsair-accumulate-file-path)              ;; Accumulate file path
(global-set-key (kbd "C-c g a w") #'corsair-accumulate-selected-text)          ;; Accumulate selected text
(global-set-key (kbd "C-c g a D") #'corsair-drop-accumulated-buffer)           ;; Drop chat buffer
(global-set-key (kbd "C-c g f") #'corsair-insert-file-or-folder-contents)      ;; Insert file or folder contents
