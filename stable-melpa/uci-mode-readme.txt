Quickstart

    $ which stockfish
    /usr/local/bin/stockfish

    (require 'uci-mode)

    M-x uci-mode-run-engine

Explanation

    Uci-mode is a comint-derived major-mode for interacting directly with
    a UCI chess engine.  Direct UCI interaction is interesting for
    programmers who are developing chess engines, or advanced players who
    are doing deep analysis on games.  This mode is not useful for simply
    playing chess.

See Also

    M-x customize-group RET uci RET

    M-x customize-group RET comint RET

    https://github.com/dwcoates/pygn-mode

    http://wbec-ridderkerk.nl/html/UCIProtocol.html

Notes

Compatibility and Requirements

    GNU Emacs version 25.1 or higher

    A command-line UCI chess engine such as Stockfish (the default)
