Multiple commands are provided to grep files in the project to get
auto complete candidates.

The keyword to grep is text from the line beginning to current cursor.

Project is *automatically* detected if Git/Mercurial/Subversion is used.
You can override the project root by setting `eacl-project-root',

List of commands,

`eacl-complete-line' completes single line by grepping the project root.
Line candidates are extracted from the files in the project root.
"C-u M-x eacl-complete-line" completes single line from deleted code
if current project is tracked by Git.

`eacl-complete-multiline' completes multiline code or html tag.

`eacl-complete-line-from-buffer' completes single line by searching text
in the buffers.  Set `eacl-ignore-buffers' and `eacl-include-buffers' to specify
ignored&included buffers.

`eacl-complete-line-from-buffer-or-project' completes single line by grepping
the project root when editing a physical file.  Or else, it searches all buffers
for line completion.

Modify `grep-find-ignored-directories' and `grep-find-ignored-files'
to setup directories and files grep should ignore:
  (with-eval-after-load 'grep
     (dolist (v '("node_modules"
                  "bower_components"
                  ".sass_cache"
                  ".cache"
                  ".npm"))
       (add-to-list 'grep-find-ignored-directories v))
     (dolist (v '("*.min.js"
                  "*.bundle.js"
                  "*.min.css"
                  "*.json"
                  "*.log"))
       (add-to-list 'grep-find-ignored-files v)))

Or you can setup above ignore options in ".dir-locals.el".
The content of ".dir-locals.el":
  ((nil . ((eval . (progn
                     (dolist (v '("node_modules"
                                  "bower_components"
                                  ".sass_cache"
                                  ".cache"
                                  ".npm"))
                       (add-to-list 'grep-find-ignored-directories v))
                     (dolist (v '("*.min.js"
                                  "*.bundle.js"
                                  "*.min.css"
                                  "*.json"
                                  "*.log"))
                       (add-to-list 'grep-find-ignored-files v)))))))

"git grep" is automatically used for grepping in git repository.
Please note "git grep" does NOT use `grep-find-ignored-directories' OR
`grep-find-ignored-files'.

The command line program of grep and git need be added into environment variable
"PATH".  Or else you need set `eacl-grep-program' and `eacl-git-program' to
specify their path.

Set `eacl-git-grep-untracked' if untracked files should be git grepped too.
