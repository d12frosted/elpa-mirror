(use-package project-tasks
  :ensure t :defer t
  :commands (project-tasks)

  :init
  ;; Show project-tasks when switching projects
  (add-to-list 'project-switch-commands '(project-tasks "tasks") t)
  ;; Add action to embark-file map
  (with-eval-after-load 'embark
    (define-key embark-file-map (kbd "P") #'project-tasks-in-dir))

  :custom
  ;; Set the default filename in project
  (project-tasks-file "tasks.org")
  ;; Set the function to get current project dir
  (project-tasks-root-func #'project-tasks-project-root)

  ;; Bind project-tasks to project keymap
  :bind
  (:map project-prefix-map
        ("P" . project-tasks)
        ("o" . project-tasks-capture)
        ("O" . project-tasks-jump))
  )
