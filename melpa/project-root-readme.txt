project-root.el allows the user to create rules that will identify
the root path of a project and then run an action based on the
details of the project.

Example usage might be might be that you want a certain indentation
level/type for a particular project.

once project-root-fetch has been run `project-details' will either
be nil if nothing was found or the project name and path in a cons
pair.

An example configuration:

(setq project-roots
      `(("Generic Perl Project"
         :root-contains-files ("t" "lib")
         :filename-regex ,(regexify-ext-list '(pl pm))
         :on-hit (lambda (p) (message (car p))))
        ("Django project"
         :root-contains-files ("manage.py")
         :filename-regex ,(regexify-ext-list '(py html css js))
         :exclude-paths ("media" "contrib"))))

I bind the following:

(global-set-key (kbd "C-c p f") 'project-root-find-file)
(global-set-key (kbd "C-c p g") 'project-root-grep)
(global-set-key (kbd "C-c p a") 'project-root-ack)
(global-set-key (kbd "C-c p d") 'project-root-goto-root)
(global-set-key (kbd "C-c p p") 'project-root-run-default-command)
(global-set-key (kbd "C-c p l") 'project-root-browse-seen-projects)

(global-set-key (kbd "C-c p M-x")
                'project-root-execute-extended-command)

(global-set-key
 (kbd "C-c p v")
 (lambda ()
   (interactive)
   (with-project-root
       (let ((root (cdr project-details)))
         (cond
           ((file-exists-p ".svn")
            (svn-status root))
           ((file-exists-p ".git")
            (git-status root))
           (t
            (vc-directory root nil)))))))

This defines one project called "Generic Perl Projects" by running
the tests path-matches and root-contains-files. Once these tests
have been satisfied and a project found then (the optional) :on-hit
will be run.
