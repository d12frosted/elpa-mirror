;;; go-direx.el --- Tree style source code viewer for Go language

;; Copyright (C) 2015 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-go-direx
;; Package-Version: 20150316.143
;; Package-Commit: 8f2206469328ee932c7f1892f5e1fb02dec98432
;; Version: 0.04
;; Package-Requires: ((direx "1.0.0") (cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; go-direx.el provides tree style source code viewer for Go langue
;; using direx.
;;
;; To use this package, add these lines to your .emacs.d/init.el:
;;     (require 'go-direx)
;;
;; I recommend you use go-direx with popwin.el. You can control popup
;; buffer easily.
;;

;;; Code:

(require 'cl-lib)
(require 'direx)

(defgroup go-direx nil
  "tagbar for Go language"
  :group 'go)

(defvar go-direx-buffer "*go-direx*")



;;; Faces

(defface go-direx-header
  '((t :inherit font-lock-type-face))
  "Face of header"
  :group 'go-direx)

(defface go-direx-package
  '((((background dark))  :foreground "green" :weight bold)
    (((background light)) :foreground "red" :weight bold))
  "Face of type"
  :group 'go-direx)

(defface go-direx-label
  '((t :inherit font-lock-function-name-face))
  "Face of type"
  :group 'go-direx)



;;; Core

(defclass go-direx-object (direx:tree) ())

(defclass go-direx-module (go-direx-object direx:node)
  ((package :initarg :package)
   (buffer :initarg :buffer)
   (file-name :initarg :file-name :accessor direx:file-full-name)

   (imports :initarg :imports)
   (constants :initarg :constants)
   (types :initarg :types)
   (variables :initarg :variables)
   (functions :initarg :functions)

   (structs :initarg :structs :initform '())
   (interfaces :initarg :interfaces :initform '()))
  "module class")

(defclass go-direx-package (go-direx-object direx:leaf) ())
(defclass go-direx-label (go-direx-object direx:leaf) ())

(defvar go-direx-field-label
  (make-instance 'go-direx-label :name "[Fields]"))
(defvar go-direx-method-label
  (make-instance 'go-direx-label :name "[Methods]"))
(defvar go-direx-embedded-label
  (make-instance 'go-direx-label :name "[Embedded]"))

(defclass go-direx-node (go-direx-object direx:node)
  ((leaves :initarg :leaves :initform '())))

(defclass go-direx-import (go-direx-object direx:leaf)
  ((line :initarg :line)))

(defclass go-direx-symbol (go-direx-object)
  ((line :initarg :line)
   (access :initarg :access)))

(defclass go-direx-variable (go-direx-symbol direx:leaf)
  ())

(defclass go-direx-constant (go-direx-symbol direx:leaf)
  ((type :initarg :type)))

(defclass go-direx-field (go-direx-symbol direx:leaf)
  ((type :initarg :type)
   (belonging :initarg :belonging)))

(defclass go-direx-function (go-direx-symbol direx:leaf)
  ((signature :initarg :signature)
   (return-type :initarg :return-type)))

(defclass go-direx-method (go-direx-function)
  ((belonging :initarg :belonging)))

(defclass go-direx-belonged ()
  ((name :initarg :name)
   (class :initarg :class)))

(defclass go-direx-type (go-direx-symbol)
  ((type :initarg :type)))

(defclass go-direx-embedded (go-direx-type direx:leaf)
  ((belonging :initarg :belonging)))

(defclass go-direx-interface (go-direx-type)
  ((class-name :initarg :class-name)
   (methods :initarg :methods :initform '())
   (embeddeds :initarg :embeddeds :initform '())))

(defclass go-direx-struct (go-direx-type)
  ((class-name :initarg :class-name)
   (fields :initarg :fields :initform '())
   (methods :initarg :methods :initform '())
   (embeddeds :initarg :embeddeds :initform '())))

(defclass go-direx-struct-node (go-direx-node)
  ((struct :initarg :struct)))

(defclass go-direx-interface-node (go-direx-node)
  ((interface :initarg :interface)))

(defsubst go-direx--construct-struct-nodes (module)
  (cl-loop for struct in (oref module :structs)
           collect (make-instance 'go-direx-struct-node
                                  :name (oref struct :name)
                                  :struct struct)))

(defsubst go-direx--construct-interface-nodes (module)
  (cl-loop for interface in (oref module :interfaces)
           collect (make-instance 'go-direx-interface-node
                                  :name (oref interface :name)
                                  :interface interface)))

(defmethod direx:node-children ((module go-direx-module))
  (append (list (oref module :package)
                (oref module :imports)
                (oref module :constants)
                (oref module :variables)
                (oref module :functions))
          (go-direx--construct-struct-nodes module)
          (go-direx--construct-interface-nodes module)))

(defmethod direx:node-children ((node go-direx-object))
  (oref node :name))

(defmethod direx:node-children ((node go-direx-node))
  (oref node :leaves))

(defmethod direx:node-children ((node go-direx-struct-node))
  (let* ((struct (oref node :struct))
         (fields (oref struct :fields))
         (methods (oref struct :methods))
         (embeddeds (oref struct :embeddeds))
         f-leaves m-leaves e-leaves)
    (when (not (null fields))
      (setq f-leaves (cons go-direx-field-label fields)))
    (when (not (null methods))
      (setq m-leaves (cons go-direx-method-label methods)))
    (when (not (null embeddeds))
      (setq e-leaves (cons go-direx-embedded-label embeddeds)))
    (append f-leaves m-leaves e-leaves)))

(defmethod direx:node-children ((node go-direx-interface-node))
  (let ((interface (oref node :interface)))
    (oref interface :methods)))



;;; Parsing

(defun go-direx--retrieve-signature (str)
  (if (null str)
      ""
    (when (string-match "\\`signature:\\(.+\\)\\'" str)
      (match-string-no-properties 1 str))))

(defun go-direx--retrieve-type (str)
  (if (null str)
      ""
    (when (string-match "\\`type:\\(.+\\)\\'" str)
      (match-string-no-properties 1 str))))

(defun go-direx--create-belonged-hash (classes)
  (let ((ret-hash (make-hash-table))
        (struct-hash (make-hash-table :test 'equal))
        (interface-hash (make-hash-table :test 'equal)))
    (cl-loop for class in classes
             for type = (oref class :type)
             when (string= "struct" type)
             do (puthash (oref class :class-name) class struct-hash)

             when (string= "interface" type)
             do (puthash (oref class :class-name) class interface-hash)

             finally
             return (progn
                      (puthash 'struct struct-hash ret-hash)
                      (puthash 'interface interface-hash ret-hash)
                      ret-hash))))

(defun go-direx--retrieve-line (str)
  (when (string-match "\\`\\([0-9]+\\);\"\\'" str)
    (string-to-number (match-string-no-properties 1 str))))

(defsubst go-direx--belonged-class (class)
  (cond ((string= class "c") 'struct)
        ((string= class "n") 'interface)
        (t (error "Invalid class type '%s'" class))))

(defun go-direx--retrieve-belonging (str)
  (when (string-match "\\`\\([cn]\\)type:\\(\\S-+\\)\\'" str)
    (make-instance 'go-direx-belonged
                   :name (match-string-no-properties 2 str)
                   :class (go-direx--belonged-class
                           (match-string-no-properties 1 str)))))

(defun go-direx--retrieve-access (str)
  (when (string-match "\\`access:\\(\\S-+\\)\\'" str)
    (let ((access (match-string-no-properties 1 str)))
      (cond ((string= access "public") 'public)
            ((string= access "private") 'private)
            (t (error "Error: Invalid access '%s'" access))))))

(defun go-direx--concat-name-and-type (name type)
  (if (string= type "")
      name
    (concat name " : " type)))

(defsubst go-direx--make-interface (name line access fields)
  (let ((type (go-direx--retrieve-type (nth 6 fields))))
    (make-instance 'go-direx-interface
                   :name (go-direx--concat-name-and-type name type)
                   :line line :access access :type type
                   :class-name name)))

(defsubst go-direx--make-constant (name line access fields)
  (let ((type (go-direx--retrieve-type (nth 6 fields))))
    (make-instance 'go-direx-constant
                   :name (go-direx--concat-name-and-type name type)
                   :access access :type type :line line)))

(defsubst go-direx--make-function-name (name signature ret-type)
  (if (string-match-p "," ret-type)
      (concat name signature " " "(" ret-type ")")
    (concat name signature " " ret-type)))

(defun go-direx--retrieve-function-signature (last2 last1)
  (if (string-match-p "\\`signature:" last1)
      (cons (go-direx--retrieve-signature last1) "")
    (if (string-match-p "\\`signature:" last2)
        (cons (go-direx--retrieve-signature last2)
              (go-direx--retrieve-type last1))
      (error "Invalid: signature type"))))

(defun go-direx--make-function (name line access fields)
  (let* ((len (length fields))
         (signature-ret (go-direx--retrieve-function-signature
                         (nth (- len 2) fields) (nth (1- len) fields)))
         (signature (car signature-ret))
         (ret-type (cdr signature-ret)))
    (make-instance 'go-direx-function
                   :name (go-direx--make-function-name name signature ret-type)
                   :line line :access access
                   :signature signature :return-type ret-type)))

(defsubst go-direx--make-field (name line access fields)
  (let ((type (go-direx--retrieve-type (nth 7 fields)))
        (belonging (go-direx--retrieve-belonging (nth 5 fields))))
    (make-instance 'go-direx-field
                   :name (concat name " : " type)
                   :line line :access access
                   :type type :belonging belonging)))

(defun go-direx--make-type (name line access fields)
  (let ((type (go-direx--retrieve-type (nth 6 fields))))
    (if (string= type "struct")
        (make-instance 'go-direx-struct
                       :name (concat name " : struct")
                       :line line :access access :type type :class-name name)
      (make-instance 'go-direx-type
                     :name (concat name " : " type)
                     :line line :access access :type type))))

(defun go-direx--search-belonging-field (line-str)
  (when (string-match "\t\\([cn]type:\\S-+\\)" line-str)
    (match-string-no-properties 1 line-str)))

(defun go-direx--make-method (name line access line-str fields)
  (let* ((belonging (go-direx--retrieve-belonging
                     (go-direx--search-belonging-field line-str)))
         (signature (go-direx--retrieve-signature (nth 7 fields)))
         (ret-type (go-direx--retrieve-type (nth 8 fields))))
    (make-instance 'go-direx-method
                   :name (go-direx--make-function-name name signature ret-type)
                   :line line :access access :signature signature :return-type
                   ret-type :belonging belonging)))

(defun go-direx--make-embedded (name line access line-str)
  (let ((belonging (go-direx--retrieve-belonging
                    (go-direx--search-belonging-field line-str))))
    (make-instance 'go-direx-embedded
                   :name name
                   :line line :access access :type name
                   :belonging belonging)))

(defun go-direx--classify (line-str)
  (let* ((fields (split-string line-str "\t"))
         (name (nth 0 fields))
         (line (go-direx--retrieve-line (nth 2 fields)))
         (short (string-to-char (nth 3 fields)))
         (access (go-direx--retrieve-access (nth 4 fields))))
    (cl-case short
      ;; package name
      (?p (cons 'package (make-instance 'go-direx-package
                                        :name (concat "package " name))))
      ;; imported package
      (?i (cons 'import (make-instance 'go-direx-import :name name :line line)))
      ;; constant variable
      (?c (cons 'constant (go-direx--make-constant name line access fields)))
      ;; type definition
      (?t (cons 'type (go-direx--make-type name line access fields)))
      ;; global variable
      (?v (cons 'variable (make-instance 'go-direx-variable
                                         :name name :line line :access access)))
      ;; function(not method)
      (?f (cons 'function (go-direx--make-function name line access fields)))
      ;; interface
      (?n (cons 'interface (go-direx--make-interface name line access fields)))

      ;; struct field
      (?w (cons 'field (go-direx--make-field name line access fields)))

      ;; methods(Belongs to `struct' or `interface'
      (?m (cons 'method (go-direx--make-method name line access line-str fields)))

      ;; embedded types
      (?e (cons 'embedded (go-direx--make-embedded name line access line-str))))))

(defmethod go-direx--add-to-node ((module go-direx-module) type instance)
  (let* ((slot (intern (format ":%ss" type)))
         (node (eieio-oref module slot)))
    (eieio-oset node :leaves (cons instance (oref node :leaves)))))

(defsubst go-direx--push-slot (class slot leaf)
  (eieio-oset class slot (cons leaf (eieio-oref class slot))))

(defsubst go-direx--public-access-p (symbol)
  (let ((case-fold-search nil))
    (not (string-match-p "^[[:lower:]]" symbol))))


(defun go-direx--define-class (type name)
  (let ((access (go-direx--public-access-p name)))
    (if (eq type 'struct)
        (make-instance 'go-direx-struct
                       :name (concat name " : struct")
                       :line -1 :access access :type "struct"
                       :class-name name)
      (make-instance 'go-direx-interface
                     :name (concat name " : interface")
                     :line -1 :access access :type "interface"
                     :class-name name))))

(defmethod go-direx--set-methods ((module go-direx-module) methods belonged-hash)
  (cl-loop for method in methods
           for method-belonged = (oref method :belonging)
           for belonged-type = (oref method-belonged :class)
           for hash = (gethash belonged-type belonged-hash)
           for class-name = (oref method-belonged :name)
           for belonged-class = (gethash class-name hash)
           do
           (if belonged-class
               (go-direx--push-slot belonged-class :methods method)
             (let ((class (go-direx--define-class belonged-type class-name)))
               (go-direx--push-slot class :methods method)
               (go-direx--add-to-node module 'type class)
               (puthash class-name class hash)))))

(defmethod go-direx--set-fields ((_module go-direx-module) fields belonged-hash)
  (cl-loop for field in fields
           for field-belonged = (oref field :belonging)
           for belonged-type = (oref field-belonged :class)
           for hash = (gethash belonged-type belonged-hash)
           for belonged-class = (gethash (oref field-belonged :name) hash)
           do
           (go-direx--push-slot belonged-class :fields field)))

(defmethod go-direx--set-embeddeds ((_module go-direx-module) embeddeds belonged-hash)
  (cl-loop for embedded in embeddeds
           for embedded-belonged = (oref embedded :belonging)
           for belonged-type = (oref embedded-belonged :class)
           for hash = (gethash belonged-type belonged-hash)
           for belonged-class = (gethash (oref embedded-belonged :name) hash)
           do
           (go-direx--push-slot belonged-class :embeddeds embedded)))

(defmethod go-direx--set-struct-interface ((module go-direx-module))
  (cl-loop for type in (oref (oref module :types) :leaves)
           do
           (cl-typecase type
             (go-direx-struct (go-direx--push-slot module :structs type))
             (go-direx-interface (go-direx--push-slot module :interfaces type)))))

(defmacro go-direx--make-node (name)
  `(make-instance 'go-direx-node :name ,name))

(defsubst go-direx--construct-module ()
  (make-instance 'go-direx-module
                 :imports (go-direx--make-node "imports")
                 :constants (go-direx--make-node "constants")
                 :types (go-direx--make-node "types")
                 :variables (go-direx--make-node "variables")
                 :functions (go-direx--make-node "functions")))

(defsubst go-direx--header-p (line)
  (string-match "\\`!" line))

(defun go-direx--parse-gotags-output ()
  (let ((module (go-direx--construct-module))
        fields methods embeddeds)
    (while (not (eobp))
      (let ((line (buffer-substring-no-properties
                   (line-beginning-position) (line-end-position))))
        (when (not (go-direx--header-p line))
          (let* ((stuff (go-direx--classify line))
                 (type (car stuff))
                 (instance (cdr stuff)))
            (cl-case type
              (package (oset module :package instance))
              (embedded (push instance embeddeds))
              (method (push instance methods))
              (field (push instance fields))
              ;; `interfaces' are added to type node
              (interface (go-direx--add-to-node module 'type instance))
              (otherwise  (go-direx--add-to-node module type instance)))))
        (forward-line 1)))
    (let* ((classes (oref (oref module :types) :leaves))
           (belonged-hash (go-direx--create-belonged-hash classes)))
      (go-direx--set-methods module methods belonged-hash)
      (go-direx--set-fields module fields belonged-hash)
      (go-direx--set-embeddeds module embeddeds belonged-hash)
      (go-direx--set-struct-interface module))
    module))

(defun go-direx--collect-info ()
  (let ((file (buffer-file-name)))
    (if (not file)
        (message "This buffer is not related file!!")
      (with-temp-buffer
        (if (not (zerop (call-process "gotags" nil t nil file)))
            (message "Failed: 'gotags %s'" file)
          (goto-char (point-min))
          (go-direx--parse-gotags-output))))))



;;; View

(defclass go-direx-item (direx:item)
  ())

(defmethod direx:make-item ((tree go-direx-object) parent)
  (make-instance 'go-direx-item :tree tree :parent parent))

(defmethod direx:make-item ((_tree go-direx-node) _parent)
  (let ((item (call-next-method)))
    (oset item :face 'go-direx-header)
    item))

(defmethod direx:make-item ((_tree go-direx-package) _parent)
  (let ((item (call-next-method)))
    (oset item :face 'go-direx-package)
    item))

(defmethod direx:make-item ((_tree go-direx-label) _parent)
  (let ((item (call-next-method)))
    (oset item :face 'go-direx-label)
    item))

(defun go-direx--goto-item (item)
  (let ((root (direx:item-tree item)))
    (when (slot-exists-p root 'line)
      (let ((line (oref root :line)))
       (if (= line -1)
           (message "This is defined in other file")
         (goto-char (point-min))
         (forward-line (1- line)))))))

(defmethod direx:generic-find-item ((item go-direx-item)
                                    not-this-window)
  (let* ((root (direx:item-root item))
         (filename (direx:file-full-name (direx:item-tree root))))
    (if not-this-window
        (find-file-other-window filename)
      (find-file filename))
    (go-direx--goto-item item)))

(defmethod direx:generic-display-item ((item go-direx-item))
  (let* ((root (direx:item-root item))
         (filename (direx:file-full-name (direx:item-tree root))))
    (with-selected-window (display-buffer (find-file-noselect filename))
      (go-direx--goto-item item))))

(defmethod go-direx--update-module-info ((module go-direx-module) updated)
  (dolist (slot '(:imports :constants :types :variables :functions))
    (eieio-oset module slot (eieio-oref updated slot))))

(defmethod direx:item-refresh ((item go-direx-item))
  (let* ((root (direx:item-root item))
         (module (direx:item-tree root)))
    (with-current-buffer (oref module :buffer)
      (let ((updated (go-direx--collect-info)))
        (go-direx--update-module-info module updated)))
    (call-next-method root)
    (save-excursion
      (goto-char (point-min))
      (direx:expand-item-recursively))))



;;; Command

(defvar go-direx--buffer-cache
  (make-hash-table :test 'equal))

(defsubst go-direx--set-buffer-info (module)
  (oset module :name (format "*go-direx:%s*" (buffer-name)))
  (oset module :buffer (current-buffer))
  (oset module :file-name (buffer-file-name)))

(defun go-direx--make-buffer ()
  (let* ((filename (buffer-file-name))
         (cached-buf (gethash filename go-direx--buffer-cache)))
    (if (and cached-buf (buffer-live-p cached-buf))
        cached-buf
      (let ((module (go-direx--collect-info)))
        (go-direx--set-buffer-info module)
        (let ((buffer (direx:ensure-buffer-for-root module)))
          (puthash filename buffer go-direx--buffer-cache)
          buffer)))))

(defun go-direx--kill-buffer-hook ()
  (let ((file (buffer-file-name)))
    (remhash file go-direx--buffer-cache)))

(defun go-direx--make-buffer-common (func)
  (let ((buf (go-direx--make-buffer)))
    (funcall func buf)
    (set (make-local-variable 'direx:leaf-icon) " ")
    (add-hook 'kill-buffer-hook 'go-direx--kill-buffer-hook nil t)
    (direx:expand-item-recursively)))

;;;###autoload
(defun go-direx-pop-to-buffer ()
  (interactive)
  (go-direx--make-buffer-common 'pop-to-buffer))

;;;###autoload
(defun go-direx-switch-to-buffer ()
  (interactive)
  (go-direx--make-buffer-common 'switch-to-buffer))

(provide 'go-direx)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; go-direx.el ends here
