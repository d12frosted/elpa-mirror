These commands let Avy act from a distance. There are three basic classes:

The commands `avy-act-follow' and `avy-act-follow-in-new-buffer', which allow
you to select a link to follow.

The commands `avy-recenter-middle-at-line', `avy-recenter-top-at-line' and
`avy-recenter-bottom-at-line', which allow recentering at a line.

Extended functions, which allow you to do simple editing from a distance.
These can be subdivided into three sub-classes:

The commands `avy-act-on-position' and `avy-act-on-position-word-1', which
act by selecting a position in the buffer through Avy, then apply a marking
command like `mark-word' or `mark-sexp', then apply a command to the marked
region.

The commands `avy-act-on-region' and `avy-act-on-region-by-same-function',
which act by marking a region through either two avy functions or the same
function applied twice, then act on that region by applying a command.

The commands `avy-act-to-point' and `avy-act-to-point-in-same-line', which
mark a region up to the current position of point using one avy command, then
apply a command to that region.

The commands that are applied in extended functions can be chosen through
keyboard shortcuts as they are in the current buffer, or through the
`avy-selection-command-map'. When using `avy-act-on-position' or
`avy-act-on-position-word-1', often either a whitespace is missing or one too
much remains is at the position where the action was performed. For this,
another command can be applied to that position from the
`avy-act-post-action-map', which by default contains commands to insert a
whitespace or delete a character.
