
This package provides a minor mode that will disallow buffers from
being killed.  Any buffer matching a regexp in the list
`unkillable-buffers' will not be killed.

Only one bufer is in `unkillable-buffers' by default: the *scratch*
buffer.

The *scratch* buffer is considered specially; in the event of a call to
`kill-buffer' the buffer will be replaced with
`initial-scratch-message'.  Removing the regexp matching *scratch* from
`unkillable-buffers' disables this behavior.

Usage:

; (optional): add regexp matching buffers to disallow killing to
; list 'unkillable-scratch
(add-to-list 'unkillable-scratch "\\*.*\\*")

; and activate the mode with
(unkillable-scratch 1)
  - or -
M-x unkillable-scratch
