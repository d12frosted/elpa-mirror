AGitjo extends Magit with a new menu for AGit-Flow operations, to make them
more convenient for users.  The AGit workflow enables users to create and
edit pull requests using just the "git push" command.  This package is
intended specifically for use with Forgejo-based (e.g. Codeberg)
repositories.

Run the following to load AGitjo and set up key-bindings in the relevant Magit
keymap (in this example, we use =#=):
  (use-package agitjo
    :config (agitjo-setup "#"))

An average workflow might look like the following:
1. Write and commit some code, and eventually decide it's ready for a pull
   request.
2. Open Agitjo's transient menu with =M-x agitjo-push= or by inputting the =#=
   key inside a Magit status buffer.
3. Set options like the title (=-t=) and the session identifier (=-s=).
4. Invoke one of the push commands to execute a git-push operation.
5. If creating a new PR (the force-push option =-f= is disabled), a dedicated
   buffer will open for drafting a PR description.
6. Visit the created pull request's link (=V=) in a browser to inspect it and
   make any additional adjustments, if needed.
7. Repeat steps 1-4 with the force-push option (=-f=) enabled to push changes to
   the existing PR.
