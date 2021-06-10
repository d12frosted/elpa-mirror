This library completes code using tags file created by Ctags.
It uses a much faster algorithm optimized for ctags.
It takes only 9 seconds to load 300M tags file which is created by
scanning the Linux Kernel code v5.3.1.
After initial loading, this library will respond immediately
when new tags file is created.

Usage:

  Step 0, Make sure `company-mode' is already set up
  See http://company-mode.github.io/ for details.

  Step 1, insert below code into your configuration,

    (with-eval-after-load 'company
       (company-ctags-auto-setup))

  Step 2, Use Ctags to create tags file and enjoy.

Tips:

- Turn on `company-ctags-support-etags' to support tags
file created by etags.  But it will increase initial loading time.

- Set `company-ctags-extra-tags-files' to load extra tags files,

  (setq company-ctags-extra-tags-files '("$HOME/TAGS" "/usr/include/TAGS"))

- Set `company-ctags-fuzzy-match-p' to fuzzy match the candidates.
  The input could match any part of the candidate instead of the beginning of
  the candidate.

- Set `company-ctags-ignore-case' to ignore case when fetching candidates

- Use rusty-tags to generate tags file for Rust programming language.
  Add below code into ~/.emacs,
    (setq company-ctags-tags-file-name "rusty-tags.emacs")

- Make sure CLI program diff is executable on Windows.
It's optional but highly recommended.  It can speed up tags file updating.
This package uses diff through variable `diff-command'.

- `company-ctags-debug-info' for debugging.
