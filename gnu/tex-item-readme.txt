           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            TEX-ITEM.EL: COMMANDS FOR WORKING WITH TEX ITEMS
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 Overview
══════════

  This package provides commands for navigating and editing in terms of
  `\item' blocks in a TeX document.


2 Configuration
═══════════════

  Download this repository, install using `M-x package-install-file' (or
  package-vc-install, straight, elpaca, …), and add something like the
  following to your [init file], adjusting the binds according to
  preference (and replacing `LaTeX-mode' with `latex-mode' or `tex-mode'
  or `plain-tex-mode', whichever is appropriate, if you don't use
  AUCTeX):
  ┌────
  │ (use-package tex-item
  │   :after latex
  │   :config
  │   (defvar-keymap tex-item-map
  │     :repeat t
  │     "n" #'tex-item-forward
  │     "p" #'tex-item-backward
  │     "SPC" #'tex-item-mark
  │     "k" #'tex-item-kill
  │     "<backspace>" #'tex-item-backward-kill
  │     "t" #'tex-item-transpose
  │     "<down>" #'tex-item-move-down
  │     "<up>" #'tex-item-move-up)
  │   (define-key LaTeX-mode-map (kbd "M-g M-i") tex-item-map))
  └────

  This configuration makes use of `repeat-mode' (see [the Emacs manual]
  or [this blog post]) to make it easier to apply such commands
  repeatedly.  The precise use-package declaration that I use may be
  found in [the LaTeX part of my config] (elpaca branch).


[init file] <https://www.emacswiki.org/emacs/InitFile>

[the Emacs manual]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Repeating.html>

[this blog post] <https://karthinks.com/software/it-bears-repeating/>

[the LaTeX part of my config]
<https://github.com/ultronozm/emacsd/blob/main/init-latex.el>


3 Usage
═══════

  The `\item' block associated to a given position is the one that
  contains that position and for which the position is not contained in
  any subordinate begin/end itemize-like block.  For example, consider
  the TeX code:
  ┌────
  │ \begin{enumerate}
  │ \item Alpha
  │ \item Beta:
  │   \begin{enumerate}
  │   \item One
  │   \item Two
  │   \end{enumerate}
  │ \end{enumerate}
  └────
  Here, the top-level `\item' blocks are:
  ┌────
  │ \item Alpha
  └────
  ┌────
  │ \item Beta:
  │   \begin{enumerate}
  │   \item One
  │   \item Two
  │   \end{enumerate}
  └────
  If the point on the line containing "Beta", then the associated
  `\item' block is the one displayed above.  If the point is instead on
  the line containing "One", then we instead associate the block
  consisting of the following line:
  ┌────
  │ \item One
  └────
  The commands provided by this package operate in an intuitive way on
  such blocks.  For example, if we apply `tex-item-move-up' (`M-g M-i
  <up>') with point on "Beta", then we obtain the following
  rearrangement:
  ┌────
  │ \begin{enumerate}
  │ \item Beta:
  │   \begin{enumerate}
  │   \item One
  │   \item Two
  │   \end{enumerate}
  │ \item Alpha
  │ \end{enumerate}
  └────


4 Customization
═══════════════

  By default, this package pays attention to the macros `\item',
  `\bibitem' and `\task', as well as the list environments `itemize',
  `enumerate' and `description'.  You can use other macros or
  environments by adding them to the customization variables
  `tex-item-items' and `tex-item-envs'.
