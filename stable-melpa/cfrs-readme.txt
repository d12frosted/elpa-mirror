; Simple implementation of reading a string with child-frames.
; Synchronous control is maintained by using `recursive-edit'.  When finished
; the entered text is read from the input buffer and the child-frame is
; hidden.
