MuType is a minimal typing practice loop for Emacs, designed for calm rhythm,
low-distraction focus, and steady flow.

Start a session with `M-x mutype-mode`.  Use `C-u M-x mutype-mode` (or
`M-x mutype-mode-custom`) to choose practice mode, duration, and source text.

During a session:
- `C-c C-p` toggles pause/resume
- `C-c C-q` stops the session
- `C-c C-n` / `C-c C-b` switches source text
- `M-x mutype-report-last-session` reopens the last report

Source texts are bundled as plain .txt files under the package's "sources/"
directory.
