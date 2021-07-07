;;; evil-textobj-anyblock.el --- Textobject for the closest user-defined blocks.

;; Author: Lit Wakefield <noct@openmailbox.org>
;; URL: https://github.com/noctuid/evil-textobj-anyblock
;; Package-Version: 20150901.2201
;; Package-Commit: 068d26a625cd6202aaf70a8ff399f9130c0ffa68
;; Keywords: evil
;; Package-Requires: ((cl-lib "0.5") (evil "1.1.0"))
;; Version: 0.1

;;; Commentary:
;; This package is a port of vim-textobj-anyblock. It gives text objects for the
;; closest block of those defined in the evil-anyblock-blocks alist. By default
;; it includes (), {}, [], <>, '', "", ``, and “”. This is convenient for
;; operating on the closest block without having to choose between typing
;; something like i{ or i<. This package allows for the list of blocks to be
;; changed. They can be more complicated regexps. A simple expand-region like
;; functionality is also provided when in visual mode, though this is not a
;; primary focus of the plugin and does not exist in vim-textobj-anyblock. Also,
;; in the case that the point is not inside of a block, anyblock will seek
;; forward to the next block.

;; The required version of evil is based on the last change I could find to
;; evil-select-paren, but the newest version of evil is probably preferable.

;; For more information see the README in the github repo.

;;; Code:
(require 'cl-lib)
(require 'evil)

(defgroup evil-anyblock nil
  "Gives text objects for selecting the closest block from any in a user-defined
alist."
  :group 'evil
  :prefix 'evil-anyblock-)

(defcustom evil-anyblock-blocks
  '(("(" . ")")
    ("{" . "}")
    ("\\[" . "\\]")
    ("<" . ">")
    ("'" . "'")
    ("\"" . "\"")
    ("`" . "`")
    ("“" . "”"))
  "Alist containing regexp blocks to look for."
  :group 'evil-anyblock
  :type '(alist
          :key-type regexp
          :value-type rexegp))

(defun evil-anyblock--choose-textobj-method
    (open-block close-block beg end type count outerp)
  "Determine appropriate evil function to use based on whether OPEN-BLOCK and
CLOSE-BLOCK can be characters and whether they are quotes. OUTERP determines
whether to make an outer or inner textobject."
  (let* ((blocks
          (if (= 1 (length open-block) (length close-block))
              ;; evil-up-block has undesirable behaviour
              ;; (which is what is used if arg to evil-select-paren is a string)
              (list (string-to-char open-block) (string-to-char close-block))
            (list open-block close-block)))
         (open-block (first blocks))
         (close-block (second blocks)))
    (if (and (equal open-block close-block)
             (or (equal open-block  ?')
                 (equal open-block  ?\")
                 (equal open-block  ?`)))
        (evil-select-quote open-block beg end type count outerp)
      (evil-select-paren open-block close-block beg end type count outerp))))

(defun evil-anyblock--sort-blocks (beg end type count outerp)
  "Sort blocks by the size of the selection they would create."
  (sort
   (cl-loop for (open-block . close-block) in evil-anyblock-blocks
            when (ignore-errors
                   (let ((block-info
                          (evil-anyblock--choose-textobj-method
                           open-block close-block beg end type count outerp)))
                     (when (and block-info
                                ;; prevent seeking forward behaviour for quotes
                                (>= (point) (first block-info))
                                (<= (point) (second block-info)))
                       block-info)))
            collect it)
   ;; sort by area of selection
   (lambda (x y) (< (- (second x) (first x))
                    (- (second y) (first y))))))

(defun evil-anyblock--seek-forward ()
  "If an open-block is found, seek to the position and return the open and close
blocks."
  (let* ((open-blocks (mapconcat 'car evil-anyblock-blocks "\\|"))
         (match-position (re-search-forward open-blocks nil t)))
    (when match-position
      ;; determine found block
      (cl-loop for (open-block . close-block) in evil-anyblock-blocks
         until (looking-back open-block)
         finally return (list open-block close-block)))))

(defun evil-anyblock--make-textobj (beg end type count outerp)
  "Helper function for creating both inner and outer text objects."
  (let ((textobj-info
         (car (evil-anyblock--sort-blocks beg end type count outerp))))
    (if textobj-info
        textobj-info
      ;; seek if no surrounding textobj found
      (let* ( ;; (save-position (point))
             (seek-block-list (evil-anyblock--seek-forward))
             (open-block (first seek-block-list))
             (close-block (second seek-block-list))
             ;; need to alter beg and end to get it to work in visual mode
             (new-beg (if (equal evil-state 'visual)
                          evil-visual-beginning
                        (point)))
             (new-end (save-excursion (right-char) (point))))
        (when seek-block-list
          (evil-anyblock--choose-textobj-method
           open-block close-block new-beg new-end type count outerp))))))

(evil-define-text-object evil-anyblock-inner-block
  (count &optional beg end type)
  "Select the closest inner anyblock block."
  (evil-anyblock--make-textobj beg end type count nil))

(evil-define-text-object evil-anyblock-a-block (count &optional beg end type)
  "Select the closest outer anyblock block."
  (evil-anyblock--make-textobj beg end type count t))

(provide 'evil-anyblock)
;;; evil-textobj-anyblock.el ends here
