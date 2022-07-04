;;; markdown-soma.el --- Live preview for Markdown

;; Copyright (C) 2022 Jason Milkins

;; Author: Jason Milkins <jasonm23@gmail.com>
;; URL: https://github.com/jasonm23/markdown-soma
;; Package-Version: 20220704.200
;; Package-Commit: 0bc5fcaeca919f0ce639eb7e6565a70de5189712
;; Keywords: wp, docs, text, markdown
;; Version: 0.1.13
;; Package-Requires: ((emacs "25") (s "1.11.0") (dash "2.19.1"))

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
;;  Markdown-soma live markdown preview for Emacs. Based on
;;  vim-markdown-composer.
;;
;;  Support for hightlightjs, KaTeX/MathJax.
;;
;;  Set hightlightjs theme with M-x markdown-soma-select-highlight-theme
;;
;;  or do: (setq markdown-soma-highlight-theme "vs")
;;
;;  See the list of themes other than "vs" at the end of this file.
;;
;;  Support for custom CSS.
;;
;;  M-x markdown-soma-select-css-file
;;
;;  or do (setq markdown-soma-custom-css "/path/to/your.css")
;;
;;  CSS path needs to be absolute. (css URL support is in the works.)
;;
;;; Code:

(require 'help-mode)
(require 's)
(require 'dash)

(defgroup markdown-soma nil
  "Live Markdown Preview."
  :group 'markdown
  :prefix "markdown-soma-")

(defcustom markdown-soma-working-directory nil
  "Server web root. Default nil pwd becomes working directory."
  :type '(string)
  :require 'markdown-soma
  :group 'markdown-soma)

(defcustom markdown-soma-highlight-theme "hybrid"
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
  "Markdown soma executable `soma` not found.

The markdown WebSocket server `soma` is in the package repository.
You'll need to compile it from source.

Install rustup if rust is not on your system.

Once rust is ready to use, open a terminal at the package/repo
folder and enter:

    cargo install --path .

compiles:

    ~/.cargo/bin/soma

By default, `~/.cargo/bin` will be in your `$PATH`."
  "Message text shown when soma is not found.")

(defvar markdown-soma--render-buffer-hooks
  '(after-revert-hook
    after-save-hook
    after-change-functions)
  "A collection of hooks which trigger markdown-soma-render-buffer.")

(defvar markdown-soma-highlightjs-theme-list
  '("3024" "a11y-dark" "a11y-light" "agate" "an-old-hope" "androidstudio" "apathy" "apprentice" "arduino-light" "arta" "ascetic" "ashes" "atelier-cave-dark" "atelier-cave-light" "atelier-cave" "atelier-cave.dark" "atelier-cave.light" "atelier-dune-dark" "atelier-dune-light" "atelier-dune" "atelier-dune.dark" "atelier-dune.light" "atelier-estuary-dark" "atelier-estuary-light" "atelier-estuary" "atelier-estuary.dark" "atelier-estuary.light" "atelier-forest-dark" "atelier-forest-light" "atelier-forest" "atelier-forest.dark" "atelier-forest.light" "atelier-heath-dark" "atelier-heath-light" "atelier-heath" "atelier-heath.dark" "atelier-heath.light" "atelier-lakeside-dark" "atelier-lakeside-light" "atelier-lakeside" "atelier-lakeside.dark" "atelier-lakeside.light" "atelier-plateau-dark" "atelier-plateau-light" "atelier-plateau" "atelier-plateau.dark" "atelier-plateau.light" "atelier-savanna-dark" "atelier-savanna-light" "atelier-savanna" "atelier-savanna.dark" "atelier-savanna.light" "atelier-seaside-dark" "atelier-seaside-light" "atelier-seaside" "atelier-seaside.dark" "atelier-seaside.light" "atelier-sulphurpool-dark" "atelier-sulphurpool-light" "atelier-sulphurpool" "atelier-sulphurpool.dark" "atelier-sulphurpool.light" "atlas" "atom-one-dark-reasonable" "atom-one-dark" "atom-one-light" "bespin" "black-metal-bathory" "black-metal-burzum" "black-metal-dark-funeral" "black-metal-gorgoroth" "black-metal-immortal" "black-metal-khold" "black-metal-marduk" "black-metal-mayhem" "black-metal-nile" "black-metal-venom" "black-metal" "brewer" "bright" "brogrammer" "brown-paper" "brown-papersq.png" "brown_paper" "brown_papersq.png" "brush-trees-dark" "brush-trees" "chalk" "circus" "classic-dark" "classic-light" "codepen-embed" "codeschool" "color-brewer" "colors" "cupcake" "cupertino" "danqing" "darcula" "dark-violet" "dark" "darkmoss" "darktooth" "darkula" "decaf" "default-dark" "default-light" "default" "devibeans" "dirtysea" "docco" "dracula" "edge-dark" "edge-light" "eighties" "embers" "equilibrium-dark" "equilibrium-gray-dark" "equilibrium-gray-light" "equilibrium-light" "espresso" "eva-dim" "eva" "far" "felipec" "flat" "foundation" "framer" "fruit-soda" "gigavolt" "github-dark-dimmed" "github-dark" "github-gist" "github" "gml" "google-dark" "google-light" "googlecode" "gradient-dark" "gradient-light" "grayscale-dark" "grayscale-light" "grayscale" "green-screen" "gruvbox-dark-hard" "gruvbox-dark-medium" "gruvbox-dark-pale" "gruvbox-dark-soft" "gruvbox-dark" "gruvbox-light-hard" "gruvbox-light-medium" "gruvbox-light-soft" "gruvbox-light" "hardcore" "harmonic16-dark" "harmonic16-light" "heetch-dark" "heetch-light" "helios" "hopscotch" "horizon-dark" "horizon-light" "humanoid-dark" "humanoid-light" "hybrid" "ia-dark" "ia-light" "icy-dark" "idea" "intellij-light" "ir-black" "ir_black" "isbl-editor-dark" "isbl-editor-light" "isotope" "kimber" "kimbie-dark" "kimbie-light" "kimbie.dark" "kimbie.light" "lightfair" "lioshi" "london-tube" "macintosh" "magula" "marrakesh" "materia" "material-darker" "material-lighter" "material-palenight" "material-vivid" "material" "mellow-purple" "mexico-light" "mocha" "mono-blue" "monokai-sublime" "monokai" "monokai_sublime" "nebula" "night-owl" "nnfx-dark" "nnfx-light" "nord" "nova" "obsidian" "ocean" "oceanicnext" "one-light" "onedark" "outrun-dark" "panda-syntax-dark" "panda-syntax-light" "papercolor-dark" "papercolor-light" "paraiso-dark" "paraiso-light" "paraiso" "paraiso.dark" "paraiso.light" "pasque" "phd" "pico" "pojoaque" "pojoaque.jpg" "pop" "porple" "purebasic" "qtcreator-dark" "qtcreator-light" "qtcreator_dark" "qtcreator_light" "qualia" "railscasts" "rainbow" "rebecca" "ros-pine-dawn" "ros-pine-moon" "ros-pine" "routeros" "sagelight" "sandcastle" "school-book" "school-book.png" "school_book" "school_book.png" "seti-ui" "shades-of-purple" "shapeshifter" "silk-dark" "silk-light" "snazzy" "solar-flare-light" "solar-flare" "solarized-dark" "solarized-light" "solarized_dark" "solarized_light" "spacemacs" "srcery" "stackoverflow-dark" "stackoverflow-light" "summercamp" "summerfruit-dark" "summerfruit-light" "sunburst" "synth-midnight-terminal-dark" "synth-midnight-terminal-light" "tango" "tender" "tokyo-night-dark" "tokyo-night-light" "tomorrow-night-blue" "tomorrow-night-bright" "tomorrow-night-eighties" "tomorrow-night" "tomorrow" "twilight" "unikitty-dark" "unikitty-light" "vs" "vs2015" "vulcan" "windows-10-light" "windows-10" "windows-95-light" "windows-95" "windows-high-contrast-light" "windows-high-contrast" "windows-nt-light" "windows-nt" "woodland" "xcode-dusk" "xcode" "xt256" "zenburn")
  "List of highlightjs themes.")

(defun markdown-soma-render (text)
  "Render TEXT via soma."
  (when (not executing-kbd-macro)
    ;; TODO More exceptions, example when markdown mode is reformatting a table.
    (process-send-string "*markdown-soma*" (format "%s\n" text))
    (process-send-eof "*markdown-soma*")))

(defun markdown-soma-render-buffer (&rest _)
  "Render buffer via soma."
  (markdown-soma-render
   (format "<!-- SOMA: {\"scrollTo\": %f} -->\n%s"
           (markdown-soma-current-scroll-percent)
           (buffer-string))))

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
  (markdown-soma--kill)
  (markdown-soma-hooks-remove))

(defun markdown-soma-retart ()
  "Restart a running soma session."
  (interactive)
  (if markdown-soma-mode
      (progn
        (markdown-soma-stop)
        (markdown-soma-start))
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
          (if  markdown-soma-highlight-theme
            (format " --highlight-theme %s " markdown-soma-highlight-theme)
            "")
          (format " --working-directory %s" (shell-quote-argument
                                             (expand-file-name
                                              (or markdown-soma-working-directory default-directory))))))

(defun markdown-soma--kill ()
  "Kill soma process and buffer."
  (when (get-buffer-process "*markdown-soma")
   (stop-process (get-buffer-process "*markdown-soma*")))
  (and (buffer-live-p (get-buffer "*markdown-soma*"))
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

(defun markdown-soma--is-css-file-p (file)
  "Rudimenmtary check that FILE is css, does it's name end with .css?"
  (s-ends-with? ".css" file))

(defun markdown-soma-select-css-file ()
  "Select markdown CSS file to use with soma."
  (interactive)
  (let ((css-file
         (read-file-name ;; only existing files allowed
          "Select CSS: " nil nil t nil)))
    (if (markdown-soma--is-css-file-p css-file)
        (setq markdown-soma-custom-css css-file)
      (user-error "Error markdown-soma-custom-css is %s is not a css file" css-file)))
  (message "Restart markdown-soma-mode to take effect in the browser"))

(defun markdown-soma-select-highlight-theme ()
  "Select a highlightjs theme for markdown."
  (interactive)
  (setq markdown-soma-highlight-theme
        (completing-read
         "Select highlightjs theme: "
         markdown-soma-highlightjs-theme-list))
  (message "Restart markdown-soma-mode to take effect in the browser"))

(provide 'markdown-soma)
;;; markdown-soma.el ends here
