;;; eshell-info-banner.el --- System information as your Eshell banner -*- lexical-binding: t -*-

;; Author: Lucien Cartier-Tilet <lucien@phundrak.com>
;; Maintainer: Lucien Cartier-Tilet <lucien@phundrak.com>
;; Version: 0.8.8
;; Package-Requires: ((emacs "25.1") (s "1"))
;; Homepage: https://github.com/Phundrak/eshell-info-banner.el

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; `eshell-info-banner' is a utility for creating an informative
;; banner akin to fish_greeting if fish shell but for Eshell.  It can
;; provide information on:
;; - the OS’ name
;; - the OS’ kernel
;; - the hostname
;; - the uptime
;; - the system’s memory usage (RAM, swap, disk)
;; - the battery status
;; It can be TRAMP-aware or not, depending on the user’s preferences.

;;; Code:

(require 'cl-lib)
(require 's)
(require 'em-banner)
(require 'json)
(require 'seq)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;                Group                ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup eshell-info-banner ()
  "System information as your Eshell banner."
  :group 'eshell
  :prefix "eshell-info-banner-"
  :link '(url-link :tag "Gitea" "https://labs.phundrak.com/phundrak/eshell-info-banner.el")
  :link '(url-link :tag "Github" "https://github.com/Phundrak/eshell-info-banner.el"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;              Constants              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst eshell-info-banner-path-separator
  (substring-no-properties (file-relative-name (expand-file-name "x" "y")) 1 2)
  "File separator used by the current operating system.")

(defconst eshell-info-banner--min-length-left 8
  "Minimum length of text on the left hand side of the banner.")

(eval-when-compile
  (defconst eshell-info-banner--macos-versions
    '(("^10\\.0\\."  . "Mac OS X Cheetah")
      ("^10\\.1\\."  . "Mac OS X Puma")
      ("^10\\.2\\."  . "Mac OS X Jaguar")
      ("^10\\.3\\."  . "Mac OS X Panther")
      ("^10\\.4\\."  . "Mac OS X Tiger")
      ("^10\\.5\\."  . "Mac OS X Leopard")
      ("^10\\.6\\."  . "Mac OS X Snow Leopard")
      ("^10\\.7\\."  . "Mac OS X Lion")
      ("^10\\.8\\."  . "OS X Mountain Lion")
      ("^10\\.9\\."  . "OS X Mavericks")
      ("^10\\.10\\." . "OS X Yosemite")
      ("^10\\.11\\." . "OS X El Capitan")
      ("^10\\.12\\." . "macOS Sierra")
      ("^10\\.13\\." . "macOS High Sierra")
      ("^10\\.14\\." . "macOS Mojave")
      ("^10\\.15\\." . "macOS Catalina")
      ("^10\\.16\\." . "macOS Big Sur")
      ("^11\\."      . "macOS Big Sur")
      ("^12\\."      . "macOS Monterey"))
    "Versions of OSX and macOS and their name."))

(defconst eshell-info-banner--posix-shells '("bash" "zsh" "sh")
  "List of POSIX-compliant shells to run external commands through.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;           Custom variables          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom eshell-info-banner-tramp-aware t
  "Make `eshell-info-banner' TRAMP aware."
  :group 'eshell-info-banner
  :type 'boolean
  :safe #'booleanp)

