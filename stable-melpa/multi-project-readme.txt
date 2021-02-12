
Multi-project simplifies working with different projects by providing support
for creating, deleting, and searching with projects.  Multi-project
supports interactively finding a file within a project by using a TAGS file.


To use multi-project add the following lines within your .emacs file:

(require 'multi-project)
(multi-project-mode)

The multi-project bindings below are for switching to a project, finding
files within a project, compilation, or grepping a project.

C-xpa - Anchor a project          Remember the current project
C-xpc - Project compile           Run the compilation command for a project
C-xpj - Project jump              Displays a list of projects
                                  multi-project-anchored
C-xpg - Run grep-find             Runs grep-find at project root
C-xpl - Last project or anchor    Jumps to the last project or anchor
C-xpp - Present project           Jumps to the current project root
C-xpP - Present project new frame Present project in a new frame
C-xpf - Find project files        Interactively find project files
C-xpn - Add a new project         Prompts for new project information
C-xpr - Go to project root        Visits the project root
C-xps - Project shell             Creates a project shell
C-xpu - Resets the anchor         Unsets the project anchor
C-xpv - Visit a project           Visits another project in a separate frame


From the project selection buffer the following bindings are present:
a     - Anchor a project          Remembers the project to quickly return
                                  after visiting another project.
C-n   - Next project              Move the cursor to the next project
C-p   - Previous project          Move the cursor to the previous project
d     - Delete a project          Marks the project for deletion
g     - Grep a project            Executes grep-find in the selected projects
r     - Reset search              Resets the project search filter
s     - Search projects           Searches by name for a project
N     - Add new project           Prompts for project information
q     - Quit
u     - Unmark a project          Removes the mark for a project
x     - Executes actions          Executes the selected operations


The multi-project-compilation-command variable can be set to a function
that provides a customized compilation command.  For example,

(defun my-compilation-command (project-list)
  (let ((project-name (car project-list))
   (project-dir (nth 1 project-list))
   (project-subdir (nth 2 project-list)))

    (cond ((string-match "proj1" project-name)
      (concat "ant -f " project-dir "/" project-subdir "/build.xml"))
     (t
      (concat "make -C " project-dir "/" project-subdir)))))

(setq multi-project-compilation-command 'my-compilation-command)
