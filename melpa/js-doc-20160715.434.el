;;; js-doc.el --- Insert JsDoc style comment easily

;; Author: mooz <stillpedant@gmail.com>
;; Version: 0.0.5
;; Package-Version: 20160715.434
;; Package-Commit: f0606e89d5aa89146f96edb38cf69af0068a9d1e
;; Keywords: document, comment
;; URL: https://github.com/mooz/js-doc

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; Installation:
;; put `js-doc.el' somewhere in your emacs load path
;; add a line below to your .emacs file
;; (require 'js-doc)

;; Example:
;; paste the codes below into your .emacs.el file and you can
;;
;; 1. insert function document by pressing Ctrl + c, i
;; 2. insert @tag easily by pressing @ in the JsDoc style comment
;;
;; (setq js-doc-mail-address "your email address"
;;       js-doc-author (format "your name <%s>" js-doc-mail-address)
;;       js-doc-url "url of your website"
;;       js-doc-license "license name")
;;
;; (add-hook 'js2-mode-hook
;;           #'(lambda ()
;;               (define-key js2-mode-map "\C-ci" 'js-doc-insert-function-doc)
;;               (define-key js2-mode-map "@" 'js-doc-insert-tag)))
;;
;; If you want to see the tag description, just input the next command
;;   M-x js-doc-describe-tag

;;; Code:

(require 'iswitchb)

;;; Custom:
(defgroup js-doc nil
  "Insert JsDoc style comment easily."
  :group 'comment
  :prefix "js-doc")

;; Variables
(defcustom js-doc-mail-address ""
  "Author's E-mail address."
  :group 'js-doc)

(defcustom js-doc-author ""
  "Author of the source code."
  :group 'js-doc)

(defcustom js-doc-license ""
  "License of the source code."
  :group 'js-doc)

(defcustom js-doc-url ""
  "Author's Home page URL."
  :group 'js-doc)

;; from jsdoc-toolkit wiki
;; http://code.google.com/p/jsdoc-toolkit/wiki/TagReference
(defvar js-doc-all-tag-alist
  '(("abstract" . "Identifies members that must be implemented (or overridden) by objects that inherit the member. Syntax: @abstrac")
    ("access" . "Specifies the access level of a member. @access <private|protected|public>")
    ("alias" . "Causes JSDoc to treat all references to a member as if the member had a different name. Syntax: @alias <aliasNamepath>")
    ("augments" . "Indicates this class uses another class as its \"base.\" Syntax: @augments <namepath>")
    ("author" . "Indicates the author of the code being documented. Syntax: @author <name> [<emailAddress>]")
    ("arg" . "Deprecated synonym for @param. Syntax: @arg [{<type>}] <name> [- <description>]")
    ("argument" . "Deprecated synonym for @param. Syntax: @argument [{<type>}] <name> [- <description>]")
    ("borrows" . "Document that class's member as if it were a member of this class. Syntax: @borrows <that namepath> as <this namepath>")
    ("callback" . "Provides information about a callback function that can be passed to other functions, including the callback's parameters and return value. Syntax: @callback <namepath>")
    ("class" . "Marks a function as being a constructor, meant to be called with the new keyword to return an instance. Syntax: @class [<type> <name>]")
    ("classdesc" . "Provides a description for a class, separate from the constructor function's description. Syntax: @classdesc <some description>")
    ("const" . "Synonym of @constant. Syntax: @const [<type> <name>]")
    ("constant" . "Indicates that a variable's value is a constant. Syntax: @constant [<type> <name>]")
    ("constructor" . "Synonym of @class. Syntax: @constructor [<type> <name>]")
    ("constructs" . "Indicates that a particular function will be used to construct instances of that class. Syntax: @constructs [<name>]")
    ("copyright" . "Indicates copyright information in a file overview comment. Use this tag in combination with the @file tag. Syntax: @copyright <some copyright text>")
    ("default" . "Describes the assigned value of a symbol (default value). Syntax: @default [<some value>]")
    ("deprecated" . "Indicates that use of the symbol is no longer supported. Syntax: @deprecated [<some text>]")
    ("desc" . "Synonym of @description. Syntax: @desc <some description>")
    ("description" . "Provides a general description of a symbol (untagged first-line is used if none is provide). It may include HTML markup or Markdown if the plugin is enabled. Syntax: @description <some description>")
    ("emits" . "Synonym of @fires. Syntax: @emits <className>#[event:]<eventName>")
    ("enum" . "Documents a collection of static properties whose values are all of the same type. An enum is similar to a collection of properties, except that an enum is documented in its own doc comment, whereas properties are documented within the doc comment of their container. Often this tag is used with @readonly, as an enum typically represents a collection of constants. Syntax: @enum [<type>]")
    ("event" . "Document an event that can be fired. A typical event is represented by an object with a defined set of properties. Once an event is documented, @fires may be used to indicate that a method fires that event. @listen may also be used to indicate that a symbol listens for the event. Syntax: @event <className>#[event:]<eventName>")
    ("example" . "Provides an example of how to use a documented item. The text that follows this tag will be displayed as highlighted code. Syntax: @example <multiline example>")
    ("exception" . "Synonym of @throws. Syntax: @exception free-form description | @exception {<type>} | @exception {<type>} free-form description")
    ("exports" . "Documents that a JavaScript module exports anything other than the \"exports\" object or the \"module.exports\" property. Syntax: @exports <moduleName>")
    ("extends" . "Synonym for @augments. Syntax: @extends <namepath>")
    ("external" . "Identifies a class, namespace, or module that is defined outside of the current package. Syntax: @external <NameOfExternal>")
    ("field" . "Indicate that the variable refers to a non-function.")
    ("file" . "Provides a description for a file. Use the tag in a JSDoc comment at the beginning of the file. Syntax: @file <file description>")
    ("fileOverview" . "Synonym of @file. Syntax: @fileOverview <file description>")
    ("fires" . "indicates that a method can fire a specified type of event when it is called. @event tag is used to document the event's content. Syntax: @fires <className>#[event:]<eventName>")
    ("func" . "Synonym of @function. Syntax: @funct [<FunctionName>]")
    ("function" . "Indicate that the variable refers to a function. Syntax: @function [<FunctionName>]")
    ("global" . "Specifies that a symbol should appear in the documentation as a global symbol. JSDoc ignores the symbol's actual scope within the source file. This tag is especially useful for symbols that are defined locally, then assigned to a global symbol. Syntax: @global")
    ("host" . "Synonym of @external. Syntax: @host <NameOfExternal>")
    ("ignore" . "Indicates that a symbol in your code should never appear in the documentation. This tag takes precedence over all others. Syntax: @ignore")
    ("implements" . "Indicates that a symbol implements an interface. The @implements tag should be at the top-level symbol that implements the interface (for example, a constructor function). @implements tag dont't need to be attached  to each member of the implementation (for example, the implementation's instance methods). Syntax: @implements {typeExpression}")
    ("inheritdoc" . "Indicates that a symbol should inherit its documentation from its parent class. Any other tags included in the JSDoc comment will be ignored. The presence of the @inheritdoc tag implies the presence of the @override tag. Syntax: @inheritdoc")
    ("inner" . "Marks a symbol as an inner member of its parent symbol (and so is also private). This means it can be referred to by \"Parent~Child\". Using @inner will override a doclet's default scope. Syntax: @inner")
    ("instance" . "Marks a symbol as an instance member of its parent symbol. This means it can be referred to by \"Parent#Child\". Using @instance will override a doclet's default scope. Syntax: @instance")
    ("interface" . "Marks a symbol as an interface that other symbols can implement (children). Syntax: @interface [<name>]")
    ("kind" . "Documents what kind of symbol is being documented (for example, a class or a module). The kind of symbol differs from a symbol's type (for example, string or boolean). Syntax: @kind <class|constant|event|external|file|function|member|mixin|module|namespace|typedef>")
    ("lends" . "Documents all the members of an object literal as if they were members of a symbol with the given name. Syntax: @lends <namepath>")
    ("license" . "Identifies the software license that applies to any portion of your code. Syntax: @license <identifier>")
    ("link" . "Creates link to the namepath or URL specified. Using {@link} tag, link text can be provided using one of several different formats. Syntax: {@link namepathOrURL} | [link text]{@link namepathOrURL} | {@link namepathOrURL|link text} | {@link namepathOrURL link text (after space)}")
    ("linkcode" . "Synonym of @link, but forces the link's text to use a monospace font.")
    ("linkplain" . "Synonym of @link, but forces the link's text to appear as normal text, without a monospace font.")
    ("listens" . "Indicates that a symbol listens for the specified event. The @event tag is uded to document the event's content. Syntax: @listens <eventName>")
    ("member" . "Identifies any member that does not have a more specialized kind, such as \"class\", \"function\", or \"constant\". A member can optionally have a type as well as a name. Syntax: @member [<type>] [<name>]")
    ("memberOf" . "Identifies a member symbol that belongs to a parent symbol. By default, the @memberof tag documents member symbols as static members. For inner and instance members, scoping punctuation can be used after the namepath, or  the @inner or @instance tag can be added. Syntax: @memberof <parentNamepath>")
    ("memberOf!" . "Synonym of @memberOf, except it forces the object to be documented as belonging to a specific parent even if it appears to have a different parent.")
    ("method" . "Synonym of @function. Syntax: @method [<FunctionName>]")
    ("mixes" . "Indicates that the current object mixes in all the members from OtherObjectPath, which is a @mixin. Syntax: @mixes <OtherObjectPath>")
    ("mixin" . "Provides functionality that is intended to be added to other objects. If desired, the @mixin tag may be added to indicate that an object is a mixin. The @mixes tag may than be added to objects that use the mixin. Syntax: @mixin [<MixinName>]")
    ("module" . "Marks the current file as being its own module. All symbols in the file are assumed to be members of the module unless documented otherwise. Syntax: @module [[{<type>}] <moduleName>]")
    ("name" . "Forces JSDoc to associate the remainder of the JSDoc comment with the given name, ignoring all surrounding code. This tag is best used in \"virtual comments\" for symbols that are not readily visible in the code, such as methods that are generated at runtime. Syntax: @name <namePath>")
    ("namespace" . "Indicates that an object creates a namespace for its members. Syntax: @namespace [{<type>}] <SomeName>")
    ("override" . "Indicates that a symbol overrides a symbol with the same name in a parent class. Syntax: @override")
    ("overview" . "Synonym of @file. Syntax: @overview <file description>")
    ("param" . "Provides the name, type, and description of a function parameter Syntax: @param [{<type>}] <name> [- <description>]")
    ("private" . "Marks a symbol as private, or not meant for general use (-p command line option to include these). Synonym of \"@access private\". Syntax: @private")
    ("property" . "Is a way to easily document a list of static properties of a class, namespace or other object within its doclet.")
    ("protected" . "Marks a symbol as protected. Typically, this tag indicates that a symbol is only available, or should only be used, within the current module (-a/--access command-line option to include these). Synonym of \"@access protected\". Syntax: @protected")
    ("public" . "Indicates that a symbol should be documented as if it were public. By default, JSDoc treats all symbols as public. It doesn't affect the symbol scope. The @instance, @static, and @global tags may be used to change a symbol's scope. Synonym of \"@access public\". Syntax: @public")
    ("readonly" . "Indicates that a symbol is intended to be read-only. Note this is for the purpose of documentation only. Syntax: @readonly")
    ("requires" . "Documents that a module is needed to use this code. Syntax: @requires <someModuleName>")
    ("return" . "Synonym of @returns. Syntax: @return {<type>} [<description]")
    ("returns" . "Describe the return value of a function. Syntax: @returns {<type>} [<description]")
    ("see" . "Refers to another symbol or resource that may be related to the one being documented. Syntax: @see <namepath> | @see <text>")
    ("since" . "Indicates that a class, method, or other symbol was added in a specific version. Syntax: @since <versionDescription>")
    ("static" . "ndicates that a symbol is contained within a parent and can be accessed without instantiating the parent. Using the @static tag will override a symbol's default scope. Syntax: @static")
    ("summary" . "Is a shorter version of the full description. It can be added to any doclet. Syntax: @summary Summary goes here.")
    ("this" . "Indicates what the this keyword refers to when used within another symbol. Syntax: @this <namePath>")
    ("throws" . "Documents an error that a function might throw. It may be used more than once. Syntax: @throws free-form description | @throws {<type>} | @throws {<type>} free-form description")
    ("todo" . "Documents tasks to be completed for some part of code. It may be used more than once. Syntax: @todo text describing thing to do.")
    ("tutorial" . "Inserts a link to a tutorial file that is provided as part of the documentation. It may be used more than once. It can be used inline. Syntax: @tutorial tutorialID")
    ("type" . "Provides a type expression identifying the type of value that a symbol may contain, or the type of value returned by a function. Syntax: @type {typeName}")
    ("typedef" . "Is useful for documenting custom types, particularly to refer to them repeatedly. These types can then be used within other tags expecting a type, such as @type or @param. Syntax: @typedef [<type>] <namepath>")
    ("var" . "Synonym of @member. Syntax: @var [<type>] [<name>]")
    ("variation" . "Helps distinguish between different symbols with the same longname. Syntax: @variation <variationNumber>")
    ("version" . "Documents the version of an item. The text following the @version tag will be used to denote the version of the item. Syntax: @version <version>")
    ("virtual" . "Synonym for @abstract."))
  "JsDoc tag list
This list contains tag name and its description")

(defvar js-doc-file-doc-lines
  '(js-doc-top-line
    " * @fileOverview\n"
    " * @name %F\n"
    " * @author %a\n"
    " * @license %l\n"
    js-doc-bottom-line)
  "JsDoc style file document format.
When the `js-doc-insert-file-doc' is called,
each lines in a list will be formatted by `js-doc-format-string'
and inserted to the top of current buffer.")

(defvar js-doc-format-string-alist
  '(("%F" . (buffer-name))
    ("%P" . (buffer-file-name))
    ("%a" . js-doc-author)
    ("%l" . js-doc-license)
    ("%d" . (current-time-string))
    ("%p" . js-doc-current-parameter-name)
    ("%f" . js-doc-current-function-name))
  "Format and value pair
Format will be replaced its value in `js-doc-format-string'")

