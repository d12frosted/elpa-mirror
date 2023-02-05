;;; markdown-soma.el --- Live preview for Markdown

;; Copyright (C) 2022 Jason Milkins

;; Author: Jason Milkins <jasonm23@gmail.com>
;; URL: https://github.com/jasonm23/markdown-soma
;; Keywords: wp, docs, text, markdown
;; Version: 0.3.1
;; Package-Requires: ((emacs "25") (s "1.11.0") (dash "2.19.1") (f "0.20.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>

;;; Commentary:
;; # Markdown Soma
;;
;; ### Live Markdown in Emacs
;;
;; `markdown-soma` is an Emacs minor-mode which gives you live rendering of
;; Markdown to HTML.
;;
;; Based on the Vim plugin [`vim-markdown-composer`][vmc],
;;
;; ## Usage
;;
;; To start:
;;
;; ```
;; M-x markdown-soma-mode
;; ```
;;
;; The default browser will open a tab with the rendered markdown view.
;;
;; Edits and commands in your current Emacs buffer, will trigger a new markdown
;; render in the browser. The browser view will automatically scroll so you can see
;; what you're editing. _(This could be better, suggestions on how to
;; improve it are welcome.)_
;;
;; ## Render hooks
;;
;; A new markdown render triggers by hooks in  `markdown-soma--render-buffer-hooks`.
;;
;; ```lisp
;; ;; default render buffer hooks
;;
;; (setq markdown-soma--render-buffer-hooks
;;   '(after-revert-hook
;;     after-save-hook
;;     after-change-functions
;;     post-command-hook))
;; ```
;;
;; ## Install
;;
;; Via [MELPA](https://melpa.org)
;;
;; ```
;; M-x package-install markdown-soma
;; ```
;;
;; Using [Doom Emacs](https://github.com/doomemacs/doomemacs)
;;
;; in `~/.doom.d/packages.el`
;;
;; ```lisp
;; (package! markdown-soma)
;; ```
;;
;; ### Install `soma` executable
;;
;; The source for the `soma` markdown/websocket server is included the package
;; repository. You'll need to compile it from source. If you don't have Rust on
;; your system, use [rustup] to get set up.
;;
;; Once rust is ready, open a terminal at the package folder.
;;
;; ```shell
;; $ cargo install --path .
;;
;; # compiles:
;; # ⟶ ~/.cargo/bin/soma
;; ```
;;
;; By default, `~/.cargo/bin` will be in your `$PATH`.
;;
;; ## Customizing
;;
;; You can select a builtin CSS theme with::
;;
;; ```
;; M-x markdown-soma-select-builtin-css
;; ```
;;
;; To persist the setting, select a theme name and add it to your Emacs init with:
;;
;; ```lisp
;; (setq markdown-soma-custom-css
;;    (markdown-soma--css-pathname-from-builtin-name "theme name")
;; ```
;;
;; You can also use any other markdown aware CSS stylesheet (i.e. targets CSS
;; selectors `#markdown-preview` and/or `.markdown-preview` as markdown content
;; containers..)
;;
;; Set a custom CSS file to use with:
;;
;; ```
;; M-x markdown-soma-select-css-file
;; ```
;;
;;Note: the CSS style will apply after restarting `markdown-soma-mode`.
;; 
;; ```
;; M-x markdown-soma-restart
;; ```
;;
;; To persist the setting add to your Emacs init
;;
;; ```lisp
;; (setq markdown-soma-custom-css "/path/to/your.css")
;; ```
;;
;; You can select a [highlightjs] theme:
;;
;; ```
;; M-x markdown-soma-select-highlight-theme
;; ```
;;
;; To persist the setting add to your Emacs init
;;
;; ```lisp
;; ;; Change "theme name" to the selected highlightjs theme.
;; (setq markdown-soma-highlightjs-theme "theme name")
;; ```
;;
;; ## Markdown support
;;
;; Soma converts markdown to HTML, using [pulldown-cmark].
;; It is 100% compliant with the common-markdown spec.
;;
;; ### Extensions
;;
;; - Github flavored markdown (gfm) tables
;; - GFM code fences
;; - GFM task lists
;; - Strike-through
;;
;; ---
;;
;; TeX/MathJax support thanks to [KaTeX][katex]
;;
;; e.g. `\\sqrt{3x-1}` wrapped in `$` ⟶ `$\\sqrt{3x-1}$` to    display the expression ⟶  $\\sqrt{3x-1}$
;;
;; wrapping with `\\(\\)` e.g. `\\(\\sqrt{3x-1}\\)` gives the same \\(\\sqrt{3x-1}\\) inline.
;;
;; Use `$$...$$` or `\\[..\\]`to center the expression in a presentation style.
;;
;; e.g. `$$\\sqrt{3x-1}$$`
;;
;; $$\\sqrt{3x-1}$$
;;
;; `$$n = {A \pm \sqrt{b^4-4ac} \over 2a}$$`
;;
;; $$n = {A \pm \sqrt{b^4-4ac} \over 2a}$$
;;
;; `$$\xleftrightharpoons{abc}$$`
;;
;; $$\xleftrightharpoons{abc}$$
;;
;; ---
;;
;; ## Technical note.
;;
;; Emacs sends text from the current buffer to `soma`
;; using `(process-send-string BUFFER-TEXT PROCESS)`.
;;
;; `soma` converts input (assumed to be markdown text) and broadcasts
;; changes to connected clients (as HTML).
;;
;; Emacs embeds a value for `scrollTo`, into the input with a
;; magic comment e.g.
;;
;; ```html
;; <!-- SOMA: {"scrollTo": 0} // scrolls to the top.  -->
;; ```
;;
;; In a nutshell [`pulldown-cmark`][pulldown-cmark] is doing the heavy lifting.
;; Providing the core markdown service, via [`aurelius`][jason-aurelius]. Which in
;; turn provides the web/websocket interface. The `soma` executable is essentially
;; just wrapping [`aurelius`][jason-aurelius] as a repeating `stdin` reader, i.e.
;; instead of terminating at EOF it will use this as a signal to broadcast the updated content to clients.
;;
;; [highlightjs]: https://highlightjs.org
;; [rustup]: https://rustup.rs
;; [pulldown-cmark]: https://github.com/raphlinus/pulldown-cmark
;; [katex]: https://katex.org
;; [aurelius]: https://github.com/euclio/aurelius
;; [jason-aurelius]: https://github.com/jasonm23/aurelius
;; [vmc]: https://github.com/euclio/vim-markdown-composer
;;
;;; Code:

;;; -*- lexical-binding: t -*-

(require 'help-mode)
(require 's)
(require 'f)
(require 'dash)

(defgroup markdown-soma nil
  "Live Markdown Preview."
  :group 'markdown
  :prefix "markdown-soma-")

(defcustom markdown-soma-working-directory nil
  "Server web root. Default nil, pwd becomes working directory."
  :type '(string)
  :require 'markdown-soma
  :group 'markdown-soma)

(defcustom markdown-soma-highlightjs-theme "hybrid"
  "Theme for highlight.js code/syntax colors."
  :type '(string)
  :require 'markdown-soma
  :group 'markdown-soma)

(defcustom markdown-soma-custom-css nil
  "Custom CSS can be set to a file or url."
  :type '(string)
  :require 'markdown-soma
  :group 'markdown-soma)

(defcustom markdown-soma-host-address "localhost"
  "Host address."
  :type '(string)
  :require 'markdown-soma
  :group 'markdown-soma)

(defcustom markdown-soma-host-port "0"
  "Host port, default to 0 = system assigns a free port."
  :type '(string)
  :require 'markdown-soma
  :group 'markdown-soma)

(define-minor-mode markdown-soma-mode
  "Live Markdown Preview."
  :group      'markdown-soma
  :init-value nil
  :global     nil
  (if markdown-soma-mode
      (markdown-soma-start)
    (markdown-soma-stop)))

(defconst markdown-soma--needs-executable-message
  "Markdown soma executable `soma' not found.

The markdown WebSocket server `soma' is in the package repository.
You'll need to compile it from source.

Install `rustup' if rust is not on your system.

Once rust is ready to use, open a terminal at the package/repo
folder and enter:

    cargo install --path .

compiles:

    ~/.cargo/bin/soma

By default, `~/.cargo/bin' will be in `$PATH'."
  "Message text shown when soma is not found.")

(defvar markdown-soma--render-buffer-hooks
  '(after-revert-hook
    after-save-hook
    after-change-functions
    post-command-hook)
  "A collection of hooks which trigger markdown-soma-render-buffer.")

(defvar markdown-soma--render-gate nil
  "Gate when t pauses render.")

(defvar markdown-soma-source-view nil
  "Toggle on to view source in browser.")

;;;###autoload
(defun markdown-soma-toggle-source-view (force)
  "Toggle source view or FORCE on/off.

FORCE will expect a prefix positive integer to mean on or
negative prefix to mean off.

This will trigger markdown-soma-restart in an active session."
  (interactive "p")
  (when (< 0 force)
      (setq markdown-soma-source-view nil))
  (when (> 1 force)
      (setq markdown-soma-source-view t))
  (when (= 1 force)
      (setq markdown-soma-source-view (not markdown-soma-source-view)))
  (when markdown-soma-mode (markdown-soma-restart)))

(defun markdown-soma--source-dir ()
 "The installed location of markdown-soma."
 (f-dirname
  (file-truename
   (replace-regexp-in-string "[.]elc$" ".el"
                   (locate-library "markdown-soma")))))

(defun markdown-soma--is-css-file-p (file)
  "Rudimenmtary check that FILE is css, does it's name end with .css?"
  (s-ends-with? ".css" file))

(defun markdown-soma--builtin-css-theme-files ()
  "A list of CSS themes filenames supplied with markdown-soma."
  (f-entries (format "%s%s%s"
              (markdown-soma--source-dir)
              (f-path-separator)
              "styles")
             'markdown-soma--is-css-file-p nil))

(defun markdown-soma--css-pathname-from-builtin-name (name)
  "Return the path and filename of CSS theme matching NAME."
  (--find (s-ends-with-p (format "%s.css" name) it) (markdown-soma--builtin-css-theme-files)))

(defun markdown-soma-render (text)
  "Render TEXT via soma.

markdown-soma-render is debounced to 400ms."
  (unless markdown-soma--render-gate
    (process-send-string (get-process "markdown-soma") (format "%s\n" text))
    (process-send-eof (get-process "markdown-soma")))
  (setq-local markdown-soma--render-gate t)
  (run-with-timer 0.400 nil
     (lambda ()
       (setq-local markdown-soma--render-gate nil))))

(defun markdown-soma--code-fence (text)
 "Wrap TEXT in markdown code fence."
 (format "```\n%s\n```" text))

(defun markdown-soma-render-buffer ()
  "Render buffer via soma."
  (ignore-errors
   (markdown-soma-render
     (format "<!-- SOMA: {\"scrollTo\": %f} -->\n%s"
           (markdown-soma-current-scroll-percent)
           (if markdown-soma-source-view (markdown-soma--code-fence (buffer-string)) (buffer-string))))))

(defun markdown-soma-hooks-add ()
  "Activate hooks to trigger soma."
  (add-hook 'kill-buffer-hook #'markdown-soma-stop nil t)
  (--map (add-hook it #'markdown-soma-render-buffer nil t)
    markdown-soma--render-buffer-hooks))

(defun markdown-soma-hooks-remove ()
  "Deactivate hooks to stop triggering soma."
  (remove-hook 'kill-buffer-hook #'markdown-soma-stop)
  (--map (remove-hook it #'markdown-soma-render-buffer)
     markdown-soma--render-buffer-hooks))

(defun markdown-soma-start ()
  "Start soma process, send a message if it cannot be found."
  (unless markdown-soma-custom-css (setq markdown-soma-custom-css (markdown-soma--css-pathname-from-builtin-name "markdown-soma")))
  (if (executable-find "soma")
      (progn
        (message "markdown-soma-start")
        (markdown-soma--run)
        (if (= 0 (buffer-size))
            (markdown-soma-render "waiting...")
          (markdown-soma-render-buffer))
        (markdown-soma-hooks-add))
    ;; else
    (switch-to-buffer-other-window (help-buffer))
    (help-insert-string markdown-soma--needs-executable-message)))

(defun markdown-soma-stop ()
  "Stop a running soma session."
  (message "markdown-soma-stop")
  (markdown-soma-hooks-remove)
  (markdown-soma--kill))

;;;###autoload
(defun markdown-soma-restart ()
  "Restart a running soma session."
  (interactive)
  (if markdown-soma-mode
      (progn
        (markdown-soma-stop)
        (run-with-timer 0.2 nil #'markdown-soma-start))
    (user-error "Please note markdown-soma-mode is not currently active")))

(defun markdown-soma--run ()
  "Run soma."
  (start-process-shell-command
   "markdown-soma"
   "*markdown-soma*"
   (markdown-soma--shell-command))
  (set-process-query-on-exit-flag
   (get-process "markdown-soma") nil))

(defun markdown-soma--shell-command ()
  "Generate the markdown-soma shell command."
  (format "soma %s %s %s %s %s"
          (if markdown-soma-host-address
              (format " --host %s" markdown-soma-host-address)
            "")
          (if markdown-soma-host-port
              (format " --port %s" markdown-soma-host-port)
            "")
          (if markdown-soma-custom-css
              (format " --custom-css %s" (shell-quote-argument
                                          (expand-file-name markdown-soma-custom-css)))
             "")
          (if  markdown-soma-highlightjs-theme
            (format " --highlight-theme %s " markdown-soma-highlightjs-theme)
            "")
          (format " --working-directory %s" (shell-quote-argument
                                             (expand-file-name
                                              (or markdown-soma-working-directory default-directory))))))

(defun markdown-soma--kill ()
  "Kill soma process and buffer."
  (when (buffer-live-p (get-buffer "*markdown-soma*"))
    (kill-buffer "*markdown-soma*")))

(defun markdown-soma--window-point ()
  "Return the current (column . row) within the window."
  (nth 6 (posn-at-point)))

(defun markdown-soma-current-scroll-percent ()
  "Calculate the position of point as decimal percentage of the buffer size."
  (if (= 0 (buffer-size))
      0.0
    (/ (- (line-number-at-pos (point))
          (- (window-height) (cdr (markdown-soma--window-point))))
      (count-lines 1 (buffer-size))
      1.0)))

(defun markdown-soma--builtin-css-theme-names ()
  "A list of CSS theme names supplied with markdown-soma."
  (--map (f-base it) (markdown-soma--builtin-css-theme-files)))

(defun markdown-soma--highlightjs-themes ()
  "A list of highlightjs themes."
 (--filter (not (string= "" it))
           (s-lines
            (f-read-text
             (format "%s%s%s"
                     (markdown-soma--source-dir)
                     (f-path-separator)
                     "highlightjs.themes")))))

(defun markdown-soma-select-builtin-css ()
  "Select markdown CSS from builtin themes.

This will trigger markdown-soma-restart in an active session."
  (interactive)
  (setq markdown-soma-custom-css
   (markdown-soma--css-pathname-from-builtin-name
    (completing-read
     "Select CSS theme: "
     (markdown-soma--builtin-css-theme-names))))
  (when markdown-soma-mode (markdown-soma-restart)))
  
(defun markdown-soma-select-css-file ()
  "Select markdown CSS file to use with soma."
  (interactive)
  (let ((css-file
         (read-file-name ;; only existing files allowed
          "Select CSS: " nil nil t nil)))
    (if (markdown-soma--is-css-file-p css-file)
        (setq markdown-soma-custom-css css-file)
      (user-error "Error markdown-soma-custom-css is %s is not a css file" css-file)))
  (when markdown-soma-mode (markdown-soma-restart)))

(defun markdown-soma-select-highlightjs-theme ()
  "Select a highlightjs theme for markdown."
  (interactive)
  (setq markdown-soma-highlightjs-theme
        (completing-read
         "Select highlightjs theme: "
         (markdown-soma--highlightjs-themes)))
  (when markdown-soma-mode (markdown-soma-restart)))

(provide 'markdown-soma)
;;; markdown-soma.el ends here
