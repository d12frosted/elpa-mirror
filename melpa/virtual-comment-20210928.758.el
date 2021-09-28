;;; virtual-comment.el --- Virtual Comments    -*- lexical-binding: t; -*-

;; Author: Thanh Vuong <thanhvg@gmail.com>
;; URL: https://github.com/thanhvg/emacs-virtual-comment
;; Package-Version: 20210928.758
;; Package-Commit: 24271e081be3bb9ebcb41e27e1dad9623a837205
;; Package-Requires: ((emacs "26.1"))
;; Version: 0.0.2

;; This program is free software; you can redistribute it and/or modify
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
;; * Intro
;;
;; This package allows adding virtual comments to files in buffers. These
;; comments don't belong to the files so they don't. They are saved in project
;; root or a global file which can be viewed and searched. The file name is
;; .evc.
;;
;; * Virtual comments
;; A virtual comment is an overlay and it is added above the line it comments on
;; and has the same indentation. The virtual comment can be single line or
;; multiline. Each line can have one comment.
;;
;; * Install
;; Spacemacs layer:
;; https://github.com/thanhvg/spacemacs-eos
;;
;; Vanilla
;; (require 'virtual-comment)
;; (add-hook 'find-file-hook 'virtual-comment-mode)
;;
;; * Commands
;; - virtual-comment-make: create or edit a comment at current line
;; - virtual-comment-next: go to next comment in buffer
;; - virtual-comment-previous: go to previous comment in buffer
;; - virtual-comment-delete: remove the current comment
;; - virtual-comment-paste: paste the last removed comment to current line
;; - virtual-comment-realign: realign the comments if they are misplaced
;; - virtual-comment-persist: manually persist project comments
;; - virtual-comment-show: show all comments of current project in a derived mode
;; from outline-mode, press enter on a comment will call virtual-comment-go to go
;; to the location of comment.
;; Commands to link to other location (reference):
;; - virtual-comment-remember-current-location store the current location
;; - virtual-comment-add-ref add the stored location (reference) as comment
;; - virtual-comment-goto-location go to location
;;
;; There are no default bindings at all for these commands.
;;
;; * Remarks
;; It's very hard to manage overlays. So this mode should be use in a sensible way.
;; Only comments of files can be persisted.
;;
;; * Test
;; cask install
;; cask exec ert-runner
;;
;; * Other similar packages and inspirations
;; https://github.com/blue0513/phantom-inline-comment
;; https://www.emacswiki.org/emacs/InPlaceAnnotations
;;
;; Change log
;; 20210-09-27: 0.02 add location/reference

;;; Code:
(require 'cl-lib)
(require 'project)
(require 'subr-x)
(require 'outline)
(require 'simple)
(require 'thingatpt)
(require 'seq)

(defvar-local virtual-comment--buffer-data nil
  "Buffer comment data.")

(defvar virtual-comment--store nil
  "Global comment store.")

(defvar-local virtual-comment--project nil
  "Project comment store.")

(defvar-local virtual-comment--is-initialized nil
  "Flag to tell if `virtual-comment--init' has already run.")

(defvar-local virtual-comment--update-data-timer nil
  "Local timer for `virtual-comment--update-data-async'.
When this value is non-nil then there is a timer for
`virtual-comment--update-data' to run in future.")

(defvar virtual-comment--current-location nil
  "A string of stored location")

(defcustom virtual-comment-idle-time 1
  "Number of seconds after Emacs is idle to run a scheduled update."
  :type 'number
  :group 'virtual-comment)

(defcustom virtual-comment-face 'highlight
  "Face for annotations."
  :type 'face
  :group 'virtual-comment)

(defcustom virtual-comment-default-file "~/.evc"
  "Default file to save comments."
  :type 'string
  :group 'virtual-comment)

(defvar virtual-comment-deleted-overlay nil
  "Reference to the overlay deleted.")

(cl-defstruct (virtual-comment-unit
               (:constructor virtual-comment-unit-create)
               (:copier nil))
  "Comment data structure.
POINT and COMMENT are self explained TARGET is the line content on
which the comment is."
  point comment target)

(cl-defstruct (virtual-comment-buffer-data
               (:constructor virtual-comment-buffer-data-create)
               (:copier nil))
  "Store data of current buffer.
FILENAME is file name from project root, it is not used.
COMMENTS is list of virtual-comment-unit."
  filename comments)

(cl-defstruct (virtual-comment-store
               (:constructor virtual-comment-store-create)
               (:copier nil))
  "Global store of comments.
Slot default is default `virtual-comment-project' for buffers
which don't belong to a project. Slot projects is a list of
`virtual-comment-project'."
  default projects)

(cl-defstruct (virtual-comment-project
               (:constructor virtual-comment-project-create)
               (:copier nil))
  "Project store of comments.
Slot files is hashtable of file-name:`virtual-comment-buffer-data'
Slot count is reference count."
  files count)

(defun virtual-comment--get-store ()
  "Get comment store.
If nil create it and create a hash table to :projects slot."
  (unless virtual-comment--store
    (setq virtual-comment--store
          (virtual-comment-store-create
           :default (virtual-comment-project-create :count 0 :files nil)
           :projects (make-hash-table :test 'equal))))
  virtual-comment--store)

(defun virtual-comment--get-project-in-store (project-id)
  "Get project data from store using PROJECT-ID as key.
When PROJECT-ID is nil return the default store."
  (let ((store (virtual-comment--get-store)))
    (if project-id
        (let ((projects (virtual-comment-store-projects store)))
          (if-let (prj (gethash project-id projects))
              prj
            (puthash project-id
                     (virtual-comment-project-create :count 0 :files nil)
                     projects)))
      ;; else get the default store
      (virtual-comment-store-default store))))

(defun virtual-comment--remove-project-in-store (project-id)
  "Remove project data from store using PROJECT-ID as key.
When PROJECT-ID is nil, the default slot of store is in action."
  (let ((store (virtual-comment--get-store)))
    (if project-id
        (let ((projects (virtual-comment-store-projects store)))
          (remhash project-id projects))
      ;; else we reset the default slot
      (setf (virtual-comment-store-default store)
            (virtual-comment-project-create :count 0 :files nil)))))

(defun virtual-comment--make-project-id (project-location)
  "Return project unique id form PROJECT-LOCATION."
  (md5 project-location))

(defun virtual-comment--get-project ()
  "Get project from store.
Return `virtual-comment--project'."
  (if virtual-comment--project
      virtual-comment--project
    (setq virtual-comment--project
          (let* ((root (cdr (project-current)))
                 (project-id (if root
                                 (virtual-comment--make-project-id root)
                               nil)))
            (virtual-comment--get-project-in-store project-id)))))

(defun virtual-comment--remove-project ()
  "Remove project from store."
  (let* ((root (cdr (project-current)))
         (project-id (if root
                         (virtual-comment--make-project-id root)
                       nil)))
    (virtual-comment--remove-project-in-store project-id)))

(defun virtual-comment--get-buffer-data-in-project (file-name prj)
  "Get buffer data fro FILE-NAME from PRJ.
If not found create it."
  (if-let (data (gethash file-name (virtual-comment-project-files prj)))
      data
    (puthash file-name
             (virtual-comment-buffer-data-create)
             (virtual-comment-project-files prj))))

(defun virtual-comment--get-buffer-data ()
  "Get struct `virtual-comment--buffer-data' if nil then create it."
  (if virtual-comment--buffer-data
      virtual-comment--buffer-data
    (let ((project-data (virtual-comment--get-project))
          (file-name (virtual-comment--get-buffer-file-name)))
      (setq
       virtual-comment--buffer-data
       (if file-name
           (virtual-comment--get-buffer-data-in-project
            file-name
            project-data)
         (virtual-comment-buffer-data-create))))))

(defun virtual-comment--buffer-data-empty-p (buffer-data)
  "Tell if BUFFER-DATA (`virtual-comment-buffer-data') is empty.
There are two slots but for now we only care about slot comments."
  (not (virtual-comment-buffer-data-comments buffer-data)))

;; (defun virtual-comment--ovs-to-cmts (ovs)
;;   "Maps overlay OVS list to list of `virtual-comment-unit'."
;;   (mapcar (lambda (ov)
;;             (virtual-comment-unit-create
;;              :point (overlay-start ov)
;;              :comment (overlay-get ov 'virtual-comment)
;;              :target (overlay-get ov 'virtual-comment-target)))
;;           ovs))

(defun virtual-comment--ovs-to-cmts (ovs)
  "Repair and map overlay OVS list to list of `virtual-comment-unit'."
  (mapcar (lambda (ov)
            (virtual-comment--repair-overlay-maybe ov t))
          ovs))

(defun virtual-comment--update-data ()
  "Update buffer comment data."
  (let ((data (virtual-comment--get-buffer-data))
        (ovs (virtual-comment--get-buffer-overlays t)))
    ;; update file name
    (setf (virtual-comment-buffer-data-filename data)
          (virtual-comment--get-buffer-file-name))
    (setf (virtual-comment-buffer-data-comments data)
          (virtual-comment--ovs-to-cmts ovs))))

(defun virtual-comment--update-data-async ()
  "Update buffer comment data when idle."
  (unless virtual-comment--update-data-timer
    (setq virtual-comment--update-data-timer
          (run-with-idle-timer
           virtual-comment-idle-time
           nil ;; no repeat
           (lambda (buff)
             (with-current-buffer buff
               (virtual-comment--update-data)
               ;; done reset the flag
               (setq virtual-comment--update-data-timer nil)))
           (current-buffer)))))

(defun virtual-comment-get-evc-file ()
  "Return evc file path."
  (let ((root (cdr (project-current))))
    (if root
        (concat root ".evc")
      virtual-comment-default-file)))

(defun virtual-comment--get-buffer-file-name ()
  "Return path from project root, nil when not a file."
  (when-let ((name (buffer-file-name)))
    (let ((root (cdr (project-current)))
          (file-abs-path (file-truename name)))
      (if root
          (substring file-abs-path (length (file-truename root)))
        file-abs-path))))

(defun virtual-comment--get-saved-file ()
  "Return path to .ipa file at project root."
  (let ((root (cdr (project-current))))
    (if root
        (concat root ".evc")
      virtual-comment-default-file)))

(defun virtual-comment--dump-data-to-file (data file)
  "Dump DATA to .evc FILE."
  (with-temp-file file
    (let ((standard-output (current-buffer)))
      (prin1 data))))

(defun virtual-comment--persist ()
  "Persist project data to file."
  (let ((data (virtual-comment--get-project))
        (file (virtual-comment-get-evc-file)))
    (virtual-comment--dump-data-to-file (virtual-comment-project-files
                                         data)
                                        file)))

(defun virtual-comment--take-non-nil (project-files-slot)
  "Create new hash table from PROJECT-FILES-SLOT and remove empty value."
  (let ((my-hashtable (make-hash-table)))
    (maphash (lambda (k v) (when (virtual-comment-buffer-data-comments v)
                             (puthash k v my-hashtable)))
             project-files-slot)
    my-hashtable))

(defun virtual-comment-persist ()
  "Persist project data to file."
  (interactive)
  (let ((data (virtual-comment--get-project))
        (file (virtual-comment-get-evc-file)))
    (virtual-comment--dump-data-to-file
     (virtual-comment--take-non-nil (virtual-comment-project-files data)) file)))

(defun virtual-comment--load-data-from-file (file)
  "Read data from FILE.
If not found or fail, return an empty hash talbe."
  (with-temp-buffer
    (condition-case nil
        (progn (insert-file-contents file)
               (read (current-buffer)))
      (error (make-hash-table :test 'equal)))))

(defun virtual-comment--load ()
  "Load stuff."
  (setq virtual-comment--buffer-data (virtual-comment--load-data-from-file
                                      (virtual-comment--get-saved-file))))

;; https://stackoverflow.com/questions/16992726/how-to-prompt-the-user-for-a-block-of-text-in-elisp
(defun virtual-comment--read-string-with-multiple-line (prompt pre-string exit-keyseq clear-keyseq)
  "Read multiline from minibuffer.
PROMPT with PRE-STRING binds EXIT-KEYSEQ to submit binds
CLEAR-KEYSEQ to clear text."
  (let ((keymap (copy-keymap minibuffer-local-map)))
    (define-key keymap (kbd "RET") 'newline)
    (define-key keymap exit-keyseq 'exit-minibuffer)
    (define-key keymap clear-keyseq
      (lambda () (interactive) (delete-region (minibuffer-prompt-end) (point-max))))
    (read-from-minibuffer prompt pre-string keymap)))

(defun virtual-comment--read-string (prompt &optional pre-string)
  "Prompt for multiline string and return it.
PROMPT is show in multiline, PRE-STRING is string added to the
prompt"
  (virtual-comment--read-string-with-multiple-line
   (concat prompt " C-s to submit, C-g to cancel, C-c C-k to clear:\n")
   pre-string
   (kbd "C-s")
   (kbd "C-c C-k")))

(defun virtual-comment--overlayp (ov)
  "Predicate for OV being commnent."
  (overlay-get ov 'virtual-comment))

(defun virtual-comment--get-overlay-at (point)
  "Return the overlay comment of this POINT."
  (seq-find #'virtual-comment--overlayp
            (overlays-in point (1+ point))))

(defun virtual-comment--get-buffer-overlays (&optional should-sort)
  "Get all overlay comment.
When SHOULD-SORT is non-nil sort by point."
  (let ((ovs (seq-filter #'virtual-comment--overlayp
                         (overlays-in (point-min) (point-max)))))
    (if should-sort
        (sort ovs
              (lambda (first second)
                (< (overlay-start first) (overlay-start second))))
      ovs)))

(defun virtual-comment--line-at-point ()
  "Reinvent `thing-at-point line'."
  (buffer-substring (point-at-bol) (point-at-eol)))

(defun virtual-comment--search (s)
  "Search for S from the beginning of buffer.
Fuzzy and ignore space, return point if found otherwise nil."
  (save-excursion
    (let* ((words (split-string s))
           (s-multi-re (mapconcat #'regexp-quote words "\\(?:[ \t\n]+\\)")))
      (goto-char (point-min))
      (if (re-search-forward s-multi-re nil t)
          (match-beginning 0)
        nil))))

(defun virtual-comment--repair-overlay-maybe (ov &optional make-comment-unit)
  "Re-align coment overlay OV if necessary.
When MAKE-COMMENT-UNIT is non nil return `virtual-comment-unit'."
  (save-excursion
    (goto-char (overlay-start ov))

    ;; exclusiv branch either here (1) or (2)
    (let ((org-target (overlay-get ov 'virtual-comment-target))
          (current-target (thing-at-point 'line t)))
      (unless (string= org-target current-target)
        (when-let (found (virtual-comment--search org-target))
          (goto-char found))
        (goto-char (point-at-bol))
        (overlay-put ov
                     'before-string
                     (virtual-comment--make-comment-for-display
                      (overlay-get ov 'virtual-comment)
                      (current-indentation)))
        (move-overlay ov (point-at-bol) (point-at-eol))
        (overlay-put ov 'virtual-comment-target (thing-at-point 'line t))))

    ;; (2) if align here then (1) was not invoked
    (unless (bolp)
      (overlay-put ov
                   'before-string
                   (virtual-comment--make-comment-for-display
                    (overlay-get ov 'virtual-comment)
                    (current-indentation)))
      (move-overlay ov (point-at-bol) (point-at-eol))))
  (when make-comment-unit
    (virtual-comment-unit-create
     :point (overlay-start ov)
     :comment (overlay-get ov 'virtual-comment)
     :target (overlay-get ov 'virtual-comment-target))))

;;;###autoload
(defun virtual-comment-realign ()
  "Realign overlays if necessary."
  (interactive)
  (mapc #'virtual-comment--repair-overlay-maybe
        (virtual-comment--get-buffer-overlays))
  (virtual-comment--update-data-async-maybe))

(defun virtual-comment--get-comment-at (point)
  "Return comment string at POINT."
  (when-let (ov (virtual-comment--get-overlay-at point))
    (overlay-get ov 'virtual-comment)))

;; (defun virtual-comment--insert-hook-handler (ov is-after-change &rest _)
;;   "Move overlay back to the front.
;; OV is overlay, IS-AFTER-CHANGE, _ are extra
;; params. If there is already a ov comment on the line, the moved
;; ov will be discarded and its comment will be added to the host
;; comment."
;;   (when is-after-change
;;     (let* ((point (point-at-bol))
;;            (comment (overlay-get ov 'virtual-comment))
;;            (comment-for-display (virtual-comment--make-comment-for-display
;;                                  comment
;;                                  (current-indentation))))
;;       (move-overlay ov point (point-at-eol))
;;       (overlay-put ov 'before-string comment-for-display)
;;       (overlay-put ov 'virtual-comment comment))))

(defun virtual-comment--insert-hook-handler (ov is-after-change &rest _)
  "Update ov field virtual-comment-target.
OV is overlay, IS-AFTER-CHANGE, _ are extra params."
  (when is-after-change
    (overlay-put ov
                 'virtual-comment-target
                 (save-excursion
                   (goto-char (overlay-start ov))
                   (thing-at-point 'line t)))))

(defun virtual-comment--get-neighbor-cmt (point end-point getter-func)
  "Return point of the neighbor comment of POINT, nil if not found.
With GETTER-FUNC until END-POINT."
  (let ((neighbor-pos (funcall getter-func point)))
    (if (virtual-comment--get-overlay-at neighbor-pos)
        neighbor-pos
      (if (= neighbor-pos end-point)
          nil
        (virtual-comment--get-neighbor-cmt neighbor-pos
                                           end-point
                                           getter-func)))))

(defun virtual-comment--kill-buffer-hook-handler ()
  "On buffer about to be killed.
Decrease counter, check if should persist data."
  (when virtual-comment--update-data-timer
    (cancel-timer virtual-comment--update-data-timer)
    (setq virtual-comment--update-data-timer nil)
    (virtual-comment--update-data))
  (let ((data (virtual-comment--get-project))
        (buffer-data (virtual-comment--get-buffer-data)))
    ;; if buffer data is nothing then remove it from project data
    (when (virtual-comment--buffer-data-empty-p buffer-data)
      (remhash
       (virtual-comment--get-buffer-file-name)
       (virtual-comment-project-files data)))
    ;; decrease reference count
    (cl-decf (virtual-comment-project-count data))
    ;; persistence maybe
    (when (= 0 (virtual-comment-project-count data))
      (message
       "virtual-comment: persisting virtual comments in %s"
       (virtual-comment-get-evc-file))
      (virtual-comment--persist)
      ;; remove project files from store
      (virtual-comment--remove-project))))

(defun virtual-comment--before-revert-buffer-hook-handler ()
  "On buffer about to revert.
Clear all overlays and act like buffer about to close."
  (virtual-comment--clear)
  (virtual-comment--kill-buffer-hook-handler)
  (setq virtual-comment--is-initialized nil))

(defun virtual-comment--after-revert-buffer-hook-handler ()
  "On buffer after revert. Restore things."
  ;; when it is a hard reload then virtual-comment-mode will
  ;; be called twice via this hook and via normal-mode actions
  ;; but it will do side effect only once thanks to the flag
  ;; virtual-comment--is-initialized
  (virtual-comment-mode))

;;;###autoload
(defun virtual-comment-next ()
  "Go to next/below comment."
  (interactive)
  (if-let (point (virtual-comment--get-neighbor-cmt (point-at-eol)
                                                    (point-max)
                                                    #'next-overlay-change))
      (goto-char point)
    (message "No next comment found.")))

;;;###autoload
(defun virtual-comment-previous ()
  "Go to previous/above comment."
  (interactive)
  (if-let (point (virtual-comment--get-neighbor-cmt (point-at-bol)
                                                    (point-min)
                                                    #'previous-overlay-change))
      (goto-char point)
    (message "No previous comment found.")))

(defun virtual-comment--make-comment-for-display (comment indent)
  "Make a comment string with face and INDENT from COMMENT for display."
  (concat (make-string indent ?\s)
          (mapconcat
           (lambda (it)
             (propertize it 'face virtual-comment-face))
           (split-string comment "\n")
           (concat "\n" (make-string indent ?\s)))
          "\n"))

(defun virtual-comment--ov-ensure (ov comment target indent)
  "Ensure overlay OV has all the necessary props from COMMENT, TARGET and INDENT."
  (overlay-put ov 'virtual-comment comment)
  (overlay-put ov 'virtual-comment-target target)
  (overlay-put ov
               'before-string
               (virtual-comment--make-comment-for-display
                comment
                indent))
  (overlay-put ov
               'modification-hooks
               '(virtual-comment--insert-hook-handler)))

(defun virtual-comment--make (unit)
  "Make a comment from a comment UNIT."
  (let ((point (virtual-comment-unit-point unit))
        (comment (virtual-comment-unit-comment unit))
        (target (virtual-comment-unit-target unit)))
    (save-excursion
      (goto-char point)
      (let* ((indent (current-indentation))
             (org-comment (virtual-comment--get-comment-at point))
             (ov (if org-comment (virtual-comment--get-overlay-at point)
                   (make-overlay point (point-at-eol) nil t nil))))
        (virtual-comment--ov-ensure ov comment target indent)))))

(defun virtual-comment--append (str)
  "Append SRT to comment.
Won't prepend new line if comment is nil"
  (let* ((point (point-at-bol))
         (indent (current-indentation))
         (target (thing-at-point 'line t))
         (org-comment (virtual-comment--get-comment-at point))
         (comment (if org-comment
                      (concat org-comment "\n" str)
                    str))
         ;; must get existing overlay when comment is non-nil
         (ov (if org-comment (virtual-comment--get-overlay-at point)
               (make-overlay point (point-at-eol) nil t nil))))
    (virtual-comment--ov-ensure ov comment target indent)
    (virtual-comment--update-data-async-maybe)))

;;;###autoload
(defun virtual-comment-add-location ()
  "Append `virtual-comment--current-location' to current line as comment."
  (interactive)
  (when virtual-comment--current-location
    (virtual-comment--append virtual-comment--current-location)))

(defun virtual-comment--get-locations (str)
  "Get locations from string STR."
  (seq-filter (lambda (x) (string-match-p ".*? | .*?:[0-9]+$" x)) (split-string str "\n")))

(defun virtual-comment--goto-location (str)
  "STR is 'symbol | filepath:number'."
  (when (string-match "\\`.*? | \\(.*?\\):\\([0-9]+\\)\\'" str)
    (let ((file-name (match-string-no-properties 1 str))
          (line-number (match-string-no-properties 2 str)))
      (find-file-other-window (if (file-name-absolute-p file-name)
                                  file-name
                                (expand-file-name file-name (cdr (project-current)))))
      (goto-char (point-min))
      (forward-line (1- (string-to-number line-number))))))

;;;###autoload
(defun virtual-comment-goto-location ()
  "Open location in other window."
  (interactive)
  (when-let* ((cmt (virtual-comment--get-comment-at (point-at-bol)))
              (candidates (virtual-comment--get-locations cmt)))
    (if (= (length candidates) 1)
        (virtual-comment--goto-location (car candidates))
      (virtual-comment--goto-location (completing-read "Select:" candidates)))))

;;;###autoload
(defun virtual-comment-make ()
  "Add or edit comment at current line."
  (interactive)
  (let* ((point (point-at-bol))
         (indent (current-indentation))
         (target (thing-at-point 'line t))
         (org-comment (virtual-comment--get-comment-at point))
         (comment (virtual-comment--read-string
                   "Insert comment:"
                   org-comment))
         ;; must get existing overlay when comment is non-nil
         (ov (if org-comment (virtual-comment--get-overlay-at point)
               (make-overlay point (point-at-eol) nil t nil))))
    (virtual-comment--ov-ensure ov comment target indent)
    (virtual-comment--update-data-async-maybe)))

(defun virtual-comment--get-location-at-point (&optional want-full-path)
  "Get symbol at point and its project path or full path plus line number."
  (format "%s | %s:%s"
          (thing-at-point 'symbol t)
          (if want-full-path
              (file-truename (buffer-file-name))
            (file-relative-name (file-truename (buffer-file-name)) (cdr (project-current))))
          (line-number-at-pos)))

;;;###autoload
(defun virtual-comment-remember-current-location (prefix)
  "Save current location to `virtual-comment--current-location'."
  (interactive "p")
  (setq virtual-comment--current-location (virtual-comment--get-location-at-point (= 4 prefix))))

(defun virtual-comment--delete-comment-at (point)
  "Delete the comment at point POINT.
Find the overlay for this POINT and delete it. Update the store."
  (when-let (ov (virtual-comment--get-overlay-at point))
    (setq virtual-comment-deleted-overlay ov)
    (delete-overlay ov)))

;;;###autoload
(defun virtual-comment-delete ()
  "Delete comments of this current line.
The comment then can be pasted with `virtual-comment-paste'."
  (interactive)
  (let ((point (point-at-bol)))
    (virtual-comment--delete-comment-at point))
  (virtual-comment--update-data-async-maybe))

(defun virtual-comment--paste-at (point indent target)
  "Paste comment at POINT and with INDENT and update its TARGET."
  (when virtual-comment-deleted-overlay
    (let ((comment-for-display (virtual-comment--make-comment-for-display
                                (overlay-get
                                 virtual-comment-deleted-overlay
                                 'virtual-comment)
                                indent)))
      (overlay-put virtual-comment-deleted-overlay
                   'before-string
                   comment-for-display)
      (overlay-put virtual-comment-deleted-overlay
                   'virtual-comment-target
                   target)
      (move-overlay virtual-comment-deleted-overlay
                    point
                    (point-at-eol)))))

;;;###autoload
(defun virtual-comment-paste ()
  "Paste comment."
  (interactive)
  (virtual-comment--paste-at (point-at-bol)
                             (current-indentation)
                             (thing-at-point 'line t))
  (virtual-comment--update-data-async-maybe))

(defun virtual-comment--clear ()
  "Clear all overlays in current buffer."
  (mapc #'delete-overlay
        (virtual-comment--get-buffer-overlays)))

;;;###autoload
(define-minor-mode virtual-comment-mode
  "This mode shows virtual commnents."
  :lighter " evc"
  :keymap (make-sparse-keymap)
  (if virtual-comment-mode
      (virtual-comment-mode-enable)
    (virtual-comment-mode-disable)))

(defun virtual-comment--update-data-async-maybe ()
  "Do update only when mode is active."
  (when virtual-comment-mode
    (virtual-comment--update-data-async)))

(defun virtual-comment--reload-project ()
  "Reload project data.
First remove current project from store then load it from file
and stuff to store again."
  (virtual-comment--remove-project)
  (let* ((project-data (virtual-comment--get-project)))
    (setf (virtual-comment-project-files project-data)
          (if-let (my-data
                   (virtual-comment--load-data-from-file
                    (virtual-comment--get-saved-file)))
              my-data
            (make-hash-table :test 'equal)))))

(defun virtual-comment--reload-data ()
  "Drop current data and reload from the store."
  (virtual-comment--clear)
  (mapc #'virtual-comment--make
        (virtual-comment-buffer-data-comments
         (virtual-comment--get-buffer-data))))

(defun virtual-comment--init ()
  "Get everything ready if necessary store, project and buffer.
This function should only run once when mode is active. That is
after variable `virtual-comment-mode' is enabled in buffer, if you
run (virtual-comment-mode) again this function won't do anything."
  (unless virtual-comment--is-initialized
    ;; get project
    (let* ((project-data (virtual-comment--get-project))
           (count (virtual-comment-project-count project-data)))
      ;; check if project-data needs initialization
      (when (= count 0)
        ;; not initialized yet. must update
        ;; first load project file
        (setf (virtual-comment-project-files project-data)
              (if-let (my-data
                       (virtual-comment--load-data-from-file (virtual-comment--get-saved-file)))
                  my-data
                (make-hash-table :test 'equal))))
      ;; increase ref counter
      (cl-incf (virtual-comment-project-count project-data))
      ;; get buffer data from project and make overlay
      (mapc #'virtual-comment--make
            (virtual-comment-buffer-data-comments
             (virtual-comment--get-buffer-data))))
    (setq virtual-comment--is-initialized t)))

(defun virtual-comment-mode-enable ()
  "Run when variable `virtual-comment-mode' is on."
  (add-hook 'after-save-hook #'virtual-comment--update-data-async 0 t)
  (add-hook 'before-revert-hook
            #'virtual-comment--before-revert-buffer-hook-handler
            0
            t)
  (add-hook 'after-revert-hook
            #'virtual-comment--after-revert-buffer-hook-handler
            0
            t)
  (add-hook 'kill-buffer-hook #'virtual-comment--kill-buffer-hook-handler 0 t)
  ;; (setq virtual-comment-buffer-data nil)
  (virtual-comment--init))

(defun virtual-comment-mode-disable ()
  "Run when variable `virtual-comment-mode' is off."
  (remove-hook 'after-save-hook #'virtual-comment--update-data-async t)
  (remove-hook 'before-revert-hook
               #'virtual-comment--before-revert-buffer-hook-handler
               t)
  (remove-hook 'after-revert-hook
               #'virtual-comment--after-revert-buffer-hook-handler
               t)
  (remove-hook 'kill-buffer-hook #'virtual-comment--kill-buffer-hook-handler t)
  (virtual-comment--kill-buffer-hook-handler)
  (virtual-comment--clear)
  (kill-local-variable 'virtual-comment--is-initialized)
  (kill-local-variable 'virtual-comment--buffer-data)
  (kill-local-variable 'virtual-comment--project))

;; view job
;;;###autoload
(defun virtual-comment-go ()
  "Go to location of comment at point of view buffer."
  (interactive)
  (let ((active-point (get-text-property (point) 'virtual-comment-point))
        (file-name (get-text-property (point) 'virtual-comment-file)))
    (when (and active-point file-name)
      (find-file file-name)
      (goto-char active-point))))

(defvar virtual-comment-show-map
  ;; (setq virtual-comment-show-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'virtual-comment-go)
    map)
  "Keymap for show.")

(defun virtual-comment--print-comments (unit file-name root)
  "Print out comments.
from UNIT is `virtual-comment-unit' for FILE-NAME of project
ROOT."
  ;; (message "%s" comments)
  (let ((full-path (concat root file-name))
        (point (virtual-comment-unit-point unit))
        (comment (virtual-comment-unit-comment unit))
        (target (virtual-comment-unit-target unit)))
    (insert (format "%s\n%s"
                    (propertize comment
                                ;; 'face 'highlight
                                ;; 'font-lock-face 'underline
                                'font-lock-face 'highlight
                                'virtual-comment-point point
                                'virtual-comment-file full-path
                                'keymap virtual-comment-show-map)
                    target))))

(defun virtual-comment--print (file-comments file-name root)
  "Print out comments from FILE-COMMENTS for FILE-NAME of project ROOT.
FILE-COMMENTS is list of (point . comment).

Should produce:
* file-name
comment1
comment2.

If no comments, print nothing
Pressing enter on comment will go to comment."
  (when (> (length file-comments) 0)
    (insert (format "* %s\n" file-name))
    (mapc (lambda (it)
            (virtual-comment--print-comments it file-name root))
          file-comments)))

;; (setq virtual-comment-show-mode-map
(defvar virtual-comment-show-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "q" 'quit-window)
    map))

;;;###autoload
(define-derived-mode virtual-comment-show-mode outline-mode "evcs"
  "Major mode to view `virutal-comment' comments."
  (setq buffer-read-only t))

(defun virtual-comment--show (project-data root buffer &optional file-name)
  "Print out an org buffer of project comments to BUFFER.
PROJECT-DATA is `virtual-comment-project' struct.
ROOT is project root."
  (with-current-buffer buffer
    (let ((inhibit-read-only t))
      (erase-buffer)
      (maphash
       (lambda (key val)
         (virtual-comment--print
          (virtual-comment-buffer-data-comments val)
          key
          root))
       (virtual-comment-project-files project-data))
      (virtual-comment-show-mode)
      (goto-char (point-min)))
    ;; go to node for file-name
    (when file-name
      (search-forward (concat "* " file-name "\n") nil t))
    ;; (local-set-key (kbd "q") 'quit-window)
    (switch-to-buffer (current-buffer))))

;;;###autoload
(defun virtual-comment-show ()
  "Show comments for this file and its project."
  (interactive)
  (let ((file-name (virtual-comment--get-buffer-file-name))
        (root (cdr (project-current))))
    (virtual-comment--show virtual-comment--project
                           root
                           (get-buffer-create
                            (format "*%s*" (if root root "default")))
                           file-name)))

(defun virtual-comment--emacs-kill-hook-handler ()
  "Handler to run when emacs about to close.
Go through buffer list and act like buffer about to close."
  (dolist (buffer (buffer-list))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (when virtual-comment-mode
          (virtual-comment--kill-buffer-hook-handler))))))

(add-hook 'kill-emacs-hook #'virtual-comment--emacs-kill-hook-handler)

(provide 'virtual-comment)
;;; virtual-comment.el ends here