;;; Lines

;; %F => file name
;; %P => file path
;; %a => author name
;; %d => current date
;; %p => parameter name
;; %f => function name

(defcustom js-doc-top-line "/**\n"
  "top line of the js-doc style comment."
  :group 'js-doc)

(defcustom js-doc-description-line" * \n"
  "description line."
  :group 'js-doc)

(defcustom js-doc-bottom-line " */\n"
  "bottom line."
  :group 'js-doc)

;; formats for function-doc

(defcustom js-doc-parameter-line " * @param {} %p\n"
  "parameter line.
 %p will be replaced with the parameter name."
  :group 'js-doc)

(defcustom js-doc-return-line " * @returns {} \n"
  "return line."
  :group 'js-doc)

(defcustom js-doc-throw-line " * @throws {} \n"
  "bottom line."
  :group 'js-doc)

;; ========== Regular expresisons ==========

(defcustom js-doc-return-regexp "return "
  "regular expression of return
When the function body contains this pattern,
js-doc-return-line will be inserted"
  :group 'js-doc)

(defcustom js-doc-throw-regexp "throw"
  "regular expression of throw
When the function body contains this pattern,
js-doc-throw-line will be inserted"
  :group 'js-doc)

(defcustom js-doc-document-regexp "^\[ 	\]*\\*[^//]"
  "regular expression of JsDoc comment
When the string ahead of current point matches this pattarn,
js-doc regards current state as in JsDoc style comment"
  :group 'js-doc)

;;; Main codes:

;; from smart-compile.el
(defun js-doc-format-string (fmt)
  "Format given string and return its result

%F => file name
%P => file path
%a => author name
%d => current date
%p => parameter name
%f => function name
"
  (let ((case-fold-search nil))
    (dolist (pair js-doc-format-string-alist fmt)
      (when (string-match (car pair) fmt)
        (setq fmt (replace-match (eval (cdr pair)) t nil fmt))))))

(defun js-doc-tail (list)
  "Return the last cons cell of the list"
  (if (cdr list)
      (js-doc-tail (cdr list))
    (car list)))

(defun js-doc-pick-symbol-name (str)
  "Pick up symbol-name from str"
  (js-doc-tail (delete "" (split-string str "[^a-zA-Z0-9_$]"))))

(defun js-doc-block-has-regexp (begin end regexp)
  "Return t when regexp matched the current buffer string between begin-end"
  (save-excursion
    (goto-char begin)
    (and t
         (re-search-forward regexp end t 1))))

;;;###autoload
(defun js-doc-insert-file-doc ()
  "Insert specified-style comment top of the file"
  (interactive)
  (goto-char 1)
  (dolist (line-format js-doc-file-doc-lines)
    (insert (js-doc-format-string (eval line-format)))))

(defun js-doc--beginning-of-defun ()
  ;; prevent odd behaviour of beginning-of-defun
  ;; when user call this command in the certain comment,
  ;; the cursor skip the current function and go to the
  ;; outside block
  (end-of-line)
  (while (or (js-doc-in-comment-p (point))
             (js-doc-blank-line-p (point)))
    (forward-line -1)
    (end-of-line))
  (end-of-line)
  (beginning-of-defun))

(defun js-doc--parse-function-params (from to)
  (mapcar #'js-doc-pick-symbol-name
          (split-string (buffer-substring-no-properties from to) ",")))

(defun js-doc--function-doc-metadata ()
  "Parse the function's metadata for use with JsDoc.
The point should be at the beginning of the function,
which is accomplished with js-doc--beginning-of-defun."
  (interactive)
  ;; Parse function info
  (let ((metadata '())
        (params '())
        from
        to
        begin
        end)
    (save-excursion
      (setq from (search-forward "(" nil t)
            to (1- (search-forward ")" nil t)))

      ;; Now we got the string between ()
      (when (> to from)
        (add-to-list
         'metadata
         `(params . ,(js-doc--parse-function-params from to))))

      ;; begin-end contains whole function body
      (setq begin (search-forward "{" nil t)
            end (scan-lists (1- begin) 1 0))

      ;; return / throw
      (when (js-doc-block-has-regexp begin end js-doc-return-regexp)
        (add-to-list 'metadata `(returns . t)))

      (when (js-doc-block-has-regexp begin end js-doc-throw-regexp)
        (add-to-list 'metadata `(throws . t)))

      metadata)))

;;;###autoload
(defun js-doc-insert-function-doc ()
  "Insert JsDoc style comment of the function
The comment style can be custimized via `customize-group js-doc'"
  (interactive)
  (js-doc--beginning-of-defun)

  ;; Parse function info
  (let ((metadata (js-doc--function-doc-metadata))
	(document-list '())
  (description-marker (make-marker))
	from)
    (save-excursion
    ;; params
    (dolist (param (cdr (assoc 'params metadata)))
      (setq js-doc-current-parameter-name param)
      (add-to-list 'document-list
		   (js-doc-format-string js-doc-parameter-line) t))
    ;; return / throw
    (when (assoc 'returns metadata)
      (add-to-list 'document-list
		   (js-doc-format-string js-doc-return-line) t))
    (when (assoc 'throws metadata)
      (add-to-list 'document-list
		   (js-doc-format-string js-doc-throw-line) t))
    ;; end
    (add-to-list 'document-list
		 (js-doc-format-string js-doc-bottom-line) t)
    ;; Insert the document
    (setq from (point))                 ; for indentation

    ;; put document string into document-list
    (insert (js-doc-format-string js-doc-top-line))
    (insert (js-doc-format-string js-doc-description-line))

    (set-marker description-marker (1- (point)))

    (dolist (document document-list)
      (insert document))

    ;; Indent
    (indent-region from (point)))

    (goto-char description-marker)
    (set-marker description-marker nil)))

;;;###autoload
(defun js-doc-insert-function-doc-snippet ()
  "Insert JsDoc style comment of the function with yasnippet."
  (interactive)

  (with-eval-after-load 'yasnippet
    (js-doc--beginning-of-defun)

    (let ((metadata (js-doc--function-doc-metadata))
          (field-count 1))
      (yas-expand-snippet
       (concat
        js-doc-top-line
        " * ${1:Function description.}\n"
        (mapconcat (lambda (param)
                     (format
                      " * @param {${%d:Type of %s}} %s - ${%d:Parameter description.}\n"
                      (incf field-count)
                      param
                      param
                      (incf field-count)))
                   (cdr (assoc 'params metadata))
                   "")
        (when (assoc 'returns metadata)
          (format
           " * @returns {${%d:Return Type}} ${%d:Return description.}\n"
           (incf field-count)
           (incf field-count)))
        (when (assoc 'throws metadata)
          (format
           " * @throws {${%d:Exception Type}} ${%d:Exception description.}\n"
           (incf field-count)
           (incf field-count)))
        js-doc-bottom-line)))))

;; http://www.emacswiki.org/emacs/UseIswitchBuffer
(defun js-doc-icompleting-read (prompt collection)
  (let ((iswitchb-make-buflist-hook
	 #'(lambda ()
             (setq iswitchb-temp-buflist collection))))
    (iswitchb-read-buffer prompt nil nil)))

(defun js-doc-make-tag-list ()
  (let ((taglist '()))
    (dolist (tagpair js-doc-all-tag-alist)
      (add-to-list 'taglist (car tagpair)))
    (reverse taglist)))

(defun js-doc-blank-line-p (p)
  "Return t when the line at the current point is blank line"
  (save-excursion (eql (progn (beginning-of-line) (point))
		       (progn (end-of-line) (point)))))

(defun js-doc-in-comment-p (p)
  "Return t when the point p is in the comment"
  (save-excursion
    (let (begin end)
      (beginning-of-line)
      (setq begin (point))
      (end-of-line)
      (setq end (point))
      (or (js-doc-block-has-regexp begin end "//")
          (js-doc-block-has-regexp begin end "/\\*")))))

(defun js-doc-in-document-p (p)
  "Return t when the point p is in JsDoc document"
  ;; Method 1 :: just search for the JsDoc
  (save-excursion
    (goto-char p)
    (and (search-backward "/**" nil t)
	 (not (search-forward "*/" p t)))))

;;;###autoload
(defun js-doc-insert-tag ()
  "Insert a JsDoc tag interactively."
  (interactive)
  (insert "@")
  (when (js-doc-in-document-p (point))
    (let ((tag (completing-read "Tag: " (js-doc-make-tag-list)
				nil nil nil nil nil)))
      (unless (string-equal tag "")
	(insert tag " ")))))

;;;###autoload
(defun js-doc-describe-tag ()
  "Describe the JsDoc tag"
  (interactive)
  (let ((tag (completing-read "Tag: " (js-doc-make-tag-list)
			      nil t (thing-at-point 'word) nil nil))
	(temp-buffer-show-hook #'(lambda ()
				  (fill-region 0 (buffer-size))
				  (fit-window-to-buffer))))
    (unless (string-equal tag "")
      (with-output-to-temp-buffer "JsDocTagDescription"
	(princ (format "@%s\n\n%s"
		       tag
		       (cdr (assoc tag js-doc-all-tag-alist))))))))

(provide 'js-doc)

;;; js-doc.el ends here

