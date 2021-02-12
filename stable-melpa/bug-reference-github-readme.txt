Automatically set `bug-reference-url-format' and enable
`bug-reference-prog-mode' buffers from Github repositories.

What it does is:

1. If `bug-reference-url-format' is not set and this appears to be
    part of a git working copy (we can locate a .git/config).

2. Find the git remote repository (run 'git ls-remote --get-url').

3. If the remote matches github.com set `bug-reference-url-format' to
    the correct Github issue URL (we set it buffer locally).

4. Enable `bug-reference-prog-mode'.

To have `bug-reference-github' check every opened file:

(add-hook 'find-file-hook 'bug-reference-github-set-url-format)

or to check just `prog-mode' buffers (i.e. most programming major modes):

(add-hook 'prog-mode-hook 'bug-reference-github-set-url-format)
