Browsing a project in Emacs leaves a trail of buffers behind.  Every file you
glanced at from the file tree, every definition you jumped to, every grep hit
you opened stays in the buffer list forever.

VS Code solves this with the preview tab: a file opened by browsing goes into
a single italicised tab, the next such file replaces it, and the tab only
becomes permanent once you edit it.  `preview-tab-mode' brings that to Emacs.

Enable it and the commands in `preview-tab-commands' -- file managers, xref,
grep, consult and friends -- open files into one temporary buffer:

    (preview-tab-mode 1)

The preview buffer is killed when the next preview replaces it, and it turns
into an ordinary buffer as soon as you edit it or run `preview-tab-keep'.
A buffer that was already open is never demoted to a preview, and a preview
that is modified, visible in another window, or running a process is never
killed -- it becomes an ordinary buffer instead.

Two commands are provided beyond the mode itself:

  `preview-tab-find-file'  visit a file as a preview instead of for good --
                           the deliberate "just let me look at it"
                           counterpart to `find-file'
  `preview-tab-keep'       keep the current preview buffer for good

Typing a file name is taken as a deliberate act and opens the file for good,
as in VS Code.  Set `preview-tab-include-named-files' if you would rather
`find-file' previewed too.

The current preview is marked in the mode line: the buffer path is italicised
and a small indicator is shown.  Both are configurable; see
`preview-tab-slant-faces' and `preview-tab-indicator'.  Under
`tab-line-mode' the preview's tab is italicised too, whether or not it is
the selected one.
