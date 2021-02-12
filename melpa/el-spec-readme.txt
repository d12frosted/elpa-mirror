########   Compatibility   ########################################

Works with Emacs-23.2.1, 23.1.1

########   Quick start   ########################################

Add to your ~/.emacs

(require 'el-spec)

and write some test, for example

(dont-compile
  (when (fboundp 'describe)
    (describe "description"
      (before
        (message "before common"))
      (after
        (message "after common\n"))
      (context "when 1"
        (before
          (message "before 1"))
        (after
          (message "after 1"))
        (it "test 1"
          (message "test 1")))
      (context "when 2"
        (before
          (message "before 2"))
        (after
          (message "after 2"))
        (it "test 2"
          (message "test 2")))
      )))

output is like this.

before common
before 1
test 1
after 1
after common

before common
before 2
test 2
after 2
after common
