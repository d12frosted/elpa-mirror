
`expectations', the simplest unit test framework using `ert'.
No test names! No extra typing!
This is aimed for a successor of el-expectations.
If you use el-expectations, you can simply replace.

I love Jay Fields' expectations unit testing framework in Ruby. It
provides one syntax and can define various assertions. So I created
Emacs Lisp Expectations modeled after expectations in Ruby.
Testing policy is same as the original expectations in Ruby. Visit
expectations site in rubyforge.
http://expectations.rubyforge.org/

With Emacs Lisp Mock (el-mock.el), Emacs Lisp Expectations supports
mock and stub, ie. behavior based testing.
You can get it from EmacsWiki
http://www.emacswiki.org/cgi-bin/wiki/download/el-mock.el

The biggest advantage is this uses `ert' feature to display test result.
You can easily understand why a test failed.

 `expectations'  vs    `ert'
 (expect 10            (ert-deftest erte-test-00001 ()
   (+ 4 6))              (should (equal 10
                                        (+ 4 6))))

Example:

  (expectations
    (desc "success")
    (expect 10
      (+ 4 6))
    (expect 5
      (length "abcde"))
    (desc "fail")
    (expect 11
      (+ 4 6))
    (expect 6
      (length "abcde")))

Press C-M-x sexp then get the result in *ert*:

  Selector: t
  Passed: 2
  Failed: 2 (2 unexpected)
  Total:  4/4

  Started at:   2012-10-09 15:37:17+0900
  Finished.
  Finished at:  2012-10-09 15:37:17+0900

  ..FF

  F erte-test-00003
      (ert-test-failed
       ((should
         (equal 11
                (mock-protect
                 (lambda nil
                   (+ 4 6)))))
        :form
        (equal 11 10)
        :value nil :explanation
        (different-atoms
         (11 "#xb" "?^K")
         (10 "#xa" "?\n"))))

  F erte-test-00004
      (ert-test-failed
       ((should
         (equal 6
                (mock-protect
                 (lambda nil
                   (length "abcde")))))
        :form
        (equal 6 5)
        :value nil :explanation
        (different-atoms
         (6 "#x6" "?^F")
         (5 "#x5" "?^E"))))


If you want more complex example, see (describe-function 'expectations)

; Installation:

Put ert-expectations.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name "~/elisp"))

And the following to your ~/.emacs startup file.

(require 'ert-expectations)

No need more.
