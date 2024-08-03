The easysession Emacs package is a lightweight session manager for Emacs that
can persist and restore file editing buffers, indirect buffers (clones),
Dired buffers, the tab-bar, and Emacs frames (including or excluding the
geometry: frame size, width, and height). It offers a convenient and
effortless way to manage Emacs editing sessions and utilizes built-in Emacs
functions to persist and restore frames.

With Easysession.el, you can effortlessly switch between sessions,
ensuring a consistent and uninterrupted editing experience.

Key features include:
- Minimalist design focused on performance and simplicity, avoiding
  unnecessary complexity.
- Quickly switch between sessions while editing without disrupting the frame
  geometry, enabling you to resume work immediately.
- Save and load file editing buffers, indirect buffers/clones, Dired buffers,
  windows/splits, the Emacs frame (including support for the tab-bar).
- Helper functions: Switch to a session (i.e., load and change the current
  session) with `easysession-switch-to', load the Emacs editing session with
  `easysession-load', save the Emacs editing session with `easysession-save'
  and `easysession-save-as', delete the current Emacs session with
  `easysession-delete', and rename the current Emacs session with
  `easysession-rename'.
