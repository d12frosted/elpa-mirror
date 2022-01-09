Leverage JuliaFormatter.jl to format julia code in Emacs.

Provide formatting tools for live coding.  These tools are packed into a
service that can be called using JSON-RPC on stdin / stdout.  Exposing
JuliaFormatter.jl as a service because the compile time required to get the
result of that first format_text() call is considerable and it hinders the
coding process.

The code that's being formatted must be self-contained (parseable, all if's
and while's with a corresponding end).  This is a requirement from
JuliaFormatter.jl since it needs to get the AST from the code.

The simplest way to use JuliaFormatter.jl is by activating
`aggressive-indent-mode' and setting the proper functions
(yes, indentation functionality can be leveraged for live formatting))

Like so:
;; load this file after downloading this package (or installing with straight.el)
(require 'julia-formatter)
;; load aggressive indent and setup appropiate variables
(julia-formatter-setup-hooks)

See https://github.com/domluna/JuliaFormatter.jl

This package requires Emacs 27 because previous version of `replace-buffer-contents' is buggy
See https://debbugs.gnu.org/cgi/bugreport.cgi?bug=32237 & https://debbugs.gnu.org/cgi/bugreport.cgi?bug=32278


