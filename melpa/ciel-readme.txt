You can use ci", ci(, ciw and so on with Ctrl-c, i.
Also you can copy them with Ctrl-c, o instead of Ctrl-c, i.
This is standalone package and you can probably use any mode.

I decided to remove cit on master branch, because it's too huge.
I'm not going to add cit againg for now.
Other command is still available and I think it's almost complete.

## Installation

Download ci.el somewhere.
For example:

cd ~/.emacs.d/elisp/
git clone https://github.com/cs14095/ciel.el

Then add the following in your .emacs file:

(setq load-path (cons "~/.emacs.d/elisp/ciel.el" load-path))
(require 'ciel)
(global-set-key "\C-ci" 'ciel-ci)
(global-set-key "\C-co" 'ciel-co)

or you installed by melpa, then just add

(global-set-key "\C-ci" 'ciel-ci)
(global-set-key "\C-co" 'ciel-co)


## Usage

Press `Ctrl-c, i` or `Ctrl-c, o` and enter available character.
Watch example or vim usage.

## Example

	Ctrl-c, i, w => kill a word
	Ctrl-c, i, ' => kill inside ''
	Ctrl-c, i, " => kill inside ""
	Ctrl-c, i, ` => kill inside ``
	Ctrl-c, i, [()] => kill inside ()
	Ctrl-c, i, [{}] => kill inside {}
	Ctrl-c, i, [<>] => kill inside <>
	Ctrl-c, i, [[]] => kill inside []

	Ctrl-c, o, w => copy a word
	Ctrl-c, o, ' => copy inside ''
	Ctrl-c, o, " => copy inside ""
	Ctrl-c, o, ` => copy inside ``
	Ctrl-c, o, [()] => copy inside ()
	Ctrl-c, o, [{}] => copy inside {}
	Ctrl-c, o, [<>] => copy inside <>
	Ctrl-c, o, [[]] => copy inside []

You can also kill the nested parentheses as you can see.
https://raw.githubusercontent.com/cs14095/cs14095.github.io/master/ci-el.gif
