Thousands times a day you want to jump from a file to its test file
(or to its CSS file, or to its header file, or any other related
file) and just as many times you want to go back to the initial
file.  Jumping to related files is what this package is about.

The question is: how does a user specify that a file is related to
a set of other files? One way is to create a function that takes a
file as argument and returns a list of related filenames:

(defun my/related-files-jumper (file)
  (let ((without-ext (file-name-sans-extension file)))
    (list
     (concat without-ext ".js")
     (concat without-ext ".css"))))

(setq related-files-jumpers (list #'my/related-files-jumper))

`my/related-files-jumper' is called a 'jumper.  With this setup,
`related-files-jump' will let the user jump from Foo.js to Foo.css and
back.

This is working good but has several limitations:

1. If Foo.css is not in the same directory as Foo.js or if you want
to include test files which end with "-tests.js",
`my/related-files-jumper' has to be modified in a non-obvious way or a
complicated new jumper must be written and added to
`related-files-jumpers';

2. The function `my/related-files-jumper' has to be shared with all Emacs
users working on the same project

So related-files recommends another approach that is less powerful but
much simpler.  Here is another way to define the same jumper:

(recipe :remove-suffix ".js" :add-suffix ".css")

This list must replace `my/related-files-jumper' in
`related-files-jumpers'.  This jumper lets the user go from Foo.js
to Foo.css.  related-files will automatically inverse the meaning
of :remove-suffix and :add-suffix arguments so the user can also go
from Foo.css to Foo.js with this jumper.  See
`related-files-jumpers' and THE MANUAL (TODO) for more information.

This kind of jumper can easily be shared with the members of a team
through a .dir-locals.el file.  See (info "(Emacs) Directory Variables").

`related-files-make' also makes it easy to create a related file and fill
it with some content.  If the content is always the same, a string
can be used to specify it:

(recipe :remove-suffix ".js" :add-suffix ".css" :filler "Fill the CSS file")

There is also an `auto-insert'-based way to fill new files and new
kinds of fillers can easily be implemented.  See the manual for
more information.

If you want to add a new kind of jump, override `related-files-apply' and
optionally `related-files-get-filler', call `related-files-add-jumper-type' and
add a function to `related-files-jumper-safety-functions'.

If you want to add a new kind of filler, override `related-files-fill'
and call `related-files-add-filler-type'.
