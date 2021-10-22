Quickstart

    (require 'pygn-mode)

    M-x pygn-mode-run-diagnostic

Explanation

    Pygn-mode is a major-mode for viewing and editing chess PGN files.
    Directly editing PGN files is interesting for programmers who are
    developing chess engines, or advanced players who are doing deep
    analysis on games.  This mode is not useful for simply playing chess.

Bindings

    No keys are bound by default.  Consider

        (eval-after-load "pygn-mode"
          (define-key pygn-mode-map (kbd "C-c C-n") 'pygn-mode-next-game)
          (define-key pygn-mode-map (kbd "C-c C-p") 'pygn-mode-previous-game)
          (define-key pygn-mode-map (kbd "M-f")     'pygn-mode-next-move)
          (define-key pygn-mode-map (kbd "M-b")     'pygn-mode-previous-move)
          (define-key pygn-mode-map (kbd "C-h $")   'pygn-mode-describe-annotation-at-pos))

Customization

    M-x customize-group RET pygn RET

See Also

    http://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm

    https://github.com/dwcoates/uci-mode

Prior Art

    https://github.com/jwiegley/emacs-chess

Notes

Compatibility and Requirements

    GNU Emacs 26.1+, compiled with dynamic module support

    tree-sitter.el and tree-sitter-langs.el

    Python and the chess library are needed for numerous features such
    as SVG board images:

        https://pypi.org/project/chess/

    A version of the Python chess library is bundled with this package.
    Note that the chess library has its own license (GPL3+).
