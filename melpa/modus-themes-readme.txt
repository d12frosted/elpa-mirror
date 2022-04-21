
The Modus themes conform with the highest standard for color-contrast
accessibility between background and foreground values (WCAG AAA).
This file contains all customization variables, helper functions,
interactive commands, and face specifications.  Please refer to the
official Info manual for further documentation (distributed with the
themes, or available at: <https://protesilaos.com/emacs/modus-themes>).

The themes share the following customization variables:

    modus-themes-completions                    (alist)
    modus-themes-headings                       (alist)
    modus-themes-org-agenda                     (alist)
    modus-themes-bold-constructs                (boolean)
    modus-themes-deuteranopia                   (boolean)
    modus-themes-inhibit-reload                 (boolean)
    modus-themes-intense-mouseovers             (boolean)
    modus-themes-italic-constructs              (boolean)
    modus-themes-mixed-fonts                    (boolean)
    modus-themes-subtle-line-numbers            (boolean)
    modus-themes-variable-pitch-ui              (boolean)
    modus-themes-box-buttons                    (choice)
    modus-themes-diffs                          (choice)
    modus-themes-fringes                        (choice)
    modus-themes-hl-line                        (choice)
    modus-themes-lang-checkers                  (choice)
    modus-themes-links                          (choice)
    modus-themes-mail-citations                 (choice)
    modus-themes-markup                         (choice)
    modus-themes-mode-line                      (choice)
    modus-themes-org-blocks                     (choice)
    modus-themes-paren-match                    (choice)
    modus-themes-prompts                        (choice)
    modus-themes-region                         (choice)
    modus-themes-syntax                         (choice)

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
    alert
    all-the-icons
    all-the-icons-dired
    all-the-icons-ibuffer
    annotate
    ansi-color
    anzu
    apropos
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
    calendar and diary
    calfw
    centaur-tabs
    cfrs
    change-log and log-view (`vc-print-log' and `vc-print-root-log')
    cider
    circe
    citar
    color-rg
    column-enforce-mode
    company-mode
    company-posframe
    compilation-mode
    completions
    consult
    corfu
    corfu-quick
    counsel
    counsel-css
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
    deft
    devdocs
    dictionary
    diff-hl
    diff-mode
    dim-autoload
    dir-treeview
    Dired
    dired-async
    dired-git
    dired-git-info
    dired-narrow
    dired-subtree
    diredfl
    diredp (dired+)
    display-fill-column-indicator-mode
    doom-modeline
    dynamic-ruler
    easy-jekyll
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
    ement (ement.el)
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
    git-rebase
    git-timemachine
    gnus
    gotest
    golden-ratio-scroll-screen
    helm
    helm-ls-git
    helm-switch-shell
    helm-xref
    helpful
    highlight-indentation
    highlight-numbers
    highlight-thing
    hl-defined
    hl-fill-column
    hl-line-mode
    hl-todo
    hydra
    ibuffer
    icomplete
    ido-mode
    iedit
    iflipb
    image-dired
    imenu-list
    indium
    info
    info-colors
    interaction-log
    ioccur
    isearch, occur, etc.
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
    mct
    mentor
    messages
    mini-modeline
    minimap
    mmm-mode
    mode-line
    mood-line
    mpdel
    mu4e
    multiple-cursors
    nano-modeline
    neotree
    notmuch
    num3-mode
    nxml-mode
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
    pass
    pdf-tools
    persp-mode
    perspective
    phi-grep
    pomidor
    popup
    powerline
    powerline-evil
    prism (see "Note for prism.el" in the manual)
    proced
    prodigy
    pulse
    pyim
    quick-peek
    racket-mode
    rainbow-blocks
    rainbow-delimiters
    rcirc
    recursion-indicator
    regexp-builder (also known as `re-builder')
    rg
    ripgrep
    rmail
    ruler-mode
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
    slime (sldb)
    sly
    smart-mode-line
    smartparens
    smerge
    spaceline
    speedbar
    stripes
    suggest
    switch-window
    swiper
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
    textsec
    tomatinho
    transient (pop-up windows like Magit's)
    trashed
    tree-sitter
    treemacs
    tty-menu
    tuareg
    typescript
    undo-tree
    vc (vc-dir.el, vc-hooks.el)
    vc-annotate (C-x v g)
    vertico
    vertico-quick
    vimish-fold
    visible-mark
    visual-regexp
    vterm
    vundo
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
