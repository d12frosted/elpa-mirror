Table of Contents
─────────────────

1. About
2. Table of Contents                                         :TOC:QUOTE:
3. Installation
.. 1. via package.el
.. 2. Manual
4. Use
.. 1. Follow links
.. 2. Exclude headings
.. 3. Quote table of contents
.. 4. Shortcut for TOC tag
5. Markdown support
6. Different href styles
7. Example


[file:https://api.travis-ci.org/snosov1/toc-org.svg?branch=master]


[file:https://api.travis-ci.org/snosov1/toc-org.svg?branch=master]
<https://travis-ci.org/snosov1/toc-org>


1 About
═══════

  `toc-org' helps you to have an up-to-date table of contents in org
  files without exporting (useful primarily for readme files on GitHub).

  It is similar to the [markdown-toc] package, but works for org
  files. Since recently, `toc-org', actually, works in , too!

  *NOTE:* Previous name of the package is `org-toc'. It was changed
  because of a name conflict with one of the org contrib modules.


[markdown-toc] <https://github.com/ardumont/markdown-toc>


2 Table of Contents                                          :TOC:QUOTE:
═══════════════════

        • 
        • 

          • 
          • 
        • 

          • 
          • 
          • 
          • 
        • 
        • 
        • 


3 Installation
══════════════

3.1 via package.el
──────────────────

  [file:http://melpa.org/packages/toc-org-badge.svg]

  This is the simplest method if you have the package.el module
  (built-in since Emacs 24.1) you can simply use `M-x package-install'
  after setting up the [MELPA] repository and then put the following
  snippet in your ~/.emacs file

  ┌────
  │ (if (require 'toc-org nil t)
  │     (progn
  │       (add-hook 'org-mode-hook 'toc-org-mode)
  │ 
  │       ;; enable in markdown, too
  │       (add-hook 'markdown-mode-hook 'toc-org-mode)
  │       (define-key markdown-mode-map (kbd "\C-c\C-o") 'toc-org-markdown-follow-thing-at-point))
  │   (warn "toc-org not found"))
  └────


[file:http://melpa.org/packages/toc-org-badge.svg]
<http://melpa.org/#/toc-org>

[MELPA] <http://melpa.org/#/getting-started>


3.2 Manual
──────────

  • Create folder ~/.emacs.d if you don't have it
  • Go to it and clone toc-org there
    ┌────
    │ git clone https://github.com/snosov1/toc-org.git
    └────
  • Put this in your ~/.emacs file
    ┌────
    │ (if (require 'toc-org nil t)
    │     (progn
    │       (add-hook 'org-mode-hook 'toc-org-mode)
    │ 
    │       ;; enable in markdown, too
    │       (add-hook 'markdown-mode-hook 'toc-org-mode)
    │       (define-key markdown-mode-map (kbd "\C-c\C-o") 'toc-org-markdown-follow-thing-at-point))
    │   (warn "toc-org not found"))
    └────


4 Use
═════

  After the installation, every time you'll be saving an org file, the
  first headline with a `:TOC:' tag will be updated with the current
  table of contents.

  To add a TOC tag, you can use the command `org-set-tags-command' (`C-c
  C-q').

  In addition to the simple :TOC: tag, you can also use the following
  tag formats:

  • :TOC_2: - sets the max depth of the headlines in the table of
    contents to 2 (the default)

  • :TOC_2_gh: - sets the max depth as in above and also uses the
    GitHub-style hrefs in the table of contents (this style is
    default). The other supported href style is 'org', which is the
    default org style.

  You can also use `@' as separator, instead of `_'.

  It's possible to set the default values of max depth and hrefify
  function with `toc-org-max-depth' and `toc-org-hrefify-default'
  variables. But, note, that if you do this outside of the org file
  itself, then you can face conflicts if you work on the same file
  collaboratively with someone else, as your default configs can vary.


4.1 Follow links
────────────────

  If you call `M-x org-open-at-point' (`C-c C-o') when you're at a TOC
  entry, the point will jump to the corresponding heading.

  Notice, that this functionality exploits the
  `org-link-translation-function' variable. So, it won't work if you use
  this variable for other purposes (i.e. it is not nil).

  You can manually disable this functionality by setting
  `toc-org-enable-links-opening' to nil.


4.2 Exclude headings
────────────────────

  Headings tagged with `:noexport:' will be excluded from the TOC. If
  you want to preserve the heading, but strip its children (for
  changelog entries, for example), you can tag it `:noexport_1:' (by
  analogy, you can use `:noexport_2:', `:noexport_3:', etc. for children
  of deeper levels). Note, though, `:noexport:' has a similar meaning in
  `org-mode', which I hope is a Good Thing (tm). However, `:noexport_1:'
  and friends won't be recognized by `org-mode' as anything
  special. Look at `org-export-exclude-tags' variable for more details.


4.3 Quote table of contents
───────────────────────────

  For presentation purposes, you might want to put the table of contents
  in a quote block (i.e. `#+BEGIN_QUOTE' / `#+END_QUOTE'). In that case,
  GitHub, for example, will add a vertical line to the left of the TOC
  that makes it distinct from the main text. To do this, just add a
  `:QUOTE:' tag to the TOC heading.


4.4 Shortcut for TOC tag
────────────────────────

  In your emacs' setup, you can bind a tag `:TOC:' to a binding `T':

  ┌────
  │ (add-to-list 'org-tag-alist '("TOC" . ?T))
  └────

  Now `C-c C-q T RET' and you are done putting the `:TOC:' entry.


5 Markdown support
══════════════════

  You can also enable the mode in Markdown files and get pretty much the
  same functionality. The package will
  1. Look for '#'s instead of '*'s as heading markers.
  2. Expect the `:TOC:' tag to appear as comment, like, `<-- :TOC: -->'
  3. Format the links and the quote block according to Markdown syntax

  Example:

  ┌────
  │ # About
  │ # Table of Contents                                    <-- :TOC: -->
  │ - [About](#about)
  │ - [Installation](#installation)
  │   - [via package.el](#via-packageel)
  │   - [Manual](#manual)
  │ - [Use](#use)
  │ - [Example](#example)
  │ 
  │ # Installation
  │ ## via package.el
  │ ## Manual
  │ # Use
  │ # Example
  └────


6 Different href styles
═══════════════════════

  Currently, only 2 href styles are supported: `gh' and `org'. You can
  easily define your own styles. If you use the tag `:TOC_2_STYLE:'
  (`STYLE' being a style name), then the package will look for a
  function named `toc-org-hrefify-STYLE'.

  It should accept a heading string and a hash table of previously
  generated hrefs. The table can be used to maintain href uniqueness
  (see `toc-org-hrefify-gh', for example). Return value should be a href
  corresponding to that heading.

  E.g. for `org' style it makes links to be the same as their visible
  text:

  ┌────
  │ (defun toc-org-hrefify-org (str &optional hash)
  │   "Given a heading, transform it into a href using the org-mode
  │ rules."
  │   (toc-org-format-visible-link str))
  └────


7 Example
═════════

  ┌────
  │ * About
  │ * Table of Contents                                           :TOC:
  │ - [[#about][About]]
  │ - [[#installation][Installation]]
  │   - [[#via-packageel][via package.el]]
  │   - [[#manual][Manual]]
  │ - [[#use][Use]]
  │ - [[#example][Example]]
  │ 
  │ * Installation
  │ ** via package.el
  │ ** Manual
  │ * Use
  │ * Example
  └────
