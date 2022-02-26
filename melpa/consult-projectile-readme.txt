A multiview for displaying open buffers, files and directories accociated with a project.
When no project is open in the current buffer display a list of known project.
and select a file from the selected project.

Additionally seperate single source function are available.

Just run the function `consult-projectile' and/or bind it to a hotkey.

To filter the multiview use:
b - For project related buffers
d - For project related dirs
f - For project related files
p - For known projects
r - For project recent files

The multiview includes initially buffers, files and known projects.  To include
recent files and directires add `consult-projectile--source-projectile-dir' and/or
`consult-projectile--source-projectile-recentf' to `consult-projectile-sources'.
