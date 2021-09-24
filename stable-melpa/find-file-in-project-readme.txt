This program provides methods to find file in project.

Features,
- Only dependency is BSD/GNU find
- Works on Windows with minimum setup
- Works on Tramp Mode (https://www.emacswiki.org/emacs/TrampMode)
- fd (faster alternative of find, see https://github.com/sharkdp/fd) is supported
- Uses native API `completing-read' and supports helm/ivy/consult/selectrum out of box.

  Helm setup,
    (helm-mode 1)

  Ivy setup,
    (ivy-mode 1)

  Ido setup,
    (setq ffip-prefer-ido-mode t)

Usage,
  - You can insert "(setq ffip-use-rust-fd t)" into ".emacs" to use fd (alternative of find)
  - `find-file-in-project-at-point' guess the file path at point and
     find file
  - `find-file-in-project-by-selected' uses the selected region
     as the keyword to search file.  You can provide the keyword
     if no region is selected.
  - `find-directory-in-project-by-selected' uses the select region
     to find directory.  You can provide the keyword if no region
     is selected.
  - `find-file-in-project' starts search file immediately
  - `ffip-create-project-file' creates ".dir-locals.el"
  - `ffip-lisp-find-file-in-project' finds file in project.
    If its parameter is not nil, it find directory.
    This command is written in pure Lisp and does not use any third party
    command line program.  So it works in all environments.

A project is found by searching up the directory tree until a file
is found that matches `ffip-project-file'.
You can set `ffip-project-root-function' to provide an alternate
function to search for the project root.  By default, it looks only
for files whose names match `ffip-patterns',

If you have so many files that it becomes unwieldy, you can set
`ffip-find-options' to a string which will be passed to the `find'
invocation in order to exclude irrelevant subdirectories/files.
For instance, in a Ruby on Rails project, you are interested in all
.rb files that don't exist in the "vendor" directory.  In that case
you could set `ffip-find-options' to "-not -regex \".*vendor.*\"".

`ffip-insert-file' insert file content into current buffer.

`find-file-with-similar-name' find file with similar name to current
opened file. The regular expression `ffip-strip-file-name-regex' is
also used by `find-file-with-similar-name'.

all these variables may be overridden on a per-directory basis in
your ".dir-locals.el".  See (info "(Emacs) Directory Variables") for
details.

Sample ".dir-locals.el",

((nil . ((ffip-project-root . "~/projs/PROJECT_DIR")
         ;; ignore files bigger than 64k and directory "dist/" when searching
         (ffip-find-options . "-not -size +64k -not -iwholename '*/dist/*'")
         ;; only search files with following extensions
         (ffip-patterns . ("*.html" "*.js" "*.css" "*.java" "*.xml" "*.js"))
         (eval . (progn
                   (require 'find-file-in-project)
                   ;; ignore directory ".tox/" when searching
                   (setq ffip-prune-patterns `("*/.tox" ,@ffip-prune-patterns))
                      ;; ignore BMP image file
                   (setq ffip-ignore-filenames `("*.bmp" ,@ffip-ignore-filenames))
                   ;; Do NOT ignore directory "bin/" when searching
                   (setq ffip-prune-patterns `(delete "*/bin" ,@ffip-prune-patterns))))
         )))

To find in current directory, use `find-file-in-current-directory'
and `find-file-in-current-directory-by-selected'.

`ffip-fix-file-path-at-point' replaces path at point with correct relative/absolute path.

File/directory searching actions are automatically stored into `ffip-find-files-history'.
Use `ffip-find-files-resume' to replay any previous action.
The maximum number of items of the history is set in `ffip-find-files-history-max-items'.

`ffip-show-diff' execute the backend from `ffip-diff-backends'.
The output is in Unified Diff Format and inserted into *ffip-diff* buffer.
Press "o" or "C-c C-c" or "ENTER" or `M-x ffip-diff-find-file' in the
buffer to open corresponding file.  Please note some backends assume that the git cli program
is added into environment variable PATH.

`ffip-diff-find-file-before-hook' is called in `ffip-diff-find-file'.
Two file names are passed to it as parameters.  One name is returned by the hook
as the file searching keyword.

`ffip-diff-apply-hunk' applies current hunk in `diff-mode' (please note
`ffip-diff-mode' inherits from `diff-mode') to the target.
file. The target file could be located by searching `recentf-list'.
Except this extra feature, `ffip-diff-apply-hunk' is same as `diff-apply-hunk'.
So `diff-apply-hunk' can be replaced by `ffip-diff-apply-hunk'.

`ffip-diff-filter-hunks-by-file-name' can filter hunks by their file names.
User input pattern "regex !exclude1 exclude1" means the hunk's file name does match "regex".
But does not match "exclude1" or "exclude2".;
Please note in "regex", space represents any string.

If you use `evil-mode', insert below code into ~/.emacs,
  (defun ffip-diff-mode-hook-setup ()
      (evil-local-set-key 'normal "K" 'diff-hunk-prev)
      (evil-local-set-key 'normal "J" 'diff-hunk-next)
      (evil-local-set-key 'normal "P" 'diff-file-prev)
      (evil-local-set-key 'normal "N" 'diff-file-next)
      (evil-local-set-key 'normal (kbd "RET") 'ffip-diff-find-file)
      (evil-local-set-key 'normal "o" 'ffip-diff-find-file))
  (add-hook 'ffip-diff-mode-hook 'ffip-diff-mode-hook-setup)

`find-relative-path' find file/directory and copy its relative path
into `kill-ring'. You can customize `ffip-find-relative-path-callback'
to format the relative path,
  (setq ffip-find-relative-path-callback 'ffip-copy-reactjs-import)
  (setq ffip-find-relative-path-callback 'ffip-copy-org-file-link)

BSD/GNU Find can be installed through Cygwin or MYSYS2 on Windows.
Executable is automatically detected. But you can manually specify
the executable location by insert below code into ".emacs",

  (if (eq system-type 'windows-nt)
     (setq ffip-find-executable "c:\\\\cygwin64\\\\bin\\\\find"))

This program works on Windows/Cygwin/Linux/macOS

See https://github.com/redguardtoo/find-file-in-project for advanced tips.
