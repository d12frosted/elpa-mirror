;;; elfeed-summary.el --- Feed summary interface for elfeed -*- lexical-binding: t -*-

;; Copyright (C) 2022 Korytov Pavel

;; Author: Korytov Pavel <thexcloud@gmail.com>
;; Maintainer: Korytov Pavel <thexcloud@gmail.com>
;; Version: 0.1.1
;; Package-Version: 20221210.1349
;; Package-Commit: ccbaf85d9ea442203027e784a42b21686f3a87d8
;; Package-Requires: ((emacs "27.1") (magit-section "3.3.0") (elfeed "3.4.1"))
;; Homepage: https://github.com/SqrtMinusOne/elfeed-summary.el

;; This file is NOT part of GNU Emacs.

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
;; The package provides a tree-based feed summary interface for
;; elfeed.  The tree can include individual feeds, searches, and
;; groups.  It mainly serves as an easier "jumping point" for elfeed,
;; so searching a subset of the elfeed database is one action away.
;;
;; `elfeed-summary' pops up the summary buffer.  The buffer shows
;; individual feeds and searches, combined into groups.  The structure
;; is determined by the `elfeed-summary-settings' variable.
;;
;; Also take a look at the package README at
;; <https://github.com/SqrtMinusOne/elfeed-summary> for more
;; information.

