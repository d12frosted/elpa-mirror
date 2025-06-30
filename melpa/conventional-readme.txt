A collection of minor modes supporting conventional syntax.

More on the initiatives on these sites:
* https://conventionalcommits.org
* https://conventionalcomments.org

To enable it for comments everywhere, and for commits with basic
EDITOR=emacsclient, you can use:

(add-hook
 'find-file-hook
 (lambda (&rest _)
   (if (string= (file-name-base buffer-file-name) "COMMIT_EDITMSG")
       (conventional-commits-mode)
     (conventional-comments-mode))))

The hook worked for me both with plain term and with magit (with EDITOR env)
