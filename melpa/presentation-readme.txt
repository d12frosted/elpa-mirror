Presentation mode is a global minor mode that provides a distraction-free
environment for live demos.  It scales text across all buffers and provides
hooks to automate UI changes, such as toggling line numbers or switching themes.

Key features:
- Global text scaling for high visibility on projectors/screen-sharing.
- `presentation-on-hook' and `presentation-off-hook' for UI automation.
- Persistence of scale size between sessions.
- Optional integration with Emacs 29's `global-text-scale-adjust'.

## How to use

 1. Execute `M-x presentation-mode' to start the presentation.
 2. Adjust scale size using `C-x C-+' or `C-x C--'.
    (See: https://www.gnu.org/software/emacs/manual/html_node/emacs/Text-Scale.html )
 3. Execute `M-x presentation-mode' again to end and restore your UI.
 4. Toggling the mode back on will automatically reproduce the last used scale.
 5. To set a permanent default scale, customize `presentation-default-text-scale'.

## Technical Notes

### Permanent font changes

This mode is NOT intended for permanent font configuration.  If you wish to
change the default font size of Emacs frames permanently, please refer to:
https://www.gnu.org/software/emacs/manual/html_node/elisp/Parameter-Access.html

## Comparison

- vs `default-text-scale': Use `default-text-scale' for permanent global
  scaling.  Use `presentation.el' for temporary demo environments.
- vs `org-tree-slide' / `org-present': These are specific to Org-mode slides.
  `presentation.el' is for general Emacs usage and live-coding.
