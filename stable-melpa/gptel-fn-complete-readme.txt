Rewriting completion of function at point using gptel in Emacs.

This uses the existing `gptel-rewrite.el` library to perform completion on an
entire function, replacing what's already written so far in that function in
a way that prefers to complete the end of the function, but may also apply
small changes to the original function.

To use this library, install both gptel and gptel-fn-complete, and then bind
`gptel-fn-complete` to your key of choice.
