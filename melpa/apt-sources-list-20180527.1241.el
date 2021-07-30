;;; apt-sources-list.el --- Mode for editing APT source.list files
;;
;; Copyright (C) 2001-2003, Dr. Rafael Sepúlveda <drs@gnulinux.org.mx>
;;               2009  Peter S. Galbraith <psg@debian.org>
;;               2017  Joe Wreschnig
;;
;; Author: Dr. Rafael Sepúlveda <drs@gnulinux.org.mx>
;; Maintainer: Joe Wreschnig <joe.wreschnig@gmail.com>
;; URL: https://git.korewanetadesu.com/apt-sources-list.git
;; Package-Commit: 5289443ceff230dfc8a2c1c6b524c90560eb08a5
;; Package-Requires: ((emacs "24.4"))
;; Package-Version: 20180527.1241
;; Package-X-Original-Version: 0
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;;
;; This package contains a major mode for editing APT’s “.list” files.
;;
;; The “/etc/apt/sources.list” file and other files in
;; “/etc/apt/sources.list.d” tell APT, found on Debian-based systems and
;; others, where to find packages for installation.
;;
;; This format specifies a package source with a single line, e.g.:
;;
;;     deb http://deb.debian.org/debian stable main contrib
;;
;; For more information about the format you can read the manual
;; pages “apt(8)” and “sources.list(5)”, also on the web at URL
;; ‘https://manpages.debian.org/stable/apt/sources.list.5.en.html’
;; and URL ‘https://manpages.debian.org/stable/apt/apt.8.en.html’.


;;; Code:

