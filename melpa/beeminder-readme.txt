beeminder.el provides a way for Emacs to interact with the Beeminder API.  It
adds the following functionality:
  - A client for viewing and modifying Beeminder goals.
  - Functions for adding data to Beeminder goals.
  - Integration with org-mode for submitting clocked time and task completions.
  - API access methods for fetching and modifying Beeminder goal information.

Please set `beeminder-username' and `beeminder-auth-token' before using.

You can find your auth token by logging in to Beeminder and then visiting the
following URI: https://www.beeminder.com/api/v1/auth_token.json

Load beeminder.el with (require 'beeminder).  This must be called after your
Org is set up if you want to use org-mode integration.

; Keyboard bindings:

We recommend binding commands to the `C-c b` prefix and using the following
key bindings in your init.el:

(global-set-key "\C-c b a" #'beeminder-add-data)
(global-set-key "\C-c b g" #'beeminder-goals)
(global-set-key "\C-c b i" #'beeminder-my-goals-org)
(global-set-key "\C-c b r" #'beeminder-refresh-goal)
(global-set-key "\C-c b w" #'beeminder-whoami)

These key bindings are:

C-c b a    - Add data to a Beeminder goal.
C-c b g    - View your list of goals in an interactive buffer.
C-c b i    - Insert your goals as an org-mode list.
C-c b r    - Refresh goal information for an org headline.
C-c b w    - Display username in message line.

The same setup for `use-package` looks like this:

(use-package beeminder
  :after (org)
  :bind
  (("C-c b a" . beeminder-add-data)
   ("C-c b g" . beeminder-goals)
   ("C-c b i" . beeminder-my-goals-org)
   ("C-c b r" . beeminder-refresh-goal)
   ("C-c b w" . beeminder-whoami)))

org-mode integration:

You can use C-c C-x p (org-set-property) to add the beeminder property to
projects or tasks that are associated with beeminder goals.  Set it to the
identifier of your goal (the short name that's in the URL).

By default, completing those tasks will log one point.  You can set the
beeminder-value property to "prompt" in order to interactively specify the
value whenever you complete the task.  Set beeminder-value to "time-today" in
order to log the time you clocked today (see "Clocking work time" in the Org
manual).
