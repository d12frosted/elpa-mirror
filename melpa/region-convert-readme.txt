; ## Interactive
;
;  1. Select text region (mark region)
;  2. M-x region-convert (or press binding key)
;  3. Input function name
;
; ### Key binding
;
;      (global-set-key (kbd "C-c r") 'region-convert)
;
; ## Use from Lisp
;
;     (region-convert 5 22 'upcase)
;
