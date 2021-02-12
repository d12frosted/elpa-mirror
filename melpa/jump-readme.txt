This library is intended to aid in the construction of functions
for navigating projects.  The `defjump' function using a hopefully
convenient specification schema which jumps to new file/methods
based upon the file/method context of the current buffer/point.

This effort was inspired heavily by find-file-in-project.el by Phil
Hagelberg and Doug Alcorn, and toggle.el by Ryan Davis.  The
initial goal of jump.el was to subsume both of these tools.

; Example: (jumping to the related model in a rails application)

(defjump
  rinari-find-model
  (("app/controllers/\\1_controller.rb#\\2"  . "app/models/\\1.rb#\\2")
   ("app/views/\\1/.*"                       . "app/models/\\1.rb")
   ("app/helpers/\\1_helper.rb"              . "app/models/\\1.rb")
   ("db/migrate/.*create_\\1.rb"             . "app/models/\\1.rb")
   ("test/functional/\\1_controller_test.rb" . "app/models/\\1.rb")
   ("test/unit/\\1_test.rb#test_\\2"         . "app/models/\\1.rb#\\2")
   ("test/unit/\\1_test.rb"                  . "app/models/\\1.rb")
   ("test/fixtures/\\1.yml"                  . "app/models/\\1.rb")
   (t                                        . "app/models/"))
  rinari-root
  "Go to the most logical model given the current location."
  '(lambda (path)
     (message (shell-command-to-string
	       (format "ruby %sscript/generate model %s"
		       (rinari-root)
		       (and (string-match ".*/\\(.+?\\)\.rb" path)
			    (match-string 1 path))))))
  'ruby-add-log-current-method)
