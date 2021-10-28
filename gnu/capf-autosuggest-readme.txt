capf-autosuggest lets you preview the most recent matching history element,
similar to zsh-autosuggestions or fish.  It works in eshell and in modes
derived from comint-mode, for example M-x shell and M-x run-python.

Installation:

Add the following to your Emacs init file:

 (add-to-list 'load-path "/path/to/emacs-capf-autosuggest")
 (autoload 'capf-autosuggest-mode "capf-autosuggest")
 (add-hook 'comint-mode-hook #'capf-autosuggest-mode)
 (add-hook 'eshell-mode-hook #'capf-autosuggest-mode)

Configuration:

Use `capf-autosuggest-define-partial-accept-cmd' to make a command that can
move point into an auto-suggested layer.

Example: to make C-M-f (forward-sexp) movable into suggested text, put the
following into your Emacs init file:

 (with-eval-after-load 'capf-autosuggest
   (capf-autosuggest-define-partial-accept-cmd
    movable-forward-sexp forward-sexp)
   (define-key capf-autosuggest-active-mode-map
     [remap forward-sexp] #'movable-forward-sexp))

By default, C-n (next-line) will accept the currently displayed suggestion
and send input to shell/eshell.  See the customization group
capf-autosuggest do disable this behaviour or enable it for other commands,
such as C-c C-n or M-n.

Details:

capf-autosuggest provides a minor mode, capf-autosuggest-mode, that lets you
preview the first completion candidate for in-buffer completion as an
overlay.  Instead of using the default hook `completion-at-point-functions',
it uses its own hook `capf-autosuggest-capf-functions'.  However, by
default, this hook contains a function that reads the default hook, but only
if point is at end of line, because an auto-suggested overlay can be
annoying in the middle of a line.  If you want, you can try enabling this
minor mode in an ordinary buffer for previewing tab completion candidates at
end of line.

A completion-at-point function for comint and eshell history is also
provided.  Because it is less useful for tab completion and more useful for
auto-suggestion preview, it is a member of
`capf-autosuggest-capf-functions', which doesn't interfere with tab
completion.  By default, if there are no matches for history completion and
point is at end of line, we fall back to previewing the default tab
completion candidates, as described in the previous paragraph.

You can customize this behaviour by customizing
`capf-autosuggest-capf-functions'. For example, you could add
`capf-autosuggest-orig-capf' to enable auto-suggestions of tab completion
candidates in the middle of a line.

Alternatives:

There is also esh-autosuggest[1] with similar functionality.  Differences:
it is simpler and more concise, however it depends on company. It optionally
allows having a delay and it is implemented only for eshell.

[1]: http://github.com/dieggsy/esh-autosuggest