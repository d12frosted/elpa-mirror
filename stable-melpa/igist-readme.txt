Edit, create and view your GitHub gists.

Usage

 `igist-dispatch' - Invoke transient menu with the list of available
  commands.

Tabulated display:

M-x `igist-list-gists' - Display your gists as table.
M-x `igist-list-other-user-gists' - Display public gists of any user.
M-x `igist-explore-public-gists' - List public gists sorted.

Completions display:

M-x `igist-edit-list' Read Gist to edit from the minibuffer.

; Create commands:

M-x `igist-create-new-gist'
     Create the editable gist buffer with the content of the current buffer.

M-x `igist-new-gist-from-buffer'
     Setup new gist buffer whole buffer contents.

M-x `igist-list-add-file'
     Add new file name to gist at point.

M-x `igist-fork-gist'
     Fork gist at point in `igist-list-mode' or currently opened.

M-x `igist-post-files' Post multiple files to Gist. If
     there are marked files in the Dired buffer, use them; otherwise, read
     the directory in the minibuffer with completions and then read multiple
     files.


Delete commands:

M-x `igist-delete-current-gist'
     Delete current gist with all files.

M-x `igist-delete-current-filename'
     Delete current file from gist.

M-x `igist-delete-other-gist-or-file' (gist)
     Delete GIST with id.

M-x `igist-kill-all-gists-buffers'
     Delete all gists buffers.

; Edit commands:

M-x `igist-list-view-current'
     Fetch tabulated gist entry at point.

M-x `igist-list-edit-gist-at-point' (&optional _entry)
     Open tabulated GIST-ITEM at point in edit buffer.

M-x `igist-browse-gist'
     Browse gist at point or currently open.

M-x `igist-save-current-gist-and-exit'
     Save current gist.

M-x `igist-save-current-gist'
     Save current gist.

M-x `igist-read-filename' (&rest _args)
     Update filename for current gist without saving.

M-x `igist-read-description' (&rest _args)
     Update description for current gist without saving.

M-x `igist-add-file-to-gist'
     Add new file to existing gist.

M-x `igist-toggle-public' (&rest _)
     Toggle value of variable `igist-current-public'.

M-x `igist-list-edit-description' (&rest _)
     Edit description for current gist at point in tabulated list mode.
Comments commands:

M-x `igist-post-comment'
     Post current comment.

M-x `igist-delete-comment-at-point' (&rest _)
     Add or edit comment for gist at point or edit buffer.

M-x `igist-add-or-edit-comment' (&rest _)
     Add or edit comment for gist at point or edit buffer.

M-x `igist-add-comment' (&rest _)
     Add new comment for gist.

M-x `igist-load-comments' (&rest _)
     Load comments for gist at point or edit buffer.

User commands:

M-x `igist-change-user' (&rest _)
     Change user for retrieving gist.

; Customization

- `igist-current-user-name': This variable should be set to a string
  that contains your GitHub username.

- `igist-auth-marker': This variable can either be a string that
  contains the OAuth token or a symbol indicating where to retrieve
  the OAuth token.

- `igist-message-function': A custom function for displaying messages.
  Should accept the same arguments as the `message' function.

- `igist-per-page-limit': The number of results displayed per page
  should be a value ranging between 30 to 100. The default value is 30.

- `igist-ask-for-description': Determines when to prompt for a
  description before posting new gists. The default setting prompts
  for a description before saving a new gist.

- `igist-enable-copy-gist-url-p': Specifies whether and when to add
  the URL of a new or updated gist to the kill ring. The default
  setting is after the creation of new gists.

- `igist-list-format': Specifies the format of the user's Tabulated
  Gists buffers.

- `igist-explore-format': Specifies the format of the Explore Public
  Gists tabulated buffers.


; Keymaps

`igist-comments-list-mode-map'
     A keymap used for displaying comments.

`igist-list-mode-map'
     Keymap used in tabulated gists views.

`igist-comments-edit-mode-map'
     Keymap for posting and editing comments.

`igist-edit-mode-map'
     Keymap used in edit gist buffers.
