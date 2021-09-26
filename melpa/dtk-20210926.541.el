;;; dtk.el --- access SWORD content via diatheke
;;
;; Copyright (C) 2017-2021 David Thompson
;;
;; Author: David Thompson
;; Keywords: hypermedia
;; Package-Version: 20210926.541
;; Package-Commit: f6a94d86263041f9a172cb7df90e00d1ec44604a
;; Package-Requires: ((emacs "24.4") (cl-lib "0.6.1") (dash "2.12.0") (seq "1.9") (s "1.9"))
;; Version: 0.2
;; URL: https://github.com/dtk01/dtk.el

;;; Commentary:
;;
;; This package provides access to SWORD content via diatheke, facilitating
;; reading Biblical text or other diatheke-accessible material in Emacs.
;;
;; To browse a particular text in a dedicated buffer, use `dtk'. To insert text
;; directly, use `dtk-bible'.

;;; Code:


;;;; Dependencies
(require 'cl-lib)
(require 'dash)
(require 's)
(require 'seq)
(require 'subr-x)

;;;; Customization
;; User configurable variables:
(defgroup dtk nil
  "Read Biblical text and other SWORD resources through diatheke."
  :prefix "dtk-"
  :group 'convenience)

;;;;; General Settings
(defcustom dtk-program "diatheke"
  "Front-end to SWORD library.
Only diatheke is supported at the moment."
  :type 'string)

(defcustom dtk-word-wrap t
  "Non-nil means to use word-wrapping for continuation lines."
  :type 'boolean)

(defcustom dtk-compact-view t
  "Show verses in compact view.
If nil, display all verses as if they're retrieved independently, e.g:

John 1:1: In the beginning was the Word, and the Word was with God, and the Word was God.
John 1:2: The same was in the beginning with God.
John 1:3: All things were made by him; and without him was not any thing made that was made.

If non-nil, hide repeated \"chapter\" for all verses except the first one, e.g:

John 1:1 In the beginning was the Word, and the Word was with
God, and the Word was God. 2 The same was in the beginning with
God. 3 All things were made by him; and without him was not any
thing made that was made."
  :type 'boolean)

(defcustom dtk-buffer-name "*dtk*"
  "Name of buffer for displaying text.")

(defcustom dtk-dict-buffer-name "*dtk-dict*"
  "Name of buffer for displaying dictionary entries and references.")

(defcustom dtk-search-buffer-name "*dtk-search*"
  "Name of buffer for displaying search results.")

(defvar dtk-diatheke-output-format nil
  "Opportunity for user to specify desired the output format when
  calling diatheke. Intended to be used in conjunction with
  dtk-preserve-diatheke-output-p.")

(defvar dtk-preserve-diatheke-output-p nil
  "When true, do not attempt to parse or format, but preserve diatheke
  output ``as-is''.")

;;;;; Biblical Text defaults
;; TODO: "module" is a more general term. Rename it properly.
(defcustom dtk-module nil
  "Module currently in use.")

(defcustom dtk-module-category nil
  "Module category last selected by the user.")

;;;;; Internal variables
(defcustom dtk--recent-book nil
  "Most recently used book when reading user's completion."
  ;; Normally we read the same book during a short period of time, so save
  ;; latest input as default. On the contrary, chapter and verses are short
  ;; numeric input, so we skip them.
  )

(defvar dtk-bible-book nil
  "DTK-BIBLE-BOOK specifies the last book value passed to the
  retriever for a module in the \"Biblical Texts\" category.")

(defvar dtk-bible-chapter-verse nil
  "DTK-BIBLE-CHAPTER-VERSE specifies the last chapter and verse values
  passed to the retriever for a module in the \"Biblical Texts\"
  category.")

(defvar dtk-inserter 'dtk-insert-verses
  "A function which accepts a single argument, the parsed content. The
  current buffer is used. The inserter is only invoked if dtk-parser
  is not NIL.")

(defvar dtk-retriever 'dtk-bible-retriever
  "A function which accepts a single argument, DESTINATION. Output is
  sent to DESTINATION. DESTINATION should be a buffer. The retriever
  should honor DTK-DIATHEKE-OUTPUT-FORMAT.")

(defvar dtk-parser 'dtk-bible-parser
  "A function which accepts a string, parses it, and returns a list of
  plists representing the parsed content.")

;;;;; Constants
(defconst dtk-books
  '("Genesis" "Exodus" "Leviticus" "Numbers" "Deuteronomy" "Joshua" "Judges" "Ruth" "I Samuel" "II Samuel" "I Kings" "II Kings" "I Chronicles" "II Chronicles" "Ezra" "Nehemiah" "Esther" "Job" "Psalms" "Proverbs" "Ecclesiastes" "Song of Solomon" "Isaiah" "Jeremiah" "Lamentations" "Ezekiel" "Daniel" "Hosea"  "Joel" "Amos" "Obadiah" "Jonah" "Micah" "Nahum" "Habakkuk" "Zephaniah" "Haggai" "Zechariah" "Malachi"
    "Matthew" "Mark" "Luke" "John" "Acts" "Romans" "I Corinthians" "II Corinthians" "Galatians" "Ephesians" "Philippians" "Colossians" "I Thessalonians" "II Thessalonians" "I Timothy" "II Timothy" "Titus" "Philemon" "Hebrews" "James" "I Peter" "II Peter" "I John" "II John" "III John" "Jude"
    "Revelation of John" ;"Revelations"
    )
  "List of strings representing books of the Bible.")

(defconst dtk-books-regexp
  (regexp-opt dtk-books)
  "Regular expression aiming to match a member of DTK-BOOKS.")

;;; Functions
;;;###autoload
(defun dtk ()
  "If the buffer specified by DTK-BUFFER-NAME already exists, move to it. Otherwise, generate the buffer and then provide a prompt to insert content from the current module into the buffer."
  (interactive)
  (cond ((dtk-buffer-exists-p)
	 (switch-to-buffer dtk-buffer-name))
	(t
	 (if (not (dtk-modules-in-category dtk-module-category))
	     (message "Content is not installed for the selected module category, %s. Install content or change the module category." dtk-module-category)
	   (dtk-init)
	   (dtk-go-to)))))

(defun dtk-check-for-text-obesity ()
  "Intended for use with handling incoming text from diatheke invocation. If text is of a length likely to trigger a substantial delay due to parsing, confirm the intent of the user. Return a true value if text length is clearly not excessive or if the user has explicitly indicated a desire to process a text of substantial length."
  (let ((sane-raw-length 100000))
    (or (< (point) sane-raw-length)
	dtk-preserve-diatheke-output-p
	(if (y-or-n-p "That's a large chunk of text. Are you sure you want to proceed? ")
	    t
	  (progn
	    (message "Okay")
	    nil)))))

(defun dtk-diatheke (query-key module destination &optional diatheke-output-format searchp)
  "Invoke diatheke using CALL-PROCESS. Return value undefined. QUERY-KEY is a string or a list (e.g., '(\"John\" \"1:1\")). See the docstring for CALL-PROCESS for a description of DESTINATION. DIATHEKE-OUTPUT-FORMAT is either NIL or a keyword specifying the diatheke output format. Supported keyword values are :osis or :plain."
  (let ((call-process-args (list dtk-program
				 nil
				 destination
				 t ; redisplay buffer as output is inserted
				 ;; ARGS
				 "-b" module)))
    (cond (searchp
	   ;; diatheke -b module_name -s regex|multi‐word|phrase [-r  search_range] [-l locale] -k search_string
	   (setf call-process-args (append call-process-args '("-s" "phrase"))))
	  (diatheke-output-format
	   (unless (eq diatheke-output-format :kludge)
	     (setf call-process-args
		   (append call-process-args
			   (list
			    "-o" (cl-case diatheke-output-format
				   (:osis "nfmslx")
				   (:plain "n"))
			    "-f" (cl-case diatheke-output-format
				   (:osis "OSIS")
				   (:plain "plain"))))))))
    (setq call-process-args (append call-process-args '("-k") (cond ((stringp query-key)
								     (list query-key))
								    (t query-key))))
    (apply 'call-process call-process-args)))

(defun dtk-diatheke-string (query-key module &optional diatheke-output-format)
  "Return a string."
  (with-temp-buffer
    (dtk-diatheke query-key module t diatheke-output-format)
    (buffer-string)))

(defun dtk-dict-raw-lines (key module)
  "Perform a dictionary lookup using the dictionary module MODULE with query key KEY (a string). Return a list of lines, each corresponding to a line of output from invocation of diatheke."
  ;; $ diatheke -b "StrongsGreek" -k 3
  (s-lines (dtk-diatheke-string key module)))

(defun dtk-follow ()
  "Look for a full citation under point. If point is indeed at a full citation, insert the corresponding verse into dtk buffer directly after citation. If point is not at a full citation, do nothing."
  (interactive)
  (dtk-to-start-of-full-citation)
  (let ((book-chapter-verse (dtk-parse-citation-at-point)))
    (dtk-go-to (elt book-chapter-verse 0)
	       (elt book-chapter-verse 1)
	       (elt book-chapter-verse 2))))

(defun dtk-go-to (&optional book chapter verse)
  "Take a cue from the current module, if specified; otherwise query
the user for the desired module. Use the values specified in
DTK-MODULE-MAP to navigate to the desired text."
  (interactive)
  (let* ((completion-ignore-case t)
         (final-module  (or (if (or current-prefix-arg ; Called with prefix argument
				    (not dtk-module))
                                (completing-read "Module: " (dtk-module-names
                                                             dtk-module-category)
                                                 nil t nil nil '(nil)))
                            dtk-module)))
    (with-dtk-module final-module
      (cond ((dtk-module-available-p dtk-module)
	     (let ((retrieve-setup (or (dtk-module-map-get dtk-module :retrieve-setup)
				       (dtk-module-map-get (dtk-module-get-category-for-module dtk-module) :retrieve-setup))))
	       (if retrieve-setup (funcall retrieve-setup)))
	     (dtk-view-text
	      t				; clear-buffer-p
	      t
	      dtk-module))
	    (t
	     (message "Module %s is not available. Use dtk-select-module (bound to '%s' in dtk mode) to select a different module. Available modules include %s"
		      dtk-module
		      (key-description (elt (where-is-internal 'dtk-select-module dtk-mode-map) 0))
		      (dtk-module-names dtk-module-category))
	     nil)))))

(defmacro with-dtk-module (module &rest body)
  "Temporarily consider module MODULE as the default module."
  (declare (debug t)
	   (indent defun))
  `(let ((original-module dtk-module))
     (dtk-set-module ,module)
     ,@body
     (dtk-set-module original-module)))

(defun dtk-bible (&optional book chapter verse dtk-buffer-p)
  "Query diatheke and insert text.
With `C-u' prefix arg, change module temporarily.

Text is inserted in place, unless DTK-BUFFER-P is true.

BOOK is a string. CHAPTER is an integer. VERSE is an integer. If
BOOK is not specified, rely on interacting via the minibuffer to
obtain book, chapter, and verse."
  (interactive)
  (when (not (dtk-biblical-texts))
    (error "One or more Biblical texts must be installed first"))
  (let* ((completion-ignore-case t)
         (final-module  (or (if current-prefix-arg ;; Called with prefix argument
                                (completing-read "Module: " (dtk-module-names
                                                             dtk-module-category)
                                                 nil t nil nil '(nil)))
                            dtk-module))
         (final-book    (or book
                            (setq dtk--recent-book
                                  (completing-read "Book: " dtk-books nil nil nil nil dtk--recent-book))))
         (final-chapter (or (when chapter (number-to-string chapter))
                            (read-from-minibuffer "Chapter: ")))
         (final-verse   (or (when verse (number-to-string verse))
                            (read-from-minibuffer "Verse: ")))
         (chapter-verse (concat final-chapter ":" final-verse)))
    ;; If dtk-buffer-p is true, insert text in the default dtk buffer
    (when dtk-buffer-p
      (cond ((not (dtk-buffer-exists-p))
	     (dtk-init))
	    (t
	     (switch-to-buffer dtk-buffer-name))))
    ;; Expose these values to the retriever
    (setq dtk-bible-book final-book)
    (setq dtk-bible-chapter-verse chapter-verse)
    (with-dtk-module final-module
      (dtk-retrieve-parse-insert
       (current-buffer)))
    ))

(defun dtk-bible--insert-using-diatheke (book chapter-verse &optional module diatheke-output-format)
  "Insert content specified by BOOK and CHAPTER-VERSE into the current buffer. CHAPTER-VERSE is a string of the form CC:VV (chapter number and verse number separated by the colon character).
Optional argument MODULE specifies the module to use."
  (unless diatheke-output-format
    (setq diatheke-output-format :plain))
  (let ((module (or module dtk-module)))
    (insert
     (with-temp-buffer
       (dtk-diatheke (list book chapter-verse) module t diatheke-output-format nil)
       (cond ((dtk-check-for-text-obesity)
	      ;; Provides user the option to work with "raw" diatheke output
	      (unless dtk-preserve-diatheke-output-p
		;; Assume diatheke emits text and then emits
		;; - zero or more empty lines followed by
		;; - a line beginning with the colon character succeeded by the text of last verse (w/o reference) followed by
		;; - a single line beginning with the ( character indicating the module (e.g., "(ESV2011)")
		;; - followed by a zero or more newlines

		;; Post-process texts
		;; Search back and remove (<module name>)
		(let ((end-point (point)))
		  (re-search-backward "^(.*)" nil t 1)
		  (delete-region (point) end-point))
		;; Search back and remove duplicate text of last verse and the preceding colon
		(let ((end-point (point)))
		  (re-search-backward "^:" nil t 1)
		  (delete-region (point) end-point))
		;; Parse text
		(let ((raw-diatheke-text (buffer-substring (point-min) (point-max))))
		  ;; PARSED-LINES is a list where each member has the form
		  ;; (:book "John" :chapter 1 :verse 1 :text (...))
		  (let ((parsed-lines (cl-case diatheke-output-format
					(:osis (dtk--parse-osis-xml-lines raw-diatheke-text))
					(:plain (dtk-sto--diatheke-parse-text raw-diatheke-text)))))
		    ;; replace diatheke output w/text from parsed-lines
		    (delete-region (point-min) (point-max))
		    (dtk-insert-verses parsed-lines))))
	      ;; Return contents of the temporary buffer
	      (buffer-string))
	     (t ""))
       )))
  t)

(defun dtk-bible-parser (raw-string)
  "Parse the string RAW-STRING. Return the parsed content as a plist."
  (cond ((member dtk-diatheke-output-format '(:kludge :osis :plain))
	 ;; Parsing can trigger an error (most likely XML parsing)
	 (condition-case nil
	     (cl-case dtk-diatheke-output-format
	       (:osis (dtk--parse-osis-xml-lines raw-string))
	       (:plain (dtk-sto--diatheke-parse-text raw-string))
	       (:kludge (dtk--parse-osis-xml-lines raw-string))
	       )
	   (error
	    (display-warning 'dtk
			     (format "dtk failed relying on %s format" dtk-diatheke-output-format)
			     :warning)
	    ;; Calling function should attempt to degrade gracefully
	    ;; and try simple format if dtk-diatheke-output-format
	    ;; isn't :plain
	    nil			       ; return NIL upon parse failure
	    ))
	 )
	(t (error "Value of dtk-diatheke-output-format is problematic"))))

(defun dtk-bible-retriever (destination)
  "Insert retrieved content in the buffer specified by DESTINATION."
  ;; Using :osis as a default is problematic since invoking `-f OSIS`
  ;; with diatheke yields output that has a variety of issues - e.g.,
  ;; see http://tracker.crosswire.org/browse/MODTOOLS-105.
  (unless dtk-diatheke-output-format
    (setq dtk-diatheke-output-format :kludge))
  (with-current-buffer destination
    (insert
     (with-temp-buffer
       (dtk-diatheke (list dtk-bible-book
			   dtk-bible-chapter-verse)
		     dtk-module
		     t
		     dtk-diatheke-output-format
		     nil)
       (when (dtk-check-for-text-obesity)
	 (unless dtk-preserve-diatheke-output-p
	   (dtk-bible-retriever--post-process)))
       (buffer-string)))))

(defun dtk-bible-retriever--post-process ()
  "Post-processing directly after insertion of text supplied via
diatheke."
  ;; Removes diatheke's quirky addition of parenthesized indications of the module name after the requested text.
  (let ((end-point (point)))
    (re-search-backward "^(.*)" nil t 1)
    (delete-region (point) end-point))
  ;; Search back and remove duplicate text of last verse and the preceding colon
  (let ((end-point (point)))
    (re-search-backward "^:" nil t 1)
    (delete-region (point) end-point)))

(defun dtk-bible-retrieve-setup (&optional book chapter verse dtk-buffer-p)
  "BOOK is a string. CHAPTER is an integer. VERSE is an integer. If
BOOK is not specified, rely on interacting via the minibuffer to
obtain book, chapter, and verse. Set DTK-BIBLE-BOOK and
DTK-BIBLE-CHAPTER-VERSE."
  (interactive)
  (let* ((completion-ignore-case t)
         (final-book    (or book
                            (setq dtk--recent-book
                                  (completing-read "Book: " dtk-books nil nil nil nil dtk--recent-book))))
         (final-chapter (or (when chapter (number-to-string chapter))
                            (read-from-minibuffer "Chapter: ")))
         (final-verse   (or (when verse (number-to-string verse))
                            (read-from-minibuffer "Verse: ")))
         (chapter-verse (concat final-chapter ":" final-verse)))
    ;; Expose these values to the retriever
    (setq dtk-bible-book final-book)
    (setq dtk-bible-chapter-verse chapter-verse)
    ))

(defun dtk-other ()
  "Placeholder anticipating possibility of using diatheke to access content distinct from Biblical texts."
  (error "Unsupported"))

(defun dtk-retrieve-parse-insert (insert-into)
  "Invoke DTK-RETRIEVER, anticipating that the text of interest will
be inserted into the buffer specified by INSERT-INTO. If
DTK-PRESERVE-DIATHEKE-OUTPUT-P is true, preserve the retrieved text.
If DTK-PRESERVE-DIATHEKE-OUTPUT-P is NIL, parse the retrieved text
using DTK-PARSER. Once parsed, invoke DTK-INSERTER with the value
returned by DTK-PARSER (presumably the parse representation of the
text), replacing the originally-inserted text with that generated by
DTK-INSERTER."
  (let ((point-start (point)))
    (funcall dtk-retriever insert-into)
    (let ((point-end (point)))
      (when (and dtk-parser (not dtk-preserve-diatheke-output-p))
	(let ((raw-content (buffer-substring-no-properties point-start
							   point-end)))
	  ;; sanity check(s) for raw-content
	  ;; - e.g., if it is "", something has gone awry
	  (cond ((and (stringp raw-content) (> (length raw-content) 0))
		 (let ((parsed-content (funcall dtk-parser raw-content)))
		   (cond (parsed-content
			  (kill-region point-start point-end)
			  (funcall dtk-inserter parsed-content))
			 (t
			  (display-warning
			   :warning
			   "Parsing yielded nothing. Is this expected behavior?"
			   )
			  ))))
		(t
		 (error "Something went awry"))))))))

;;;###autoload
(defun dtk-search (&optional word-or-phrase)
  "Search for the text string WORD-OR-PHRASE. If WORD-OR-PHRASE is NIL, prompt the user for the search string."
  (interactive)
  (let ((word-or-phrase (or word-or-phrase (read-from-minibuffer "Search: ")))
	(search-buffer (dtk-ensure-search-buffer-exists)))
    (dtk-clear-search-buffer)
    (dtk-switch-to-search-buffer)
    (dtk-search-mode)
    (dtk-diatheke word-or-phrase dtk-module t nil t)
    ))

(defun dtk-search-follow ()
  "Populate the dtk buffer with the text corresponding to the citation at point."
  (interactive)
  ;; The most likely desired behavior is to open the dtk buffer
  ;; alongside the dtk-search buffer and to keep the focus in
  ;; dtk-search buffer
  (dtk-clear-dtk-buffer)
  (dtk-follow)
  (switch-to-buffer-other-window dtk-search-buffer-name)
  )

;;;
;;; dtk modules/books
;;;

(defun dtk-bible-module-available-p (module)
  "Indicate whether the module MODULE is available. MODULE is a string."
  (dtk-module-available-p module "Biblical Texts"))

(defun dtk-biblical-texts ()
  "Return a list of module names associated with the 'Biblical Texts' category."
  (dtk-modules-in-category "Biblical Texts"))

(defun dtk-commentary-module-available-p (module)
  "Return an indication of whether module MODULE is both available and associated with the 'Commentaries' category."
  (dtk-module-available-p module "Commentaries"))

(defun dtk-module-available-p (module-name &optional module-category)
  "Test whether the module specified by MODULE-NAME is locally available. MODULE-CATEGORY is either NIL or a string such as 'Biblical Texts' or 'Commentaries'. If NIL, test across all modules (don't limit by module category)."
  (member module-name (dtk-module-names (or module-category :all))))

(defun dtk-module-category (category)
  "CATEGORY is a string such as 'Biblical Texts' or 'Commentaries'."
  (assoc category (dtk-modulelist)))

(defun dtk-module-get-category-for-module (module)
  (cl-loop
   for modulelist-entry in (dtk-modulelist)
   if (member module (dtk-module-names-from-modulelist-entry modulelist-entry))
   do (cl-return (cl-first modulelist-entry))))

(defvar dtk-module-last-selection nil
  "A plist specifying the last selection of a module by module category.")

(defvar dtk-module-map
  '(
    ;; key: string for module or module category
    ("Biblical Texts" :retriever dtk-bible-retriever
                      :parser dtk-bible-parser
                      :inserter dtk-insert-verses
                      :retrieve-setup dtk-bible-retrieve-setup)
    ;("Daily" dtk-daily-retrieve dtk-daily-parse dtk-daily-insert)
    )
  "DTK-MODULE-MAP is an alist where each key is a string corresponding
either to a module category or a module. Modules and module categories
are specified with string suchs as 'KJV', 'ESV2011', 'Biblical Texts',
or 'Commentaries'. Each entry maps a module or module category to a
key-value store which specifies a retriever, a parser, an inserter,
and/or a mode. The mode, if specified, is specified by the
corresponding symbol. :RETRIEVE-SETUP, if specified, specifies a
funcallable entity to invoke prior to retrieving the text."
  )

(defun dtk-module-map-entry (module-name)
  "Return the member of DTK-MODULE-MAP describing the module specified by MODULE-NAME."
  (assoc module-name dtk-module-map))

(defun dtk-module-map-get (module-spec key)
  "Return the specified value, if any, associated with the module specified by MODULE-SPEC."
  (plist-get (cl-rest (dtk-module-map-entry module-spec))
	     key))

(defun dtk-module-map-get-mode (module-spec)
  "Return the mode specification, if any, associated with the module or module category specified by MODULE-SPEC."
  (let ((mode (dtk-module-map-get module-spec :mode)))
    (cond ((not mode)
           ;; Fall back to module category if mode is not specified
           ;; for a specific module
	   (if (dtk-module-get-category-for-module module-spec)
	       (setq mode
		     (dtk-module-map-get-mode
		      (dtk-module-get-category-for-module module-spec)))))
          ;; The mode should be specified as a symbol
          ((symbolp mode)
           mode)
          (mode
           (error "%s" "The corresponding mode must be specified as a symbol.")))))

(defun dtk-module-names (module-category)
  "Return a list of strings, each corresponding to a module name within the module category specified by MODULE-CATEGORY. If MODULE-CATEGORY is :all, return all module names across all categories."
  (cond ((eq module-category :all)
	 (let ((shortnames nil))
	   (mapc #'(lambda (category-data)
		     (mapc #'(lambda (shortname-description)
			       (push (elt shortname-description 0) shortnames))
			   (cdr category-data)))
		 (dtk-modulelist))
	   shortnames))
	((stringp module-category)
	 (mapcar #'(lambda (shortname-description)
		     (elt shortname-description 0))
		 (cdr (assoc (or module-category dtk-module-category)
			     (dtk-modulelist)))))))

(defun dtk-module-remember-selection ()
  "Remember the module last selected by the user."
  (setq dtk-module-last-selection (lax-plist-put dtk-module-last-selection dtk-module-category dtk-module)))

(defun dtk-modulelist ()
  "Return an alist where each key is a string corresponding to a category and each value is a list of lists. Each value represents a set of modules. Each module is described by a list of the form (\"Nave\" \"Nave's Topical Bible\")."
  (let ((modulelist-strings (s-lines (dtk-diatheke-string '("modulelist") "system")))
	(modules-by-category nil))
    ;; construct list with the form ((category1 module11 ...) ... (categoryN moduleN1 ...))
    (dolist (x modulelist-strings)
      (cond ((string= "" (s-trim x))	; disregard empty lines
	     nil)
	    ;; if last character in string is colon (:), assume X represents a category
	    ((= (aref x (1- (length x)))
		58)
	     (push (list (seq-subseq x 0 (1- (length x)))) modules-by-category))
	    (t
	     ;; handle "modulename : moduledescription"
	     (let ((colon-position (seq-position x 58)))
	       (let ((modulename (seq-subseq x 0 (1- colon-position)))
		     (module-description (seq-subseq x (+ 2 colon-position))))
		 (setf (elt modules-by-category 0)
		       (append (elt modules-by-category 0)
			       (list (list modulename module-description)))))))))
    modules-by-category))

(defun dtk-modules-in-category (category)
  "Return a list of module names associated with module category CATEGORY."
  (dtk-module-names-from-modulelist-entry (dtk-module-category category)))

(defun dtk-module-names-from-modulelist-entry (modulelist-entry)
  "Return a list of module names. MODULELIST-ENTRY has the form of a
member of the value returned by DTK-MODULELIST."
  (let ((module-descriptions (cdr modulelist-entry)))
    (mapcar
     #'(lambda (modulename-description)
	 (elt modulename-description 0))
     module-descriptions)))

;;;###autoload
(defun dtk-select-module-category ()
  "Prompt the user to select a module category."
  (interactive)
  (let ((module-category
         (let ((completion-ignore-case t))
           (completing-read "Module type: "
                            (dtk-modulelist)))))
    (if (and module-category
	     (not (string= module-category "")))
	(setf dtk-module-category module-category))))

;;;###autoload
(defun dtk-select-module ()
  "Prompt the user to select a module."
  (interactive)
  (let ((module (dtk-select-module-of-type "Module: " dtk-module-category)))
    (if module
	(progn
	  (dtk-set-module module)
	  (dtk-module-remember-selection))
      (message "Module not selected"))))

(defun dtk-select-module-of-type (prompt module-category)
  "Prompt the user to select a module. MODULE-CATEGORY specifies the subset of modules to offer for selection."
  (let ((completion-ignore-case t))
    (completing-read prompt
                     (dtk-module-names module-category)
                     nil
                     t
                     nil
                     nil
                     '(nil))))

(defun dtk-set-module (module)
  (setq dtk-module module)
  ;; Set retriever, parser, inserter values
  (cond ((dtk-module-map-entry module)
	 (setq dtk-parser (dtk-module-map-get module :parser))
	 (setq dtk-retriever (dtk-module-map-get module :retriever))
	 (setq dtk-inserter (dtk-module-map-get module :inserter)))
	;; Use category entry as fallback if an entry isn't present for a specific module
	((dtk-module-map-entry (dtk-module-get-category-for-module module))
	 (let ((category (dtk-module-get-category-for-module module)))
	   (setq dtk-parser (dtk-module-map-get category :parser))
	   (setq dtk-retriever (dtk-module-map-get category :retriever))
	   (setq dtk-inserter (dtk-module-map-get category :inserter))))
	(t (message "Specify parser, retriever, and inserter for the module"))
	))

;;;
;;; dtk buffers
;;;
(defun dtk-buffer-exists-p ()
  "Return an indication of whether the default dtk buffer exists."
  (get-buffer dtk-buffer-name))

(defun dtk-clear-buffer (buffer-name)
  (with-current-buffer buffer-name
    (delete-region (point-min) (point-max))))

(defun dtk-clear-dtk-buffer ()
  "Clear the dtk buffer."
  (interactive)
  (dtk-clear-buffer dtk-buffer-name))

(defun dtk-clear-search-buffer ()
  "Clear the search buffer."
  (dtk-clear-buffer dtk-search-buffer-name))

(defun dtk-init ()
  "Initialize dtk buffer, if necessary. Switch to the dtk buffer."
  (when (not (dtk-buffer-exists-p))
    (get-buffer-create dtk-buffer-name))
  ;; Switch window only when we're not already in *dtk*
  (if (not (string= (buffer-name) dtk-buffer-name))
      (switch-to-buffer-other-window dtk-buffer-name)
    (switch-to-buffer dtk-buffer-name))
  (dtk-mode)
  )

(defun dtk-ensure-search-buffer-exists ()
  "Ensure the default dtk buffer exists for conducting a search."
  (get-buffer-create dtk-search-buffer-name))

(defun dtk-set-mode ()
  "If a mode is specified for the current module, set it for the
current buffer. Fall back to the module category if a mode is not
specified for a specific module."
  (let ((mode (dtk-module-map-get-mode dtk-module)))
    (when mode
      (funcall mode))))

(defun dtk-switch-to-search-buffer ()
  "Switch to the dtk search buffer using SWITCH-TO-BUFFER."
  (switch-to-buffer dtk-search-buffer-name))

;;;
;;; interact with dtk buffers
;;;
(defun dtk-verse-inserter (book ch verse text new-bk-p new-ch-p)
  "Insert a verse associated book BOOK, chapter CH, verse number VERSE, and text TEXT. If this function is being invoked in the context of a change to a new book or a new chapter, indicate this with NEW-BK-P or NEW-CH-P, respectively."
  (let ((book-start (point)))
    (when (or (not dtk-compact-view) new-bk-p)
      (insert book #x20)
      (set-text-properties book-start (point) (list 'book book)))
    (when (or (not dtk-compact-view) new-ch-p)
      (let ((chapter-start (point)))
	(insert (int-to-string chapter)
		(if verse #x3a #x20))
	(add-text-properties (if new-ch-p
				 chapter-start
			       book-start)
			     (point)
			     (list 'book book 'chapter chapter 'font-lock-face 'dtk-chapter-number)))))
  (when verse
    (let ((verse-start (point)))
      (when dtk-verse-number-inserter
	(funcall dtk-verse-number-inserter (int-to-string verse)))
      (set-text-properties verse-start (point) (list 'book book 'chapter chapter 'verse verse))
      ;; fontify verse numbers explicitly
      (add-text-properties verse-start (point) '(font-lock-face dtk-verse-number))))
  (when text
    (let ((text-start (point)))
      (funcall dtk-verse-text-inserter text)
      ;; verse text inserter may set text properties
      (add-text-properties text-start (point) (list 'book book 'chapter chapter 'verse verse))))
  (unless dtk-compact-view
    (insert #xa)))

(defvar dtk-verse-number-inserter
  (lambda (verse-number)
    (insert verse-number #x20)))

(defun dtk-text-props-for-lemma (lemma)
  "Return text properties for LEMMA."
  (let ((strongs-refs (dtk-dict-parse-osis-xml-lemma lemma))
	(text-props nil))
    (unless strongs-refs
      (warn "Failed to handle lemma value %s" lemma))
    (cl-map nil #'(lambda (strongs-ref)
		    ;; ignore lemma components which were disregarded by DTK-DICT-PARSE-OSIS-XML-LEMMA
		    (when strongs-ref
		      (cl-destructuring-bind (strongs-number module)
			  strongs-ref
			(when dtk-show-dict-numbers (insert " " strongs-number))
			(setq text-props
			      (append
			       (list 'dict (list strongs-number module))
			       text-props)))))
	    strongs-refs)
    text-props))

(defun dtk-insert-osis-string (string)
  ;; Ensure some form of whitespace precedes a word. OSIS-ELT may be a word, a set of words (e.g., "And" or "the longsuffering"), or a bundle of punctuation and whitespace (e.g., "; ").
  (when (string-match "^[a-zA-Z]" string)
    (when (not (member (char-before) '(32 9 10 11 12 13 8220)))
      (insert #x20)))
  (insert string)
  ;; Ensure whitespace succeeds certain characters.
  (when (member (char-before) '(58))
    (insert #x20)))

(defun dtk-insert-osis-elt (osis-elt)
  (let* ((tag (pop osis-elt))
	 (attributes (pop osis-elt))
	 (children osis-elt))
    (cl-case tag
      (w
       (when children
	 ;; The example provided in the 2006 description of OSIS shows
	 ;; the "gloss" attribute used to support inclusion of
	 ;; Strong's numbers. The reality seems to be that the "lemma"
	 ;; attribute is used to support inclusion of Strong's numbers
	 ;; for Biblical texts.
	 (let ((lemma (let ((lemma-pair (assoc 'lemma attributes)))
			(if lemma-pair
			    (cdr lemma-pair)))))
	   (let ((beg (point)))
	     (dtk-simple-osis-inserter children)
	     (when lemma
	       (add-text-properties beg (point)
				    (dtk-text-props-for-lemma lemma))
	       )))))
      (divineName
       (dtk-simple-osis-inserter children))
      (transChange
       (when children
	 (let ((beg (point)))
	   (dtk-simple-osis-inserter children)
	   ;;(add-text-properties beg (point) (list 'transChange t))
	   ;;(add-text-properties beg (point) '(font-lock-face dtk-translChange-face))
	   )))
      (q				; quote
       (let ((quote-marker (let ((quote-marker-pair (assoc 'marker attributes)))
			     (if quote-marker-pair
				 (cdr quote-marker-pair)))))
	 (when quote-marker (insert quote-marker))
	 (dtk-simple-osis-inserter children)
	 ))
      ;; containers
      (div
       (let ((type (let ((type-pair (assoc 'type attributes)))
		     (if type-pair
			 (cdr type-pair)))))
	 (cond ((and
		 t		       ;dtk-honor-osis-div-paragraph-p
		 (cl-equalp type "paragraph"))
		(insert #xa)))
	 (dtk-simple-osis-inserter children)))
      (chapter
       (dtk-simple-osis-inserter children))
      (verse
       (dtk-simple-osis-inserter children))
      (l				; poetic line(s)
       (dtk-simple-osis-inserter children))
      (lg				; poetic line(s)
       (dtk-simple-osis-inserter children))
      (note
       (when nil			;dtk-show-notes-p
	 (dtk-simple-osis-inserter children)))
      ;; formatting
      (milestone
       (let ((type (let ((type-pair (assoc 'type attributes)))
		     (if type-pair
			 (cdr type-pair)))))
	 (cond ((and nil	      ;dtk-honor-osis-milestone-line-p
		     (cl-equalp type "line"))
		(insert #xa)))))
      (lb
       (when (and t			;dtk-honor-osis-lb-p
		  (insert #xa))))
      ;; indicate inability to handle this OSIS element
      (t (when nil		   ;dtk-flag-unhandled-osis-elements-p
	   (insert "!" (prin1-to-string tag) "!"))))))

(defun dtk-insert-osis-thing (osis-thing)
  "Insert verse text represented by OSIS-THING."
  (cond ((stringp osis-thing)
	 (dtk-insert-osis-string osis-thing))
	((consp osis-thing)
	 (dtk-insert-osis-elt osis-thing))
	;; indicate inability to handle this elt
	(t (insert "*" (prin1-to-string osis-thing) "*"))))

(defvar dtk-verse-text-inserter
  'dtk-simple-osis-inserter
  "Specifies function used to insert verse text.

The function is called with a single argument, CHILDREN, a list where
each member is either a string or a list representing a child element
permissible within an OSIS XML document. Consider this example
representation of a W element:

  (w ((lemma . \"strong:G1722\") (wn . \"001\")) \"In\")")

(defun dtk-simple-osis-inserter (children)
  (dolist (osis-elt children)
    (dtk-insert-osis-thing osis-elt)))

(defun dtk-insert-verses (verse-plists)
  "Insert formatted text described by VERSE-PLISTS."
  (cl-flet ()
    (let ((this-chapter nil)
	  (first-verse-plist (pop verse-plists)))
      ;; handle first verse
      (-let (((&plist :book book :chapter chapter :verse verse :text text) first-verse-plist))
	(when dtk-insert-verses-pre
	  (funcall dtk-insert-verses-pre book chapter verse verse-plists))
	(dtk-verse-inserter book chapter verse text t t)
	(setf this-chapter chapter))
      ;; Format the remaining verses, anticipating changes in chapter
      ;; number. Assume that book will not change.
      (cl-loop
       for verse-plist in verse-plists
       do (-let (((&plist :book book :chapter chapter :verse verse :text text) verse-plist))
	    (if (equal chapter this-chapter)
		(progn
		  (unless (member (char-before) '(#x20 #x0a #x0d))
		    (insert #x20)
		    (add-text-properties (1- (point))
					 (point)
					 (list 'book book
					       'chapter chapter)))
		  (dtk-verse-inserter book chapter verse text nil nil))
	      ;; new chapter
	      (progn
		(insert #xa #xa)
		(setf this-chapter chapter)
		(dtk-verse-inserter book chapter verse text nil t)))))
      (when dtk-insert-verses-post (funcall dtk-insert-verses-post))
      )))

(defvar dtk-insert-verses-pre nil
  "If non-NIL, this should define a function to invoke prior to
inserting a set of verses via DTK-INSERT-VERSES. The function is
called with four arguments: book, chapter, verse, and verse-plists.")

(defvar dtk-insert-verses-post nil
  "If non-NIL, this should define a function to invoked after
insertion of a set of verses via DTK-INSERT-VERSES.")

(defun dtk-parse-citation-at-point ()
  "Assume point is at the start of a full verse citation. Return a list where the first member specifies the book, the second member specifies the chapter, and the third member specifies the verse by number."
  (let ((book-start-position (point))
	(book-end-position nil)
	(chapter-start-position nil)
	(colon1-position nil)
	;; CITATION-END-POSITION: last position in the full citation
	(citation-end-position nil))
    ;; move to start of chapter component of citation
    (search-forward ":")
    (setf colon1-position (point))
    (search-backward " ")
    (setf book-end-position (1- (point)))
    (forward-char)
    (setf chapter-start-position (point))
    ;; move to end of of citation
    (search-forward ":")
    ;; - if citation is end start of buffer, searching for non-word character will fail
    (condition-case nil
	(progn (search-forward-regexp "\\W")
	       (backward-char))
      (error nil
	     (progn (goto-char (point-max))
		    (backward-char)
		    (message "end-of-buffer"))))
    (setf citation-end-position (point))
    (list
     (buffer-substring-no-properties book-start-position (1+ book-end-position))
     (string-to-number (buffer-substring-no-properties chapter-start-position (1- colon1-position)))
     (string-to-number
      (buffer-substring-no-properties colon1-position citation-end-position)))))

(defun dtk-preview-citation ()
  "Preview citation at point."
  (interactive)
  ;; lazy man's preview -- append at end of *dtk* buffer so at least it's readable
  (with-current-buffer dtk-buffer-name
    ;; (move-point-to-end-of-dtk-buffer)
    (goto-char (point-max))
    ;; (add-vertical-line-at-end-of-dtk-buffer)
    (insert #xa))
  ;; (back-to-point-in-search/current-buffer)
  (dtk-follow))

(defun dtk-quit ()
  "Quit."
  (interactive)
  (when (member (buffer-name (current-buffer))
		(list dtk-buffer-name dtk-dict-buffer-name dtk-search-buffer-name))
    (kill-buffer nil)))

(defun dtk-to-start-of-full-citation ()
  "If point is within a full citation, move the point to the start of the full citation."
  (interactive)
  (let ((full-citation-component (dtk-at-verse-full-citation?)))
    (when full-citation-component
      ;; place point at space before chapter number
      (cond ((eq full-citation-component :space-or-book)
	     (search-forward ":")
	     (search-backward " "))
	    ((member full-citation-component
		     '(:chapter :colon :verse))
	     (search-backward " ")))
      ;; move to start of chapter name
      (search-backward-regexp dtk-books-regexp)
      ;; kludge to anticipate any order in dtk-books-regexp
      ;; - if citation is at start of buffer, searching for non-word character will fail
      (if (condition-case nil
	      (progn (search-backward-regexp "\\W")
		     t)
	    (error nil
		   (progn (beginning-of-line-text)
			  nil)))
	  (forward-char)))))

(defun dtk-view-text (clear-buffer-p dtk-buffer-p module)
  (interactive)
  ;; If dtk-buffer-p is true, insert text in the default dtk buffer.
  ;; Otherwise, use the current buffer.
  (when dtk-buffer-p
    (cond ((not (dtk-buffer-exists-p))
	   (dtk-init))
	  (t
	   (switch-to-buffer dtk-buffer-name))))
  (when clear-buffer-p
    (dtk-clear-buffer (current-buffer)))
  (dtk-set-module module)
  (dtk-set-mode)
  (dtk-retrieve-parse-insert (current-buffer)))

;;
;; parse diatheke raw text from a "Biblical Texts" text
;;

;; The `dtk-sto` prefix indicates code derived from alphapapa's
;; sword-to-org project.
(defconst dtk-sto--diatheke-parse-line-regexp
  (rx bol
      ;; Book name
      (group-n 1 (minimal-match (1+ anything)))
      space
      ;; chapter:verse
      (group-n 2 (1+ digit)) ":" (group-n 3 (1+ digit)) ":"
      ;; Passage text (which may start with a newline, in which case
      ;; no text will be on the same line after chapter:verse)
      (optional (1+ space)
                (group-n 4 (1+ anything))))
  "Regexp to parse each line of output from `diatheke'.")

(defun dtk-sto--diatheke-parse-text (text &optional keep-newlines-p)
  "Parse TEXT line-by-line, returning a list of verse plists. When
KEEP-NEWLINES-P is non-nil, keep blank lines in text.

Each verse plist has the format (:book \"Genesis\" :chapter 1 :verse 1
                                 :text (\"In the \" ...)).

The value for the :text key is a list where each member is either a
string or a list representing a child element permissible within an
OSIS XML document."
  (cl-loop with result
           with new-verse
           for line in (s-lines text)
           for parsed = (dtk-sto--diatheke-parse-line line)
           if parsed
           do (progn
                (push new-verse result)
                (setq new-verse parsed))
           else do (let ((text (plist-get new-verse :text)))
		     (setf text
			   (append text
				   (if (s-present? line)
				       (list line)
				     (if keep-newlines-p
					 '("\n")
				       nil))))
                     (plist-put new-verse :text text))
           finally return (cdr (progn
                                 (push new-verse result)
                                 (nreverse result)))))

(defun dtk-sto--diatheke-parse-line (line)
  "Return plist from LINE.  If LINE is not the beginning of a verse, return nil.

Each verse plist has the format (:book \"Genesis\" :chapter 1 :verse 1
                                 :text (\"In the \" ...)).

The value for the :text key is a list where each member is either a
string or a list representing a child element permissible within an
OSIS XML document."
  (if (s-present? line)
      (when (string-match dtk-sto--diatheke-parse-line-regexp line)
        (let ((book (match-string 1 line))
              (chapter (string-to-number (match-string 2 line)))
              (verse (string-to-number (match-string 3 line)))
              ;; Ensure text is present, which may not be the case if
              ;; a verse starts with a newline.  See
              ;; <https://github.com/alphapapa/sword-to-org/issues/2>
              (text (when (s-present? (match-string 4 line))
                      (s-trim (match-string 4 line)))))
          (list :book book :chapter chapter :verse verse :text (if text (list text)))))))

(defun dtk--parse-osis-xml-lines (text)
  "Parse the string TEXT, assuming it is a set of lines in the OSIS output format generated by diatheke."
  (let ((lines (s-lines text)))
    (let ((lines-n (length lines))
	  (parsed nil)
	  (current-line-n 0))
      (while (< current-line-n lines-n)
	;; consume lines associated with a single verse
	(cl-multiple-value-bind (last-line-parsed-n parsed-verse)
	    (dtk--diatheke-parse-osis-xml-for-verse lines current-line-n)
	  (if parsed-verse
	      (push parsed-verse parsed))
	  (setf current-line-n (1+ last-line-parsed-n))))
      (nreverse parsed))))

(defvar dtk-parse-osis-ignore-regexp
  (regexp-opt '("^Unprocessed Token:"))
  "Regular expression describing lines to be ignored in diatheke OSIS output.")

(defun dtk--diatheke-parse-osis-xml-for-verse (lines n)
  "Consume lines associated with a single verse. Return multiple values where where the first value is the index of the last line consumed in parsing a single verse and the second value is a plist associated with a single verse. Use list of strings, LINES, starting at list element N. If an indication of the beginning of a verse is not encountered at element N, return nil."
  ;; Anticipate LINES to correspond to what diatheke coughs up. For a single verse of a "Bible text", this is typically one or more lines of the form
  ;; II Peter 3:15: <w lemma=\"strong:G3588 lemma.TR:την\" morph=\"robinson:T-ASF\" src=\"2\" wn=\"001\"/><w lemma=\"strong:G2532 lemma.TR:και\" morph=\"robinson:CONJ\" src=\"1\" wn=\"002\">And</w> <w lemma=\"strong:G2233 lemma.TR:ηγεισθε\" morph=\"robinson:V-PNM-2P\" src=\"8\" wn=\"003\">account</w> ...
  ;;
  ;; Note that diatheke may emit, for a single verse, a set of lines of the form
  ;; II Peter 3:15: Unprocessed Token: <br /> in key II Peter 3:15
  ;; Unprocessed Token: <br /> in key II Peter 3:15
  ;; ...
  (let ((line (elt lines n))
	(current-line-n n)
	(last-line-n (1- (length lines))))
    (when (s-present? line)
      (when (string-match dtk-sto--diatheke-parse-line-regexp line)
	(let ((book (match-string 1 line))
	      (chapter (string-to-number (match-string 2 line)))
	      (verse (string-to-number (match-string 3 line)))
	      ;; Ensure text is present, which may not be the case if
	      ;; a verse starts with a newline.  See
	      ;; <https://github.com/alphapapa/sword-to-org/issues/2>
	      (first-line-raw-text (when (s-present? (match-string 4 line))
				     (s-trim (match-string 4 line))))
	      (text-raw ""))
	  ;; Once initial line associated with verse has been dealt
	  ;; with, modify the initial line so that it, along with
	  ;; every subsequent line can be handled in the same manner.
	  (when book
	    (setf (elt lines n) first-line-raw-text))
	  ;; per-line processing
	  (cl-do ((ignorep
		   ;; discard/ignore some classes of diatheke OSIS output
		   (string-match dtk-parse-osis-ignore-regexp (elt lines current-line-n))
		   (string-match dtk-parse-osis-ignore-regexp (elt lines current-line-n))))
	      (nil nil)
	    (unless ignorep
	      (setf text-raw
		    (cl-concatenate 'string text-raw (elt lines current-line-n))))
	    (when (or (>= current-line-n last-line-n)
		      ;; check if next line corresponds to start of a new verse
		      (string-match dtk-sto--diatheke-parse-line-regexp (elt lines (1+ current-line-n))))
	      (cl-return))
	    (cl-incf current-line-n))
	  ;; Add root element and parse text as a single piece of XML
	  (let ((text-structured (with-temp-buffer
				   (insert "<r>" text-raw "</r>")
				   (xml-parse-region))))
            (cl-values current-line-n
		       (list
			:book book :chapter chapter :verse verse
			:text (cl-subseq (car text-structured) 2)))))))))

;;
;; dictionary: handle dictionary entries and references
;;

;;; `dtk-dict-entry': Details for a dictionary entry
(cl-defstruct dtk-dict-entry
  key ; the key that one would use to "look up" the entry via diatheke
  crossrefs			 ; cross-references; a list of strings
  def ; definition - a plain text string; this may include notes if the parser is unable to distinguish definition and notes
  notes	     ; NIL or a plain text string
  word	     ; the dictionary entry itself - a simple string (word or phrase)
  )

(defvar dtk-dict-current-entry
  nil
  "A DTK-DICT-ENTRY structure corresponding to the most recent dictionary lookup. This should be considered the `current` dictionary entry. NIL if a dictionary lookup has not yet occurred.")

(defvar dtk-dict-key-functions
  '(("Nave" word-at-point)
    ("StrongsGreek" dtk-dict-strongs-key-for-word-at-point)
    ("StrongsHebrew" dtk-dict-strongs-key-for-word-at-point))
  "Maps the indicated dictionary module to a function which attempts to determine the key for the word at point. Such a function should return a cons where the car is the dictionary key and the cdr is module directly associated with the key, if such information is available.")

;;;###autoload
(defun dtk-dict ()
  "Use word at point to set, and then display, the current dictionary entry."
  (interactive)
  (dtk-dict-set-current-entry)
  (dtk-dict-populate-dtk-dict-buffer)
  ;; The most likely use case for DTK-DICT is invocation while reading
  ;; a passage. In this case, the most likely desired behavior is to
  ;; open the dtk-dict buffer alongside the buffer containing the
  ;; passage being read.
  (switch-to-buffer-other-window dtk-dict-buffer-name))

(defun dtk-dict-handle-raw-lines (lines module format)
  "Helper function for DTK-DICTIONARY. Parses content in list of strings, LINES, corresponding to lines of diatheke output associated with a dictionary query in diatheke module MODULE. Returns NIL if unsuccessful. Returns a dict-entry structure if successful. Argument FORMAT specifies the anticipated format of LINES."
  (let ((parser (dtk-module-map-get module :parser)))
    (cond (parser (funcall parser lines))
	  (t
	   (message "Missing parser for %s" module)
	   nil))))

(defun dtk-dict-key-for-word-at-point (dict-module)
  "Return a list where (a) the first element is a guess at the dictionary key to use for the word at point (NIL if unable to suggest a key for the word at point), (b) the second element is NIL or, if a module is directly associated with the key, the string specifying that module and (c) the third element is an (optional) explanatory note. DICT-MODULE specifies the dictionary module to be used."
  (if (not dict-module)
      (message "%s" "specify the current dictionary module.")
    (let ((f-entry (assoc dict-module dtk-dict-key-functions)))
      (cond ((consp f-entry)
	     (let ((key-module-note (eval (cl-rest f-entry))))
	       (cond ((stringp key-module-note)
		      (list nil nil key-module-note))
		     ((consp key-module-note)
		      key-module-note)
		     (t
		      (cons nil dict-module)))))
	    ;; The specified dictionary module is not yet supported
	    ((stringp dict-module)
	     nil)
	    (t
	     (error "Why are we here?")
	     nil)))))

;; Consider the situation where, for some text X,
;; - a request has been made to look up a dictionary entry using module requested-module
;; - the attempt to grab a dictionary key yielded the key KEY and the explicitly/directly-associated module KEY-ASSOCIATED-MODULE
(defun dtk-dict-module-sanity-check (key requested-module key-associated-module)
  "Look for nonsensical dictionary module situations. REQUESTED-MODULE is the module requested for the key KEY. KEY-ASSOCIATED-MODULE is a module known to be sane for the key under consideration. Return the optimal module choice when possible. If REQUESTED-MODULE is clearly inappropriate and a sane module choice is not immediately obvious, return NIL."
  (cond ((and (stringp requested-module) (stringp key-associated-module)
	      (string= requested-module key-associated-module))
	 ;; If KEY is NIL, then it is likely that the text in use does not have STrong's data associated with it
	 (cond ((not key)
		(message "Text likely does not have Strong's numbers associated with it. Try a different text.")
		nil)
	       (t requested-module)))
	;; At this point, StrongGreek-StrongsHebrew mismatch is the only
	;; such case
	((and (string= dict-module "StrongsGreek")
		 (cl-equalp key-associated-module "StrongsHebrew"))
	    (message "Requested StrongsGreek but using StrongsHebrew")
	    "StrongsHebrew")
	((and (string= dict-module "StrongsHebrew")
	      (cl-equalp key-associated-module "StrongsGreek"))
	 (message "Requested StrongsHebrew but using StrongsGreek")
	 "StrongsGreek")
	(t nil)))

(defface dtk-dict-word
  '((t ()))
  "Face for a word or phrase with a corresponding dictionary entry."
  :group 'dtk-faces)

(defconst dtk-dict-osis-xml-lemma-strongs-regexp
  ;; Look for a string of the form "strong:G1722" or
  ;; "strong:G2532 strong:G2147". Note that multiple
  ;; Strong's references may be attached to a single lemma attribute
  ;; value.
  (rx
   "strong:"
   (group-n 1 (char "GH")) ; Greek or Hebrew ("G" or "H")
   (group-n 2 (1+ digit)) ; dictionary number
   ))

(defun dtk-dict-overlay-at-point ()
  "Return an overlay."
  (let ((overlays (overlays-at (point)))
	(dtk-dict-overlay nil))
    (if overlays
	(catch 'overlays-loop
	  (dolist (ol overlays)
	    (when (overlay-get ol 'dtk-dict-overlay)
	      (setf dtk-dict-overlay ol)
	      (throw 'overlays-loop nil)))))
    dtk-dict-overlay))

(defun dtk-dict-populate-dtk-dict-buffer ()
  "Populate the dtk-dict-buffer buffer with the current dictionary entry."
  (get-buffer-create dtk-dict-buffer-name)
  ;;(dtk-clear-dict-buffer)
  (with-current-buffer dtk-dict-buffer-name
    (delete-region (progn (goto-char (point-min)) (point))
		   (progn (goto-char (point-max)) (point)))
    (dtk-dict-mode)
    (when dtk-dict-current-entry
      (insert (dtk-dict-entry-word dtk-dict-current-entry)
	      #xa
	      (dtk-dict-entry-def dtk-dict-current-entry)
	      #xa)
      (mapc #'(lambda (cr) (insert cr #xa))
	    (dtk-dict-entry-crossrefs dtk-dict-current-entry)))))

(defun dtk-dict-set-current-entry ()
  "Use word at point to set the current dictionary entry."
  (let* ((dict-module-category "Lexicons / Dictionaries")
	 (dict-module (or (if (equal dtk-module-category dict-module-category)
			      dtk-module)
			  (lax-plist-get dtk-module-last-selection dict-module-category)
			  (dtk-select-module-of-type "First select a module: " dict-module-category))))
    (cond (dict-module
	   (let ((key-module-note (dtk-dict-key-for-word-at-point dict-module))
		 (format :plain))
	     (cond ((not key-module-note)
		    (message "Module %s is not supported as a dictionary module." dict-module))
		   ((not (car key-module-note))
		    (if (stringp (third key-module-note))
			(message "%s" (third key-module-note))
			(message "Unable to find dictionary data for %s." (cdr key-module))))
		   (t
		    (setf dict-module (dtk-dict-module-sanity-check (car key-module-note) dict-module (cdr key-module-note)))
		    (if dict-module
			(dtk-dict-set-dtk-dict-current-entry (car key-module-note)
							     dict-module
							     format)
		      (message "First select a reasonable dictionary module"))))))
	  (t (error "First select a dictionary module")))))

(defun dtk-dict-set-dtk-dict-current-entry (key module format)
  "Set DTK-DICT-CURRENT-ENTRY by performing a lookup with KEY using the dictionary module MODULE. KEY is a string, the query key for the dictionary lookup. Returns NIL if unsuccessful. Returns T if successful."
  (let ((dict-entry (dtk-dict-handle-raw-lines (dtk-dict-raw-lines key module) module format)))
    (cond (dict-entry
	   (setf (dtk-dict-entry-key dict-entry) key)
	   (setf dtk-dict-current-entry dict-entry)
	   t)
	  (t nil))))

(defcustom dtk-show-dict-numbers nil
  "If true, show dictionary numbers, if available. Otherwise, ensure dictionary information is not visible.")

(defconst dtk-dict-strongs-line1-regexp
  (rx (1+ digit)
      ":"
      (1+ space)			; whitespace
      (group-n 1 (1+ digit))		; strongs-number
      (1+ space)			; whitespace
      (group-n 2 (1+ (not (any space)))) ; word
      )
  "Match the first line of a Strongs entry.")

(defun dtk-dict-strongs-key-for-word-at-point ()
  "Return a cons where the car is the dictionary key for a Strongs Greek or Strongs Hebrew dictionary entry and the cdr is an indication of the module corresponding to the key."
  ;; the key (diatheke) is the dictionary number
  (let (
	;; look for 'lemma' text property and corresponding dictionary data
	;;(lemma-raw (get-text-property (point) 'lemma))
	(lemma-raw nil)
	;; currently...
	(word-dict (get-text-property (point) 'dict)))
    (cond (lemma-raw
	   ;; look for pattern like "strong:G1722 ..."
	   (string-match dtk-dict-osis-xml-lemma-strongs-regexp lemma-raw)
	   (let ((G-or-H (match-string 1 lemma-raw))
		 (strongs-number (match-string 2 lemma-raw)))
	     (cons strongs-number
		   (pcase G-or-H
		     ("G" "StrongsGreek")
		     ("H" "StrongsHebrew")))))
	  (word-dict
	   (cons (cl-first word-dict) (cl-second word-dict)))
	  (t
	   "No Strong's data at point. Use a Biblical text with Strong's numbers."))))

(defun dtk-dict-strongs-parse (lines)
  "Parse either StrongsGreek or StrongsHebrew diatheke output"
  ;; Diatheke seems to not support structured (XML) output for
  ;; StrongsGreek nor for StrongsHebrew. The first line begins with an
  ;; integer succeeded by a colon character. Examples:
  ;; 0358803588:  3588  ho   ho, including the feminine
  ;; 0305603056:  3056  logos  log'-os
  (let ((raw-first-line (pop lines))
	(dict-crossrefs nil)
	(dict-def "")
	(dict-word nil))
    ;; grab Strong's # and word
    (string-match dtk-dict-strongs-line1-regexp raw-first-line)
    (setq dict-word (match-string 2 raw-first-line))
    ;; remove any additional lines associated with the word
    (while (not (and (string= (elt lines 0) "")
  		     (string= (elt lines 1) "")))
      (pop lines))
    ;; two empty lines seem to denote boundary between the word/number/etymology and the description/definition/notes
    (pop lines)
    (pop lines)
    ;; set definition/notes component
    (while (and (not (and
		      (>= (length (elt lines 0))
			  4)
		      (string= (seq-subseq (string-trim (elt lines 0))
					   0 4)
			       "see ")))
		;; See note below regarding end of entire diatheke response
		(not (and (>= (length (elt lines 0))
			      (+ 2 (length module)))
			  (string= (seq-subseq (elt lines 0) 1 (1+ (length module)))
				   module))))
      (setf dict-def (concat dict-def (pop lines))))
    ;; set cross-references
    (while (and lines
		;; Expect the entire diatheke response to end with a
		;; line with the parenthesized module name -- for
		;; example, "(StrongsHebrew)".
		(and (>= (length (elt lines 0))
			 (+ 2 (length module)))
		     (not (string= (seq-subseq (elt lines 0) 1 (1+ (length module)))
				   module))))
      ;; FIXME: string may end with module name in parentheses; should clean that up
      (let ((line (pop lines)))
	(if (consp line) (setf line (cl-first line)))
	(setf dict-crossrefs (push line
				   dict-crossrefs))))
    (make-dtk-dict-entry :crossrefs dict-crossrefs
			 :def dict-def
			 :key nil
			 :notes nil
			 :word dict-word)))

;; The current implementation assumes that, if the "lemma" attribute is present, it is a string of whitespace-separated values. Values of the form "strong:G1161" are handled. Others (e.g., "lemma.TR:δε") are disregarded.
(defun dtk-dict-parse-osis-xml-lemma (x)
  "Return a list where each element is either NIL (indicating value
was disregarded) or a list where the first element is the dictionary
number and the second element is a string describing the module
corresponding to the key."
  (let ((raw-strings (split-string x "[ \f\t\n\r\v]+")))
    (mapcar #'(lambda (raw-string)
		(cond ((string-match dtk-dict-osis-xml-lemma-strongs-regexp
				     raw-string)
		       (let ((G-or-H (match-string 1 raw-string))
			     (strongs-number (match-string 2 raw-string)))
			 (list strongs-number
			       (pcase G-or-H
				 ("G" "StrongsGreek")
				 ("H" "StrongsHebrew")))))
		      (t
		       nil ; Silently ignore values we don't handle (vs. (display-warning ... ))
		       )))
	    raw-strings)))
;;
;; dtk major mode
;;

;; The dtk major mode uses font-lock-face for some text and also uses the normal Font Lock machinery.
(defcustom dtk-books-font-lock-variable-name-face-string
  (concat "^\\("
	  (mapconcat #'(lambda (book)
			 book)
		     ;; treat last book differently
		     dtk-books ; (butlast dtk-books 1)
		     "\\|")
	  "\\)")
  "Facilitate font lock in dtk major mode for books in DTK-BOOKS.")

;; these could use some TLC/refinement
(defconst dtk-font-lock-keywords
  (list
   ;; book names
   (cons dtk-books-font-lock-variable-name-face-string
	 ;;(find-face 'dtk-full-book)
	 font-lock-variable-name-face  ; Foreground: LightGoldenrod
	 )
   ;; translation/source
   (list dtk-module))
  "List of font lock keywords for dtk major mode.")

(defface dtk-full-book
  '((t (:background "gray50" :foreground "red" :height 1.2)))
  "Face for book component of a full citation."
  :group 'dtk-faces)

(defface dtk-chapter-number
  '((t (:inherit font-lock-constant-face)))
  "Face for marking chapter number."
  :group 'dtk-faces)

(defface dtk-verse-number
  '((t (:inherit font-lock-constant-face)))
  "Face for marking verse number."
  :group 'dtk-faces)

(defvar dtk-mode-map
  (let ((map (make-keymap)))
    (define-key map "c" 'dtk-clear-dtk-buffer)
    (define-key map "b" 'dtk-backward-verse)
    (define-key map "d" 'dtk-dict)
    (define-key map "g" 'dtk-go-to)
    (define-key map "f" 'dtk-forward-verse)
    (define-key map "m" 'dtk-select-module)
    (define-key map "M" 'dtk-select-module-category)
    (define-key map "s" 'dtk-search)
    (define-key map "q" 'dtk-quit)
    (define-key map "x" 'dtk-follow)
    (define-key map (kbd "C-M-b") 'dtk-backward-chapter)
    (define-key map (kbd "C-M-f") 'dtk-forward-chapter)
    map)
  "Keymap for in dtk buffer.")

;;;###autoload
(define-derived-mode dtk-mode text-mode "dtk"
  "Major mode for displaying dtk text
\\{dtk-mode-map}
Turning on dtk mode runs `text-mode-hook', then `dtk-mode-hook'."
  (setq font-lock-defaults '(dtk-font-lock-keywords))
  (make-local-variable 'paragraph-start)
  (make-local-variable 'paragraph-separate)
  (setq word-wrap dtk-word-wrap)
  )

;;;###autoload
(define-derived-mode dtk-search-mode dtk-mode "dtk-search"
  "Major mode for interacting with dtk search results.")

;;;###autoload
(define-derived-mode dtk-dict-mode dtk-mode "dtk-dict"
  "Major mode for interacting with dtk dict results.")

(defvar dtk-search-mode-map
  (let ((map (make-keymap)))
    (define-key map [return] 'dtk-preview-citation)
    (define-key map "g" 'dtk-search-follow)
    map)
  "Keymap for dtk search buffer.")

;;; navigating (by book, chapter, and verse)

(defun dtk-at-verse-full-citation? ()
  "Return a true value if point is at a full verse citation."
  ;; could be at a verse number or at a full citation (e.g., 'John 1:1')
  (cond ((dtk-at-verse-full-citation-chapter?)
	 :chapter)
	((dtk-at-verse-full-citation-verse?)
	 :verse)
	((dtk-at-verse-full-citation-colon?)
	 :colon)
	((dtk-at-verse-full-citation-space-or-book?)
	 :space-or-book)))

(defun dtk-at-verse-full-citation-colon? ()
  "Return a true value if point is at the colon character in a full verse citation."
  ;; if at a colon, is it between two numerals?
  (and (= 58 (char-after (point)))	; colon character?
       (dtk-number-at-point (1+ (point)))
       (dtk-number-at-point (1- (point)))))

(defun dtk-at-verse-full-citation-chapter? ()
  "Return a true value if point appears to be at the numeral(s) indicating the chapter number in a full verse citation."
  (looking-at "[[:digit:]]+:[[:digit:]]"))

(defun dtk-at-verse-full-citation-verse? ()
  "Return a true value if point appears to be at the numeral(s) indicating the verse number in a full verse citation."
  (and (dtk-number-at-point (point))
       ;; might be at third digit of a verse...
       (looking-back "[[:digit:]]:[[:digit:]]?[[:digit:]]?" 5)))

(defun dtk-at-verse-full-citation-space-or-book? ()
  "Return a true value if point appears to be at the space preceding a full verse citation or at the start of a full verse citation."
  (or (and (= 32 (char-after (point)))
	   (or
	    ;; if at a space, ask if it precedes ch:v
	    (looking-at " [[:digit:]]+:[[:digit:]]")
	    ;; if at a space, ask if it precedes something like 'John 3:5'
	    ;; FIXME: this is lazy since it will include space that really isn't part of citation but is adjacent to citation (it's here because this catches the space in things like 'I John')
	    (looking-at " \\w+ [[:digit:]]+:[[:digit:]]")))
      ;; if at a character, ask if it is book component of a citation
      ;; A = 65, Z = 90, a = 97, z = 122
      (and (dtk-alpha-at-point (point))
	   (or
	    ;; this misses any book that isn't a single word (e.g., 'I John')
	    (looking-at "\\w+ [[:digit:]]+:[[:digit:]]")
	    ;; catch the possibility that we're at the 'I' in something like 'I John 1:1'
	    ;; FIXME: this will erroneously identify the end of the previous verse as part of the succeeding citation if the previous verse ends with an 'I' (seems unlikely but...)
	    (looking-at "\\(\\(I \\)\\|\\(II \\)\\)\\w+ [[:digit:]]+:[[:digit:]]")))))

(defun dtk-backward-chapter ()
  "Move to the previous chapter. Behavior is undefined if the current chapter is not
preceded by a different chapter."
  (interactive)
  (or
   ;; If at whitespace w/o chapter property, or if at end of buffer, move backward until chapter defined
   (dtk-backward-until-chapter-defined)
   ;; If at start of buffer, move forward until chapter defined
   (dtk-forward-until-chapter-defined))
  (let ((book (get-text-property (point) 'book))
	(current-chapter (get-text-property (point) 'chapter)))
    ;; If unable to move to prior chapter with current buffer content,
    ;; try to insert the text of the prior chapter at the start of
    ;; the buffer
    (if (not (dtk-backward-until-defined-chapter-not-equal current-chapter))
	(progn
	  (dtk-insert-chapter-at book
				 (1- current-chapter)
				 (point-min))
	  (backward-word)		; expose chapter
	  (dtk-to-start-of-current-chapter)))))

(defun dtk-backward-until-chapter-defined ()
  "If the chapter text property is not defined at point, move backward
until at a position where the chapter text property is defined. Return
NIL if a position does not exist before point where the chapter text
property is defined."
  (interactive)
  (when (and (not (bobp))
	     (not (get-text-property (point) 'chapter)))
    (cond ((get-text-property (1- (point)) 'chapter)
	   (goto-char (1- (point))))
	  (t
	   (let ((changes-at (previous-single-property-change
			      (point)
			      'chapter)))
	     (when changes-at
	       (goto-char (1-
			   (previous-single-property-change
			    (point)
			    'chapter)))))))))

(defun dtk-backward-until-defined-chapter-not-equal (x &optional start-point)
  "Move backward past either START-POINT (if non-nil) or current
point if, at some point before the current point, the chapter text
property value is defined and the test for equality between the
chapter text property value and X does not return a true value."
  (let ((changes-at-point (previous-single-property-change (or start-point
							       (point))
							   'chapter)))
    (when changes-at-point
      (let ((new-chapter-text-property (get-text-property changes-at-point 'chapter)))
	(cond ((and new-chapter-text-property
		    (not (equal (get-text-property changes-at-point 'chapter)
				x)))
	       (goto-char changes-at-point))
	      ;; Possibly at whitespace
	      (t (dtk-backward-until-defined-chapter-not-equal x changes-at-point)))))))

(defun dtk-backward-verse ()
  "Move to the numeric component of the verse citation for the previous verse."
  (interactive)
  (dtk-previous-verse)
  (dtk-to-start-of-current-verse))

(defun dtk-insert-chapter-at (bk ch at)
  "Attempt to insert the indicated chapter at the start of the buffer. CH is a number."
  (goto-char at)
  ;; Expose these values to the retriever
  (setq dtk-bible-book bk)
  (setq dtk-bible-chapter-verse (concat (int-to-string ch) ":"))
  (dtk-retrieve-parse-insert (current-buffer)))

(defun dtk-previous-verse ()
  "Move to the previous verse. No assurance is offered with respect to the exact location of point within the preceding verse after invoking DTK-PREVIOUS-VERSE."
  (interactive)
  ;; It is possible that point is currently at whitespace not
  ;; associated with a verse; if so, move until the 'verse property is
  ;; defined and treat that verse value as the current verse.
  (dtk-back-until-verse-defined)
  (dtk-previous-verse-change)
  ;; As above, it's possible point is at a position where
  ;; the 'verse property is not defined.
  (dtk-back-until-verse-defined))

(defun dtk-back-until-verse-defined ()
  "If the verse text property is not defined at point, back up to the first point, relative to the current point, at which the verse text property is defined."
  (interactive)
  (when (and (not (= (point) 1))
	     (not (get-text-property (point) 'verse)))
    (if (get-text-property (1- (point)) 'verse)
	(goto-char (1- (point)))
      (goto-char (1-
		  (previous-single-property-change
		   (point)
		   'verse))))))

(defun dtk-previous-chapter-change ()
  "Move to the point at which the 'chapter text property assumes a different value (relative to the 'chapter text property at the current point). Return the point at which the 'chapter text property changed or, if the property does not change prior to the current point, return NIL."
  (interactive)
  (let ((chapter-changes-at (previous-single-property-change (1+ (point)) 'chapter)))
    (when chapter-changes-at
      (goto-char (1- chapter-changes-at)))
    chapter-changes-at))

(defun dtk-previous-verse-change ()
  "Move to the point at which the 'verse text property assumes a different value (relative to the 'verse text property at the current point). Return the point at which the 'verse text property changed or, if the property does not change prior to the current point, return NIL."
  (interactive)
  (let ((verse-changes-at (previous-single-property-change (1+ (point)) 'verse)))
    (when verse-changes-at
      (goto-char (1- verse-changes-at)))
    verse-changes-at))

(defun dtk-forward-chapter ()
  "Move to the next chapter (the point at which the chapter text
property changes to a new value distinct from the current chapter text
property value). If the current chapter is not succeeded by the text
of a different chapter, attempt to insert the text of the next
chapter."
  (interactive)
  ;; If at a position where the chapter property is not defined,
  ;; attempt to move forward until the chapter property is defined.
  (or (dtk-forward-until-chapter-defined)
      ;; If at whitespace at the end of the buffer (whitespace which succeeds the "last" chapter), move back to get the chapter value
      (dtk-back-until-verse-defined))
  (let ((current-chapter (get-text-property (point) 'chapter)))
    ;; If unable to move to next chapter with current buffer content,
    ;; try to insert the text of the next chapter at the end of
    ;; current text.
    (if (not (dtk-forward-until-defined-chapter-not-equal current-chapter))
	;; insert next chapter at eob
	(let ((book (get-text-property (point) 'book)))
	  (goto-char (point-max))
	  (newline)
	  (dtk-insert-chapter-at book (1+ current-chapter) (point-max))
	  (backward-word)		; expose chapter
	  (dtk-to-start-of-current-chapter)))))

(defun dtk-forward-until-chapter-defined ()
  "If the chapter text property is defined at point, return a true
value. If the chapter text property is not defined at point, move
forward until at a position where the chapter text property is
defined. Return NIL if a position does not exist forward of point
where the chapter text property changes."
  (interactive)
  (cond ((eobp)
	 nil)
	((not (get-text-property (point) 'chapter))
	 (let ((changes-at-point (next-single-property-change (point) 'chapter)))
	   (if changes-at-point
	       (goto-char changes-at-point))))
	(t t)))

(defun dtk-forward-until-defined-chapter-not-equal (x &optional start-point)
  "Move forward past either START-POINT (if non-nil) or the current
point if, at some point past the current point, the chapter text
property value is defined and the test for equality between the
chapter text property value and X does not return a true value. Return
NIL if unable to move forward in the described manner."
  (let ((changes-at-point (next-single-property-change (1+ (or start-point
							       (point)))
						       'chapter)))
    (if changes-at-point
	(let ((new-chapter-text-property (get-text-property changes-at-point 'chapter)))
	  (cond ((and new-chapter-text-property
		      (not (equal (get-text-property changes-at-point 'chapter)
				  x)))
		 (goto-char changes-at-point)
		 t)
		;; Possibly at whitespace
		(t (dtk-forward-until-defined-chapter-not-equal x changes-at-point))))
      nil)))

(defun dtk-forward-verse ()
  "Move to the numeric component of the verse citation for the next verse."
  (interactive)
  (goto-char (next-single-property-change (point) 'verse))
  ;; it is possible that whitespace is present not associated with a verse; if that's the case move forward until the 'verse property is defined
  (if (not (get-text-property (point) 'text))
      (goto-char (next-single-property-change (point) 'verse))))

(defun dtk-to-start-of-current-chapter ()
  "Move to the start of the current chapter."
  (interactive)
  (if (dtk-previous-chapter-change)
      (forward-char)
    (beginning-of-buffer)))

(defun dtk-to-start-of-current-verse ()
  "Move to the start (beginning of the citation) of the current verse."
  (interactive)
  (let ((verse-changes-at (dtk-previous-verse-change)))
    (cond (verse-changes-at
	   (forward-char))
	  ;; In less-than-ideal circumstances, VERSE-CHANGES-AT assumes a value of NIL when at the first verse. Ugly kludges include moving to start of buffer or searching back for the first numeric character encountered.
	  (t
	   (beginning-of-buffer)))))

;;;
;;; miscellany
;;;


;;;
;;; utility functions
;;;
(defun dtk-alpha-at-point (&optional point)
  "Match if the character at point POINT (defaults to current point) is an upper-case or lower-case alphabetical letter character (i.e., in the range A through Z or the range a through z)."
  (let ((char-code (char-after (or point (point)))))
    (or
     (and (>= char-code 65)
	  (<= char-code 90))
     (and (>= char-code 97)
	  (<= char-code 122)))))

(defun dtk-number-at-point (&optional point)
  "A more flexible version of NUMBER-AT-POINT. POINT optionally specifies a point."
  (let ((char-code (char-after (or point (point)))))
    (and (>= char-code 48)
	 (<= char-code 57))))

;;;
;;; establish defaults (relying on dtk code)
;;;
(unless dtk-module-category
  (setf dtk-module-category "Biblical Texts"))
(unless dtk-module
  (setf dtk-module (elt (dtk-module-names dtk-module-category) 0)))

(provide 'dtk)
;;; dtk.el ends here
