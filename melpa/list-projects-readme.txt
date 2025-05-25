List Projects provides an interactive tabulated list of all
projects known to Emacs.  It gives you a centralized view of your
projects with useful information and actions.

Features
- Shows project names, root directories, open buffer counts, and version control status
- Fast buffer-to-project assignment using an efficient trie-based algorithm
- Clickable items to:
  - Open project roots in Dired
  - List all buffers belonging to a project
  - View version control status (with Magit integration for Git repositories)
- Sets the default directory to the project at point for command context

Usage:
M-x list-projects         - Display the project list buffer
In the project list buffer:
- Click on a project name or root to open in Dired
- Click on the buffer count to list project buffers
- Click on the VC system to view version control status
- Regular commands are executed in the context of the project at point

You can customize the appearance via:
- list-projects-project-name-column-width
- list-projects-project-root-column-width
- list-projects-project-buffers-count-column-width
- list-projects-project-vc-column-width

To use a different function for listing projects, set:
- list-projects-default-listing-function

TODO
- Show current compilation status BLOCKED (I don't think that
   information is even stored?)
- Fix project list showing up in buffer list when hitting c-x p c-b
   (list buffers) (might not be possible? requires changes to project.el?)
