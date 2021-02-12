Presentation mode is a global minor mode to zoom characters.
This mode applies the effect of `text-scale-mode' to all buffers.
This feature help you to present Emacs edit / operation to the audience
in front of the screen.

## How to use

 1. Execute `M-x presentation-mode' to start the presentation.
 2. Adjust scale size by `C-x C-+' or `C-x C--'
    See https://www.gnu.org/software/emacs/manual/html_node/emacs/Text-Scale.html
 3. After the presentation, execute `M-x presentation-mode` again.
 4. And then execute `M-x presentation-mode` again, the last scale will be reproduced.
 5. If you want to persistize its size as the default size of presentation-mode
    after restarting Emacs, set `presentation-default-text-scale`.

## Notice

### Not for "persistent font size change"

It is well known that how to change the font size of Emacs in GUI is difficult.
However, this mode is *NOT* intended for permanent font size change.

https://www.gnu.org/software/emacs/manual/html_node/elisp/Parameter-Access.html
https://www.gnu.org/software/emacs/manual/html_node/emacs/Frame-Parameters.html

## Difference from other methods

### vs GlobalTextScaleMode (Emacs Wiki)

Although the content of this article is simple, it does not provide a way to
recover buffers.
https://www.emacswiki.org/emacs/GlobalTextScaleMode

### Org Tree Slide / org-present

These packages are simple presentations using org-mode.
By using these with org-babel, it may be possible to perform live coding of
arbitrary languages.
https://github.com/takaxp/org-tree-slide
https://github.com/rlister/org-present