(defcustom eshell-info-banner-shorten-path-from 7
  "From which length should a path be shortened?"
  :group 'eshell-info-banner
  :type 'integer
  :safe #'integer-or-marker-p)

(defcustom eshell-info-banner-width 80
  "Width of the info banner to be shown in Eshell."
  :group 'eshell-info-banner
  :type 'integer
  :safe #'integer-or-marker-p)

(defcustom eshell-info-banner-progress-bar-char "="
  "Character to fill the progress bars with."
  :group 'eshell-info-banner
  :type 'string
  :safe #'stringp)

(defcustom eshell-info-banner-warning-percentage 75
  "When to warn about a percentage."
  :group 'eshell-info-banner
  :type 'float
  :safe #'floatp)

(defcustom eshell-info-banner-critical-percentage 90
  "When a percentage becomes critical."
  :group 'eshell-info-banner
  :type 'float
  :safe #'floatp)

(defcustom eshell-info-banner-partition-prefixes '("/dev")
  "List of prefixes for detecting which partitions to display."
  :group 'eshell-info-banner
  :type 'list)

(defcustom eshell-info-banner-filter-duplicate-partitions nil
  "Whether to filter duplicate partitions.

Two partitions are considered duplicate if they have the same
size and amount of space used."
  :group 'eshell-info-banner
  :type 'boolean)

(defcustom eshell-info-banner-exclude-partitions nil
  "List of patterns to exclude from the partition list.

Patterns are matched against the partition name with
`string-match-p'."
  :group 'eshell-info-banner
  :type '(repeat string))

(defmacro eshell-info-banner--executable-find (program)
  "Find PROGRAM executable, possibly on a remote machine.
This is a wrapper around `executable-find' in order to avoid
issues with older versions of the functions only accepting one
argument. `executable-find'’s remote argument has the value of
`eshell-info-banner-tramp-aware'."
  (if (version< emacs-version "27.1")
      `(let ((default-directory (if eshell-info-banner-tramp-aware
                                    default-directory
                                  "~")))
         (executable-find ,program))
    `(executable-find ,program eshell-info-banner-tramp-aware)))

(defcustom eshell-info-banner-duf-executable "duf"
  "Path to the `duf' executable."
  :group 'eshell-info-banner
  :type 'string
  :safe #'stringp)

(defcustom eshell-info-banner-use-duf
  (if (eshell-info-banner--executable-find eshell-info-banner-duf-executable)
      t
    nil)
  "If non-nil, use `duf' instead of `df'."
  :group 'eshell-info-banner
  :type 'boolean
  :safe #'booleanp)

(defcustom eshell-info-banner-file-size-flavor nil
  "Display sizes with IEC prefixes."
  :group 'eshell-info-banner
  :type '(radio (const :tag "Default" nil)
                (const :tag "SI" si)
                (const :tag "IEC" iec)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;                Faces                ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defface eshell-info-banner-background-face
  '((t :inherit font-lock-comment-face))
  "Face for \"empty\" part of progress bars."
  :group 'eshell-info-banner)

(defface eshell-info-banner-normal-face
  '((t :inherit font-lock-string-face))
  "Face for `eshell-info-banner' progress bars displaying acceptable levels."
  :group 'eshell-info-banner)

(defface eshell-info-banner-warning-face
  '((t :inherit warning))
  "Face for `eshell-info-banner' progress bars displaying high levels."
  :group 'eshell-info-banner)

(defface eshell-info-banner-critical-face
  '((t :inherit error))
  "Face for `eshell-info-banner' progress bars displaying critical levels."
  :group 'eshell-info-banner)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;         Macros and Utilities        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro eshell-info-banner--with-face (str &rest properties)
  "Helper macro for applying face PROPERTIES to STR."
  `(propertize ,str 'face (list ,@properties)))

(defun eshell-info-banner--shell-command-to-string (command)
  "Execute shell command COMMAND and return its output as a string.
Ensures the command is ran with LANG=C."
  (let ((shell (or (seq-find (lambda (shell)
                              (eshell-info-banner--executable-find shell))
                            eshell-info-banner--posix-shells)
                  "sh")))
    (with-temp-buffer
      (let ((default-directory (if eshell-info-banner-tramp-aware default-directory "~")))
        (process-file shell nil t nil "-c" (concat "LANG=C " command))
        (buffer-string)))))

(defun eshell-info-banner--progress-bar-without-prefix (bar-length used total &optional newline)
  "Display a progress bar without its prefix.
Display a progress bar of BAR-LENGTH length, followed by an
indication of how full the memory is with a human readable USED
and TOTAL size.
Optional argument NEWLINE: Whether to output a newline at the end
of the progress bar."
  (let ((percentage (if (= used 0)
                        0
                      (/ (* 100 used) total))))
    (concat (eshell-info-banner--progress-bar bar-length percentage)
            (format (if (equal eshell-info-banner-file-size-flavor 'iec)
                        " %8s / %-8s (%3s%%)%s"
                      " %6s / %-6s (%3s%%)%s")
                    (file-size-human-readable used eshell-info-banner-file-size-flavor)
                    (file-size-human-readable total eshell-info-banner-file-size-flavor)
                    (eshell-info-banner--with-face
                     (number-to-string percentage)
                     :inherit (eshell-info-banner--get-color-percentage percentage))
                    (if newline "\n" "")))))

(defun eshell-info-banner--string-repeat (str times)
  "Repeat STR for TIMES times."
  (declare (pure t) (side-effect-free t))
  (let (result)
    (cl-dotimes (_ times)
      (setq result (cons str result)))
    (apply #'concat result)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;          Internal functions         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                                        ; Misc ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eshell-info-banner--get-uptime ()
  "Get uptime of machine if `uptime' is available.

If the executable `uptime' is not found, return nil."
  (when (eshell-info-banner--executable-find "uptime")
    (let ((uptime-str (eshell-info-banner--shell-command-to-string "uptime -p")))
      (if (not (seq-some (lambda (keyword)
                           (string-match-p keyword uptime-str))
                         '("invalid" "illegal" "unknown")))
          (s-chop-prefix "up " (s-trim uptime-str))
        (let ((uptime-str (eshell-info-banner--shell-command-to-string "uptime")))
          (save-match-data
            (string-match "[^,]+up *\\([^,]+\\)," uptime-str)
            (s-trim (substring-no-properties uptime-str
                                             (match-beginning 1)
                                             (match-end 1)))))))))

                                        ; Partitions ;;;;;;;;;;;;;;;;;;;;;;;;;;

(cl-defstruct eshell-info-banner--mounted-partitions
  "Object representing a mounted partition found in the system."
  path size used percent)

(defun eshell-info-banner--get-longest-path (partitions)
  "Return the length of the longest partition path in PARTITIONS.

The returned value is in any case greater than
`eshell-info-banner--min-length-left'."
  (let ((length eshell-info-banner--min-length-left))
    (dolist (partition partitions length)
      (setf length (max length
                        (length (eshell-info-banner--mounted-partitions-path partition)))))))

(defun eshell-info-banner--abbr-path (path &optional abbr)
  "Remove `$HOME' from PATH, abbreviate parent dirs if ABBR non nil.

Abbreviate PATH by removing the value of HOME if it is present in
the former, and if ABBR is t then all parent directories of the
current PATH are abbreviated to only one character. If an
abbreviated directory starts with a dot, then include it before
the abbreviated name of the directory, e.g. \".config\" ->
\".c\".

For public use, PATH should be a string representing a UNIX path.
For internal use, PATH can also be a list. If PATH is neither of
these, an error will be thrown by the function."
  (cond
   ((stringp path)
    (let ((abbr-path (abbreviate-file-name path)))
      (if abbr
          (abbreviate-file-name
           (eshell-info-banner--abbr-path
            (split-string abbr-path eshell-info-banner-path-separator t)))
        abbr-path)))
   ((null path) "")
   ((listp path)
    (let ((file (eshell-info-banner--abbr-path (cdr path)))
          (directory (if (= (length path) 1)
                         (car path)
                       (let* ((dir        (car path))
                              (first-char (substring dir 0 1)))
                         (if (string= "." first-char)
                             (substring dir 0 2)
                           first-char)))))
       (if (string= "" file)
           directory
         (let ((relative-p (not (file-name-absolute-p directory)))
               (new-dir    (expand-file-name file directory)))
           (if relative-p
               (file-relative-name new-dir)
             new-dir)))))
   (t (error "Invalid argument %s, neither stringp or listp" path))))

(defun eshell-info-banner--get-mounted-partitions-duf ()
    "Detect mounted partitions on systems supporting `duf'.

Return detected partitions as a list of structs. See
`eshell-info-banner-partition-prefixes' to see how partitions are
chosen. Relies on the `duf' command."
    (let* ((partitions (json-read-from-string (with-temp-buffer
                                                (call-process "duf" nil t nil "-json")
                                                (buffer-string))))
           (partitions (cl-remove-if-not (lambda (partition)
                                           (let ((device (format "%s" (cdr (assoc 'device partition)))))
                                             (seq-some (lambda (prefix)
                                                         (string-prefix-p prefix device t))
                                                       eshell-info-banner-partition-prefixes)))
                                         (seq-into-sequence partitions))))
      (mapcar (lambda (partition)
                (let* ((mount-point (format "%s" (cdr (assoc 'mount_point partition))))
                       (total       (cdr (assoc 'total partition)))
                       (used        (cdr (assoc 'used  partition)))
                       (percent     (/ (* 100 used) total)))
                  (make-eshell-info-banner--mounted-partitions
                   :path    (if (> (length mount-point) eshell-info-banner-shorten-path-from)
                                (eshell-info-banner--abbr-path mount-point t)
                              mount-point)
                   :size    total
                   :used    used
                   :percent percent)))
              partitions)))

(defun eshell-info-banner--get-mounted-partitions-df (mount-position)
  "Get mounted partitions through df.
Common function between
`eshell-info-banner--get-mounted-partitions-gnu' and
`eshell-info-banner--get-mounted-partitions-darwin' which would
otherwise differ solely on the position of the mount point in the
partition list. Its position is given by the argument
MOUNT-POSITION."
  (let ((partitions (cdr (split-string (eshell-info-banner--shell-command-to-string "df -l -k")
                                       (regexp-quote "\n")
                                       t))))
    (cl-remove-if #'null
                  (mapcar (lambda (partition)
                            (let* ((partition  (split-string partition " " t))
                                   (filesystem (nth 0 partition))
                                   (size       (* (string-to-number (nth 1 partition)) 1024))
                                   (used       (* (string-to-number (nth 2 partition)) 1024))
                                   (percent    (nth 4 partition))
                                   (mount      (nth mount-position partition)))
                              (when (seq-some (lambda (prefix)
                                                (string-prefix-p prefix filesystem t))
                                              eshell-info-banner-partition-prefixes)
                                (make-eshell-info-banner--mounted-partitions
                                 :path (if (> (length mount) eshell-info-banner-shorten-path-from)
                                           (eshell-info-banner--abbr-path mount t)
                                         mount)
                                 :size size
                                 :used used
                                 :percent (string-to-number
                                           (s-chop-suffix "%" percent))))))
                          partitions))))

(defun eshell-info-banner--get-mounted-partitions-gnu ()
  "Detect mounted partitions on a Linux system.

Return detected partitions as a list of structs.  See
`eshell-info-banner-partition-prefixes' to see how partitions are
chosen.  Relies on the `df' command."
  (eshell-info-banner--get-mounted-partitions-df 5))

(defun eshell-info-banner--get-mounted-partitions-windows ()
  "Detect mounted partitions on a Windows system.

Return detected partitions as a list of structs.  See
`eshell-info-banner-partition-prefixes' to see how partitions are
chosen."
  (progn
    (warn "Partition detection for Windows and DOS not yet supported.")
    nil))

(defun eshell-info-banner--get-mounted-partitions-darwin ()
  "Detect mounted partitions on a Darwin/macOS system.

Return detected partitions as a list of structs.  See
`eshell-info-banner-partition-prefixes' to see how partitions are
chosen.  Relies on the `df' command."
  (eshell-info-banner--get-mounted-partitions-df 8))

(defun eshell-info-banner--get-mounted-partitions-1 ()
  "Detect mounted partitions on the system.

Return detected partitions as a list of structs."
  (if eshell-info-banner-use-duf
      (eshell-info-banner--get-mounted-partitions-duf)
    (pcase system-type
      ((or 'gnu 'gnu/linux 'gnu/kfreebsd 'berkeley-unix)
       (eshell-info-banner--get-mounted-partitions-gnu))
      ((or 'ms-dos 'windows-nt 'cygwin)
       (eshell-info-banner--get-mounted-partitions-windows))
      ('darwin
       (eshell-info-banner--get-mounted-partitions-darwin))
      (other
       (progn
         (warn "Partition detection for %s not yet supported." other)
         nil)))))

(defun eshell-info-banner--get-mounted-partitions ()
  "Detect mounted partitions on the system.

Take `eshell-info-banner-filter-duplicate-partitions' and
`eshell-info-banner-exclude-partitions' into account."
  (let ((partitions (eshell-info-banner--get-mounted-partitions-1)))
    (when eshell-info-banner-filter-duplicate-partitions
      (setq partitions
            (cl-loop for partition in partitions
                     with used = nil
                     for signature =
                     (format "%d-%d"
                             (eshell-info-banner--mounted-partitions-size partition)
                             (eshell-info-banner--mounted-partitions-used partition))
                     unless (member signature used)
                     collect partition and do (push signature used))))
    (when eshell-info-banner-exclude-partitions
      (setq partitions
            (seq-filter (lambda (partition)
                          (let ((path (eshell-info-banner--mounted-partitions-path
                                       partition)))
                            (not (seq-some
                                  (lambda (pattern)
                                    (string-match-p pattern path))
                                  eshell-info-banner-exclude-partitions))))
                        partitions)))
    partitions))

(defun eshell-info-banner--partition-to-string (partition text-padding bar-length)
  "Display a progress bar showing how full a PARTITION is.

For TEXT-PADDING and BAR-LENGTH, see the documentation of
`eshell-info-banner--display-memory'."
  (concat (s-pad-right text-padding
                       "."
                       (eshell-info-banner--with-face
                        (eshell-info-banner--mounted-partitions-path partition)
                        :weight 'bold))
          ": "
          (eshell-info-banner--progress-bar-without-prefix
           bar-length
           (eshell-info-banner--mounted-partitions-used partition)
           (eshell-info-banner--mounted-partitions-size partition))))

(defun eshell-info-banner--display-partitions (text-padding bar-length)
  "Display the detected mounted partitions of the system.

For TEXT-PADDING and BAR-LENGTH, see the documentation of
`eshell-info-banner--display-memory'."
  (mapconcat (lambda (partition)
               (eshell-info-banner--partition-to-string partition text-padding bar-length))
             (eshell-info-banner--get-mounted-partitions)
             "\n"))


                                        ; Memory ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun eshell-info-banner--get-memory-gnu ()
  "Get memory usage for GNU/Linux and Hurd."
  (mapcar (lambda (line)
            (let* ((line (split-string line " " t)))
              (list (s-chop-suffix ":" (nth 0 line))   ; name
                    (string-to-number (nth 1 line))    ; total
                    (string-to-number (nth 2 line))))) ; used
          (split-string (eshell-info-banner--shell-command-to-string "free -b | tail -2")
                        "\n"
                        t)))

(defun eshell-info-banner--get-memory-unix-command-to-mem (command)
  "Get the output of COMMAND corresponding to memory information.
This function is to be only used on platforms which support sysctl."
  (string-to-number
   (s-trim
    (car (last
          (split-string (eshell-info-banner--shell-command-to-string command)
                        " "
                        t))))))

(defun eshell-info-banner--get-memory-netbsd ()
  "Get memory usage for NetBSD systems.
See `eshell-info-banner--get-memory'."
  (let* ((total (eshell-info-banner--get-memory-unix-command-to-mem "sysctl hw.physmem64"))
         (used  (- total
                   (* 1024 (string-to-number
                            (s-trim
                             (with-temp-buffer
                               (insert-file-contents-literally "/proc/meminfo")
                               (save-match-data
                                 (string-match (rx bol
                                                   "MemFree:"
                                                   (* blank)
                                                   (group (+ digit))
                                                   (* blank)
                                                   "kB")
                                               (buffer-string))
                                 (substring-no-properties (buffer-string)
                                                          (match-beginning 1)
                                                          (match-end 1))))))))))
    `(("RAM" ,total ,used))))

(defun eshell-info-banner--get-memory-darwin ()
  "Get memory usage for Darwin systems.
See `eshell-info-banner--get-memory'."
  (let* ((total  (eshell-info-banner--get-memory-unix-command-to-mem "sysctl -n hw.memsize"))
         (vmstat (with-temp-buffer
                   (call-process "vm_stat" nil t nil)
                   (buffer-string)))
         (wired  (save-match-data
                   (string-match (rx " wired" (* (not digit)) (+ blank) (group (+ digit)) ".")
                                 vmstat)
                   (* 1024 4
                      (string-to-number (substring-no-properties vmstat
                                                                 (match-beginning 1)
                                                                 (match-end 1))))))
         (active (save-match-data
                   (string-match (rx " active" (* (not digit)) (+ blank) (group (+ digit)) ".")
                                 vmstat)
                   (* 1024 4
                      (string-to-number (substring-no-properties vmstat
                                                                 (match-beginning 1)
                                                                 (match-end 1))))))
         (compressed (save-match-data
                       (if (string-match (rx " occupied" (* (not digit)) (+ blank) (group (+ digit)) ".")
                                         vmstat)
                           (* 1024 4
                              (string-to-number (substring-no-properties vmstat
                                                                         (match-beginning 1)
                                                                         (match-end 1))))
                         0))))
    `(("RAM" ,total ,(+ wired active compressed)))))

(defun eshell-info-banner--get-memory-unix ()
  "Get memory usage for UNIX systems."
  (cond ((and (equal system-type 'berkeley-unix)
              (string-match-p "NetBSD" (eshell-info-banner--shell-command-to-string "uname")))
         (eshell-info-banner--get-memory-netbsd))
        ((equal system-type 'darwin)
         (eshell-info-banner--get-memory-darwin))
        (t
         (let* ((total (eshell-info-banner--get-memory-unix-command-to-mem "sysctl hw.physmem"))
                (used  (eshell-info-banner--get-memory-unix-command-to-mem "sysctl hw.usermem")))
           `(("RAM" ,total ,used))))))

(defun eshell-info-banner--get-memory-windows ()
  "Get memory usage for Window."
  (warn "Memory usage not yet implemented for Windows and DOS")
  nil)

(defun eshell-info-banner--get-memory ()
  "Get memory usage of current operating system.

Return a list of either one or two elements.  The first element
represents the RAM, the second represents the swap.  Both are
lists and contain three elements: the name of the memory, the
total amount of memory available, and the amount of used memory,
in bytes."
  (pcase system-type
    ((or 'gnu 'gnu/linux)
     (eshell-info-banner--get-memory-gnu))
    ((or 'darwin 'berkeley-unix 'gnu/kfreebsd)
     (eshell-info-banner--get-memory-unix))
    ((or 'ms-dos 'windows-nt 'cygwin)
     (eshell-info-banner--get-memory-windows))
    (os (warn "Memory usage not yet implemented for %s" os)
        nil)))

(defun eshell-info-banner--memory-to-string (type total used text-padding bar-length)
  "Display a memory’s usage with a progress bar.

The TYPE of memory will be the text on the far left, while USED
and TOTAL will be displayed on the right of the progress bar.
From them, a percentage will be computed which will be used to
display a colored percentage of the progress bar and it will be
displayed on the far right.

TEXT-PADDING will determine how many dots are necessary between
TYPE and the colon.

BAR-LENGTH determines the length of the progress bar to be
displayed."
  (concat (s-pad-right text-padding "." type)
          ": "
          (eshell-info-banner--progress-bar-without-prefix bar-length used total t)))

(defun eshell-info-banner--display-memory (text-padding bar-length)
  "Display memories detected on your system.

This function will create a string used by `eshell-info-banner'
in order to display memories detected by the package, generally
the Ram at least, sometimes the swap too.  Displayed progress
bars will have this appearance:

TYPE......: [=========] XXG / XXG  (XX%)

TEXT-PADDING: the space allocated to the text at the left of the
progress bar.

BAR-LENGTH: the length of the progress bar."
  (mapconcat (lambda (mem)
               (eshell-info-banner--memory-to-string (nth 0 mem) (nth 1 mem)
                                                     (nth 2 mem) text-padding
                                                     bar-length))
             (eshell-info-banner--get-memory)
             ""))


                                        ; Display information ;;;;;;;;;;;;;;;;;

(defun eshell-info-banner--get-color-percentage (percentage)
  "Display a PERCENTAGE with its according face."
  (let ((percentage (if (stringp percentage)
                        (string-to-number percentage)
                      percentage)))
    (cond
     ((>= percentage eshell-info-banner-critical-percentage)
      'eshell-info-banner-critical-face)
     ((>= percentage eshell-info-banner-warning-percentage)
      'eshell-info-banner-warning-face)
     (t 'eshell-info-banner-normal-face))))

(defun eshell-info-banner--progress-bar (length percentage &optional invert)
  "Display a progress bar LENGTH long and PERCENTAGE full.
The full path will be displayed filled with the character
specified by `eshell-info-banner-progress-bar-char' up to
PERCENTAGE percents.  The rest will be empty.

If INVERT is t, then consider the percentage to approach
critical levels close to 0 rather than 100."
  (let* ((length-filled     (if (= 0 percentage)
                                0
                              (/ (* length percentage) 100)))
         (length-empty      (- length length-filled))
         (percentage-level (if invert
                               (- 100 percentage)
                             percentage)))
    (concat
     (eshell-info-banner--with-face "[" :weight 'bold)
     (eshell-info-banner--with-face (eshell-info-banner--string-repeat eshell-info-banner-progress-bar-char
                                                                       length-filled)
                                    :weight 'bold
                                    :inherit (eshell-info-banner--get-color-percentage percentage-level))
     (eshell-info-banner--with-face (eshell-info-banner--string-repeat eshell-info-banner-progress-bar-char
                                                                       length-empty)
                                    :weight 'bold
                                    :inherit 'eshell-info-banner-background-face)
     (eshell-info-banner--with-face "]" :weight 'bold))))

(defun eshell-info-banner--display-battery (text-padding bar-length)
  "If the computer has a battery, display its level.

Pad the left text with dots by TEXT-PADDING characters.

BAR-LENGTH indicates the length in characters of the progress
bar.

The usage of `eshell-info-banner-warning-percentage' and
`eshell-info-banner-critical-percentage' is reversed, and can be
thought of as the “percentage of discharge” of the computer.
Thus, setting the warning at 75% will be translated as showing
the warning face with a battery level of 25% or less."
  (let ((battery-level (unless (and (equal system-type 'gnu/linux)
                                    (not (file-readable-p "/sys/")))
                         (battery))))
    (if (or (null battery-level)
            (string= battery-level "Battery status not available")
            (string-match-p (regexp-quote "N/A") battery-level))
        ""
      (let ((percentage (save-match-data
                          (string-match "\\([0-9]+\\)\\(\\.[0-9]\\)?%" battery-level)
                          (string-to-number (substring battery-level
                                                       (match-beginning 1)
                                                       (match-end 1))))))
        (concat (s-pad-right text-padding "." "Battery")
                ": "
                (eshell-info-banner--progress-bar bar-length
                                                  percentage
                                                  t)
                (eshell-info-banner--string-repeat
                 " "
                 (if (equal eshell-info-banner-file-size-flavor 'iec) 21 17))
                (format "(%3s%%)\n"
                        (eshell-info-banner--with-face
                         (number-to-string percentage)
                         :inherit (eshell-info-banner--get-color-percentage (- 100.0 percentage)))))))))


                                        ; Operating system identification ;;;;;;;;;;;;;;;;;;
(defun eshell-info-banner--get-os-information-from-release-file (&optional release-file)
  "Read the operating system from the given RELEASE-FILE.

If RELEASE-FILE is nil, use '/etc/os-release'."
  (let ((prefix (if eshell-info-banner-tramp-aware (file-remote-p default-directory) "")))
    (with-temp-buffer
      (insert-file-contents (concat prefix (or release-file "/etc/os-release")))
      (goto-char (point-min))
      (re-search-forward "PRETTY_NAME=\"\\(.*\\)\"")
      (match-string 1))))

(defun eshell-info-banner--get-os-information-from-hostnamectl ()
  "Read the operating system via hostnamectl."
  (let ((default-directory (if eshell-info-banner-tramp-aware default-directory "~")))
    (with-temp-buffer
      (process-file "hostnamectl" nil t nil)
      (re-search-backward "Operating System: \\(.*\\)")
      (match-string 1))))

(defun eshell-info-banner--get-os-information-from-lsb-release ()
  "Read the operating system information from lsb_release."
  (eshell-info-banner--shell-command-to-string "lsb_release -d -s"))

(defun eshell-info-banner--get-os-information-from-registry ()
  "Read the operating system information from the Windows registry."
  (let ((win32-name "Windows")
        (win32-build "Unknown"))
    (with-temp-buffer
      (call-process "reg" nil t nil "query" "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion")
      (goto-char (point-min))
      (while (re-search-forward "\\([^[:blank:]]+\\) *\\(REG_[^[:blank:]]+\\) *\\(.+\\)" nil t)
        (cond
         ((string= "ProductName" (match-string 1)) (setq win32-name (match-string 3)))
         ((string= "BuildLab" (match-string 1)) (setq win32-build (match-string 3)))))
      (format "%s (%s)" win32-name win32-build))))

(defun eshell-info-banner--get-os-information-windows ()
  "See `eshell-info-banner--get-os-information'."
  (let ((os (eshell-info-banner--get-os-information-from-registry)))
    (save-match-data
      (string-match "\\([^()]+\\) *(\\([^()]+\\))" os)
      `(,(s-trim (substring-no-properties os
                                          (match-beginning 1)
                                          (match-end 1)))
        .
        ,(substring-no-properties os
                                  (match-beginning 2)
                                  (match-end 2))))))

(defun eshell-info-banner--get-os-information-gnu ()
  "See `eshell-info-banner--get-os-information'."
  (let ((prefix (if eshell-info-banner-tramp-aware (file-remote-p default-directory) "")))
    `(,(cond
        ;; Bedrock Linux
        ((file-exists-p (concat prefix "/bedrock/etc/bedrock-release"))
         (s-trim (with-temp-buffer
                   (insert-file-contents (concat prefix "/bedrock/etc/bedrock-release"))
                   (buffer-string))))
        ;; Proxmox
        ((eshell-info-banner--executable-find "pveversion")
         (let ((distro (eshell-info-banner--shell-command-to-string "pveversion")))
           (save-match-data
             (string-match "/\\([^/]+\\)/" distro)
             (concat "Proxmox "
                     (substring-no-properties distro
                                              (match-beginning 1)
                                              (match-end 1))))))
        ((eshell-info-banner--executable-find "hostnamectl")
         (eshell-info-banner--get-os-information-from-hostnamectl))
        ((eshell-info-banner--executable-find "lsb_release")
         (eshell-info-banner--get-os-information-from-lsb-release))
        ((file-exists-p (concat prefix "/etc/os-release"))
         (eshell-info-banner--get-os-information-from-release-file))
        ((eshell-info-banner--executable-find "shepherd")
         (let ((distro (car (s-lines (eshell-info-banner--shell-command-to-string "guix -V")))))
           (save-match-data
             (string-match "\\([0-9\\.]+\\)" distro)
             (concat "Guix System "
                     (substring-no-properties distro
                                              (match-beginning 1)
                                              (match-end 1))))))
        ((equal system-type 'gnu/kfreebsd)
         (let* ((default-directory (if eshell-info-banner-tramp-aware default-directory "~")))
           (s-trim (with-temp-buffer
                     (process-file "uname" nil t nil "-s")
                     (buffer-string)))))
        ((and (file-exists-p (concat prefix "/system/app"))
              (file-exists-p (concat prefix "/system/priv-app")))
         (concat "Android "
                 (s-trim (eshell-info-banner--shell-command-to-string "getprop ro.build.version.release"))))
        (t "Unknown"))
      .
      ,(s-trim (eshell-info-banner--shell-command-to-string "uname -rs")))))

(defmacro eshell-info-banner--get-macos-name (version)
  "Get the name of the current macOS or OSX system based on its VERSION."
  `(cond
    ,@(mapcar (lambda (major)
                `((string-match-p ,(car major)
                                  ,version)
                  ,(cdr major)))
              eshell-info-banner--macos-versions)
    (t "unknown version")))

(defun eshell-info-banner--get-os-information-darwin ()
  "See `eshell-info-banner--get-os-information'."
  `(,(eshell-info-banner--get-macos-name
      (s-trim
       (eshell-info-banner--shell-command-to-string "sw_vers -productVersion")))
    .
    ,(s-trim (eshell-info-banner--shell-command-to-string "uname -rs"))))

(defun eshell-info-banner--get-os-information ()
  "Get operating system identifying information.
Return a pair containing first the name of the operating system
and second its kernel name and version (or in Windows’ case its
build number)."
  (pcase system-type
    ((or 'ms-dos 'windows-nt 'cygwin)
     (eshell-info-banner--get-os-information-windows))
    ((or 'gnu 'gnu/linux 'gnu/kfreebsd 'berkeley-unix)
     (eshell-info-banner--get-os-information-gnu))
    ('darwin
     (eshell-info-banner--get-os-information-darwin))
    (os (warn "Operating system information retrieving not yet supported for %s" os)
        '((format "%s") . "Unknown"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;           Public functions          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun eshell-info-banner ()
  "Banner for Eshell displaying system information."
  (let* ((default-directory (if eshell-info-banner-tramp-aware default-directory "~"))
         (system-info       (eshell-info-banner--get-os-information))
         (os                (car system-info))
         (kernel            (cdr system-info))
         (hostname          (if  eshell-info-banner-tramp-aware
                                (or (file-remote-p default-directory 'host) (system-name))
                              (system-name)))
         (uptime             (eshell-info-banner--get-uptime))
         (partitions         (eshell-info-banner--get-mounted-partitions))
         (left-padding       (eshell-info-banner--get-longest-path partitions))
         (left-text          (max (length os)
                                  (length hostname)))
         (left-length        (+ left-padding 2 left-text)) ; + ": "
         (right-text         (+ (length "Kernel: ")
                                (max (length uptime)
                                     (length kernel))))
         (tot-width          (max (+ left-length right-text 3)
                                  eshell-info-banner-width))
         (middle-padding     (- tot-width right-text left-padding 4))

         (bar-length         (- tot-width left-padding 4 23))
         (bar-length         (if (equal eshell-info-banner-file-size-flavor 'iec)
                                 (- bar-length 4)
                               bar-length)))
    (concat (format "%s\n" (eshell-info-banner--string-repeat eshell-info-banner-progress-bar-char
                                                              tot-width))
            (format "%s: %s Kernel.: %s\n"
                    (s-pad-right left-padding
                                 "."
                                 "OS")
                    (s-pad-right middle-padding " " (eshell-info-banner--with-face os :weight 'bold))
                    kernel)
            (format "%s: %s Uptime.: %s\n"
                    (s-pad-right left-padding "." "Hostname")
                    (s-pad-right middle-padding " " (eshell-info-banner--with-face hostname :weight 'bold))
                    uptime)
            (eshell-info-banner--display-battery left-padding bar-length)
            (eshell-info-banner--display-memory left-padding bar-length)
            (eshell-info-banner--display-partitions left-padding bar-length)
            (format "\n%s\n" (eshell-info-banner--string-repeat eshell-info-banner-progress-bar-char
                                                                tot-width)))))

;;;###autoload
(defun eshell-info-banner-update-banner ()
  "Update the Eshell banner."
  (setq eshell-banner-message (eshell-info-banner)))

(provide 'eshell-info-banner)

;;; eshell-info-banner.el ends here
