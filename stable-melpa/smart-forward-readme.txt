smart-forward gives you semantic navigation, building on
[expand-region](https://github.com/magnars/expand-region.el). It is most easily
explained by example:

   function test() {
     return "semantic navigation";
   }

With point at the start of the quotes,

 * `smart-forward` would go to the end of the quotes
 * `smart-backward` would go to the start of `return`, then to the `{`.
 * `smart-up` would go to the `{`
 * `smart-down` would go to the `}`

I use M-up/down/left/right arrows for this.

## Installation

Start by installing
[expand-region](https://github.com/magnars/expand-region.el).

    (require 'smart-forward)
    (global-set-key (kbd "M-<up>") 'smart-up)
    (global-set-key (kbd "M-<down>") 'smart-down)
    (global-set-key (kbd "M-<left>") 'smart-backward)
    (global-set-key (kbd "M-<right>") 'smart-forward)

## Contribute

smart-forward is a thin wrapper around expand-region. Most fixes to
smart-forward belong there.
