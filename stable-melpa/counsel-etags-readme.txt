 Configuration,

  "Ctags" (Universal Ctags is recommended) should exist.
  Or else, customize `counsel-etags-update-tags-backend' to generate tags file.
  Please note etags bundled with Emacs is not supported any more.

Usage,

  `counsel-etags-find-tag-at-point' to navigate.  This command will also
  run `counsel-etags-scan-code' AUTOMATICALLY if tags file does not exist.
  It also calls `counsel-etags-fallback-grep-function' if not tag is found.

  Use `counsel-etags-imenu-excluded-names' to exclude tags by name.
  Use `counsel-etags-imenu-excluded-types' to exclude tags by type

  `counsel-etags-scan-code' to create tags file
  `counsel-etags-grep' to grep
  `counsel-etags-grep-extra-arguments' has extra arguments for grep
  `counsel-etags-grep-current-directory' to grep in current directory
  `counsel-etags-recent-tag' to open recent tag
  `counsel-etags-find-tag' to two steps tag matching use regular expression and filter
  `counsel-etags-list-tag' to list all tags
  `counsel-etags-update-tags-force' to update current tags file by force
  `counsel-etags-ignore-config-file' specifies paths of ignore configuration files
  (".gitignore", ".hgignore", etc).  Path is either absolute or relative to the tags file.
  `counsel-etags-universal-ctags-p' to detect if Universal Ctags is used.
  `counsel-etags-exuberant-ctags-p' to detect if Exuberant Ctags is used.
  See documentation of `counsel-etags-use-ripgrep-force' on using ripgrep.
  If it's not set, correct grep program is automatically detected.

Tips,
- Use `pop-tag-mark' to jump back.

- The grep program path on Native Windows Emacs uses either forward slash or
  backward slash.  Like "C:/rg.exe" or "C:\\\\rg.exe".
  If grep program path is added to environment variable PATH, you don't need
  worry about slash problem.

- Add below code into "~/.emacs" to AUTOMATICALLY update tags file:

  ;; Don't ask before reloading updated tags files
  (setq tags-revert-without-query t)
  ;; NO warning when loading large tag files
  (setq large-file-warning-threshold nil)
  (add-hook 'prog-mode-hook
    (lambda ()
      (add-hook 'after-save-hook
                'counsel-etags-virtual-update-tags 'append 'local)))

- You can use ivy's exclusion patterns to filter candidates.
  For example, input "keyword1 !keyword2 keyword3" means:
  "(keyword1 and (not (or keyword2 keyword3)))"

- `counsel-etags-extra-tags-files' contains extra tags files to parse.
  Set it like,
    (setq counsel-etags-extra-tags-files
          '("./TAGS" "/usr/include/TAGS" "$PROJ1/include/TAGS"))

  Files in `counsel-etags-extra-tags-files' should have symbols with absolute path only.

- You can set up `counsel-etags-ignore-directories' and `counsel-etags-ignore-filenames',
  (with-eval-after-load 'counsel-etags
     ;; counsel-etags-ignore-directories does NOT support wildcast
     (push "build_clang" counsel-etags-ignore-directories)
     (push "build_clang" counsel-etags-ignore-directories)
     ;; counsel-etags-ignore-filenames supports wildcast
     (push "TAGS" counsel-etags-ignore-filenames)
     (push "*.json" counsel-etags-ignore-filenames))

 - Rust programming language is supported.
   The easiest setup is to use ".dir-locals.el".
  in root directory.  The content of .dir-locals.el" is as below,

  ((nil . ((counsel-etags-update-tags-backend . (lambda (src-dir) (shell-command "rusty-tags Emacs")))
           (counsel-etags-tags-file-name . "rusty-tags.emacs"))))

 - User could use `counsel-etags-convert-grep-keyword' to customize grep keyword.
   Below setup enable `counsel-etags-grep' to search Chinese using pinyinlib,

   (unless (featurep 'pinyinlib) (require 'pinyinlib))
   (setq counsel-etags-convert-grep-keyword
     (lambda (keyword)
       (if (and keyword (> (length keyword) 0))
           (pinyinlib-build-regexp-string keyword t)
         keyword)))

 - `counsel-etags-find-tag-name-function' finds tag name at point.  If it returns nil,
   `find-tag-default' is used.  `counsel-etags-word-at-point' gets word at point.

 - You can append extra content into tags file in `counsel-etags-after-update-tags-hook'.
   The parameter of hook is full path of the tags file.
   `counsel-etags-tag-line' and `counsel-etags-append-to-tags-file' are helper functions
   to update tags file in the hook.

 - The ignore files (.gitignore, etc) are automatically detected and append to ctags
   cli options as "--exclude="@/ignore/file/path".
   Set `counsel-etags-ignore-config-files' to nil to turn off this feature.

 - If base configuration file "~/.ctags.exuberant" exists, it's used to
   generate "~/.ctags" automatically.
   "~/.ctags.exuberant" is Exuberant Ctags format, but the "~/.ctags" could be
   Universal Ctags format if Universal Ctags is used.
   You can customize `counsel-etags-ctags-options-base' to change the path of
   base configuration file.

 - Grep result is sorted by string distance of current file path and candidate file path.
   The sorting happens in Emacs 27+.
   You can set `counsel-etags-sort-grep-result-p' to nil to disable sorting.

 - Run `counsel-etags-list-tag-in-current-file' to list tags in current file.
   You can also use native imenu with below setup,
     (setq imenu-create-index-function
           'counsel-etags-imenu-default-create-index-function)

See https://github.com/redguardtoo/counsel-etags/ for more tips.
