This package piggy-backs on `tab-bar-mode' to implement a simple
buffer manager.  Instead of managing tabs it manages buffers.

Installation:

Add the following tor your init file.

`(tab-bar-buffers-mode t)'

Or enable `tab-bar-buffers-mode` from the Easy Customization form.

`(customize-group 'tab-bar-buffers)'

Customization:

`tab-bar-buffers-mode` has only one customization item of its own: *Uninteresting buffers*.  This is a list of buffer names that you do **not** want shown in the tab bar.  Visible buffers are always shown.

`tab-bar-close-button-show'
`tab-bar-position'
`tab-bar-select-tab-modifiers'
`tab-bar-tab-hints'

If `tab-bar-tab-name-function' is `tab-bar-tab-name-truncated' then
`tab-bar-tab-name-truncated-max' and `tab-bar-tab-name-ellipsis'
are honored.

Faces:

The face for `tab-bar-tab' is used for `current-buffer'.
`tab-bar-tab-inactive' is used for all other buffers.

Bindings:

Key and mouse bindings are preserved by advising some of
tab-bar-mode's commands around their tab-bar-buffers equivalent, as
defined by `tab-bar--define-keys'.

`tab-new'
`tab-bar-select-tab'
`tab-next'
`tab-previous'
`tab-recent'
`tab-last'
`tab-bar-close-tab'
