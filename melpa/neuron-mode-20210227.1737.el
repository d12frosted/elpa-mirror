;;; neuron-mode.el --- Major mode for editing zettelkasten notes using neuron -*- lexical-binding: t; -*-

;;
;; Copyright (C) 2020 felko
;;
;; Author: felko <http://github/felko>
;; Homepage: https://github.com/felko/neuron-mode
;; Keywords: outlines
;; Package-Commit: a968a923aad07ab15fb35deb79ac95581a427b4c
;; Package-Version: 20210227.1737
;; Package-X-Original-Version: 0.1
;; Package-Requires: ((emacs "26.3") (f "0.20.0") (s "1.12.0") (markdown-mode "2.3") (company "0.9.13"))
;;
;; This file is not part of GNU Emacs.

;;; License: GNU General Public License v3.0
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Editing zettelkasten notes using the neuron zettelkasten manager
;; https://neuron.zettel.page/

;;; Code:

(require 'f)
(require 's)
(require 'cl-macs)
(require 'cl-seq)
(require 'json)
(require 'markdown-mode)
(require 'subr-x)
(require 'seq)
(require 'thingatpt)
(require 'url-parse)
(require 'url-util)
(require 'simple)
(require 'company)
(require 'xref)

(defgroup neuron nil
  "A major mode for editing Zettelkasten notes with neuron."
  :prefix "neuron-"
  :link '(url-link "https://github.com/felko/neuron-mode")
  :group 'markdown)

(defcustom neuron-default-zettelkasten-directory "~/zettelkasten"
  "The location of the default Zettelkasten directory."
  :group 'neuron
  :type  'string
  :safe  'f-directory?)

(defcustom neuron-generate-on-save nil
  "Whether to generate the necessary zettels when a buffer is saved."
  :group 'neuron
  :type  'boolean
  :safe  'booleanp)

(defcustom neuron-executable "neuron"
  "Path to the neuron binary or wrapper around the neuron command.
This might be useful e.g. for Windows users that need to run neuron
from WSL."
  :group 'neuron
  :type  'string)

(defcustom neuron-id-format 'hash
  "The ID format in which new zettels are created.
'hash will make neuron generate a hexadecimal 8-digit UUID.
'prompt will ask for the user to specify the ID every time a zettel is created.
This can be also set to a callable that takes the title as an argument
and returns the desired ID."
  :group 'neuron
  :type  '(choice
           (symbol   :tag "Let neuron handle the ID creation using CLI arguments")
           (function :tag "Function taking the title as argument and returning an ID")))

(defcustom neuron-title-format "# %s"
  "Format of title of a new zettel note.
This format string will be run through `format' (with title
as argument) to populate the new zettel"
  :group 'neuron
  :type 'string)

(defcustom neuron-daily-note-id-format "%Y-%m-%d"
  "Format of daily note IDs.
When creating a daily note with `neuron-open-daily-notes' this format
string will be run through `format-time-string' to create a zettel
ID."
  :group 'neuron
  :type  'string)

(defcustom neuron-daily-note-title-format "%x"
  "Format of daily note titles.
When creating a daily note with `neuron-open-daily-notes' this format
string will be run through `format-time-string' to create the title
of the zettel."
  :group 'neuron
  :type  'string)

(defcustom neuron-default-tags nil
  "List of tags to add to a newly created zettels."
  :group 'neuron
  :type  '(repeat string))

(defcustom neuron-daily-note-tags (list "journal/daily")
  "List of tags to add to a newly created daily notes file."
  :group 'neuron
  :type  '(repeat string))

(defcustom neuron-tag-specific-title-faces nil
  "Faces for links that point to a zettel having a specific tag.
Overrides `neuron-title-overlay-face' which you may inherif from."
  :group 'neuron
  :type '(alist :key-type string :value-type face))

(defcustom neuron-rib-server-host "localhost"
  "The host on which the rib server is started."
  :group 'neuron
  :type  'stringp)

(defcustom neuron-rib-server-port 8080
  "The port on which the rib server is started."
  :group 'neuron
  :type  'integerp)

(defcustom neuron-max-completion-width 30
  "Maximum width of the title in the completion candidates."
  :group 'neuron
  :type 'integerp)

(defcustom neuron-max-trail-length 20
  "Maximum length of the trail.
The trail stores a list of zettel IDs which tracks
the previously visited zettels."
  :group 'neuron
  :type 'integerp)

(defcustom neuron-title-in-buffer-name 't
  "Whether to include zettel titles in buffer names.

If non-nil, the zettel title will be included in the buffer name."
  :group 'neuron
  :type 'booleanp)

(defgroup neuron-faces nil
  "Faces used in neuron-mode."
  :group 'neuron
  :group 'faces)

(defface neuron-link-face
  '((((class color) (min-colors 88) (background dark)) :foreground "burlywood")
    (((class color) (min-colors 88) (background light)) :foreground "sienna")
    (t :inherit link))
  "Face for zettel IDs in zettels and prompts"
  :group 'neuron-faces)

(defface neuron-invalid-zettel-id-face
  '((t :inherit error))
  "Face for links that point to non existent zettels."
  :group 'neuron-faces)

(defface neuron-zettel-tag-face
  '((t :inherit shadow))
  "Face for tags in prompts."
  :group 'neuron-faces)

(defface neuron-title-overlay-face
  '((((class color) (min-colors 88) (background dark)) :foreground "MistyRose2" :underline "MistyRose2")
    (((class color) (min-colors 88) (background light)) :foreground "MistyRose4" :underline "MistyRose4")
    (((class color) :foreground "grey" :underline "grey"))
    (t :inherit italic))
  "Face for title overlays displayed with folgezettel links."
  :group 'neuron-faces)

(defface neuron-invalid-link-face
  '((t :inherit error))
  "Face for the 'Unknown' label dislayed next to short links with unknown IDs."
  :group 'neuron-faces)

(defface neuron-link-mouse-face
  '((t :inherit highlight))
  "Face displayed when hovering a zettel short link.")

(defvar neuron-make-title
  (lambda (selection)
    (with-temp-buffer
      (insert selection)
      (goto-char (point-min))
      (call-interactively #'capitalize-dwim)
      (buffer-string)))
  "Postprocess the selected text to make the title of zettels.
This function is called by `neuron-create-zettel-from-selected-title' to
generate a title for the new zettel, it passes the selected text as
an argument.")

(defvar neuron-show-ids nil
  "Whether to show IDs next to zettel titles.
Applies both in neuron-mode buffers and in the completion minibuffer when
selecting a zettel. Can be toggled using `neuron-toggle-id-visibility'.")

(defvar neuron--current-zettelkasten nil
  "The currently active zettelkasten.
Since it can be invalid sometimes, it should only be used in internal
functions when we know that the zettelkasten was just updated.")

(defvar-local neuron-trail nil
  "List of previously visited zettels, in order.")

(defun neuron--detect-zettelkasten (pwd)
  "Navigate upwards from PWD until a neuron.dhall file is found.
When no neuron.dhall file was found, return nil."
  (let ((is-zk (lambda (dir) (f-exists? (f-join "/" dir "neuron.dhall")))))
    (f-traverse-upwards is-zk pwd)))

(defun neuron--get-zettelkasten (&optional pwd)
  "Return the location of the current zettelkasten.
Assuming the current working directory is PWD, first try to
detect the zettelkasten automatically by traversing the hierarchy
upwards until a neuron.dhall file is found. When no neuron.dhall
file is found, return `neuron-default-zettelkasten-directory'.
Lastly, if the default zettelkasten location doesn't point to
an actual directory, return nil."
  (interactive "P")
  (or
   (neuron--detect-zettelkasten pwd)
   (let ((root neuron-default-zettelkasten-directory))
     (and (f-exists? root) (f-directory? root) neuron-default-zettelkasten-directory))))

(defun neuron--update-current-zettelkasten (root)
  "Update `neuron--current-zettelkasten' with the new value ROOT.
Refresh the zettel cache if the value has changed."
  (let ((old-root neuron--current-zettelkasten)
        (new-root (expand-file-name root)))
    (setq neuron--current-zettelkasten new-root)
    (when (or
           ;; When the current zettelkasten has changed since last time
           (and neuron--current-zettelkasten (not (equal old-root new-root)))
           ;; First time that a neuron-mode function was called:
           (not neuron--current-zettelkasten))
      (neuron--rebuild-cache))
    neuron--current-zettelkasten))

(defun neuron--pop-to-buffer-same-window (buffer)
  (xref-push-marker-stack)
  (pop-to-buffer-same-window buffer))

;;;###autoload
(defun neuron-zettelkasten (&optional pwd)
  "The location of the current Zettelkasten directory.
First, it tries to detect automatically the current zettelkasten assuming
the working directory is PWD, by traversing upwards in the directory
hierarchy until a neuron.dhall file is met, and returns
`neuron-default-zettelkasten-directory' when no neuron.dhall was found.
If in turn `neuron-default-zettelkasten-directory' doesn't point to an
existing directory, throw an user error."
  (neuron--update-current-zettelkasten
   (or
    (call-interactively 'neuron--get-zettelkasten pwd)
    (let ((default neuron-default-zettelkasten-directory))
      (and
       (when (not (f-exists? default))
         (user-error "Invalid zettelkasten: %s does not exist" default))
       (when (not (f-directory? default))
         (user-error "Invalid zettelkasten: %s is not a directory" default)))))))

;; Convenient alias when the result of `neuron-zettelkasten' isn't assigned
(defun neuron-check-if-zettelkasten-exists ()
  "Check whether the active zettelkasten exists."
  (neuron-zettelkasten))

(defun neuron--make-command (cmd &rest args)
  "Construct a neuron command CMD with argument ARGS."
  (let ((neuron-args
         (if (stringp args)
             (append (list "-d" neuron--current-zettelkasten cmd) args)
           (seq-concatenate 'list (list "-d" neuron--current-zettelkasten cmd) args))))
    (concat
     neuron-executable
     " "
     (mapconcat
      #'shell-quote-argument
      neuron-args " "))))

(defun neuron--make-query-command (args)
  "Construct a neuron query command with the given arguments.
ARGS describes the argument to pass to `neuron query'."
  (neuron--make-command "query" args))

(defun neuron--run-command (cmd)
  "Run the CMD neuron command with arguments ARGS in the current zettekasten.
The command is executed as a synchronous process and the standard output is
returned as a string."
  (let* ((result    (with-temp-buffer
                      (list (call-process-shell-command cmd nil '(t nil)) (buffer-string))))
         (exit-code (nth 0 result))
         (output    (nth 1 result)))
    (if (equal exit-code 0)
        (string-trim-right output)
      (and (user-error "Command \"%s\" exited with code %d: %s" cmd exit-code output)
           nil))))

(defun neuron--read-query-result (output)
  "Parse the OUTPUT of a query command in JSON.
Extract only the result itself, so the query type is lost."
  (json-read-from-string output))

(defun neuron--query-command (args)
  "Run a neuron query with given arguments."
  (neuron--read-query-result (neuron--run-command (neuron--make-query-command args))))

(defun neuron--run-rib-process (&rest args)
  "Run an asynchronous neuron process spawned by the rib command with arguments ARGS."
  (start-process-shell-command "rib" "*rib*" (apply #'neuron--make-command "rib" args)))

(defun neuron--run-rib-compile (&rest args)
  "Run an synchronous neuron command spawned by the rib command with arguments ARGS."
  (compile (apply #'neuron--make-command "rib" args)))

(defvar neuron--zettel-cache nil
  "Map containing all zettels indexed by their ID.")

(defun neuron--rebuild-cache ()
  "Rebuild the zettel cache with the current zettelkasten."
  (let ((zettels (neuron--query-command "--zettels"))
        (assoc-id (lambda (zettel) (cons (intern (map-elt zettel 'ID)) zettel))))
    (setq neuron--zettel-cache (mapcar assoc-id zettels))))

(defun neuron-list-buffers ()
  "Return the list of all open neuron-mode buffers in the current zettelkasten."
  (let* ((root (neuron-zettelkasten))
         (pred (lambda (buffer)
                 (with-current-buffer buffer
                   (and
                    (eq major-mode 'neuron-mode)
                    (f-parent-of? root buffer-file-name))))))
    (seq-filter pred (buffer-list))))

;;;###autoload
(defun neuron-refresh ()
  "Regenerate the zettel cache and the title overlays in all neuron-mode buffers."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (make-thread (lambda ()
                 (progn
                   (neuron--rebuild-cache)
                   (dolist (buffer (neuron-list-buffers))
                     (with-current-buffer
                         buffer
                       (neuron--setup-overlays)
                       (neuron--name-buffer))
                     (with-current-buffer buffer (neuron--name-buffer)))
                   (message "Regenerated zettel cache")))
               "neuron-refresh"))

(defun neuron--is-valid-id (id)
  "Check whether the ID is a valid neuron zettel ID.
Valid IDs should be strings of alphanumeric characters."
  (string-match (rx bol (+ (or (char (?A . ?Z)) (char (?a . ?z)) digit (char "_-") (char " "))) eol) id))

(defun neuron--make-new-command (&optional id title)
  (neuron-check-if-zettelkasten-exists)
  (unless id
    (setq id (pcase neuron-id-format
               ('prompt
                (if-let* ((id (read-string "ID: "))
                          ((neuron--is-valid-id id)))
                    id
                  (user-error "Invalid zettel ID: %S" id)))
               ((pred functionp)
                (let ((id (funcall neuron-id-format title)))
                  (if (neuron--is-valid-id id)
                      id
                    (user-error "Invalid zettel ID: %S" id)))))))
  (let ((args (if id (list id) nil)))
    (apply #'neuron--make-command "new" args)))

(defun neuron-create-zettel-buffer (title &optional id no-default-tags)
  "Create a new zettel in the current zettelkasten.
The new zettel will be generated with the given TITLE and ID if specified.
When TITLE is nil, prompt the user.
If NO-DEFAULT-TAGS is non-nil, don't add the tags specified the variable
`neuron-default-tags'."
  (interactive (list (read-string "Title: ")))
  (neuron-check-if-zettelkasten-exists)
  (when (or (not id) (and id (not (neuron--get-cached-zettel-from-id id))))
    (let* ((cmd     (neuron--make-new-command id title))
           (path    (neuron--run-command cmd))
           (buffer  (find-file-noselect path)))
      (with-current-buffer buffer
        (unless no-default-tags
          (dolist (tag neuron-default-tags)
            (neuron-add-tag tag)))
        (when title
          (goto-char (point-max))
          (newline)
          (insert (format neuron-title-format title)))
        (save-buffer))
      (neuron--rebuild-cache)
      (message "Created %s" (f-filename path))
      buffer)))

(defun neuron--name-buffer ()
  "Name the zettel BUFFER according to `neuron-title-in-buffer-name'"
  (let* ((zettel-id (neuron--get-zettel-id (current-buffer)))
         (zettel-title (neuron--get-zettel-title zettel-id))
         (short-buffer-filename (f-filename (buffer-file-name (current-buffer))))
         (new-buffer-name (if neuron-title-in-buffer-name
                              (if zettel-title
                                  (concat short-buffer-filename " (" zettel-title ")")
                                short-buffer-filename)
                            short-buffer-filename)))
    (rename-buffer new-buffer-name)))

(defun neuron--get-zettel-title (id)
  "Get the title of the zettel with an id of ID.
Returns nil if no such zettle is found."
  (alist-get 'Title (neuron--get-cached-zettel-from-id id) nil))

;;;###autoload
(defun neuron-new-zettel (&optional title id)
  "Create a new zettel and open it in a new buffer.
The new zettel will be generated with the given TITLE and ID if specified.
When TITLE is nil, prompt the user."
  (interactive)
  (if-let (buffer (call-interactively #'neuron-create-zettel-buffer t (vector title id)))
      (neuron--pop-to-buffer-same-window buffer)
    (user-error "Unable to create zettel %s" id)))

;;;###autoload
(defun neuron-open-daily-notes ()
  "Create or open today's daily notes."
  (interactive)
  (let* ((today  (current-time))
         (zid    (format-time-string neuron-daily-note-id-format today))
         (title  (format-time-string neuron-daily-note-title-format today))
         (new    (neuron-create-zettel-buffer title zid t))
         (path   (neuron--get-zettel-path (neuron--query-zettel-from-id zid)))
         (buffer (or new (find-file-noselect path))))
    (and
     (neuron--pop-to-buffer-same-window buffer)
     (with-current-buffer buffer
       (when new
         (dolist (tag neuron-daily-note-tags)
           (neuron-add-tag tag)))))))

(defun neuron--style-zettel-id (zid)
  "Style a ZID as shown in the completion prompt."
  (propertize (format "[[[%s]]]" zid) 'face 'neuron-link-face))

(defun neuron--style-tags (tags)
  "Style TAGS as shown in the completion prompt when selecting a zettel."
  (if (eq tags [])
      ""
    (propertize (format "(%s)" (s-join ", " tags)) 'face 'neuron-zettel-tag-face)))

(defun neuron--propertize-zettel (zettel)
  "Format ZETTEL as shown in the selection prompt."
  (let ((id (alist-get 'ID zettel))
        (title (alist-get 'Title zettel))
        (tags (neuron--get-zettel-tags zettel)))
    (format "%s %s %s" (neuron--style-zettel-id id) title (neuron--style-tags tags))))

(defun neuron--select-zettel-from-list (zettels &optional prompt require-match)
  "Select a zettel from a given list.
ZETTELS is a list of maps containing zettels (keys: id, title, day, tags, path)
PROMPT is the prompt passed to `completing-read'.  When REQUIRE-MATCH is
non-nil require the input to match an existing zettel."
  (let ((selection
         (completing-read (or prompt "Select Zettel: ")
                          (mapcar #'neuron--propertize-zettel zettels)
                          nil
                          require-match)))
    (if (string-match (eval `(rx bos (regexp ,neuron-link-regex))) selection)
        ;; The selection is among the candidates
        (neuron--get-cached-zettel-from-id (match-string 1 selection))
      (unless require-match
        (let ((buffer (neuron-create-zettel-buffer selection)))
          (neuron--get-cached-zettel-from-id (neuron--get-zettel-id buffer)))))))

(defun neuron--select-zettel-from-cache (&optional prompt)
  "Select a zettel from the current cache.
PROMPT is the prompt passed to `completing-read'."
  (neuron--select-zettel-from-list (map-values neuron--zettel-cache) prompt t))

(defun neuron--select-zettel-from-query (args)
  "Select a zettel from a query.
ARGS is the arguments to pass to the neuron query command."
  (neuron--select-zettel-from-list (neuron--query-command args) nil t))

(defun neuron-select-zettel (&optional prompt)
  "Find a zettel in the current zettelkasten.
PROMPT is the prompt passed to `completing-read'."
  (neuron-check-if-zettelkasten-exists)
  (neuron--select-zettel-from-cache prompt))

(defun neuron--get-zettel-path (zettel)
  "Get the absolute path of ZETTEL."
  (f-join "/" neuron--current-zettelkasten (alist-get 'Path zettel)))

(defun neuron--get-plugin-data (plugin-data-list plugin i)
  "Extract from all plugin data the part that is relevant for a given plugin.
PLUGIN-DATA-LIST is in the JSON representation of the plugin data and PLUGIN
is the plugin name."
  (if (eq i (length plugin-data-list))
      nil
    (let* ((data (aref plugin-data-list i))
           (name (aref (aref data 0) 0)))
      (if (equal name plugin)
          (aref data 1)
        (neuron--get-plugin-data plugin-data-list plugin (+ i 1))))))

(defun neuron--get-zettel-tags (zettel)
  "Get the tags of ZETTEL."
  (alist-get 'Tagged (neuron--get-plugin-data (alist-get 'PluginData zettel) "Tags" 0)))

;;;###autoload
(defun neuron-edit-zettel (zettel)
  "Select and edit ZETTEL."
  (interactive (list (neuron-select-zettel "Edit zettel: ")))
  (neuron--edit-zettel-from-path (neuron--get-zettel-path zettel)))

(defun neuron--get-uplinks-from-id (id)
  "Get the list of zettels that point to the zettel ID."
  (when-let* ((cmd (neuron--make-command "query" "--uplinks-of" id))
              (output (neuron--run-command cmd))
              (results (neuron--read-query-result output)))
    (mapcar (lambda (result) (seq-elt result 1)) results)))

(defun neuron-edit-uplink ()
  "Select and edit a zettel among the ones that link to the current zettel."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (let* ((id (neuron--get-zettel-id))
         (uplinks (neuron--get-uplinks-from-id id)))
    (neuron-edit-zettel (neuron--select-zettel-from-list uplinks "Edit uplink: " t))))

;;;###autoload
(defun neuron-edit-zettelkasten-configuration ()
  "Open the neuron.dhall configuration file at the root of the zettelkasten."
  (interactive)
  (find-file (f-join "/" (neuron-zettelkasten) "neuron.dhall")))

(defun neuron--select-static-file (&optional allow-copy)
  "Select a file located in the static directory of the current zettelkasten.
If ALLOW-COPY is non-nil and that the selected file is not in the static
directory, prompt the user if they want to copy it to the static directory,
otherwise return nil."
  (let* ((root (neuron-zettelkasten))
         (static-dir (f-join "/" root "static"))
         (path (read-file-name "Select static file: " static-dir nil t)))
    (if (f-descendant-of? path static-dir)
        path
      (if (and allow-copy
               (y-or-n-p (format "File %s is not in the static directory, copy it to %sstatic? " path root)))
          (let ((copied-path (f-join "/" static-dir (f-filename path))))
            (copy-file path copied-path)
            copied-path)
        (user-error "File %s is not in %sstatic" path root)))))

(defun neuron-insert-static-link (path)
  "Insert a link to PATH in the static directory."
  (interactive (list (neuron--select-static-file t)))
  (when path
    (insert (format "[](%s)" (f-relative path neuron--current-zettelkasten)))))

(defun neuron--insert-zettel-link-from-id (id)
  "Insert a zettel link."
  (progn
    (insert (format "[[[%s]]]" id))
    (neuron--setup-overlays)))

(defun neuron-insert-zettel-link ()
  "Insert a markdown hypertext link to another zettel."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (neuron--insert-zettel-link-from-id (map-elt (neuron-select-zettel "Link zettel: ") 'ID)))

(defun neuron-insert-new-zettel ()
  "Create a new zettel."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (when-let* ((buffer (call-interactively #'neuron-create-zettel-buffer))
              (id (neuron--get-zettel-id buffer)))
    (progn
      (neuron--insert-zettel-link-from-id id)
      (save-buffer)
      (neuron--rebuild-cache)
      (neuron--pop-to-buffer-same-window buffer)
      (message "Created %s" (buffer-name buffer)))))

(defun neuron-create-zettel-from-selected-title ()
  "Transforms the selected text into a new zettel with the selection as a title."
  (interactive)
  (when-let* ((selection (buffer-substring-no-properties (region-beginning) (region-end)))
              (title     (if (s-blank? selection)
                             (user-error "Cannot create zettel: empty title")
                           (funcall neuron-make-title selection)))
              (buffer    (funcall-interactively #'neuron-create-zettel-buffer title))
              (id        (neuron--get-zettel-id buffer)))
    (save-excursion
      (delete-region (region-beginning) (region-end))
      (goto-char (region-beginning))
      (neuron--insert-zettel-link-from-id id)
      (neuron--setup-overlays))))

(defun neuron-create-and-insert-zettel-link (no-prompt)
  "Insert a markdown hypertext link to another zettel.
If the selected zettel does not exist it will be created.  When
NO-PROMPT is non-nil do not prompt when creating a new zettel."
  (interactive "P")
  (neuron-check-if-zettelkasten-exists)
  (let* ((selection
          (neuron--select-zettel-from-list
           (map-values neuron--zettel-cache)
           "Link zettel: "))
         (id (and (listp selection) (alist-get 'ID selection))))
    (pcase selection
      ;; Existing zettel:
      ((guard id)
       (neuron--insert-zettel-link-from-id id))
      ;; Title of new zettel:
      ((pred stringp)
       (when (or no-prompt
                 (y-or-n-p (concat "Create a new zettel (" selection ")? ")))
         (let* ((buffer (neuron-create-zettel-buffer selection))
                (id     (neuron--get-zettel-id buffer)))
           (neuron--rebuild-cache)
           (neuron--insert-zettel-link-from-id id)))))))

(defun neuron-toggle-connection-type ()
  "Toggle the link under point between folgezettel and cf connection."
  (interactive)
  (if (thing-at-point-looking-at
       neuron-link-regex
       ;; limit to current line
       (max (- (point) (line-beginning-position))
            (- (line-end-position) (point))))
      (if-let* ((link (match-string 1))
                (start (match-beginning 0))
                (end (match-end 0))
                (conn (if (null (match-string 2)) 'ordinary 'folgezettel))
                (query (neuron--parse-query-from-url-or-id link (eq conn 'folgezettel)))
                (toggled (if (eq conn 'folgezettel) 'ordinary 'folgezettel))
                (new-query (progn (setf (map-elt query 'conn nil) toggled) query)))
          (save-excursion
            (goto-char start)
            (delete-region start end)
            (insert (neuron-render-query new-query))
            (neuron--setup-overlays))
        (user-error "Invalid query"))
    (user-error "No query under point")))

(defun neuron--flatten-tag-node (node &optional root)
  "Flatten NODE into a list of tags.
Each element is a map containing 'tag and 'count keys.
The full tag is retrieved from the ROOT argument that is passed recursively.
See `neuron--flatten-tag-tree'."
  (let* ((name  (map-elt node 'name))
         (count (map-elt node 'count))
         (children (map-elt node 'children))
         (tag   (if root (concat root "/" name) name))
         (elem  (list (cons 'count count) (cons 'tag tag))))
    (cons elem (neuron--flatten-tag-tree children tag))))

(defun neuron--flatten-tag-tree (tree &optional root)
  "Flatten TREE into a list of tags.
Each element is a map containing 'tag and 'count keys.
The full tag is retrieved from the ROOT argument that is passed recursively."
  (apply #'append (mapcar (lambda (node) (neuron--flatten-tag-node node root)) tree)))

(defun neuron--propertize-tag (elem)
  "Format ELEM as shown in the tag selection prompt.
ELEM is a map containing the name of the tag and the number of associated zettels."
  (let* ((tag   (alist-get 'tag elem))
         (count (alist-get 'count elem))
         (display-count (propertize (format "(%d)" count) 'face 'shadow)))
    (format "%s %s" tag display-count)))

(defun neuron--select-tag-from-query (args &optional prompt require-match)
  "Prompt for a tag that is matched by the query.
ARGS is the arguments to pass to the neuron query command.
PROMPT is the prompt that appears when asked to select the tag.
If REQUIRE-MATCH is non-nil require user input to match an existing tag."
  (let ((tags (append (neuron--query-command args) nil)))
    (completing-read (or prompt "Select tag: ")
                     tags
                     nil
                     require-match)))

(defun neuron--get-metadata-block-bounds (&optional create-if-missing)
  "Return the bounds of the metadata block.
If CREATE-IF-MISSING is non-nil, insert automatically the YAML metadata
blocks delimiters (---)."
  (save-excursion
    (goto-char (point-min))
    (when-let* ((delim (rx bol "---" (0+ blank) eol))
                (begin (if (looking-at-p delim) (point)
                         (when create-if-missing
                           (save-excursion (insert "---\n---\n"))
                           (point))))
                (end (save-excursion
                       (goto-char begin)
                       (forward-line)
                       (while (not (looking-at-p delim))
                         (forward-line))
                       (point))))
      (list begin end))))

(defun neuron--navigate-to-metadata-field (field)
  "Move point to the character after metadata FIELD.
If FIELD does not exist it is created."
  (goto-char (point-min))
  (let* ((block-end (nth 1 (neuron--get-metadata-block-bounds 'create-if-missing)))
         (fieldre (rx-to-string `(: bol (0+ blank) ,field ":" (0+ blank)))))
    (unless (search-forward-regexp fieldre block-end t)
      (goto-char block-end)
      (forward-line -1)
      (end-of-line)
      (insert (concat "\n" field ": ")))))

(defun neuron-select-tag (&optional prompt require-match)
  "Prompt for a tag that is already used in the zettelkasten.
PROMPT is the prompt passed to `completing-read'.
If REQUIRE-MATCH is non-nil require user input to match an existing
tag."
  (neuron-check-if-zettelkasten-exists)
  (neuron--select-tag-from-query "--tags" prompt require-match))

(defun neuron-select-multiple-tags (&optional prompt)
  "Select multiple tags as a comma-separated list.
PROMPT is the prompt passed to `completing-read'."
  (let* ((query-result (neuron--query-command "--tags"))
         (tags (mapcar (lambda (el) (alist-get 'tag el)) query-result)))
    (completing-read-multiple (or prompt "Select tags: ") tags)))

(defun neuron-add-tags (tags)
  "Add multiple TAGS to the tags metadata field.
When called interactively it promps for multiple comma-separated tags."
  (interactive (list (neuron-select-multiple-tags)))
  (save-excursion
    (neuron--navigate-to-metadata-field "tags")
    (dolist (tag tags)
      (insert (format "\n  - %s" tag)))))

(defun neuron-add-tag (tag)
  "Add TAG to the list of tags.
When called interactively this command prompts for a tag."
  (interactive (list (neuron-select-tag)))
  (neuron-add-tags (list tag)))

;;;###autoload
(defun neuron-query-tags (&rest tags)
  "Select and edit a zettel from those that are tagged by TAGS."
  (interactive (list (neuron-select-tag "Search by tag: " t)))
  (neuron-edit-zettel
   (neuron--select-zettel-from-list
    (seq-mapcat
     (lambda (tag) (neuron--query-command (format "--tag=%s" tag)))
     tags
     'list))))

(defun neuron--edit-zettel-from-path (path)
  "Open a neuron zettel from PATH."
  (let ((buffer (find-file-noselect path)))
    (neuron--pop-to-buffer-same-window buffer)))

(defun neuron--query-zettel-from-id (id)
  "Query a single zettel from the active zettelkasten from its ID.
Returns a map containing its title, tag and full path."
  (neuron--read-query-result (neuron--run-command (neuron--make-command "query" "--id" id))))

(defun neuron--get-cached-zettel-from-id (id &optional retry)
  "Fetch a cached zettel from its ID.
When RETRY is non-nil and that the ID wasn't found, the cache is regenerated
and queried a second time. This is called internally to automatically refresh
the cache when the ID is not found."
  (or (map-elt neuron--zettel-cache (intern id))
      (when retry
        (neuron--rebuild-cache)
        (or (map-elt neuron--zettel-cache (intern id))
            (user-error "Cannot find zettel with ID %s" id)))))

(defun neuron--edit-zettel-from-id (id)
  "Open a neuron zettel from ID."
  (if-let ((zettel (neuron--get-cached-zettel-from-id id)))
      (neuron-edit-zettel zettel)
    (user-error "Zettel %s does not exist" id)))

(defun neuron--edit-zettel-from-query (args)
  "Select and edit a zettel from a query.
ARGS is the arguments to pass to the neuron query command."
  (neuron-edit-zettel (neuron--select-zettel-from-query args)))

(defun neuron--get-zettel-id (&optional buffer)
  "Extract the zettel ID of BUFFER."
  (interactive "b")
  (f-base (buffer-file-name buffer)))

(defun neuron--open-page (rel-path)
  "Open the REL-PATH in the browser.
The path is relative to the neuron output directory."
  (let* ((path (f-join "/" neuron--current-zettelkasten ".neuron" "output" rel-path))
         (url (format "file://%s" path)))
    (browse-url url)))

(defun neuron--open-zettel-from-id (id)
  "Open the generated HTML file from the zettel ID."
  (neuron--open-page (format "%s.html" id)))

;;;###autoload
(defun neuron-open-zettel ()
  "Select a zettel and open the associated HTML file."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (neuron--open-zettel-from-id (map-elt (neuron-select-zettel "Open zettel: ") 'ID)))

(defun neuron-open-index ()
  "Open the index.html file."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (neuron--open-page "index.html"))

(defun neuron-open-current-zettel ()
  "Open the current zettel's HTML file in the browser."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (neuron--open-zettel-from-id (funcall-interactively #'neuron--get-zettel-id)))

(defconst neuron-link-regex
  (concat "\\[\\{2,3\\}\\(z:" thing-at-point-url-path-regexp "\\|[[:alnum:]-_ ]+\\(?:\?[^][\t\n\\ {}]*\\)?\\)]]\\(]\\)*")
  "Regex matching zettel links like [[[URL/ID]]] or [[URL/ID]] .
Group 1 is the matched ID or URL.")


(defun neuron--extract-id-from-partial-url (url)
  "Extract the ID from a single zettel URL."
  (let* ((struct (url-generic-parse-url url))
         (path   (car (url-path-and-query struct)))
         (type   (url-type struct))
         (parts  (s-split "/" path)))
    (pcase (length parts)
      (1 (when (not type) path))  ; path is ID
      (2 (when (and (equal type "z") (equal (nth 0 parts) "zettel")) (nth 1 parts))))))

(defun neuron--follow-query (query)
  "Follow a neuron link from a zettel ID or an URL.
QUERY is a query object as described in `neuron--parse-query-from-url-or-id'."
  (let ((url (map-elt query 'url)))
    (pcase (map-elt query 'type)
      ('zettel  (neuron--edit-zettel-from-id (alist-get 'id query)))
      ('zettels (neuron--edit-zettel-from-query url))
      ('tags    (neuron-query-tags (neuron--select-tag-from-query url "Search by tag: "))))))

(defun neuron--parse-query-from-url-or-id (url-or-id folgezettel?)
  "Parse a neuron URL or a raw zettel ID as an object representing the query.
URL-OR-ID is a string that is meant to be parsed inside neuron links inside
angle brackets. The query is returned as a map having at least a `'type' field.
When URL-OR-ID is a raw ID, or that it is an URL having startin with z:zettel,
the map also has an `ID' field. Whenever URL-OR-ID is an URL and not an
ID, the map features an `'url' field."
  (let* ((struct (url-generic-parse-url url-or-id))
         (path-and-query (url-path-and-query struct))
         (path   (car path-and-query))
         (query  (cdr path-and-query))
         (parts  (s-split "/" path))
         (type   (url-type struct))
         (args   (when query (url-parse-query-string query)))
         (conn   (if folgezettel? 'folgezettel 'ordinary))
         (common `((conn . ,conn)
                   (url . ,url-or-id)
                   (args . ,(assoc-delete-all "cf" args)))))
    (append
     common
     (if (equal type "z")
         (pcase (car parts)
           ("zettel"  (when-let ((id (nth 1 parts))) `((type . zettel) (id . ,id))))
           ("zettels" `((type . zettels)))
           ("tags"    `((type . tags))))
       ;; Probably just an ID
       `((type . zettel) (id . ,path))))))

;; FIXME avoid hexifying link
(defun neuron-render-query (query)
  "Render a neuron query in markdown.
QUERY is an alist containing at least the query type and the URL."
  (let* ((args (alist-get 'args query))
         (conn (alist-get 'conn query))
         (link-opening (if (eq conn 'ordinary) "[[" "[[["))
         (link-closing (if (eq conn 'ordinary) "]]" "]]]"))
         (url-args args)
         (url-query (url-build-query-string url-args))
         (url-suffix (if url-args (format "?%s" url-query) "")))
    (pcase (alist-get 'type query)
      ('zettel (format "%s%s%s%s" link-opening (alist-get 'id query) url-suffix link-closing))
      ('zettels (format "%sz:zettels%s%s" link-opening url-suffix link-closing))
      ('tags (format "%sz:tags%s%s" link-opening url-suffix link-closing)))))

;;;###autoload
(defun neuron-follow-thing-at-point ()
  "Open the zettel link at point."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  ;; New links (from the `thing-at-point' demo)
  (if (thing-at-point-looking-at
       neuron-link-regex
       ;; limit to current line
       (max (- (point) (line-beginning-position))
            (- (line-end-position) (point))))
      (if-let ((query (neuron--parse-query-from-url-or-id (match-string 1) 't)))
          (neuron--follow-query query)
        (user-error "Invalid query"))
    ;; Old style links
    ;; TODO deprecate
    (let* ((link   (markdown-link-at-pos (point)))
           (id     (nth 2 link))
           (url    (nth 3 link))
           (struct (url-generic-parse-url url))
           (type   (url-type struct)))
      (pcase type
        ((or "z" "zcf") (neuron--edit-zettel-from-id id))
        ((or "zquery" "zcfquery")
         (pcase (url-host struct)
           ("search" (neuron-edit-zettel (neuron--select-zettel-from-query url)))
           ("tags"   (neuron-query-tags (neuron--select-tag-from-query url)))))
        (_ (markdown-follow-thing-at-point link))))))

;;;###autoload
(defun neuron-rib-watch ()
  "Start a web app for browsing the zettelkasten."
  (interactive)
  (let ((root (neuron-zettelkasten)))
    (if (neuron--run-rib-process "-w")
        (message "Watching %s for changes..." root)
      (user-error "Failed to watch %s" root))))

;;;###autoload
(defun neuron-rib-serve ()
  "Start a web app for browsing the zettelkasten."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (let ((address (format "%s:%d" neuron-rib-server-host neuron-rib-server-port)))
    (if (neuron--run-rib-process "-ws" address)
        (message "Started web application on %s" address)
      (user-error "Failed to run rib server on %s" address))))

;;;###autoload
(defun neuron-rib-generate ()
  "Do an one-off generation of the web interface of the zettelkasten."
  (interactive)
  (let ((root (neuron-zettelkasten)))
    (if (neuron--run-rib-compile)
        (message "Generated HTML files")
      (user-error "Failed to generate %s" root))))

;;;###autoload
(defun neuron-rib-open-page (page)
  "Open the web-application at page PAGE."
  (neuron-check-if-zettelkasten-exists)
  (browse-url (format "http://%s:%d/%s" neuron-rib-server-host neuron-rib-server-port page)))

;;;###autoload
(defun neuron-rib-open-z-index ()
  "Open the web application in the web browser at z-index."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (neuron-rib-open-page "z-index.html"))

(defun neuron-rib-open-current-zettel ()
  "Open the web application in the web browser at the current zettel note."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (let ((id (f-base (buffer-file-name))))
    (neuron-rib-open-page (concat id ".html"))))

;;;###autoload
(defun neuron-rib-open-zettel ()
  "Open a zettel in the web application."
  (interactive)
  (neuron-check-if-zettelkasten-exists)
  (let ((zettel (neuron-select-zettel)))
    (neuron-rib-open-page (concat (map-elt zettel 'ID) ".html"))))

(defun neuron-rib-kill ()
  "Stop the web application."
  (interactive)
  (kill-buffer "*rib*"))

(defconst neuron-tag-component-regex
  "[A-Za-z0-9-_]+"
  "Regex matching a tag component.")

(defconst neuron-tag-regex
  (eval `(rx (* (regexp ,neuron-tag-component-regex) "/") (regexp ,neuron-tag-component-regex)))
  "Regex matching a possibly hierarchical tag.")

(defun neuron--make-tag-pattern-component-regex (component &optional leading-slash)
  "Translate the component COMPONENT of a tag pattern into a regex.
If LEADING-SLASH is non-nil, introduce a leading `/' character in front
of the necessary regexes."
  (let ((prefix (if leading-slash "/" "")))
    (pcase component
      ((pred (string-match neuron-tag-component-regex))
       (eval `(rx ,prefix ,(regexp-quote component))))
      ("*"
       (eval `(rx ,prefix (group (regexp ,neuron-tag-component-regex)))))
      ("**"
       (eval `(rx (? ,prefix (group (* (regexp ,neuron-tag-component-regex) "/") (regexp ,neuron-tag-component-regex)))))))))

(defun neuron--make-tag-pattern-regex (pattern)
  "Transform a tag pattern PATTERN into a regex."
  (let* ((components (s-split "/" pattern t))
         (concat-patterns (lambda (pat1 pat2)
                            (eval `(rx (regexp ,pat1) (regexp ,pat2)))))
         (append-comp-pattern (lambda (pat comp)
                                (funcall concat-patterns pat (neuron--make-tag-pattern-component-regex comp 'leading-slash))))
         (remaining (cl-reduce append-comp-pattern (cdr components) :initial-value ""))
         (tag-pattern
          (funcall concat-patterns (neuron--make-tag-pattern-component-regex (car components)) remaining)))
    (eval `(rx bow (regexp ,tag-pattern) eow))))

(defun neuron--replace-tag-in-current-zettel (pattern repl)
  "Replace tags matched by PATTERN to a replacement REPL.
REPL is a string that may contain substrings like `\\N' where
N denotes the tag components that were matched by the Nth
glob."
  (save-excursion
    (when-let* ((tag-regex (neuron--make-tag-pattern-regex pattern))
                (bounds (neuron--get-metadata-block-bounds)))
      (goto-char (nth 1 bounds))
      (while (re-search-backward tag-regex nil t)
        (replace-match repl 'fixed-case)))))

;;;###autoload
(defun neuron-replace-tag (pattern repl)
  "Map all tags matching PATTERN to a REPL.
PATTERN is a tag glob as used in neuron queries.
REPL is a string that may contain substrings like `\\N' where
N denotes the tag components that were matched by the Nth glob
pattern.
Example:
`(neuron-add-tag \"**/theorem\" \"math/theorem/\\1\")'
will replace number-theory/theorem to math/theorem/number-theory
and algebra/linear/theorem to math/theorem/algebra/linear."
  (interactive (list
                (read-string "Tag pattern: ")
                (read-string "Replacement: ")))
  (neuron--rebuild-cache)
  (let ((current-buffers (neuron-list-buffers)))
    (map-do
     (lambda (_ zettel) (when-let* ((path (neuron--get-zettel-path zettel))
                                    (buffer (find-file-noselect path)))
                          (with-current-buffer buffer
                            (neuron--replace-tag-in-current-zettel pattern repl)
                            (save-buffer))
                          (unless (member buffer current-buffers)
                            (kill-buffer buffer))))
     neuron--zettel-cache)
    (message "Replaced all tags")))

(defun neuron--get-title-face-for-tags (tags)
  "Return the face of the title overlay based on the zettel's list of tags TAGS.
It picks the faces from the `neuron-tag-specific-title-faces' variable.
When no tag has a particular face, return the default `neuron-title-overlay-face'."
  (or (catch 'found-face
        (pcase-dolist (`(,tag . ,face) neuron-tag-specific-title-faces)
          (when (seq-contains-p tags tag)
            (throw 'found-face (car face)))))
      'neuron-title-overlay-face))

(defun neuron--setup-overlay-from-id (ov id conn)
  "Setup a single title overlay from a zettel ID.
OV is the overay to setup or update and CONN describes whether the link is a
folgezettel or an ordinary connection."
  (if-let* ((zettel (ignore-errors (neuron--get-cached-zettel-from-id id)))
            (title (alist-get 'Title zettel))
            (title-face (neuron--get-title-face-for-tags (neuron--get-zettel-tags zettel)))
            (title-suffix (if (eq conn 'folgezettel) " ᛦ" "")))
      (if neuron-show-ids
          (progn
            (overlay-put ov 'display nil)
            (overlay-put ov 'after-string (format " %s" (propertize title 'face title-face))))
        (overlay-put ov 'after-string nil)
        (overlay-put ov 'display (format "%s%s" (propertize title 'face title-face) title-suffix)))
    ))

(defun neuron--overlay-update (ov after &rest _)
  "Delete the title overlay OV on modification.
When AFTER is non-nil, this hook is being called after the update occurs."
  (let ((link (buffer-substring (overlay-start ov) (overlay-end ov))))
    (when after
      (if (string-match neuron-link-regex link)
          (let* ((link (match-string 1 link))
                 (folgezettel? (not (null (match-string 2))))
                 (query (neuron--parse-query-from-url-or-id link folgezettel?)))
            (if query (neuron--setup-overlay-from-query ov query)
              (overlay-put ov 'face 'neuron-invalid-link-face)))
        (delete-overlay ov)))))

(defun neuron--setup-overlay-from-query (ov query)
  "Setup a overlay OV from any zettel link QUERY."
  (overlay-put ov 'evaporate t)
  (overlay-put ov 'modification-hooks (list #'neuron--overlay-update))
  (overlay-put ov 'face 'neuron-link-face)
  (overlay-put ov 'mouse-face 'neuron-link-mouse-face)
  (overlay-put ov 'keymap neuron-mode-link-map)
  (when (equal (alist-get 'type query) 'zettel)
    (neuron--setup-overlay-from-id ov (alist-get 'id query) (alist-get 'conn query))))

(defun neuron--setup-overlays ()
  "Setup title overlays on zettel links."
  (remove-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward neuron-link-regex nil t)
      (let* ((ov (make-overlay (match-beginning 0) (match-end 0) nil t nil))
             (id-string (match-string 1))
             (closing-bracket (match-string 2))
             (folgezettel? (not (null closing-bracket)))
             (query (neuron--parse-query-from-url-or-id id-string folgezettel?)))
        (neuron--setup-overlay-from-query ov query)))))

;;;###autoload
(defun neuron-toggle-id-visibility ()
  "Toggle the visibility of IDs in simple links.
This can be useful to debug when searching for ID, explicitly seeing whether the
link is a folgezettel of ordinary connection."
  (interactive)
  (setq neuron-show-ids (not neuron-show-ids))
  (dolist (buffer (neuron-list-buffers))
    (with-current-buffer buffer (neuron--setup-overlays))))

;; Completion

(defun company-neuron--prefix ()
  "Extract the completion prefix, triggered by entering an opening angle bracket."
  (and (derived-mode-p 'neuron-mode)
       (when (looking-back (rx "<" (group (+ (not (any ">"))))) nil)
         (match-string 1))))

(defun company-neuron--fuzzy-match-title (prefix candidate)
  "Return whether PREFIX fuzzily matches the title of the CANDIDATE zettel."
  (let ((full-title (alist-get 'Title (get-text-property 0 'zettel candidate))))
    (cl-subsetp (string-to-list prefix)
                (string-to-list full-title))))

(defun company-neuron--propertize-completion-candidate (zettel)
  "Propertize a zettel title to contain all information about ZETTEL.
The resulting title is truncated and padded to fit the width given by
`neuron-max-completion-width'."
  (let* ((title (alist-get 'Title zettel))
         (padded (s-pad-right neuron-max-completion-width " " title))
         (truncated (s-truncate neuron-max-completion-width padded)))
    (propertize truncated 'zettel zettel)))

(defun company-neuron--all-candidates ()
  "Propertize all cached zettels to provide completion candidates."
  (mapcar #'company-neuron--propertize-completion-candidate neuron--zettel-cache))

(defun company-neuron--candidates (prefix)
  "Filter the candidates by fuzzily matching PREFIX against the candidates."
  (cl-remove-if-not
   (lambda (candidate) (company-neuron--fuzzy-match-title prefix candidate))
   (company-neuron--all-candidates)))

(defun company-neuron--completion-annotation (candidate)
  "Annotate the completion CANDIDATE so that it includes the ID of the underlying zettel."
  (let* ((zettel (get-text-property 0 'zettel candidate))
         (annot (format "<%s>" (alist-get 'ID zettel))))
    (concat " " (propertize annot 'face 'neuron-link-face))))

(defun company-neuron--completion-meta (candidate)
  "Display information about the underlying zettel of CANDIDATE.
The resulting string contains the ID, the full title of the zettel, as well as
the list of its tags."
  (let ((zettel (get-text-property 0 'zettel candidate)))
    (neuron--propertize-zettel zettel)))

(defun company-neuron--post-completion-action (candidate)
  "Delete the completed zettel title CANDIDATE and replace it with an actual neuron link."
  (let ((begin (point))
        (zettel (get-text-property 0 'zettel candidate)))
    (when (re-search-backward (rx "<"))
      (goto-char begin)
      (delete-region begin (match-end 0))
      (insert (concat (alist-get 'ID zettel) ">"))
      (neuron--setup-overlays))))

;;;###autoload
(defun company-neuron (command &optional arg &rest ignored)
  "Defines a company completion backend that completes zettels by title.
COMMAND is the relevant command provided by company.
ARG is the command argument, depending on which command was received.
IGNORED is the rest of the arguments, not sure why it's there."
  (interactive (list 'interactive))
  (cl-case command
    ((interactive) (company-begin-backend 'company-neuron-backend))
    ((prefix) (company-neuron--prefix))
    ((candidates) (company-neuron--candidates arg))
    ((annotation) (company-neuron--completion-annotation arg))
    ((meta) (company-neuron--completion-meta arg))
    ((post-completion) (company-neuron--post-completion-action arg))
    ((no-cache) 't)
    ((ignore-case) t)))

;;;###autoload
(defun company-neuron-setup ()
  "Setup company to use the neuron backend."
  (add-to-list 'company-backends 'company-neuron))

;; Mode declaration

(defvar neuron-mode-map nil "Keymap for `neuron-mode'.")

(progn
  (setq neuron-mode-map (make-sparse-keymap))

  (define-key neuron-mode-map (kbd "C-c C-z")   #'neuron-new-zettel)
  (define-key neuron-mode-map (kbd "C-c C-e")   #'neuron-edit-zettel)
  (define-key neuron-mode-map (kbd "C-c C-t")   #'neuron-add-tag)
  (define-key neuron-mode-map (kbd "C-c C-S-t") #'neuron-add-tags)
  (define-key neuron-mode-map (kbd "C-c C-l")   #'neuron-insert-zettel-link)
  (define-key neuron-mode-map (kbd "C-c C-S-L") #'neuron-insert-new-zettel)
  (define-key neuron-mode-map (kbd "C-c C-s")   #'neuron-insert-static-link)
  (define-key neuron-mode-map (kbd "C-c C-r")   #'neuron-open-current-zettel)
  (define-key neuron-mode-map (kbd "C-c C-o")   #'neuron-open-daily-notes)
  (define-key neuron-mode-map (kbd "C-c C-,")   #'neuron-edit-uplink)

  (setq neuron-mode-link-map (make-sparse-keymap))
  (define-key neuron-mode-link-map [mouse-1]    #'neuron-follow-thing-at-point)
  (define-key neuron-mode-link-map (kbd "RET")  #'neuron-follow-thing-at-point))

(defvar neuron-mode-hook nil
  "Hook run when entering `neuron-mode'.")

(push "z:" thing-at-point-uri-schemes)

;;;###autoload
(define-derived-mode neuron-mode markdown-mode "Neuron"
  "A major mode to edit Zettelkasten notes with neuron."
  (neuron-check-if-zettelkasten-exists)
  (when neuron-generate-on-save
    (add-hook 'after-save-hook #'neuron-rib-generate t t))
  (add-hook 'after-save-hook #'neuron--setup-overlays t t)
  (neuron--setup-overlays)
  (use-local-map neuron-mode-map)
  (neuron--name-buffer))

(defun neuron--auto-enable-when-in-zettelkasten ()
  "Automatically switch to neuron-mode when located in a zettelkasten."
  (when (and (eq major-mode 'markdown-mode)
             (neuron--detect-zettelkasten (f-parent buffer-file-name)))
    (neuron-mode)))

(add-hook 'markdown-mode-hook #'neuron--auto-enable-when-in-zettelkasten t nil)

(provide 'neuron-mode)

;;; neuron-mode.el ends here
