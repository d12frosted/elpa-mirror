; Adds new textobjects:
;
; ii - Inner Indentation: the surrounding textblock with the same indentation
; ai - Above and Indentation: ii + the line above with a different indentation
; aI - Above and Indentation+: ai + the line below with a different indentation
;
; With | representing the cursor:
;
; (while (not done)
;   (messa|ge "All work and no play makes Jack a dull boy."))
; (1+ 41)
;
; - vii will select the line with message
; - vai will select the whole while loop
; - vaI will select the whole fragment
