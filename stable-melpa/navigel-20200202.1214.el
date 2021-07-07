;;; navigel.el --- Facilitate the creation of tabulated-list based UIs -*- lexical-binding: t; -*-

;; Copyright (C) 2019, 2020  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Url: https://gitlab.petton.fr/DamienCassou/navigel
;; Package-Version: 20200202.1214
;; Package-Commit: 0a2d624d6b49f8363badc5ba8699b7028ef85632
;; Package-requires: ((emacs "25.1") (tablist "1.0"))
;; Version: 0.7.0

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

;; This library makes it simpler for Emacs Lisp developers to define
;; user-interfaces based on tablists (also known as tabulated-lists).
;; Overriding a few (CL) methods and calling `navigel-open' is all
;; that's required to get a nice UI to navigate your domain objects
;; (e.g., files, music library, database).
;;
;; Features include :
;;
;; - pressing RET to open the entity at point in another buffer;
;; - pressing ^ to open the current entity's parent;
;; - marking entities for bulk operations (e.g., delete);
;; - `imenu' support for quick navigation;

;;; Code:

(require 'tablist)
(require 'seq)
(require 'map)
(require 'bookmark)


;; Customization

(defgroup navigel nil
  "Navigel."
  :group 'magit-extensions)

(defcustom navigel-changed-hook nil
  "Normal hook run after a navigel's tablist buffer has been refreshed or populated."
  :type 'hook)

(defcustom navigel-init-done-hook nil
  "Normal hook run after a navigel's tablist buffer has been initially populated."
  :type 'hook)

(defcustom navigel-display-messages t
  "Whether to display navigel's informative messages in the echo area."
  :type 'boolean)

(defcustom navigel-single-buffer-apps nil
  "Applications using a single buffer to display all entities.

Either a list of symbols denoting applications, t for all
applications or nil, the default, for none."
  :type '(choice (const :tag "None" nil)
                 (const :tag "All applications" t)
                 (repeat (symbol :tag "Application"))))


;; Private variables

(defvar navigel-entity nil
  "Specify the entity that was used to generate the buffer.")

(defvar navigel-app nil
  "Specify the application that was used to generate the buffer.")

(defvar navigel-single-buffers nil
  "An alist of (APP . BUFFER) associating app symbols with their buffer name.

This name is used only for applications that are working in single-buffer mode.")

(defvar-local navigel--state-cache nil
  "Cache of entity states for single-buffer applications.

This cache is an alist of (APP . STATE) pairs, where in turn
STATE is an alist of (ENTITY-ID . ENTITY-STATE) pairs,
associating to each entity that has been displayed by APP in this
buffer its last state (as returned by `navigel--save-state').")


;; Private functions

(defun navigel--tablist-operation-function (operation &rest args)
  "Setup `tablist' operations in current buffer.

OPERATION and ARGS are defined by `tablist-operations-function'."
  (cl-case operation
    (supported-operations '(find-entry delete))
    (find-entry (navigel-open (car args) nil))
    (delete (navigel-delete (car args) #'navigel--revert-buffer))))

(defun navigel--imenu-extract-index-name ()
  "Return the name of entity at point for `imenu'.
This function is used as a value for
`imenu-extract-index-name-function'.  Point should be at the
beginning of the line."
  (navigel-imenu-name (tabulated-list-get-id)))

(defun navigel--imenu-prev-index-position ()
  "Move point to previous line in current buffer.
This function is used as a value for
`imenu-prev-index-position-function'."
  (unless (bobp)
    (forward-line -1)))

(defun navigel-go-to-entity (entity)
  "Move point to ENTITY.
Return non-nil if ENTITY is found, nil otherwise."
  (goto-char (point-min))
  (while (and (not (= (point) (point-max)))
              (not (navigel-equal (navigel-entity-at-point) entity)))
    (forward-line 1))
  (not (= (point) (point-max))))

;; CL Context rewriter: this lets users write "&context (navigel-app
;; something)" instead of "&context (navigel-app (eql something))"
(cl-generic-define-context-rewriter navigel-app (app)
  `(navigel-app (eql ,app)))

(defun navigel--bookmark-jump (bookmark)
  "Open a navigel buffer showing BOOKMARK."
  (let ((entity (bookmark-prop-get bookmark 'navigel-entity))
        (target (bookmark-prop-get bookmark 'navigel-target))
        (navigel-app (bookmark-prop-get bookmark 'navigel-app)))
    (navigel-open entity target)
    (message "Current buffer at the end of navigel--bookmark-jump: %s" (current-buffer))))

(defun navigel--message (&rest args)
  "Display a message in the echo area.
This function only has an effect when `navigel-display-messages'
is true.  ARGS are the message format followed by any arguments
it takes."
  (when navigel-display-messages
    (apply #'message args)))


;; Generic methods: Those methods are the one you may override.

(cl-defgeneric navigel-name (entity)
  "Return a short string describing ENTITY.

The returned value is the default for `navigel-buffer-name',
`navigel-tablist-name' and `navigel-imenu-name'.  Those can be
overridden separately if necessary."
  (format "%s" entity))

(cl-defgeneric navigel-entity-id (entity)
  "Return a possibly unique identifier for the given ENTITY.

Under some circumstances, Navigel will cache information about
displayed entities, using its id as key.  By default, this
function calls `navigel-name', which should be good enough in the
majority of cases."
  (navigel-name entity))

(cl-defgeneric navigel-buffer-name (entity)
  "Return a string representing ENTITY in the buffer's name."
  (navigel-name entity))

(cl-defgeneric navigel-single-buffer-name (app entity)
  "Return a string representing ENTITY in the buffer's name, for single-buffer APP."
  (let ((app (or app navigel-app 'navigel))
        (suffix (if entity (format " - %s" (navigel-buffer-name entity)) "")))
    (format "*%s%s*" app suffix)))

(cl-defgeneric navigel-tablist-name (entity)
  "Return a string representing ENTITY in tablist columns."
  (navigel-name entity))

(cl-defgeneric navigel-imenu-name (entity)
  "Return a string representing ENTITY for `imenu'."
  (navigel-name entity))

(cl-defgeneric navigel-bookmark-name (entity)
  "Return a string representing ENTITY for `bookmark'."
  (navigel-name entity))

(cl-defgeneric navigel-children (entity callback)
  "Execute CALLBACK with the list of ENTITY's children as argument.
This method must be overridden for any tablist view to work.")

(cl-defmethod navigel-children ((entities list) callback)
  "Execute CALLBACK with the children of ENTITIES as argument."
  (navigel-async-mapcar  #'navigel-children entities callback))

(cl-defgeneric navigel-parent (_entity)
  "Return the parent of ENTITY if possible, nil if not."
  nil)

(cl-defgeneric navigel-equal (entity1 entity2)
  "Return non-nil if ENTITY1 and ENTITY2 represent the same entity."
  (equal entity1 entity2))

(cl-defgeneric navigel-entity-at-point ()
  "Return the entity at point or nil if none.")

(cl-defmethod navigel-entity-at-point (&context (major-mode (derived-mode navigel-tablist-mode)))
  "Return the entity at point in the context of a mode derived from MAJOR-MODE."
  (or (tabulated-list-get-id) navigel-entity))

(cl-defgeneric navigel-marked-entities (&optional _at-point-if-empty)
  "Return a list of entities that are selected.
If no entity is selected and AT-POINT-IF-EMPTY is non-nil, return
a list with just the entity at point."
  nil)

(cl-defmethod navigel-marked-entities (&context (major-mode (derived-mode navigel-tablist-mode))
                                                &optional at-point-if-empty)
  "Return a list with marked entities for MAJOR-MODE derived from a tablist.

AT-POINT-IF-EMPTY indicates whether to return the entity at point if none
is marked."
  ;; `tablist-get-marked-items' automatically includes the entity at
  ;; point if no entity is marked. We have to remove it unless
  ;; `at-point-if-empty' is non-nil.
  (let ((entities (mapcar #'car (tablist-get-marked-items))))
    (if (or (> (length entities) 1)
            (save-excursion ;; check if the entity is really marked
              (navigel-go-to-entity (car entities))
              (tablist-get-mark-state))
            at-point-if-empty)
        entities
      (list))))

(cl-defgeneric navigel-entity-buffer (entity)
  "Return a buffer name for ENTITY.
The default name is based on `navigel-app' and `navigel-buffer-name'."
  (format "*%s-%s*" navigel-app (navigel-buffer-name entity)))

(cl-defgeneric navigel-entity-tablist-mode (_entity)
  "Enable the `major-mode' most suited to display children of ENTITY."
  (navigel-tablist-mode))

(cl-defgeneric navigel-tablist-format (_entity)
  "Return a vector specifying columns to display ENTITY's children.
The return value is set as `tabulated-list-format'."
  (vector (list "Name" 0 t)))

(cl-defgeneric navigel-tablist-format-children (_entity &optional _children)
  "Return a vector specifying columns to display ENTITY's CHILDREN.
The return value is set as `tabulated-list-format' after the list
of children has been retrieved, unless this call returns nil."
  nil)

(cl-defgeneric navigel-entity-to-columns (entity)
  "Return the column descriptors to display ENTITY in a tabulated list.
The return value is a vector for `tabulated-list-entries'.

The vector should be compatible to the one defined with
`navigel-tablist-format'."
  (vector (navigel-tablist-name entity)))

(cl-defgeneric navigel-open (entity target)
  "Open a buffer displaying ENTITY.
If TARGET is non-nil and is in buffer, move point to it.

By default, list ENTITY's children in a tabulated list."
  (navigel--list-children entity target))

(cl-defgeneric navigel-parent-to-open (entity)
  "Return an indication of what to open if asked to open the parent of ENTITY.
Return nil if there is no parent to open.

The return value is (PARENT . ENTITY), where PARENT is the entity
to open and ENTITY is the entity to move point to."
  (cons (navigel-parent entity) entity))

(cl-defmethod navigel-parent-to-open (entity &context (major-mode navigel-tablist-mode))
  "Parent or ENTITY to open in the context of MAJOR-MODE derived from tablist."
  ;; Override default implementation because, in navigel-tablist-mode,
  ;; opening the parent of the entity at point would usually result in
  ;; opening the current buffer again. This is because the current
  ;; buffer typically already displays the parent of the entity at
  ;; point.
  (let* ((parent (navigel-parent entity))
         (ancestor (and parent (navigel-parent parent))))
    (cond ((and ancestor (navigel-equal parent navigel-entity))
           (cons ancestor parent))
          ((and parent (not (navigel-equal parent navigel-entity)))
           (cons parent entity))
          (t nil))))

(cl-defgeneric navigel-delete (_entity &optional _callback)
  "Remove ENTITY from its parent.
If non-nil, call CALLBACK with no parameter when done."
  (user-error "This operation is not supported in this context"))

(cl-defmethod navigel-delete ((entities list) &optional callback)
  "Remove each item of ENTITIES from its parent.
If non-nil, call CALLBACK with no parameter when done."
  (navigel-async-mapc #'navigel-delete entities callback))

(cl-defmethod navigel-make-bookmark ()
  "Return a record to bookmark the current buffer.

This function is to be used as value for
`bookmark-make-record-function' in navigel buffers."
  `(
    ,(navigel-bookmark-name navigel-entity)
    ((handler . ,#'navigel--bookmark-jump)
     (navigel-entity . ,navigel-entity)
     (navigel-target . ,(navigel-entity-at-point))
     (navigel-app . ,navigel-app))))


;;; Public functions

(defun navigel-single-buffer-app-p (app)
  "Check whether APP is registered as a single-buffer application.

See also `navigel-single-buffer-apps'."
  (or (eq t navigel-single-buffer-apps)
      (memq app navigel-single-buffer-apps)))

(defun navigel-register-single-buffer-app (app)
  "Register APP as a single buffer application."
  (or (navigel-single-buffer-app-p app)
      (add-to-list 'navigel-single-buffer-apps app)))

(defun navigel-app-buffer (app)
  "If APP is a single-buffer application, return its buffer."
  (navigel--app-buffer app t))

(defun navigel-async-mapcar (mapfn list callback)
  "Apply MAPFN to each element of LIST and pass result to CALLBACK.

MAPFN is a function taking 2 arguments: the element to map and a
callback to call when the mapping is done."
  (if (not list)
      (funcall callback nil)
    (let ((result (make-vector (length list) nil))
          (count 0))
      (cl-loop for index below (length list)
               for item in list
               do (let ((index index) (item item))
                    (funcall
                     mapfn
                     item
                     (lambda (item-result)
                       (setf (seq-elt result index) item-result)
                       (cl-incf count)
                       (when (eq count (length list))
                         ;; use `run-at-time' to ensure that CALLBACK is
                         ;; consistently called asynchronously even if MAPFN is
                         ;; synchronous:
                         (run-at-time
                          0 nil
                          callback
                          (seq-concatenate 'list result))))))))))

(defun navigel-async-mapc (mapfn list callback)
  "Same as `navigel-async-mapcar' but for side-effects only.

MAPFN is a function taking 2 arguments: an element of LIST and a
callback.  MAPFN should call the callback with no argument when
done computing.

CALLBACK is a function of no argument that is called when done
computing for the all elements of LIST."
  (navigel-async-mapcar
   (lambda (item callback) (funcall mapfn item (lambda () (funcall callback nil))))
   list
   (lambda (_result) (funcall callback))))

(defun navigel-open-parent (&optional entity)
  "Open in a new buffer the parent of ENTITY, entity at point if nil."
  (interactive (list (navigel-entity-at-point)))
  (when entity
    (pcase (navigel-parent-to-open entity)
      (`(,parent . ,entity) (navigel-open parent entity))
      (_ (message "No parent to go to")))))

(defun navigel-refresh (&optional target callback)
  "Compute `navigel-entity' children and list those in the current buffer.

If TARGET is non-nil and is in buffer, move point to it.

If CALLBACK is non nil, execute it when the buffer has been
refreshed."
  (let ((entity navigel-entity)
        ;; save navigel-app so we can rebind below
        (app navigel-app))
    (navigel--message (if (equal (point-min) (point-max))
                          "Populating…"
                        "Refreshing…"))
    (navigel-children
     entity
     (lambda (children)
       ;; restore navigel-app
       (let ((navigel-app app) state)
         (with-current-buffer (navigel--entity-buffer app entity)
           (let ((fmt (navigel-tablist-format-children entity children)))
             (when fmt
               (setq-local tabulated-list-format fmt)
               (tabulated-list-init-header)))
           (setq state (navigel--save-state))
           (setq-local tabulated-list-entries
                       (mapcar (lambda (child)
                                 (list child (navigel-entity-to-columns child)))
                               children))
           (tabulated-list-print)
           (when (not (navigel-single-buffer-app-p app))
             (navigel--restore-state state))
           (when target
             (navigel-go-to-entity target))
           (run-hooks 'navigel-changed-hook)
           (when callback
             (funcall callback))
           (navigel--message "Ready!")))))))

(defmacro navigel-method (app name args &rest body)
  "Define a method NAME with ARGS and BODY.
This method will only be active if `navigel-app' equals APP."
  (declare (indent 3))
  `(cl-defmethod ,name ,(navigel--insert-context-in-args app args)
     ,@body))


;;; Private functions

(defvar bookmark-make-record-function)

(defun navigel--list-children (entity &optional target)
  "Open a new buffer showing ENTITY's children.

If TARGET is non-nil and is in buffer, move point to it.

Interactively, ENTITY is either the element at point or the user
is asked for a top level ENTITY."
  ;; save navigel-app because (navigel-tablist-mode) will reset it
  (let ((app navigel-app)
        (prev-entity navigel-entity)
        (single (navigel-single-buffer-app-p navigel-app))
        (buffer (navigel--entity-buffer navigel-app entity))
        cache)
    (with-current-buffer buffer
      ;; set navigel-app first because it is used on the line below to
      ;; select the appropriate mode:
      (setq-local navigel-app app)
      (when single
        (when prev-entity (navigel--cache-state prev-entity))
        (setq cache navigel--state-cache))
      (navigel-entity-tablist-mode entity)
      ;; restore navigel-app because is got erased by activating the major mode:
      (setq-local navigel-app app)
      (setq-local tabulated-list-padding 2) ; for `tablist'
      (setq-local navigel-entity entity)
      (when single
        (setq-local navigel--state-cache cache)
        (rename-buffer (navigel-single-buffer-name app entity) t))
      (setq-local tablist-operations-function #'navigel--tablist-operation-function)
      (setq-local revert-buffer-function #'navigel--revert-buffer)
      (setq-local imenu-prev-index-position-function
                  #'navigel--imenu-prev-index-position)
      (setq-local imenu-extract-index-name-function
                  #'navigel--imenu-extract-index-name)
      (setq-local tabulated-list-format (navigel-tablist-format entity))
      (setq-local bookmark-make-record-function #'navigel-make-bookmark)
      (tabulated-list-init-header)
      (navigel-refresh
       nil
       (lambda ()
         (with-current-buffer buffer
           (when (and single entity)
             (navigel--restore-state (navigel--cached-state entity)))
           (when target (navigel-go-to-entity target))
           (run-hooks 'navigel-init-done-hook)))))
    (switch-to-buffer buffer)))

(defun navigel--save-state ()
  "Return an object representing the state of the current buffer.
This should be restored with `navigel--restore-state'.

The state contains the entity at point, the column of point, and the marked entities."
  `(
    (entity-at-point . ,(navigel-entity-at-point))
    (column . ,(current-column))
    (marked-entities . ,(navigel-marked-entities))))

(defun navigel--restore-state (state)
  "Restore STATE.  This was saved with `navigel--save-state'."
  (let-alist state
    (if .entity-at-point
        (navigel-go-to-entity .entity-at-point)
      (setf (point) (point-min)))
    (when .column
      (setf (point) (line-beginning-position))
      (forward-char .column))
    (when .marked-entities
      (save-excursion
        (dolist (entity .marked-entities)
          (when (navigel-go-to-entity entity)
            (tablist-put-mark)))))))

(defun navigel--forget-single-buffer ()
  "Remove the entry for the current buffer in `navigel-single-buffers."
  (map-delete navigel-single-buffers navigel-app))

(defun navigel--single-app-buffer-create (app)
  "Create and return a buffer for the given APP, setting it up for single mode."
  (let ((buffer (get-buffer-create (navigel-single-buffer-name app nil))))
    (setf (alist-get app navigel-single-buffers) buffer)
    (with-current-buffer buffer
      (add-hook 'kill-buffer-hook #'navigel--forget-single-buffer nil t)
      (setq-local navigel-app app))
    buffer))

(defun navigel--app-buffer (app &optional no-create)
  "If APP is a single-buffer application, find or create its buffer.

If NO-CREATE is not nil, do not create a fresh buffer if one does
not already exist."
  (when (navigel-single-buffer-app-p app)
    (let ((buffer (alist-get app navigel-single-buffers)))
      (when (and (not (buffer-live-p buffer)) (not no-create))
        (setq buffer (navigel--single-app-buffer-create app)))
      buffer)))

(defun navigel--entity-buffer (app entity)
  "Return the buffer that APP should use for the given ENTITY."
  (or (navigel--app-buffer app)
      (get-buffer-create (navigel-entity-buffer entity))))

(defun navigel--cache-state (entity)
  "Save in the local cache the state of ENTITY, as displayed in the current buffer."
  (let ((id (when entity (navigel-entity-id entity))))
    (when id
      (when (not navigel--state-cache)
        (setq-local navigel--state-cache ()))
      (setf (alist-get id navigel--state-cache nil nil #'equal)
            (navigel--save-state)))))

(defun navigel--cached-state (&optional entity app)
  "Return the cached state of the given ENTITY, in application APP.

ENTITY and APP default to the local values of `navigel-entity' and `navigel-app'."
  (let ((entity (or entity navigel-entity)))
    (when entity
      (let ((app-buffer (navigel--app-buffer (or app navigel-app))))
        (when app-buffer
          (cdr (assoc (navigel-entity-id entity)
                      (buffer-local-value 'navigel--state-cache app-buffer))))))))

(defun navigel--revert-buffer (&rest _args)
  "Compute `navigel-entity' children and list those in the current buffer."
  (navigel-refresh))

(defun navigel--insert-context-in-args (app args)
  "Return an argument list with a &context specializer for APP within ARGS."
  (let ((result (list))
        (rest-args args))
    (catch 'found-special-arg
      (while rest-args
        (let ((arg (car rest-args)))
          (when (symbolp arg)
            (when (eq arg '&context)
              (throw 'found-special-arg
                     (append (nreverse result)
                             `(&context (navigel-app ,app))
                             (cdr rest-args))))
            (when (string= "&" (substring-no-properties (symbol-name arg) 0 1))
              (throw 'found-special-arg
                     (append (nreverse result)
                             `(&context (navigel-app ,app))
                             rest-args))))
          (setq result (cons arg result))
          (setq rest-args (cdr rest-args))))
      (append (nreverse result) `(&context (navigel-app ,app))))))


;;; Major mode

(defvar navigel-tablist-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "^") #'navigel-open-parent)
    map)
  "Keymap for `navigel-tablist-mode'.")

(define-derived-mode navigel-tablist-mode tablist-mode "navigel-tablist"
  "Major mode for all elcouch listing modes.")

(provide 'navigel)
;;; navigel.el ends here

;;; LocalWords:  navigel tablist tablists keymap
