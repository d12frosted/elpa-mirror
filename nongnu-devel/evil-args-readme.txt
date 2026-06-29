# evil-args
Motions and text objects for delimited arguments in
[Evil](https://gitorious.org/evil/), the extensible vi layer for Emacs.

## Setup
### Installing from MELPA
If you already use MELPA, all you have to do is:

    M-x package-install RET evil-args RET

For help installing and using MELPA, see [these instructions](
melpa.milkbox.net/#/getting-started).

### Installing from Github
Install `evil-args` manually from Github with:

    git clone https://github.com/wcsmith/evil-args.git
    
### Configuration
After installing `evil-args`, add the following to your `.emacs`:

    ;; locate and load the package
    (add-to-list 'load-path "path/to/evil-args")
    (require 'evil-args)

    ;; bind evil-args text objects
    (define-key evil-inner-text-objects-map "a" 'evil-inner-arg)
    (define-key evil-outer-text-objects-map "a" 'evil-outer-arg)

    ;; bind evil-forward/backward-args
    (define-key evil-normal-state-map "L" 'evil-forward-arg)
    (define-key evil-normal-state-map "H" 'evil-backward-arg)
    (define-key evil-motion-state-map "L" 'evil-forward-arg)
    (define-key evil-motion-state-map "H" 'evil-backward-arg)

    ;; bind evil-jump-out-args
    (define-key evil-normal-state-map "K" 'evil-jump-out-args)

## Functionality

### `evil-inner-arg`/`evil-outer-arg`
Select an inner/outer argument text object.

For example, `cia` transforms:

    function(ar|g1, arg2, arg3)
    function(|, arg2, arg3)

or

    function(arg1, ar|g2, arg3)
    function(arg1, |, arg3)

`daa` transforms:

    function(ar|g1, arg2, arg3)
    function(|arg2, arg3)

or

    function(arg1, ar|g2, arg3)
    function(arg1, |arg3)

### `evil-forward-arg`/`evil-backward-arg`

Move the curser to the next/previous argument.

For example, successive presses of `evil-forward-arg` yield:

    function(ar|g1, arg2, arg3)
    function(arg1, |arg2, arg3)
    function(arg1, arg2, |arg3)
    function(arg1, arg2, arg3|)

Successive presses of `evil-backward-arg` yield:

    function(arg1, arg2, ar|g3)
    function(arg1, arg2, |arg3)
    function(arg1, |arg2, arg3)
    function(|arg1, arg2, arg3)

### `evil-jump-out-args`
Moves to the beginning of the first object outside of the current argument
context.

For example, pressing `evil-jump-out-args` yields:

    function(arg1, arg2, ar|g3)
    |function(arg1, arg2, arg3)

Successive presses of `evil-jump-out-args` yield:

    if (x == y) {
        statement1;
        state|ment2;
    }

    if (|x == y) {
        statement1;
        statement2;
    }

    |if (x == y) {
        statement1;
        statement2;
    }
    
## Customization
Currently, `evil-args` uses `,` and `;` as delimiters. The definition of
delimiters and matching pairs can be customized by changing the variables
`evil-args-openers`, `evil-args-closers`, and `evil-args-delimiters`.

For example, setting `evil-args-delimiters` to `(" ")` would allow for
`evil-args` features in Lisp lists; repeated presses of `evil-forward-arg`
would yield:

    (fun|ction a b)
    (function |a b)
    (function a |b)
    (function a b|)
