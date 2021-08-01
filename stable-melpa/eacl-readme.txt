Multiple commands are provided to grep files in the project to get
auto complete candidates.
The keyword to grep is text from line beginning to current cursor.
Project is *automatically* detected if Git/Mercurial/Subversion is used.
You can override the project root by setting `eacl-project-root',

List of commands,

`eacl-complete-line' completes single line.
Line candidates are extracted in project root.
"C-u M-x eacl-complete-line" completes single line from deleted code
if current project is tracked by Git.

`eacl-complete-multiline' completes multiline code or html tag.

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
To use "git grep", Git should be added into environment variable "PATH".

Set `eacl-git-grep-untracked' if untracked files should be git grepped too.
