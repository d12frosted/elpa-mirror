This code comes from my article "Effective Editing I: Movement"
http://www.masteringemacs.org/articles/2011/01/14/effective-editing-movement/

Smart Scan lets you jump between symbols in your buffer, based on
the initial symbol your point was on when you started the
search. Incremental calls will still respect the original search
query so you can move up or down in your buffer, quickly, to find
other matches without having to resort to `isearch' to find things
first. The main advantage over isearch is speed: Smart Scan will
guess the symbol point is on and immediately find other symbols
matching it, in an unintrusive way.

INSTALLATION

Install package
(package-install 'smartscan)

Enable minor mode in a specific mode hook using
(smartscan-mode 1)
or globally using
(global-smartscan-mode 1)

HOW TO USE IT

Simply type `smartscan-symbol-go-forward' (or press M-n) to go
forward; or `smartscan-symbol-go-backward' (M-p) to go
back. Additionally, you can replace all symbols point is on by
invoking M-' (that's "M-quote")

CUSTOMIZATION
You can customize `smartscan-use-extended-syntax' to alter
(temporarily, when you search) the syntax table used by Smart Scan
to find matches in your buffer.
