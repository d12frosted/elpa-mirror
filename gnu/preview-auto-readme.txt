            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             PREVIEW-AUTO.EL: AUTOMATIC PREVIEWS IN AUCTEX
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 Overview
══════════

  The [introduction] to the `preview' manual reads as follows:

        Does your neck hurt from turning between previewer windows
        and the source too often? This AUCTeX component will
        render your displayed LaTeX equations right into the
        editing window where they belong.

        The purpose of preview-latex is to embed LaTeX
        environments such as display math or figures into the
        source buffers and switch conveniently between source and
        image representation.

  AUCTeX provides commands for generating previews in various regions:
  the current section, the entire document, the marked region, and so
  on.  While these previews generate, you're not supposed to edit while
  the previews generate, because that can mess up their positioning.  A
  typical workflow is thus to run the command `preview-section' (`C-c
  C-p C-s') every few minutes, during pauses in editing.  This
  introduces a bit of overhead if you prefer to have previews on by
  default.

  This package provides a minor mode, `preview-auto-mode', toggled via
  the command `M-x preview-auto-mode', the keybinding `C-c C-p C-a', or
  the `Preview' menu.  With this minor mode activated, the visible
  portion of an AUCTeX buffer is continuously previewed.  Moreover,
  previews will automatically abort if you edit in a way that could
  affect their positioning.  Finally, it works in more general
  situations (e.g., you can use it out-of-the-box to highlight LaTeX in
  source code comments for other programming languages).


[introduction]
<https://www.gnu.org/software/auctex/manual/preview-latex/Introduction.html#Introduction>


2 Configuration
═══════════════

  This package requires [AUCTeX], so install that first, and check that
  the [preview-latex] feature of AUCTeX works.

  Download this repository, install using `M-x package-install-file' (or
  package-vc-install, straight, elpaca, …), and add something like the
  following to your [init file]:
  ┌────
  │ (use-package preview-auto
  │   :hook (LaTeX-mode . preview-auto-setup))
  └────

  Customization options can be discovered via `M-x customize-group
  preview-auto'.


[AUCTeX]
<https://www.gnu.org/software/auctex/manual/auctex/Installation.html#Installation>

[preview-latex]
<https://www.gnu.org/software/auctex/manual/preview-latex/index.html#Top>

[init file] <https://www.emacswiki.org/emacs/InitFile>

2.1 Recommended AUCTeX settings
───────────────────────────────

  We recommend the following AUCTeX settings.
  ┌────
  │ (setq preview-locating-previews-message nil)
  │ (setq preview-protect-point t)
  │ (setq preview-leave-open-previews-visible t)
  └────


2.2 Optimization
────────────────

  The following setting makes preview always use DVI's, which generate
  faster than PDF's:
  ┌────
  │ (setq preview-LaTeX-command-replacements '(preview-LaTeX-disable-pdfoutput))
  └────
  If you use a package such as `hyperref' that works only with PDF's,
  then you should replace `\usepackage{hyperref}' in your TeX file with
  something like the following:
  ┌────
  │ \usepackage{ifpdf}
  │ \ifpdf \usepackage{hyperref} \fi
  └────


2.3 Always enable
─────────────────

  If you want `preview-auto-mode' to activate automatically when you
  visit a tex file (but not when you visit a bbl file), then use the
  following config:
  ┌────
  │ (use-package preview-auto
  │   :hook
  │   (LaTeX-mode . czm-preview-mode-conditionally-enable))
  └────


2.4 My setup
────────────

  I use something like the following `use-package' declaration:
  ┌────
  │ (use-package preview-auto
  │   :after latex
  │   :hook (LaTeX-mode . preview-auto-setup)
  │   :config
  │   (setq preview-protect-point t)
  │   (setq preview-locating-previews-message nil)
  │   (setq preview-leave-open-previews-visible t)
  │   :custom
  │   (preview-auto-interval 0.1)
  │ 
  │   ;; Uncomment the following only if you have followed the above
  │   ;; instructions concerning, e.g., hyperref:
  │ 
  │   ;; (preview-LaTeX-command-replacements
  │   ;;  '(preview-LaTeX-disable-pdfoutput))
  │   )
  └────

  My precise current setup may be found in [the LaTeX part of my config]
  (`elpaca' branch).


[the LaTeX part of my config]
<https://github.com/ultronozm/emacsd/blob/main/init-latex.el>


2.5 Non-file buffers and other modes
────────────────────────────────────

  This package works fine in non-file buffers running `LaTeX-mode',
  provided that you set the local variable `TeX-master' to the name of a
  valid tex file containing all the macros that you use.  For example,
  if "~/doit/preview-master.tex" is the name of such a file, and you
  want to use `preview-auto-mode' in [indirect org-mode source blocks],
  just add something like the following to your config:

  ┌────
  │ (defun my/set-TeX-master ()
  │   (setq TeX-master "~/doit/preview-master.tex"))
  │ 
  │ (advice-add 'org-edit-src-code :after 'my/set-TeX-master)
  └────

  It also works in buffers running other major modes.  (For example, I
  use it to preview LaTeX in comments in Lean4 files.)  Again, you just
  need to specify a suitable TeX-master.  For Lean4, I use something
  like:
  ┌────
  │ (add-hook 'lean4-mode-hook 'my/set-TeX-master)
  └────
  The default behavior is that in programming modes, only the comments
  are searched for latex code.  You can customize this via the defcustom
  `preview-auto-check-function'.


[indirect org-mode source blocks]
<https://orgmode.org/manual/Editing-Source-Code.html>


2.6 tikzpicture support
───────────────────────

  According to section B.4.5 of the `preview-latex' info manual, support
  for the tikzpicture environment can be enabled by adding the following
  lines to your document preamble:
  ┌────
  │ \usepackage[displaymath,sections,graphics,floats,textmath]{preview}
  │ \PreviewEnvironment[{[]}]{tikzpicture}
  └────
  If you want `preview-auto-mode' to preview such environments
  automatically (including when they are not wrapped in some math
  environment), then you should add "tikzpicture" to the customizable
  list variable `preview-auto--extra-environments', e.g., by putting
  ┌────
  │ (add-to-list 'preview-auto--extra-environments "tikzpicture")
  └────
  in your config.  I keep this disabled by default because of the extra
  setup required in the document preamble, without which `preview-latex'
  would return "LaTeX found no preview images" errors.


3 Issues
════════

  • Sometimes the preview command run by the timer produces the same
    error over and over again, effectively locking Emacs.  If this
    happens, you should hold down `C-g' until the timer dies.  Then, try
    using `preview' "normally" and sort out the erorrs.  Finally, toggle
    `preview-auto-mode'.

  • When the timer provided by `preview-auto' fires, it clears the
    minibuffer.  This is because `inhibit-message' is used surrounding a
    call to `write-region' to prevent flooding the minibuffer with
    "Wrote…" messages, but messages sent under `inhibit-message' still
    clear the minibuffer.  This can be a bit annoying if you are looking
    at the minibuffer for some other reason (e.g., Flymake) while the
    `preview-auto' timer is firing a bunch.  Fixing this would require
    tweaking AUCTeX's internals a bit.

  • Very rarely, I've seen some `preview-latex' process (e.g.,
    Ghostscript) gets stuck.  The symptom is that `preview-auto' will
    not generate anything, even after resetting the mode.  You can check
    if this has happened using `M-: (get-buffer-process
    (TeX-process-buffer-name (TeX-region-file)))'.  The fix is then to
    navigate to the `_region_.tex' buffer and do `M-x TeX-kill-job'.
