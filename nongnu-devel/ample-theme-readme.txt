1 Ample Themes
══════════════

  [file:http://melpa.org/packages/ample-theme-badge.svg]
  • A Triplet of themey goodness.
  • Full colored gui and modern 256 color terminal support only.


[file:http://melpa.org/packages/ample-theme-badge.svg]
<http://melpa.org/#/ample-theme>

1.1 Installation
────────────────

  Ample Theme is on Melpa, ensure that Melpa is added to your package
  archives, then use `M-x' `package-install' `ample-theme'.
  ┌────
  │ ;; then in your init you can load all of the themes
  │ ;; without enabling theme (or just load one)
  │ (load-theme 'ample t t)
  │ (load-theme 'ample-flat t t)
  │ (load-theme 'ample-light t t)
  │ ;; choose one to enable
  │ (enable-theme 'ample)
  │ ;; (enable-theme 'ample-flat)
  │ ;; (enable-theme 'ample-light)
  │ 
  │ ;; Or, if you use `use-package', do something like this:
  │ (use-package ample-theme
  │   :init (progn (load-theme 'ample t t)
  │                (load-theme 'ample-flat t t)
  │                (load-theme 'ample-light t t)
  │                (enable-theme 'ample-flat))
  │   :defer t
  │   :ensure t)
  └────


1.2 Easy Customization
──────────────────────

  You can use the following example to customize ample theme in a way
  that won't affect other themes.

  For example, some users prefer to use a different color for strings or
  the region for more contrast.

  ┌────
  │ (with-eval-after-load "ample-theme"
  │   ;; add one of these blocks for each of the themes you want to customize
  │   (custom-theme-set-faces
  │     'ample
  │     ;; this will overwride the color of strings just for ample-theme
  │     '(font-lock-string-face ((t (:foreground "#bdba81"))))))
  └────


1.3 If you get ugly colors in terminal:
───────────────────────────────────────

  ┌────
  │ # throw this in your ~/.bash_profile
  │ export TERM="xterm-256color"
  └────


1.4 All Three Themes:
─────────────────────

  <http://i.imgur.com/WZjJty6.png> Font is [Envy Code R]


[Envy Code R]
<https://damieng.com/blog/2008/05/26/envy-code-r-preview-7-coding-font-released>


1.5 Old Screenshots:
────────────────────

1.5.1 Ample-theme in Emacs.app on osx
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  <http://i.imgur.com/5AYS8EA.png>


1.5.2 Ample-theme in Terminal.app on osx
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  <http://i.imgur.com/p15i1QM.png>