;;; Code:
(require 'cl-lib)
(require 'elfeed)
(require 'elfeed-db)
(require 'elfeed-log)
(require 'elfeed-search)
(require 'magit-section)
(require 'seq)
(require 'widget)

;; XXX I want to have the compatibility with evil-mode without
;; requiring it, so I check whether this function is bound later in
;; the code.
(declare-function evil-define-key* "evil-core")

;; XXX Compatibility with elfeed-org.  If this function is bound, then
;; `elfeed-org' is available
(declare-function rmh-elfeed-org-process "elfeed-org")

(define-widget 'elfeed-summary-query 'lazy
  "Type widget for the `<query-params>' form of `elfeed-summary-settings'."
  :offset 4
  :tag "Extract subset of elfeed feed list"
  :type '(choice (symbol :tag "One tag")
                 (const :tag "All" :all)
                 (cons :tag "Match title"
                       (const :tag "Title" title)
                       (choice (string :tag "String")
                               (sexp :tag "Lisp expression")))
                 (cons :tag "Match author"
                       (const :tag "Author" author)
                       (choice (string :tag "String")
                               (sexp :tag "Lisp expression")))
                 (cons :tag "Match URL"
                       (const :tag "URL" url)
                       (choice (string :tag "String")
                               (sexp :tag "Lisp expression")))
                 (cons :tag "AND"
                       (const :tag "AND" and)
                       (repeat elfeed-summary-query))
                 (cons :tag "NOT"
                       (const :tag "NOT" not)
                       elfeed-summary-query)
                 (repeat :tag "OR (Implicit)" elfeed-summary-query)
                 (cons :tag "OR"
                       (const :tag "OR" or)
                       (repeat elfeed-summary-query))))

(define-widget 'elfeed-summary-setting-elements 'lazy
  "Type widget for `elfeed-summary-settings'"
  :offset 4
  :tag "Settings list"
  :type '(repeat
          (choice
           (cons :tag "Group"
                 (const group)
                 (repeat :tag "Group params"
                         (choice
                          (cons
                           (const :tag "Title" :title)
                           (string :tag "Title"))
                          (cons
                           (const :tag "Face" :face)
                           (face :tag "Face"))
                          (cons
                           (const :tag "Hide" :hide)
                           (boolean :tag "Hide"))
                          (cons
                           (const :tag "Elements" :elements)
                           elfeed-summary-setting-elements))))
           (cons :tag "Query"
                 (const query)
                 elfeed-summary-query)
           (cons :tag "Search"
                 (const search)
                 (repeat :tag "Search params"
                         (choice
                          (cons :tag "Filter"
                                (const :tag "Filter" :filter)
                                (string :tag "Filter string"))
                          (cons :tag "Title"
                                (const :tag "Title" :title)
                                (string :tag "Filter title"))
                          (cons :tag "Tags"
                                (const :tag "Tags" :tags)
                                (repeat symbol))
                          (cons (const :tag "Add the default filter string" :add-default)
                                (boolean :tag "Add the default filter string")))))
           (cons :tag "Generate a tree from tags"
                 (const auto-tags)
                 (repeat :tag "Tree generation parameters"
                         (choice
                          (cons :tag "Source"
                                (const :tag "Source" :source)
                                (choice
                                 (cons :tag "Query"
                                       (const query)
                                       elfeed-summary-query)
                                 (const :tag "Misc feeds" :misc)))
                          (cons :tag "Maximum tree level"
                                (const :tag "Maximum tree level" :max-level)
                                (number :tag "Value"))
                          (cons :tag "Original tag order"
                                (const :tag "Original tag order" :original-order)
                                (boolean :tag "Original tag order"))
                          (cons :tag "Faces"
                                (const :tag "Faces" :faces)
                                (repeat
                                 (face :tag "Face"))))))
           (cons :tag "Insert each tag as group"
                 (const tag-groups)
                 (repeat :tag "Tag group parameters"
                         (choice
                          (cons :tag "Source"
                                (const :tag "Source" :source)
                                (choice
                                 (cons :tag "Query"
                                       (const query)
                                       elfeed-summary-query)
                                 (const :tag "Misc feeds" :misc)))
                          (cons :tag "Allow feeds to repeat"
                                (const :tag "Allow feeds to repeat" :repeat-feeds)
                                (boolean :tag "Allow feeds to repeat"))
                          (cons :tag "Face"
                                (const :tag "Face" :faces)
                                (face :tag "Face")))))
           (const :tag "Misc feeds" :misc))))

(defgroup elfeed-summary ()
  "Feed summary interface for elfeed."
  :group 'elfeed)

(defcustom elfeed-summary-settings
  '((group (:title . "All feeds")
           (:elements (query . :all)))
    (group (:title . "Searches")
           (:elements (search
                       (:filter . "@7-days-ago +unread")
                       (:title . "Unread entries this week"))
                      (search
                       (:filter . "@6-months-ago emacs")
                       (:title . "Something about Emacs")))))
  "Elfeed summary settings.

This is a list of these possible items:
- Group `(group . <group-params>)'
  Groups are used to group elements under collapsible sections.
- Query `(query . <query-params>)'
  Query extracts a subset of elfeed feeds based on the given criteria.
  Each found feed will be represented as a line.
- Search `(search . <search-params>)'
  Elfeed search, as defined by `elfeed-search-set-filter'.
- Tags tree `(auto-tags . <auto-tags-params>)'
  A tree generated automatically from the available tags.
- Tag groups `(tag-groups . <tag-group-params>)'
  Insert one tag as one group.
- a few special forms

`<group-params>' is an alist with the following keys:
- `:title' (mandatory)
- `:elements' (mandatory) - elements of the group.  The structure is
  the same as in the root definition.
- `:face' - group face.  The default face is `elfeed-summary-group-face'.
- `:hide' - if non-nil, the group is collapsed by default.

`<query-params>' can be:
- A symbol of a tag.
  A feed will be matched if it has that tag.
- `:all'.  Will match anything.
- `(title . \"string\")' or `(title . <form>)'
  Match feed title with `string-match-p'.  <form> makes sense if you
  want to pass something like `rx'.
- `(author . \"string\")' or `(author . <form>)'
- `(url . \"string\")' or `(url . <form>)'
- `(and <q-1> <q-2> ... <q-n>)'
  Match if all the conditions 1, 2, ..., n match.
- `(or <q-1> <q-2> ... <q-n>)' or `(<q-1> <q-2> ... <q-n>)'
  Match if any of the conditions 1, 2, ..., n match.
- `(not <query>)'
variable.

Query examples:
- `(emacs lisp)'
  Return all feeds that have either \"emacs\" or \"lisp\" tags.
- `(and emacs lisp)'
  Return all feeds that have both \"emacs\" and \"lisp\" tags.
- `(and (title . \"Emacs\") (not planets))'
  Return all feeds that have \"Emacs\" in their title and don't have
  the \"planets\" tag.

`<search-params>' is an alist with the following keys:
- `:filter' (mandatory) filter string, as defined by
  `elfeed-search-set-filter'
- `:title' (mandatory) title.
- `:tags' - list of tags to get the face of the entry.
- `:add-default' - if t, prepend the filter with
  `elfeed-summary-default-filter'.

`<auto-tags-params>' is an alist with the following keys:
- `:max-level' - maximum level of the tree (default 2)
- `:source' - which feeds to use to build the tree.
  Can be `:misc' (default) or `(query . <query-params>)'.
- `:original-order' - do not try to build a more concise tree by
  putting the most frequent tags closer to the root of the tree.
- `:faces' - list of faces for groups.

`<tag-group-params>' is an alist with the following keys:
- `:source' - which feeds to use to build the tree.
  Can be `:misc' (default) or `(query . <query-params>)'.
- `:repeat-feeds' - allow feeds to repeat.  Otherwise, each feed is
  assigned to group with the least amount of members.
- `:face' - face for groups.

Available special forms:
- `:misc' - print out feeds, not found by any query above.

Also keep in mind that '(key . ((values))) is the same as '(key
\(values)).  This helps to shorten the form in many cases.

Also, this variable is not validated by any means, so wrong values can
produce somewhat cryptic errors."
  :group 'elfeed-summary
  :type 'elfeed-summary-setting-elements)

(defcustom elfeed-summary-look-back (* 60 60 24 180)
  "The date range for which to count entries in the feed list.

The value is in seconds.  The default value is 180 days, which means
that only entries less than 180 days old will be counted.

This has to be set up for efficiency because the elfeed database is
time-based, so this allows querying only the most recent part of the
database."
  :group 'elfeed-summary
  :type 'integer)

(defcustom elfeed-summary-default-filter "@6-months-ago "
  "Default filter for `elfeed-search'.

This has to end with space.  The unread tag will be added
automatically."
  :group 'elfeed-summary
  :type 'integer)

(defcustom elfeed-summary-unread-tag 'unread
  "Tag that determines whether the entry is unread.

Probably should be one of `elfeed-initial-tags'."
  :group 'elfeed-summary
  :type 'symbol)

(defcustom elfeed-summary-feed-face-fn #'elfeed-summary--feed-face-fn
  "Function to get the face of the feed entry.

Accepts two arguments:
- The corresponding instance of `elfeed-feed'.
- List of tags from `elfeed-feeds'.

The default implementation, `elfeed-summary--feed-face-fn', calls
`elfeed-search--faces'."
  :group 'elfeed-summary
  :type 'function)

(defcustom elfeed-summary-search-face-fn #'elfeed-summary--search-face-fn
  "Function to get the face of the search entry.

Accepts the following arguments:
- `<search-params>', as described in `elfeed-summary-settings'.
- The number of found unread items.
- The number of found items.

The default implementation, `elfeed-summary--search-face-fn', calls
`elfeed-search--faces' with the contents of `:tags' of
`<search-params>' plus `unread' if the number of found items is
greater than zero."
  :group 'elfeed-summary
  :type 'function)

(defcustom elfeed-summary-feed-sort-fn #'elfeed-summary--feed-sort-fn
  "Function to sort feeds in query.

Accepts two instances of `elfeed-feed'.

The default implementation does the alphabetical case-insensitive
ordering."
  :group 'elfeed-summary
  :type 'function)

(defcustom elfeed-summary-auto-tags-group-title-fn
  #'elfeed-summary--auto-tags-group-title
  "Function to get the title of an autogenerated group.

Accepts the only parameter, which is a tree node created by
`elfeed-summary--arrange-sequences-in-tree'.

See `elfeed-summary--auto-tags-group-title' for the default
implementation."
  :group 'elfeed-summary
  :type 'function)

(defcustom elfeed-summary-refresh-on-each-update nil
  "Whether to refresh the elfeed summary buffer after each update.

This significantly slows down the `elfeed-update' command when run
from the summary buffer."
  :group 'elfeed-summary
  :type 'boolean)

(defcustom elfeed-summary-confirm-mark-read t
  "Whether to confirm marking the feed as read."
  :group 'elfeed-summary
  :type 'boolean)

(defcustom elfeed-summary-group-faces
  '(magit-section-heading magit-section-secondary-heading)
  "List of default group faces, one face per level."
  :group 'elfeed-summary
  :type '(repeat face))

(defcustom elfeed-summary-other-window nil
  "Whether to open the elfeed-search buffer in other window."
  :group 'elfeed-summary
  :type 'boolean)

(defcustom elfeed-summary-width 55
  "Width of the summary buffer when opening the search buffer.

Useful only if `elfeed-summary-other-window' is set to t."
  :group 'elfeed-summary
  :type 'integer)

(defconst elfeed-summary-buffer "*elfeed-summary*"
  "Elfeed summary buffer name.")

(defface elfeed-summary-group-face
  '((t (:inherit magit-section-heading)))
  "Default face for the elfeed summary group."
  :group 'elfeed-summary)

(defface elfeed-summary-count-face
  '((t (:inherit elfeed-search-title-face)))
  "Face for the number of entries of a read feed or search."
  :group 'elfeed-summary)

(defface elfeed-summary-count-face-unread
  '((t (:inherit elfeed-search-unread-title-face)))
  "Face for the number of entries of an unread feed or search."
  :group 'elfeed-summary)


;;; Logic
(cl-defun elfeed-summary--match-tag (query &key tags title url author title-meta)
  "Check if attributes of elfeed feed match QUERY.

QUERY is a `<query-params>' form as described in
`elfeed-summary-settings'.

TAGS is a list of tags from `elfeed-feeds', TITLE, URL, AUTHOR
and TITLE-META are attributes of the `elfeed-db-feed'."
  (cond
   ;; `:all'
   ((equal query :all) t)
   ;; symbol
   ((symbolp query) (member query tags))
   ;; (title . "Title")
   ;; (title . (rx "Title"))
   ((eq (car query) 'title)
    (or (and title
             (string-match-p
              (if (stringp (cdr query))
                  (cdr query)
                (eval (cdr query)))
              title))
        (and title-meta
             (string-match-p
              (if (stringp (cdr query))
                  (cdr query)
                (eval (cdr query)))
              title-meta))))
   ;; (author . "Author")
   ;; (author . (rx "Author"))
   ((eq (car query) 'author)
    (and author
         (string-match-p
          (if (stringp (cdr query))
              (cdr query)
            (eval (cdr query)))
          author)))
   ;; (url . "URL")
   ;; (url . (rx "URL"))
   ((eq (car query) 'url)
    (and url
         (string-match-p
          (if (stringp (cdr query))
              (cdr query)
            (eval (cdr query)))
          url)))
   ;; (and <query-1> <query-2> ... <query-n>)
   ((eq (car query) 'and)
    (seq-every-p
     (lambda (query-elem)
       (elfeed-summary--match-tag
        query-elem
        :tags tags
        :title title
        :title-meta title-meta
        :url url
        :author author))
     (cdr query)))
   ;; (not <query>)
   ((eq (car query) 'not)
    (not
     (elfeed-summary--match-tag
      (cdr query)
      :tags tags
      :title title
      :title-meta title-meta
      :url url
      :author author)))
   ;; (or <query-1> <query-2> ... <query-n>)
   ;; (<query-1> <query-2> ... <query-n>)
   (t (seq-some
       (lambda (query-elem)
         (elfeed-summary--match-tag
          query-elem
          :tags tags
          :title title
          :title-meta title-meta
          :url url
          :author author))
       (if (eq (car query) 'or)
           (cdr query)
         query)))))

(defun elfeed-summary--feed-sort-fn (feed-1 feed-2)
  "The default implementation of a feed sorting function.

FEED-1 and FEED-2 are instances of `elfeed-feed'."
  (string-lessp
   (downcase
    (or (plist-get (elfeed-feed-meta feed-1) :title)
        (elfeed-feed-title feed-1)
        (elfeed-feed-id feed-1)))
   (downcase
    (or (plist-get (elfeed-feed-meta feed-2) :title)
        (elfeed-feed-title feed-2)
        (elfeed-feed-id feed-2)))))

(defun elfeed-summary--get-feeds (query)
  "Get elfeed feeds that match QUERY.

QUERY is described in `elfeed-summary-settings'."
  (seq-sort
   elfeed-summary-feed-sort-fn
   (cl-loop for entry in elfeed-feeds
            for url = (car entry)
            for tags = (cdr entry)
            for feed = (elfeed-db-get-feed url)
            if (elfeed-summary--match-tag
                query
                :tags tags
                :title (elfeed-feed-title feed)
                :title-meta (plist-get (elfeed-feed-meta feed) :title)
                :url url
                :author (plist-get (car (elfeed-feed-author feed)) :name))
            collect feed)))

(defun elfeed-summary--feed-face-fn (_feed tags)
  "The default implementation of the feed face function.

FEED is an instance of `elfeed-feed', TAGS is a list of tags from
`elfeed-feeds'."
  (elfeed-search--faces tags))

(defun elfeed-summary--build-tree-feed (feed unread-count total-count)
  "Create a feed entry for the summary details tree.

FEED is an instance of `elfeed-feed'.  UNREAD-COUNT and TOTAL-COUNT
are hashmaps with feed ids as keys and corresponding numbers of
entries as values."
  (let* ((unread (or (gethash (elfeed-feed-id feed) unread-count) 0))
         (tags (alist-get (elfeed-feed-id feed) elfeed-feeds
                          nil nil #'equal))
         (all-tags (if (< 0 unread)
                       (cons elfeed-summary-unread-tag tags)
                     tags)))
    `(feed . ((feed . ,feed)
              (unread . ,unread)
              (total . ,(or (gethash (elfeed-feed-id feed) total-count) 0))
              (faces . ,(funcall elfeed-summary-feed-face-fn feed all-tags))
              (tags . ,all-tags)))))

(defun elfeed-summary--search-face-fn (search unread _total)
  "The default implementation of the search entry face function.

SEARCH is a `<search-params>' form as described in
`elfeed-summary-settings'.

UNREAD is the number of unread entries, TOTAL is the total number of
entries."
  (let ((tags (append
               (alist-get :tags search)
               (when (< 0 unread)
                 '(unread)))))
    (elfeed-search--faces tags)))

(defun elfeed-summary--build-search (search)
  "Create a search entry for the summary details tree.

SEARCH is a `<search-params>' form as described in
`elfeed-summary-settings'.

Implented the same way as `elfeed-search--update-list'."
  (let* ((filter-str
          (concat
           (when (alist-get :add-default search)
             elfeed-summary-default-filter)
           (alist-get :filter search)))
         (filter (elfeed-search-parse-filter filter-str))
         (head (list nil))
         (tail head)
         (unread 0)
         (total 0)
         unread-ids)
    (if elfeed-search-compile-filter
        ;; Force lexical bindings regardless of the current
        ;; buffer-local value. Lexical scope uses the faster
        ;; stack-ref opcode instead of the traditional varref opcode.
        (let ((lexical-binding t)
              (func (byte-compile (elfeed-search-compile-filter filter))))
          (with-elfeed-db-visit (entry feed)
            (when (funcall func entry feed total)
              (setf (cdr tail) (list entry)
                    tail (cdr tail)
                    total (1+ total))
              (when (member elfeed-summary-unread-tag (elfeed-entry-tags entry))
                (setq unread (1+ unread))
                (push (elfeed-entry-id entry) unread-ids) ))))
      (with-elfeed-db-visit (entry feed)
        (when (elfeed-search-filter filter entry feed total)
          (setf (cdr tail) (list entry)
                tail (cdr tail)
                total (1+ total))
          (when (member elfeed-summary-unread-tag (elfeed-entry-tags entry))
            (setq unread (1+ unread))
            (push (elfeed-entry-id entry) unread-ids)))))
    `(search . ((params . ,(cdr search))
                (faces . ,(funcall elfeed-summary-search-face-fn
                                   (cdr search) unread total))
                (unread . ,unread)
                (unread-ids . ,unread-ids)
                (total . ,total)))))

(defun elfeed-summary--get-tags-ordered ()
  "Return the list of elfeed tags, properly ordered.

The tags are ordered (1) by their most frequent position in
`elfeed-feeds' and (2) alphabetically."
  (let* ((tags-order
          ;; list of (tag . ((<position-1> . <freq-1>) (<position-2> . <freq-2>) ...))
          (cl-loop with tags-order = '()
                   for feed in elfeed-feeds
                   do (cl-loop for tag in (cdr feed)
                               for i from 0
                               unless (alist-get tag tags-order)
                               do (push (list tag) tags-order)
                               do (cl-incf (alist-get
                                            i (alist-get tag tags-order) 0)))
                   finally return tags-order))
         ;; list of (tag . <most-frequent-position>)
         (tags-most-freq-order
          (cl-loop for (tag . order) in tags-order collect
                   (cons
                    tag
                    (car
                     (cl-reduce
                      (lambda (acc value)
                        (if (> (cdr value) (cdr acc))
                            value
                          acc))
                      order
                      :initial-value '(-1 . -1)))))))
    (mapcar
     #'car
     (seq-sort
      (lambda (datum1 datum2)
        (if (not (= (cdr datum1) (cdr datum2)))
            (< (cdr datum1) (cdr datum2))
          (string-lessp (symbol-name (car datum1))
                        (symbol-name (car datum2)))))
      tags-most-freq-order))))

(defun elfeed-summary--build-tree-auto-tags-reorder-tags (feeds)
  "Reorder tags in FEEDS.

FEEDS is a list of (<feed> . <tags>), where <feed> is an instance of
`elfeed-feed' and <tags> is a list of tag symbols."
  (let* ((all-tags (elfeed-summary--get-tags-ordered))
         (tag-priority (make-hash-table)))
    (cl-loop for tag in all-tags
             for i from 0
             do (puthash tag i tag-priority))
    (cl-loop for (feed . tags) in feeds
             collect
             (cons feed
                   (seq-sort-by (lambda (tag) (gethash tag tag-priority))
                                #'> tags)))))

(defun elfeed-summary--compare-sequences (sequence1 sequence2)
  "Compare SEQUENCE1 and SEQUENCE2.

Both are lists of symbols."
  (cond
   ((null sequence1) t)
   ((null sequence2) nil)
   (t (let ((item1 (symbol-name (car sequence1)))
            (item2 (symbol-name (car sequence2))))
        (if (string-equal item1 item2)
            (elfeed-summary--compare-sequences (cdr sequence1)
                                               (cdr sequence2))
          (string-lessp item1 item2))))))

(defun elfeed-summary--arrange-sequences-in-tree (sequences)
  "Arrange SEQUENCES in a tree structure.

Each element of SEQUENCES is a list of symbols.

The resulting structure is an alist of tree nodes with the following keys:
- `value' - the current node symbol
- `children' - child nodes
- `sequences' - sequences at this node

The root of the tree has the value of nil."
  (let ((ordered-sequences
         (seq-reverse
          (seq-sort #'elfeed-summary--compare-sequences sequences)))
        (tree `(,nil . ((value . ,nil) (children . ,nil) (sequences . ,nil))))
        current-tree-pos
        (processed-sequences (make-hash-table :test #'equal)))
    (dolist (sequence ordered-sequences)
      (unless (gethash sequence processed-sequences)
        (setq current-tree-pos tree)
        (dolist (value sequence)
          (if-let ((value-in-tree (alist-get value (alist-get 'children current-tree-pos))))
              (setq current-tree-pos value-in-tree)
            (setq current-tree-pos
                  (setf
                   (alist-get value (alist-get 'children current-tree-pos))
                   `((value . ,value) (children . ,nil) (sequences . ,nil))))))
        (push sequence (alist-get 'sequences current-tree-pos))
        (puthash sequence t processed-sequences)))
    tree))

(defun elfeed-summary--auto-tags-group-title (child-tree)
  "Default function to get the name of an auto-tags group.

CHILD-TREE is a structure as defined in
`elfeed-summary--arrange-sequences-in-tree', with tag lists as
sequences."
  (symbol-name (alist-get 'value child-tree)))

(defun elfeed-summary--build-tree-auto-tags-recursive
    (param tree feeds-by-tag-sequence unread-count total-count &optional level)
  "Recursively create the auto-tags tree.

PARAM is an `<auto-tags-params>' form as described in
`elfeed-summary-settings'.  TREE is the result of applying
`elfeed-summary--arrange-sequences-in-tree' onto the list of tags of
all feeds.

FEEDS-BY-TAG-SEQUENCE is a hashmap with lists of tags as keys and
instances of `elfeed-feed' as values.  This is used to figure out
feeds in a particular TREE node.

UNREAD-COUNT and TOTAL-COUNT are hashmaps with feed ids as keys and
corresponding numbers of entries as values.

LEVEL is the current level of recursion, which is 0 by default."
  (unless level
    (setq level 0))
  (let ((max-level (or (alist-get :max-level (cdr param)) 2))
        (face (when-let (faces (alist-get :faces (cdr param)))
                (nth (% level (length faces)) faces))))
    (append
     ;; Just append all the feeds at the current level
     (cl-loop for sequence in (alist-get 'sequences tree) append
              (cl-loop for feed in (seq-sort
                                    #'elfeed-summary--feed-sort-fn
                                    (gethash sequence feeds-by-tag-sequence))
                       collect (elfeed-summary--build-tree-feed
                                feed unread-count total-count)))
     ;; Go deeper if we can
     (when (< level max-level)
       (cl-loop
        for datum in (alist-get 'children tree)
        for child-tree = (cdr datum) collect
        `(group . ((params . ((:title
                               . ,(funcall elfeed-summary-auto-tags-group-title-fn
                                           child-tree))))
                   (face . ,face)
                   (children . ,(elfeed-summary--build-tree-auto-tags-recursive
                                 param child-tree feeds-by-tag-sequence
                                 unread-count total-count (1+ level)))))))
     ;; If we can't go deeper, this will just append all the feeds to
     ;; the current level anyway
     (when (>= level max-level)
       (cl-loop for datum in (alist-get 'children tree) append
                (elfeed-summary--build-tree-auto-tags-recursive
                 param (cdr datum) feeds-by-tag-sequence
                 unread-count total-count (1+ level)))))))

(defun elfeed-summary--build-tree-get-feeds (param misc-feeds)
  "Get feeds for PARAM.

PARAM is an alist with the optional `:source' key.  The value can be
either `(query . <query-params>)' or `:misc' (default).

MISC-FEEDS is the list of feeds used for `:misc'.

The result is a list of items like (`<feed>' tag1 tag2 ...), where
`<feed>' is an instance of `elfeed-feed'."
  (let* ((source (alist-get :source (cdr param))))
    (mapcar
     (lambda (feed)
       (cons feed (alist-get (elfeed-feed-id feed) elfeed-feeds
                             nil nil #'equal)))
     (cond ((or (eq source :misc) (null source))
            misc-feeds)
           ((and (listp source) (eq (car source) 'query))
            (elfeed-summary--get-feeds (cdr source)))
           (t (error "Invalid source: %s" source))))))

(defun elfeed-summary--build-tree-auto-tags (param unread-count total-count misc-feeds)
  "Create the auto-tags tree.

PARAM is a cons cell `(auto-tags . <auto-tags-params>)', where
`<auto-tags-params>' is described in `elfeed-summary-settings'.

UNREAD-COUNT and TOTAL-COUNT are hashmaps with feed ids as keys and
corresponding numbers of entries as values.

MISC-FEEDS is a list of feeds that were not used in PARAMS."
  (let ((feeds (elfeed-summary--build-tree-get-feeds param misc-feeds))
        (reorder-tags (not (alist-get :original-order (cdr param)))))
    (when reorder-tags
      (setq feeds (elfeed-summary--build-tree-auto-tags-reorder-tags feeds)))
    (let ((tree (elfeed-summary--arrange-sequences-in-tree
                 (mapcar #'cdr feeds)))
          (feeds-by-tag-sequence (make-hash-table :test #'equal)))
      (cl-loop
       for (feed . sequence) in feeds
       do (puthash sequence (cons feed (gethash sequence feeds-by-tag-sequence))
                   feeds-by-tag-sequence))
      (elfeed-summary--build-tree-auto-tags-recursive
       param tree feeds-by-tag-sequence unread-count total-count))))

(defun elfeed-summary--build-tree-tag-groups (param unread-count total-count misc-feeds)
  "Create the tag-groups tree.

PARAM is a cell of `(tag-groups . <tag-group-params>)', with the
`<tag-group-params>' form as defined in `elfeed-summary-settings'.

UNREAD-COUNT and TOTAL-COUNT are hashmaps with feed ids as keys and
corresponding numbers of entries as values.

MISC-FEEDS is a list of feeds that were not used in PARAMS."
  (let ((feeds (elfeed-summary--build-tree-get-feeds param misc-feeds))
        (repeat-feeds (alist-get :repeat-feeds (cdr param)))
        (face (alist-get :face (cdr param)))
        (groups (make-hash-table)))
    (if (not repeat-feeds)
        (let ((tag-freqs (make-hash-table)))
          (cl-loop for feed in feeds do
                   (cl-loop for tag in (cdr feed) do
                            (puthash
                             tag (1+ (gethash tag tag-freqs 0))
                             tag-freqs)))
          (cl-loop for feed in feeds
                   for min-freq-tag = (cl-reduce
                                       (lambda (acc tag)
                                         (let ((freq (gethash tag tag-freqs)))
                                           (if (or (null (cdr acc)) (< freq (cdr acc)))
                                               (cons tag freq)
                                             acc)))
                                       (cdr feed)
                                       :initial-value '(nil . nil))
                   when min-freq-tag do
                   (puthash (car min-freq-tag)
                            (cons (car feed) (gethash min-freq-tag groups))
                            groups)))
      (cl-loop for feed in feeds do
               (cl-loop for tag in (cdr feed) do
                        (puthash tag (cons (car feed) (gethash tag groups)) groups))))
    (let ((groups-list (seq-sort-by
                        (lambda (f) (symbol-name (car f)))
                        #'string-lessp
                        (cl-loop for tag being the hash-keys of groups
                                 using (hash-values feeds)
                                 collect (cons tag feeds)))))
      (cl-loop for (tag . feeds) in groups-list
               collect `(group
                         . ((params . ((:title . ,(symbol-name tag))))
                            (face . ,face)
                            (children . ,(mapcar
                                          (lambda (feed) (elfeed-summary--build-tree-feed
                                                          feed unread-count total-count))
                                          (seq-sort
                                           #'elfeed-summary--feed-sort-fn feeds)))))))))

(defun elfeed-summary--build-tree (params unread-count total-count misc-feeds)
  "Recursively create the summary details tree.

PARAMS is a form as described in `elfeed-summary-settings'.

UNREAD-COUNT and TOTAL-COUNT are hashmaps with feed ids as keys and
corresponding numbers of entries as values.

MISC-FEEDS is a list of feeds that were not used in PARAMS.

The resulting form is described in `elfeed-summary--get-data'."
  (cl-loop for param in params
           if (and (listp param) (eq (car param) 'group))
           collect `(group . ((params . ,(cdr param))
                              (face . ,(alist-get :face (cdr param)))
                              (children . ,(elfeed-summary--build-tree
                                            (cdr (assoc :elements (cdr param)))
                                            unread-count total-count misc-feeds))))
           else if (and (listp param) (eq (car param) 'search))
           collect (elfeed-summary--build-search param)
           else if (and (listp param) (eq (car param) 'query))
           append (cl-loop for feed in (elfeed-summary--get-feeds (cdr param))
                           collect (elfeed-summary--build-tree-feed
                                    feed unread-count total-count))
           else if (and (listp param) (eq (car param) 'auto-tags))
           append (elfeed-summary--build-tree-auto-tags
                   param unread-count total-count misc-feeds)
           else if (and (listp param) (eq (car param) 'tag-groups))
           append (elfeed-summary--build-tree-tag-groups
                   param unread-count total-count misc-feeds)
           else if (eq param :misc)
           append (cl-loop for feed in (seq-sort #'elfeed-summary--feed-sort-fn
                                                 misc-feeds)
                           collect (elfeed-summary--build-tree-feed
                                    feed unread-count total-count))
           else do (error "Can't parse: %s" (prin1-to-string param))))

(defun elfeed-summary--extract-feeds (params)
  "Extract feeds from PARAMS.

PARAMS is a form as described in `elfeed-summary-settings'."
  (cl-loop for param in params
           if (and (listp param) (eq (car param) 'group))
           append (elfeed-summary--extract-feeds
                   (cdr (assoc :elements (cdr param))))
           else if (and (listp param) (eq (car param) 'query))
           append (elfeed-summary--get-feeds (cdr param))
           else if (and (listp param)
                        (or (eq (car param) 'auto-tags) (eq (car param) 'tag-groups))
                        (eq (car-safe (alist-get :source (cdr param)))
                            'query))
           append (elfeed-summary--get-feeds
                   (cdr (alist-get :source (cdr param))))))

(defun elfeed-summary--ensure ()
  "Ensure that elfeed database is loaded and feeds are set up."
  (elfeed-db-ensure)
  (when (and (fboundp #'rmh-elfeed-org-process)
             ;; To silence the byte compiler
             (boundp 'rmh-elfeed-org-files)
             (boundp 'rmh-elfeed-org-tree-id))
    (rmh-elfeed-org-process rmh-elfeed-org-files rmh-elfeed-org-tree-id)))

(defun elfeed-summary--get-data ()
  "Create the summary details tree from scratch.

The summary tree is created by extending `elfeed-summary-settings'
with the data from the elfeed database.

The return value is a list of alists of the following elements:
- `(group . <tree-group-params>)'
- `(feed . <feed-group-params>)'
- `(search . <search-group-params>)'

`<tree-group-params>' is an alist with the following keys:
- `params' - `<group-params>' as described in
  `elfeed-summary-settings'.
- `face' - face for the group.
- `children' - list of children, same structure as the root form.

`<feed-group-params>' is an alist with the following keys:
- `feed' - an instance of `elfeed-feed'.
- `tags' - feed tags.
- `faces' - list of faces for the search entry.
- `unread' - number of unread entries in the feed.
- `total' - total number of entries in the feed.

`<search-group-params>' is an alist with the following keys:
- `params' - `<search-params>' as described in
  `elfeed-summary-settings'.
- `faces' - list of faces for the search entry.
- `unread' - number of unread entries in the search results.
- `unread-ids' - ids of unread entries for marking them as read.
- `total' - total number of entries in the search results."
  (let* ((feeds (elfeed-summary--extract-feeds
                 elfeed-summary-settings))
         (all-feeds (mapcar #'car elfeed-feeds))
         (misc-feeds
          (thread-last feeds
                       (mapcar #'elfeed-feed-id)
                       (seq-difference all-feeds)
                       (mapcar #'elfeed-db-get-feed)))
         (unread-count (make-hash-table :test #'equal))
         (total-count (make-hash-table :test #'equal)))
    (with-elfeed-db-visit (entry feed)
      (puthash (elfeed-feed-id feed)
               (1+ (or (gethash (elfeed-feed-id feed) total-count) 0))
               total-count)
      (when (member elfeed-summary-unread-tag (elfeed-entry-tags entry))
        (puthash (elfeed-feed-id feed)
                 (1+ (or (gethash (elfeed-feed-id feed) unread-count) 0))
                 unread-count))
      (when (> (- (float-time)
                  elfeed-summary-look-back)
               (elfeed-entry-date entry))
        (elfeed-db-return)))
    (elfeed-summary--build-tree elfeed-summary-settings
                                unread-count total-count misc-feeds)))

;;; View
(defvar-local elfeed-summary--tree nil
  "The current value of the elfeed summary tree.")

(defvar elfeed-summary--unread-padding 3
  "Padding for the unread column in the elfeed summary buffer.")

(defvar elfeed-summary--total-padding 3
  "Padding for the total column in the elfeed summary buffer.")

(defvar elfeed-summary--only-unread nil
  "Only show items with unread entries in the elfeed summary buffer.")

(defvar elfeed-summary--search-show-read nil
  "Do not filter +unread when switching to the elfeed search buffer.")

(defvar elfeed-summary--search-mark-read nil
  "If t, mark the feed as read instead of switching to it.")

(defun elfeed-summary--magit-section-toggle-workaround (section)
  "`magit-section-toggle' with a workaround for invisible lines.

SECTION is an instance of `magit-section'.

No idea what I'm doing wrong, but this seems to help."
  (interactive (list (save-excursion
                       (let ((lines (count-lines (point-min) (point-max))))
                         (while (and (invisible-p (point))
                                     (< (line-number-at-pos) lines))
                           (forward-line 1)))
                       (magit-current-section))))
  (magit-section-toggle section))

(defvar elfeed-summary-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map magit-section-mode-map)
    (define-key map (kbd "RET") #'elfeed-summary--action)
    (define-key map (kbd "M-RET") #'elfeed-summary--action-show-read)
    (define-key map (kbd "q") #'elfeed-summary-quit-window)
    (define-key map (kbd "r") #'elfeed-summary--refresh)
    (define-key map (kbd "R") #'elfeed-summary-update)
    (define-key map (kbd "u") #'elfeed-summary-toggle-only-unread)
    (define-key map (kbd "U") #'elfeed-summary--action-mark-read)
    (define-key map (kbd "<tab>") #'elfeed-summary--magit-section-toggle-workaround)
    (when (fboundp #'evil-define-key*)
      (evil-define-key* 'normal map
        (kbd "<tab>") #'elfeed-summary--magit-section-toggle-workaround
        "r" #'elfeed-summary--refresh
        "R" #'elfeed-summary-update
        "u" #'elfeed-summary-toggle-only-unread
        (kbd "RET") #'elfeed-summary--action
        "M-RET" #'elfeed-summary--action-show-read
        "U" #'elfeed-summary--action-mark-read
        "q" #'elfeed-summary-quit-window))
    map)
  "A keymap for `elfeed-summary-mode-map'.")

(define-derived-mode elfeed-summary-mode magit-section "Elfeed Summary"
  "A major mode to display the elfeed summary data."
  :group 'org-journal-tags
  (setq-local buffer-read-only t)
  (setq-local truncate-lines t))

(defclass elfeed-summary-group-section (magit-section)
  ((group :initform nil)))

(defun elfeed-summary--action (pos &optional event)
  "Run action at thing at the point in the elfeed summary buffer.

If there's a widget at the point, pass the press event to the widget.
That should result in the call to
`elfeed-summary--feed-notify'.  Otherwise, if there's a group
section, run the corresponding action for the group.

The behavior of both `elfeed-summary--feed-notify' and
`elfeed-summary--open-section' is modified by lexically scoped
variables `elfeed-summary--search-show-read' and
`elfeed-summary--search-mark-read'.

POS and EVENT are forwarded to `widget-button-press'."
  (interactive "@d")
  (cond ((get-char-property pos 'button)
         (widget-button-press pos event))
        ((when-let (section (magit-current-section))
           (and (slot-exists-p section 'group)
                (slot-boundp section 'group)))
         (elfeed-summary--open-section (magit-current-section)))))

(defun elfeed-summary--action-show-read (pos &optional event)
  "Run action with `elfeed-summary--search-show-read' set to t.

POS and EVENT are forwarded to `widget-button-press'."
  (interactive "@d")
  (let ((elfeed-summary--search-show-read t))
    (elfeed-summary--action pos event)))

(defun elfeed-summary--action-mark-read (pos &optional event)
  "Run action with `elfeed-summary--search-mark-read' set to t.

POS and EVENT are forwarded to `widget-button-press'."
  (interactive "@d")
  (let ((elfeed-summary--search-mark-read t))
    (elfeed-summary--action pos event)))

(defun elfeed-summary--mark-read (feeds)
  "Mark all the entries in FEEDS as read.

FEEDS is a list of instances of `elfeed-feed'."
  (when (or (not elfeed-summary-confirm-mark-read)
            (y-or-n-p "Mark all entries in feed as read? "))
    (with-elfeed-db-visit (entry feed)
      (when (member feed feeds)
        (when (member elfeed-summary-unread-tag (elfeed-entry-tags entry))
          (setf (elfeed-entry-tags entry)
                (seq-filter (lambda (tag) (not (eq elfeed-summary-unread-tag tag)))
                            (elfeed-entry-tags entry))))))
    (elfeed-summary--refresh)))

(defun elfeed-summary--open-elfeed ()
  "Open elfeed.

If `elfeed-summary-other-window' is t, open elfeed in other window."
  (if elfeed-summary-other-window
      (let ((window (selected-window)))
        (switch-to-buffer-other-window (elfeed-search-buffer))
        (when elfeed-summary-width
          (with-selected-window window
            (enlarge-window (- elfeed-summary-width
                               (window-width))
                            t))))
    (switch-to-buffer (elfeed-search-buffer)))
  (unless (eq major-mode 'elfeed-search-mode)
    (elfeed-search-mode)))

(defun elfeed-summary--goto-feed (feed show-read)
  "Open the FEED in a elfeed search buffer.

FEED is an instance `elfeed-feed'.  If SHOW-READ is t, also show read
items."
  (elfeed-summary--open-elfeed)
  (elfeed-search-set-filter
   (concat
    elfeed-summary-default-filter
    (unless (or elfeed-summary--search-show-read
                show-read)
      (format "+%s " elfeed-summary-unread-tag))
    "="
    (rx-to-string (elfeed-feed-id feed) t))))

(defun elfeed-summary--feed-notify (widget &rest _)
  "The function to run in `:notify' in a feed widget button.

WIDGET is the instance of the pressed widget."
  (cond
   (elfeed-summary--search-mark-read
    (elfeed-summary--mark-read (list (widget-get widget :feed))))
   (t (elfeed-summary--goto-feed
       (widget-get widget :feed) (widget-get widget :only-read)))))

(defun elfeed-summary--group-extract-feeds (group)
  "Extract feeds from GROUP.

GROUP is a `<tree-group-params>' as described in
`elfeed-summary--get-data'."
  (cl-loop for child in (alist-get 'children group)
           if (eq (car child) 'group)
           append (elfeed-summary--group-extract-feeds child)
           else if (eq (car child) 'feed)
           collect (alist-get 'feed (cdr child))))

(defun elfeed-summary--open-section (section)
  "Open section under cursor.

SECTION is an instance of `elfeed-summary-group-section'."
  (let ((feeds (elfeed-summary--group-extract-feeds
                (oref section group))))
    (unless feeds
      (user-error "No feeds in section!"))
    (cond
     (elfeed-summary--search-mark-read
      (elfeed-summary--mark-read feeds))
     (t (elfeed-summary--open-elfeed)
        (elfeed-search-set-filter
         (concat
          elfeed-summary-default-filter
          (unless elfeed-summary--search-show-read
            (format "+%s " elfeed-summary-unread-tag))
          (mapconcat
           (lambda (feed)
             (format "=%s" (rx-to-string (elfeed-feed-id feed) t)))
           feeds
           " ")))))))

(defun elfeed-summary--render-feed (data _level)
  "Render a feed item for the elfeed summary buffer.

DATA is a `<feed-group-params>' form as described in
`elfeed-summary--get-data'.  LEVEL is the level of the recursive
descent."
  (let* ((feed (alist-get 'feed data))
         (title (or (plist-get (elfeed-feed-meta feed) :title)
                    (elfeed-feed-title feed)
                    (elfeed-feed-id feed)))
         (text-format-string
          (concat "%" (number-to-string elfeed-summary--unread-padding)
                  "d / %-" (number-to-string elfeed-summary--total-padding)
                  "d "))
         (text (concat
                (propertize
                 (format text-format-string
                         (alist-get 'unread data) (alist-get 'total data))
                 'face (if (< 0 (alist-get 'unread data))
                           'elfeed-summary-count-face-unread
                         'elfeed-summary-count-face))
                (propertize title 'face (alist-get 'faces data)))))
    (widget-create 'push-button
                   :notify #'elfeed-summary--feed-notify
                   :feed feed
                   :only-read (= 0 (alist-get 'unread data))
                   text)
    (insert "\n")))

(defun elfeed-summary--mark-read-ids (ids)
  "Mark elfeed entries with IDS as read."
  (when (or (not elfeed-summary-confirm-mark-read)
            (y-or-n-p "Mark all entries in feed as read? "))
    (let ((ids-hash (make-hash-table)))
      (dolist (id ids)
        (puthash id t ids-hash))
      (with-elfeed-db-visit (entry feed)
        ;; XXX to shut up the byte compiler
        (ignore feed)
        (when (and
               (gethash (elfeed-entry-id entry) ids-hash nil)
               (member elfeed-summary-unread-tag (elfeed-entry-tags entry)))
          (setf (elfeed-entry-tags entry)
                (seq-filter (lambda (tag) (not (eq elfeed-summary-unread-tag tag)))
                            (elfeed-entry-tags entry))))))
    (elfeed-summary--refresh)))

(defun elfeed-summary--search-notify (widget &rest _)
  "The function to run in `:notify' in a search widget button.

WIDGET is the instance of the pressed widget."
  (cond
   (elfeed-summary--search-mark-read
    (elfeed-summary--mark-read-ids
     (widget-get widget :unread-ids)))
   (t (elfeed-summary--open-elfeed)
      (elfeed-search-set-filter
       (concat
        (when (widget-get widget :add-default)
          elfeed-summary-default-filter)
        (widget-get widget :filter)
        (unless (or elfeed-summary--search-show-read
                    (widget-get widget :only-read))
          (format " +%s " elfeed-summary-unread-tag)))))))

(defun elfeed-summary--render-search (data _level)
  "Render a search item for the elfeed summary buffer.

DATA is a `<search-group-params>' form as described in the
`elfeed-summary--get-data'.  LEVEL is the level of the recursive
descent."
  (let* ((search-data (alist-get 'params data))
         (text-format-string
          (concat "%" (number-to-string elfeed-summary--unread-padding)
                  "d / %-" (number-to-string elfeed-summary--total-padding)
                  "d "))
         (text (concat
                (propertize
                 (format text-format-string
                         (alist-get 'unread data) (alist-get 'total data))
                 'face
                 (if (< 0 (alist-get 'unread data))
                     'elfeed-summary-count-face-unread
                   'elfeed-summary-count-face))
                (propertize
                 (alist-get :title search-data)
                 'face
                 (alist-get 'faces data)))))
    (widget-create 'push-button
                   :notify #'elfeed-summary--search-notify
                   :filter (alist-get :filter search-data)
                   :only-read (= 0 (alist-get 'unread data))
                   :add-default (alist-get :add-default search-data)
                   :unread-ids (alist-get 'unread-ids data)
                   text)
    (widget-insert "\n")))

(defun elfeed-summary--render-group (data level)
  "Render a group item for the elfeed summary buffer.

DATA is a `<tree-group-params>' from as described in
`elfeed-summary-get-data'.  LEVEL is the level of the recursive
descent."
  (let ((group-data (alist-get 'params data)))
    (magit-insert-section group (elfeed-summary-group-section
                                 nil (alist-get :hide group-data))
      (insert (propertize
               (alist-get :title group-data)
               'face
               (or (alist-get 'face data)
                   (nth (% level (length elfeed-summary-group-faces))
                        elfeed-summary-group-faces))))
      (insert "\n")
      (magit-insert-heading)
      (oset group group data)
      (cl-loop for child in (alist-get 'children data)
               do (elfeed-summary--render-item child (1+ level))))))

(defun elfeed-summary--render-item (item &optional level)
  "Render one item for the elfeed summary buffer.

ITEM is one alist as returned by `elfeed-summary--get-data'.  LEVEL is
the level of the recursive descent."
  (unless level
    (setq level 0))
  (let ((data (cdr item)))
    (pcase (car item)
      ('group
       (elfeed-summary--render-group data level))
      ('feed
       (elfeed-summary--render-feed data level))
      ('search
       (elfeed-summary--render-search data level))
      (_ (error "Unknown tree item: %s" (prin1-to-string (car item)))))))

(defun elfeed-summary--render-params (tree &optional max-unread max-total)
  "Get rendering parameters from the summary tree.

TREE is a form such as returned by `elfeed-summary--get-data'.

MAX-UNREAD and MAX-TOTAL are parameters for the recursive descent."
  (unless max-unread
    (setq max-unread 0
          max-total 0))
  (cl-loop for item in tree
           for type = (car item)
           if (eq type 'group)
           do (let ((data (elfeed-summary--render-params
                           (alist-get 'children (cdr item))
                           max-unread max-total)))
                (setq max-unread (max max-unread (nth 0 data))
                      max-total (max max-total (nth 1 data))))
           else if (or (eq type 'feed) (eq type 'search))
           do (setq max-unread
                    (max max-unread (alist-get 'unread (cdr item)))
                    max-total
                    (max max-total (alist-get 'total (cdr item)))))
  (list max-unread max-total))

(defun elfeed-summary--leave-only-unread (tree)
  "Leave only items that have unread elfeed entries in them.

TREE is a form such as returned by `elfeed-summary--get-data'."
  (cl-loop for item in tree
           for type = (car item)
           if (and (eq type 'group)
                   (let ((children (elfeed-summary--leave-only-unread
                                    (alist-get 'children (cdr item)))))
                     (setf (alist-get 'children (cdr item))
                           children)
                     (< 0 (length children))))
           collect item
           else if (and (or (eq type 'feed) (eq type 'search))
                        (< 0 (alist-get 'unread (cdr item))))
           collect item))

(defun elfeed-summary--render (tree)
  "Render the elfeed summary tree.

TREE is a form such as returned by `elfeed-summary--get-data'."
  (when elfeed-summary--only-unread
    (setq tree (elfeed-summary--leave-only-unread tree)))
  (setq-local widget-push-button-prefix "")
  (setq-local widget-push-button-suffix "")
  (setq-local elfeed-search-filter-active t)
  (let* ((inhibit-read-only t)
         (render-data (elfeed-summary--render-params tree))
         (elfeed-summary--unread-padding
          (length (number-to-string (nth 0 render-data))))
         (elfeed-summary--total-padding
          (length (number-to-string (nth 1 render-data)))))
    (erase-buffer)
    (setq-local elfeed-summary--tree tree)
    (unless (eq major-mode 'elfeed-summary-mode)
      (elfeed-summary-mode))
    (insert (elfeed-search--header) "\n\n")
    (magit-insert-section _
      (magit-insert-heading)
      (unless tree
        (insert "No items found."))
      (mapc #'elfeed-summary--render-item tree))
    (widget-setup)))

(defun elfeed-summary--get-folding-state (&optional section folding-state parent-hidden)
  "Get the folding state of elfeed summary groups.

SECTION is an instance of `magit-section', FOLDING-STATE is a hash
map.  PARENT-HIDDEN shows whether the parent section is hidden.

If SECTION has the `group' slot, it is presumed to hold an instance of
`<tree-group-params>' as described in `elfeed-summary--get-data'.  The
resulting hash map will have `<group-params>' as keys and values of
the corresponding `hidden' slots as values."
  (unless section
    (setq section magit-root-section))
  (unless folding-state
    (setq folding-state (make-hash-table :test #'equal)))
  (when (and (slot-exists-p section 'group)
             (slot-boundp section 'group))
    (puthash (alist-get 'params (oref section group))
             (or parent-hidden (oref section hidden))
             folding-state))
  (cl-loop for child in (oref section children)
           do (elfeed-summary--get-folding-state
               child folding-state (oref section hidden)))
  folding-state)

(defun elfeed-summary--restore-folding-state (folding-state &optional section)
  "Restore the folding state of elfeed summary groups.

FOLDING-STATE is a hash map as returned by
`elfeed-summary--get-folding-state'.

SECTION is an instance of `magit-section', used for recursive
descent."
  (unless section
    (setq section magit-root-section))
  (when (and (slot-exists-p section 'group)
             (slot-boundp section 'group)
             (not (eq (gethash (alist-get 'params (oref section group) 'null)
                               folding-state)
                      'null)))
    (if (gethash (alist-get 'params (oref section group)) folding-state)
        (magit-section-hide section)
      (magit-section-show section)))
  (cl-loop for child in (oref section children)
           do (elfeed-summary--restore-folding-state folding-state child)))

(defun elfeed-summary--refresh ()
  "Refresh the elfeed summary tree."
  (interactive)
  (when (equal (buffer-name) elfeed-summary-buffer)
    ;; XXX this should've been `save-excursion, but somehow it doesn't
    ;; work.  And it is also necessary to preserve the folding state.
    (let ((inhibit-read-only t)
          (point (point))
          (window-start (window-start))
          (folding-state (elfeed-summary--get-folding-state)))
      (erase-buffer)
      (elfeed-summary--render
       (elfeed-summary--get-data))
      (elfeed-summary--restore-folding-state folding-state)
      (set-window-point (get-buffer-window) point)
      (set-window-start (get-buffer-window) window-start))))

(defun elfeed-summary-toggle-only-unread ()
  "Toggle displaying only items with unread elfeed entries."
  (interactive)
  (setq-local elfeed-summary--only-unread
              (not elfeed-summary--only-unread))
  (elfeed-summary--refresh))

(defun elfeed-summary--on-feed-update (&rest _)
  "Message the status of the elfeed update.

If `elfeed-summary-refresh-on-each-update' is t, also update the
summary buffer."
  (when-let (buffer (get-buffer elfeed-summary-buffer))
    (message (if (> (elfeed-queue-count-total) 0)
                 (let ((total (elfeed-queue-count-total))
                       (in-process (elfeed-queue-count-active)))
                   (format "%d jobs pending, %d active..."
                           (- total in-process) in-process))
               "Elfeed update completed"))
    (when elfeed-summary-refresh-on-each-update
      (with-current-buffer buffer
        (elfeed-summary--refresh)))))

(defun elfeed-summary--refresh-if-exists ()
  "Refresh the elfeed summary buffer if it exists."
  (when-let (buffer (get-buffer elfeed-summary-buffer))
    (with-current-buffer buffer
      (elfeed-summary--refresh))))

(defun elfeed-summary-update ()
  "Update all the feeds in `elfeed-feeds' and the summary buffer."
  (interactive)
  (elfeed-log 'info "Elfeed update: %s"
              (format-time-string "%B %e %Y %T %Z"))
  ;; XXX Here's a remarkably dirty solution.  This command is meant to
  ;; refresh the elfeed-summary buffer after all the feeds have been
  ;; updated.  But elfeed doesn't seem to provide anything to hook
  ;; into for that.
  ;; There's `elfeed-update-hooks', which is run after an individual feed
  ;; update, so it is possible to figure out when the last feed has
  ;; been updated.  But it seems impossible to override this hook with
  ;; lexical binding.
  ;; Thus, this function pushes a closure to the hook and cleans it up
  ;; afterwards.  Also, a closure is occasionally byte-compiled, so
  ;; this is checked by `byte-code-function-p'.
  (setq elfeed-update-hooks
        (seq-filter (lambda (hook)
                      (not (or (and (listp hook) (eq (car hook) 'closure))
                               (byte-code-function-p hook))))
                    elfeed-update-hooks))
  (let* ((elfeed--inhibit-update-init-hooks t)
         (remaining-feeds (elfeed-feed-list))
         (elfeed-update-closure
          (lambda (url)
            (message (if (> (elfeed-queue-count-total) 0)
                         (let ((total (elfeed-queue-count-total))
                               (in-process (elfeed-queue-count-active)))
                           (format "%d jobs pending, %d active..."
                                   (- total in-process) in-process))
                       "Elfeed update completed"))
            (setq remaining-feeds
                  (seq-remove
                   (lambda (url-1)
                     (string-equal url-1 url))
                   remaining-feeds))
            (when (seq-empty-p remaining-feeds)
              (setq elfeed-update-hooks
                    (seq-filter (lambda (hook)
                                  (not (or (and (listp hook) (eq (car hook) 'closure))
                                           (byte-code-function-p hook))))
                                elfeed-update-hooks)))
            (when (or (seq-empty-p remaining-feeds)
                      elfeed-summary-refresh-on-each-update)
              (elfeed-summary--refresh-if-exists)))))
    (add-hook 'elfeed-update-hooks elfeed-update-closure)
    (mapc #'elfeed-update-feed (elfeed--shuffle (elfeed-feed-list)))
    (run-hooks 'elfeed-update-init-hooks)
    (elfeed-db-save)))

(defvar elfeed-summary--setup nil
  "Whether elfeed summary was set up.")

(defun elfeed-summary--elfeed-search-quit ()
  "Quit the elfeed-search window.

This is meant to override `elfeed-search-quit-window'.

If elfeed summary buffer is available, refresh it, otherwise save the
database.  Thus the summary buffer will reflect changes made in the
search buffer."
  (interactive)
  (quit-window)
  (if-let (buffer (get-buffer elfeed-summary-buffer))
      (with-current-buffer buffer
        (elfeed-summary--refresh))
    (elfeed-db-save)))

(defun elfeed-summary-quit-window ()
  "Save the database, then `quit-window'."
  (interactive)
  (elfeed-db-save)
  (quit-window t))

(defun elfeed-summary--setup ()
  "Setup elfeed summary."
  (advice-add #'elfeed-search-quit-window :override #'elfeed-summary--elfeed-search-quit))

;;;###autoload
(defun elfeed-summary ()
  "Display a feed summary for elfeed.

The feed summary is a tree of three basic items: groups, feeds and
searches.  Groups also may contain other items.  The structure of the
tree is determined by the `elfeed-summary-settings' variable.

Take a look at `elfeed-summary-mode' for the list of available
keybindings, and at the `elfeed-summary' group for the available
options."
  (interactive)
  (elfeed-summary--ensure)
  (unless elfeed-summary--setup
    (elfeed-summary--setup))
  (when-let ((buffer (get-buffer elfeed-summary-buffer)))
    (kill-buffer buffer))
  (let ((buffer (get-buffer-create elfeed-summary-buffer)))
    (with-current-buffer buffer
      (elfeed-summary--render
       (elfeed-summary--get-data)))
    (switch-to-buffer buffer)
    (goto-char (point-min))))

(provide 'elfeed-summary)
;;; elfeed-summary.el ends here
