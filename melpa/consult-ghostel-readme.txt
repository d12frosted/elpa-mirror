Pick a ghostel buffer through `consult', so moving through the
candidate list previews each ghostel buffer in the target window.
Ghostel's own `ghostel-list-buffers' / `ghostel-project-list-buffers'
route through `read-buffer', which has no preview.

  `consult-ghostel'          all ghostel buffers
  `consult-ghostel-project'  ghostel buffers in this project
  `consult-ghostel-history'  pick from the shell's command history

Candidates are ordered for switching (recently-used first, current
buffer last) and annotated with the terminal title, and submitting a
name that matches no buffer creates a new ghostel terminal with that
name (reach-or-create, like `consult-buffer's create-on-miss).
With a prefix argument the buffer pickers behave like `ghostel' /
`ghostel-project' instead (C-u creates a new terminal); a "New"
group inside the picker offers the same default-named creation.
When marginalia is installed, the title is prepended to marginalia's
buffer annotations instead, in every buffer prompt.

`consult-ghostel-history' picks from the shell's own command history
(retrieved per shell via `ghostel-shell-history-commands') and types
the selection into the terminal, completing or replacing the pending
command line.

`consult-ghostel-mode' wires ghostel into consult's own commands:
it registers hidden sources in `consult-buffer' and
`consult-project-buffer' that enable the `g' narrow key (restricting
the view to ghostel buffers only), makes `consult-line' match across
soft line wraps in ghostel buffers (rows joined by wrap newlines
become one candidate), adds a "Ghostel" group to `consult-bookmark'
so the `g' narrow key restricts the candidates to ghostel bookmarks.

Enable by adding to your init:

  (use-package consult-ghostel
    :after (ghostel consult)
    :demand t
    :config (consult-ghostel-mode)
    :bind (("C-x m" . consult-ghostel)
           :map project-prefix-map
           ("m" . consult-ghostel-project)
           :map ghostel-semi-char-mode-map
           ("C-c h" . consult-ghostel-history)))
