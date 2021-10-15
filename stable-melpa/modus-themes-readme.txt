
The Modus themes conform with the highest standard for color-contrast
accessibility between background and foreground values (WCAG AAA).
This file contains all customization variables, helper functions,
interactive commands, and face specifications.  Please refer to the
official Info manual for further documentation (distributed with the
themes, or available at: <https://protesilaos.com/modus-themes>).

The themes share the following customization variables:

    modus-themes-headings                       (alist)
    modus-themes-org-agenda                     (alist)
    modus-themes-bold-constructs                (boolean)
    modus-themes-inhibit-reload                 (boolean)
    modus-themes-intense-markup                 (boolean)
    modus-themes-italic-constructs              (boolean)
    modus-themes-mixed-fonts                    (boolean)
    modus-themes-scale-headings                 (boolean)
    modus-themes-subtle-line-numbers            (boolean)
    modus-themes-success-deuteranopia           (boolean)
    modus-themes-variable-pitch-headings        (boolean)
    modus-themes-variable-pitch-ui              (boolean)
    modus-themes-completions                    (choice)
    modus-themes-diffs                          (choice)
    modus-themes-fringes                        (choice)
    modus-themes-hl-line                        (choice)
    modus-themes-lang-checkers                  (choice)
    modus-themes-links                          (choice)
    modus-themes-mail-citations                 (choice)
    modus-themes-mode-line                      (choice)
    modus-themes-org-blocks                     (choice)
    modus-themes-paren-match                    (choice)
    modus-themes-prompts                        (choice)
    modus-themes-region                         (choice)
    modus-themes-syntax                         (choice)
    modus-themes-mode-line-padding              (natnum)

The default scale for headings is as follows (it can be customized as
well---remember, no scaling takes place by default):

    modus-themes-scale-1                        1.05
    modus-themes-scale-2                        1.1
    modus-themes-scale-3                        1.15
    modus-themes-scale-4                        1.2
    modus-themes-scale-title                    1.3

There is another scaling-related option, which however is reserved
for special cases and is not used for headings:

    modus-themes-scale-small                    0.9

There also exist two unique customization variables for overriding
color palette values.  The specifics are documented in the manual.
The symbols are:

    modus-themes-operandi-color-overrides       (alist)
    modus-themes-vivendi-color-overrides        (alist)

Below is the list of explicitly supported packages or face groups
(there are implicitly supported packages as well, which inherit from
font-lock or some basic group).  You are encouraged to report any
missing package or change you would like to see.

    ace-window
    ag
    alert
    all-the-icons
    annotate
    ansi-color
    anzu
    apropos
    apt-sources-list
    artbollocks-mode
    auctex and TeX
    auto-dim-other-buffers
    avy
    awesome-tray
    bbdb
    binder
    bm
    bongo
    boon
    bookmark
    breakpoint (provided by built-in gdb-mi.el)
    buffer-expose
    calendar and diary
    calfw
    centaur-tabs
    cfrs
    change-log and log-view (`vc-print-log' and `vc-print-root-log')
    cider
    circe
    color-rg
    column-enforce-mode
    company-mode
    company-posframe
    compilation-mode
    completions
    consult
    corfu
    counsel
    counsel-css
    counsel-org-capture-string
    cov
    cperl-mode
    css-mode
    csv-mode
    ctrlf
    cursor-flash
    custom (M-x customize)
    dap-mode
    dashboard (emacs-dashboard)
    deadgrep
    debbugs
    define-word
    deft
    dictionary
    diff-hl
    diff-mode
    dim-autoload
    dir-treeview
    dired
    dired-async
    dired-git
    dired-git-info
    dired-narrow
    dired-subtree
    diredc
    diredfl
    diredp (dired+)
    disk-usage
    display-fill-column-indicator-mode
    doom-modeline
    dynamic-ruler
    easy-jekyll
    easy-kill
    ebdb
    ediff
    eglot
    el-search
    eldoc
    eldoc-box
    elfeed
    elfeed-score
    elpher
    embark
    emms
    enh-ruby-mode (enhanced-ruby-mode)
    epa
    equake
    erc
    eros
    ert
    eshell
    eshell-fringe-status
    eshell-git-prompt
    eshell-prompt-extras (epe)
    eshell-syntax-highlighting
    evil (evil-mode)
    evil-goggles
    evil-snipe
    evil-visual-mark-mode
    eww
    exwm
    eyebrowse
    fancy-dabbrev
    flycheck
    flycheck-color-mode-line
    flycheck-indicator
    flycheck-posframe
    flymake
    flyspell
    flyspell-correct
    flx
    freeze-it
    frog-menu
    focus
    fold-this
    font-lock (generic syntax highlighting)
    forge
    fountain (fountain-mode)
    geiser
    git-commit
    git-gutter (and variants)
    git-lens
    git-rebase
    git-timemachine
    git-walktree
    gnus
    gotest
    golden-ratio-scroll-screen
    helm
    helm-ls-git
    helm-switch-shell
    helm-xref
    helpful
    highlight-blocks
    highlight-defined
    highlight-escape-sequences (`hes-mode')
    highlight-indentation
    highlight-numbers
    highlight-symbol
    highlight-tail
    highlight-thing
    hl-defined
    hl-fill-column
    hl-line-mode
    hl-todo
    hydra
    hyperlist
    ibuffer
    icomplete
    ido-mode
    iedit
    iflipb
    imenu-list
    indium
    info
    info-colors
    interaction-log
    ioccur
    isearch, occur, etc.
    isl (isearch-light)
    ivy
    ivy-posframe
    jira (org-jira)
    journalctl-mode
    js2-mode
    julia
    jupyter
    kaocha-runner
    keycast
    ledger-mode
    line numbers (`display-line-numbers-mode' and global variant)
    lsp-mode
    lsp-ui
    macrostep
    magit
    magit-imerge
    make-mode
    man
    marginalia
    markdown-mode
    markup-faces (`adoc-mode')
    mentor
    messages
    minibuffer-line
    minimap
    mmm-mode
    mode-line
    mood-line
    mpdel
    mu4e
    mu4e-conversation
    multiple-cursors
    nano-modeline
    neotree
    no-emoji
    notmuch
    num3-mode
    nxml-mode
    objed
    orderless
    org
    org-journal
    org-noter
    org-pomodoro
    org-recur
    org-roam
    org-superstar
    org-table-sticky-header
    org-tree-slide
    org-treescope
    origami
    outline-mode
    outline-minor-faces
    package (M-x list-packages)
    page-break-lines
    pandoc-mode
    paradox
    paren-face
    parrot
    pass
    pdf-tools
    persp-mode
    perspective
    phi-grep
    phi-search
    pkgbuild-mode
    pomidor
    popup
    powerline
    powerline-evil
    prism (see "Note for prism.el" in the manual)
    proced
    prodigy
    pulse
    quick-peek
    racket-mode
    rainbow-blocks
    rainbow-identifiers
    rainbow-delimiters
    rcirc
    recursion-indicator
    regexp-builder (also known as `re-builder')
    rg
    ripgrep
    rmail
    ruler-mode
    sallet
    selectrum
    selectrum-prescient
    semantic
    sesman
    shell-script-mode
    shortdoc
    show-paren-mode
    shr
    side-notes
    sieve-mode
    skewer-mode
    smart-mode-line
    smartparens
    smerge
    spaceline
    speedbar
    spell-fu
    spray
    stripes
    suggest
    switch-window
    swiper
    swoop
    sx
    symbol-overlay
    syslog-mode
    tab-bar-groups
    tab-bar-mode
    tab-line-mode
    table (built-in table.el)
    telega
    telephone-line
    terraform-mode
    term
    tomatinho
    transient (pop-up windows like Magit's)
    trashed
    treemacs
    tty-menu
    tuareg
    typescript
    undo-tree
    vc (vc-dir.el, vc-hooks.el)
    vc-annotate (C-x v g)
    vdiff
    vertico
    vertico-quick
    vimish-fold
    visible-mark
    visual-regexp
    volatile-highlights
    vterm
    wcheck-mode
    web-mode
    wgrep
    which-function-mode
    which-key
    whitespace-mode
    window-divider-mode
    winum
    writegood-mode
    woman
    xah-elisp-mode
    xref
    xterm-color (and ansi-colors)
    yaml-mode
    yasnippet
    ztree

For a complete view of the project, also refer to the following files
(should be distributed in the same repository/directory as the
current item):

- modus-operandi-theme.el    (Light theme)
- modus-vivendi-theme.el     (Dark theme)