(require 'cl-lib)
(require 'subr-x)
(eval-when-compile
  (require 'rx))

(defgroup apt-sources-list nil
  "Mode for editing APT sources.list file."
  :group 'tools)

(defface apt-sources-list-type
  '((t (:inherit font-lock-constant-face)))
  "Face for a source’s type (i.e. “deb” or “deb-src”).")

(defface apt-sources-list-uri
  '((t (:inherit font-lock-variable-name-face)))
  "Face for a source’s URI.")

(defface apt-sources-list-suite
  '((t (:inherit font-lock-type-face)))
  "Face for a source’s suite (e.g. “unstable”, “stretch/updates”).")

(defface apt-sources-list-options
  '((t (:inherit font-lock-builtin-face)))
  "Face for a package source’s options (e.g. “[arch=amd64]”).")

(defface apt-sources-list-components
  '((t (:inherit font-lock-keyword-face)))
  "Face for a package source’s components (e.g. “main”, “non-free”).")

(defcustom apt-sources-list-suites
  '("stable" "testing" "unstable" "oldstable" "jessie" "stretch" "sid")
  "Suites to offer for completion.

The first item in this list is used as the default value when
editing sources."
  :type '(repeat string))

(defcustom apt-sources-list-components
  '("main" "contrib" "non-free")
  "Components to offer for completion.

The first item in this list is used as the default value when
editing sources."
  :type '(repeat string))

(defcustom apt-sources-list-name-format "# %s"
  "Format used in the name of a new source line.

This is used by ‘apt-sources-list-insert’.  It should contain a
single “%s” which will be replaced with the source name."
  :type 'string
  :group 'apt-sources-list)

(defconst apt-sources-list-one-line
  (rx line-start
      (zero-or-more blank)
      (group (or "deb" "deb-src"))
      (one-or-more blank)
      (optional
       ;; TODO: This matches malformed options.
       "[" (group (one-or-more (not (any "]\n#")))) "]"
       (one-or-more blank))
      (group
       (one-or-more (any "-A-Za-z0-9._"))
       ":"
       (one-or-more (not (any " \t\n#"))))
      (one-or-more blank)
      (group
       (or (and (zero-or-more (not (any " \t\n#"))) "/")
           (and (zero-or-more (not (any " \t\n#")))
                (not (any " \t\n/#"))
                (one-or-more blank)
                (group
                 (one-or-more (not (any " \t\n#")))
                 (zero-or-more
                  (one-or-more blank)
                  (one-or-more (not (any " \t\n#"))))))))
      (zero-or-more blank)
      (or line-end "#"))
  "Regex to match a valid APT source in one-line format.")

(defconst apt-sources-list-font-lock-keywords
  `((,apt-sources-list-one-line
     (1 'apt-sources-list-type)
     (2 'apt-sources-list-options nil t)
     (3 'apt-sources-list-uri)
     (4 'apt-sources-list-suite)
     (5 'apt-sources-list-components t t)))
  "Faces for parts of sources.list lines.")

(cl-defun apt-sources-list-insert
    (uri &key name (type "deb") options
         (suite (car apt-sources-list-suites))
         (components (car apt-sources-list-components)))
  "Insert a new package source at URI.

When called interactively without a prefix argument, assume
the type is “deb” and no special options.

When called from Lisp, optional arguments include:

NAME - a source name to include in a leading comment
TYPE - “deb” or “deb-src”, defaulting to “deb”
OPTIONS - an options string, without […] delimiters
SUITE - defaults to the first item of ‘apt-sources-list-suites’
COMPONENTS - defaults to the first item of ‘apt-sources-list-components’

You should read the official APT documentation for further
explanation of the format."
  (interactive
   (let* ((_ (barf-if-buffer-read-only))
          (name (read-string "Source name: "))
          (type (if current-prefix-arg
                    (completing-read "Type: " '("deb" "deb-src") nil t "deb")
                  "deb"))
          (options (if current-prefix-arg (read-string "Options: ") ""))
          (uri (read-string "URI: " "https://"))
          (suite (completing-read "Suite: "
                                  apt-sources-list-suites nil nil
                                  (car apt-sources-list-suites)))
          (components
           (unless (string-suffix-p "/" suite)
             (apt-sources-list--read-components))))
     (list uri
           :name (unless (string-blank-p name) name)
           :type type
           :options (unless (string-blank-p options) options)
           :suite suite :components components)))

  (when name
    (insert (format apt-sources-list-name-format name) "\n"))
  (insert type (if options (format " [%s] " options) " ") uri " "
          suite (if (string-suffix-p "/" suite) ""
                  (format " %s" components))))

(defun apt-sources-list-forward-source (&optional n)
  "Go N source lines forward (backward if N is negative)."
  (interactive "p")
  (save-excursion
    (if (> (or n 1) 0)
        (end-of-line)
      (beginning-of-line))
    (condition-case nil
        (re-search-forward apt-sources-list-one-line nil nil n)
      (search-failed
       (error "No further repositories found buffer"))))
  (goto-char (match-beginning 0)))

(defun apt-sources-list-backward-source (&optional n)
  "Go N source lines backward (forward if N is negative)."
  (interactive "p")
  (apt-sources-list-forward-source (- (or n 1))))

(defun apt-sources-list-source-p ()
  "Return non-nil if the line at point is a source."
  (string-match-p apt-sources-list-one-line (thing-at-point 'line)))

(define-error 'apt-sources-list-not-found
  "The point is not on an APT source line")

(define-error 'apt-sources-list-suite-component-mismatch
  "Exact suite paths (ending with “/”) may not specify components")

(defun apt-sources-list-match-source ()
  "Fill the match data with the source at point.

If there is no source, error."
  (save-mark-and-excursion
    (beginning-of-line)
    (or (looking-at apt-sources-list-one-line)
        (signal 'apt-sources-list-not-found nil))))

(defun apt-sources-list-change-type (&optional type)
  "Change the type of the source at point to TYPE.

Interactively or when TYPE is nil, toggle the type between “deb”
and “deb-src”."
  (interactive "*")
  (save-match-data
    (apt-sources-list-match-source)
    (unless type
      (setq type (if (equal (match-string 1) "deb") "deb-src" "deb")))
    (save-mark-and-excursion
     (replace-match type t t nil 1))))

(defun apt-sources-list-change-options (options)
  "Change the options of the source at point to OPTIONS (excluding []s)."
  (interactive
   (list (save-match-data
           (barf-if-buffer-read-only)
           (apt-sources-list-match-source)
           (read-string "Options: " (match-string 2)))))
  (save-match-data
    (apt-sources-list-match-source)
    (when (= 0 (length options))
      (setq options nil))
    (save-mark-and-excursion
     (cond ((and (match-string 2) options)
            (replace-match options t t nil 2))
           ((match-string 2)
            (delete-region (- (match-beginning 2) 2) (1+ (match-end 2))))
           (options
            (replace-match (concat (match-string 1) " [" options "]")
                           nil t nil 1))))))

(defun apt-sources-list-change-uri (uri)
  "Change the URI of the source at point to URI."
  (interactive
   (list (save-match-data
           (barf-if-buffer-read-only)
           (apt-sources-list-match-source)
           (read-string "URI: " (match-string 3)))))
  (save-match-data
    (apt-sources-list-match-source)
    (save-mark-and-excursion
     (replace-match uri t t nil 3))))

(defun apt-sources-list--read-components (&optional initial)
  "Read a components string, defaulting to INITIAL."
  (save-match-data
    (let ((minibuffer-local-completion-map
           (copy-keymap minibuffer-local-completion-map)))
      (define-key minibuffer-local-completion-map (kbd "<SPC>") nil)
      (completing-read "Components: "
                       apt-sources-list-components
                       nil nil
                       (or initial (car apt-sources-list-components))))))

(defun apt-sources-list-change-suite (suite &optional default-components)
  "Change the suite of the source at point to SUITE.

If the new suite requires components and the old one did not,
DEFAULT-COMPONENTS is used.  If none are provided, the first item
in ‘apt-sources-list-components’ is used."
  (interactive
   (save-match-data
     (barf-if-buffer-read-only)
     (apt-sources-list-match-source)
     (let ((components (match-string 5))
           (suite (completing-read "Suite: "
                                   apt-sources-list-suites)))
       (if (not (string-suffix-p "/" suite))
           (list suite (apt-sources-list--read-components))
         (list suite)))))

  (save-mark-and-excursion
   (save-match-data
     (apt-sources-list-match-source)
     (if (string-suffix-p "/" suite)
         (when (match-string 5)
           (replace-match "" t t nil 5))
       (setq suite (concat suite " "
                           (or (match-string 5)
                               default-components
                               (car apt-sources-list-components)
                               "main"))))
     (replace-match suite t t nil 4))))

(defun apt-sources-list-change-components (components)
  "Change the components of the source at point to COMPONENTS."
  (interactive
   (save-match-data
     (barf-if-buffer-read-only)
     (apt-sources-list-match-source)
     (when (string-suffix-p "/" (match-string 4))
       (signal 'apt-sources-list-suite-component-mismatch nil))
     (list (apt-sources-list--read-components
            (substring-no-properties (match-string 5))))))

  (save-match-data
    (apt-sources-list-match-source)
    (when (string-suffix-p "/" (match-string 4))
      (signal 'apt-sources-list-suite-component-mismatch nil))
    (save-mark-and-excursion
     (replace-match components t t nil 5))))

(defun apt-sources-list-replicate ()
  "Copy the source line, toggling the type."
  (interactive "*")
  (apt-sources-list-match-source)
  (let ((copy (buffer-substring (line-beginning-position)
                                (line-end-position))))
    (save-excursion
      (end-of-line)
      (insert (concat "\n" copy))
      (apt-sources-list-change-type))))

;;;###autoload
(define-derived-mode apt-sources-list-mode prog-mode "apt/sources.list"
  "Major mode for editing APT’s “.list” files.

The “/etc/apt/sources.list” file and other files in
“/etc/apt/sources.list.d” tell APT, found on Debian-based systems
and others, where to find packages for installation.

This format specifies a package source with a single line, e.g.:

    deb http://deb.debian.org/debian stable main contrib

For more information about the format you can read the manual
pages “apt(8)” and “sources.list(5)”, also on the web at URL
‘https://manpages.debian.org/stable/apt/sources.list.5.en.html’
and URL ‘https://manpages.debian.org/stable/apt/apt.8.en.html’.

\\{apt-sources-list-mode-map}

The above editing commands will raise errors if the current line
is not a correctly-formatted APT source."
  :syntax-table
  (let ((syntab (make-syntax-table)))
    (modify-syntax-entry ?#  "<"  syntab)
    (modify-syntax-entry ?\n "> " syntab)
    syntab)

  (setq-local comment-start "#")
  (setq-local comment-start-skip "#+ *")
  (font-lock-add-keywords nil apt-sources-list-font-lock-keywords))

;;;###autoload
(add-to-list
 'auto-mode-alist
 (cons (rx (or (and (any "./") "sources.list")
               (and "/sources.list.d/" (one-or-more anything) ".list"))
           string-end)
       #'apt-sources-list-mode))

(let ((map apt-sources-list-mode-map))
  (define-key map (kbd "C-c C-i") #'apt-sources-list-insert)
  (define-key map (kbd "C-c C-r") #'apt-sources-list-replicate)
  (define-key map (kbd "C-c C-t") #'apt-sources-list-change-type)
  (define-key map (kbd "C-c C-o") #'apt-sources-list-change-options)
  (define-key map (kbd "C-c C-u") #'apt-sources-list-change-uri)
  (define-key map (kbd "C-c C-s") #'apt-sources-list-change-suite)
  (define-key map (kbd "C-c C-c") #'apt-sources-list-change-components)
  (define-key map [remap forward-list] #'apt-sources-list-forward-source)
  (define-key map [remap backward-list] #'apt-sources-list-backward-source)

  (easy-menu-define apt-sources-list-mode-menu map
    "Menu for APT sources.list mode."
    '("APT"
      ["Insert Source" apt-sources-list-insert]
      ["Copy Source" apt-sources-list-replicate
       (apt-sources-list-source-p)]
      "--"
      ["Backward Source" apt-sources-list-backward-source]
      ["Forward Source" apt-sources-list-forward-source]
      "--"
      ["Change Type" apt-sources-list-change-type
       (apt-sources-list-source-p)]
      ["Change Options" apt-sources-list-change-options
       (apt-sources-list-source-p)]
      ["Change URI" apt-sources-list-change-uri
       (apt-sources-list-source-p)]
      ["Change Suite" apt-sources-list-change-suite
       (apt-sources-list-source-p)]
      ["Change Components" apt-sources-list-change-components
       (ignore-errors
         (and (apt-sources-list-match-source) (match-string 5)))])))


(provide 'apt-sources-list)
;;; apt-sources-list.el ends here
