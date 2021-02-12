;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                     ;; Hi, I'm a box. My style is 525 ;;
                     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Features first:

** minor-mode features

   - auto-fill boxes (install filladapt for optimal filling)
   - motion (beginning-of-line, end-of-line) within box
   - S-return rebox-newline
   - kill/yank (within box) only text, not box borders
   - move box by using space, backspace / center with M-c
     - point has to be to the left of the border

** interesting variables for customization

   - `rebox-style-loop'
   - `rebox-min-fill-column'
   - `rebox-allowance'


; Installation:

1. Add rebox2.el to a directory in your load-path.

2. Basic install - add to your ".emacs":

       (setq rebox-style-loop '(24 16))
       (require 'rebox2)
       (global-set-key [(meta q)] 'rebox-dwim)
       (global-set-key [(shift meta q)] 'rebox-cycle)

   Note that if you do not need to specify the HUNDREDS digit of the style,
   rebox will figure it out based on the major-moe.

3. Full install - use `rebox-mode' in major-mode hooks:

       ;; setup rebox for emacs-lisp
       (add-hook 'emacs-lisp-mode-hook (lambda ()
                                         (set (make-local-variable 'rebox-style-loop) '(25 17 21))
                                         (set (make-local-variable 'rebox-min-fill-column) 40)
                                         (rebox-mode 1)))

   Default `rebox-style-loop' should work for most programming modes, however,
   you may want to set the style you prefer.

   Here is an customization example that

     - sets comments to use "/* ... */" style in c++-mode
     - adds Doxygen box style for C++

       (defun my-c++-setup ()
         (setq comment-start "/* "
               comment-end " */")
         (unless (memq 46 rebox-style-loop)
           (make-local-variable 'rebox-style-loop)
           (nconc rebox-style-loop '(46))))
       (add-hook 'c++-mode-hook #'my-c++-setup)

; Ideas removed from François Pinard's original version

* Building styles on top of each other.


; Future improvement ideas:

* remove reliance on dynamic binding using `destructuring-bind' or a hash
* allow mixed borders "-=-=-=-=-=-"
* optimize functions that modify the box contents so they don't unbuild and
  rebuild boxes all the time.
* style selection can use some kind of menu completion where all styles are
  presented and the user navigates

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
