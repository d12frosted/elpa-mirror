                                ━━━━━━━━
                                 EL-JOB
                                ━━━━━━━━


Imagine you have a function you'd like to run on a long list of inputs.
You could run `(mapcar #'FN INPUTS)', but that hangs Emacs until done.

This library lets you run the same function in many subprocesses (one
per CPU core), each with their own split of the `INPUTS' list, then
merge their outputs and pass it back to the current Emacs.

In the meantime, current Emacs does not hang at all.

Best of all, it completes /faster/ than `(mapcar #'FN INPUTS)', owing to
the use of all CPU cores!

That's it in a nutshell.  You can look at real-world usage by searching
for "el-job" in these packages:
• [org-mem.el]
• [org-roam-async.el]


[org-mem.el]
<https://raw.githubusercontent.com/meedstrom/org-mem/refs/heads/main/org-mem.el>

[org-roam-async.el]
<https://raw.githubusercontent.com/meedstrom/org-roam-async/refs/heads/main/org-roam-async.el>


1 Since 2.5.0
═════════════

  Released [2025-10-06 Mon], v2.5.0 comes with a variant library
  "el-job-ng".

  I find it simpler and easier to reason about.  400 lines of code
  instead of 800.

  Some differences:

  • Does /not/ ever keep a process alive
  • Does /not/ merge the subprocesses' outputs in a bespoke way, just
    uses `append'.
  • Does /not/ look up `load-history' to try hard to find an .eln
    variant of your libraries, instead it lets `require' look up
    `load-path' normally.
  • Removed argument `:if-busy', you can manage this yourself with
    `el-job-ng-busy-p' and `el-job-ng-kill'.
  • Argument `:funcall-per-input' now takes a function of two (2)
    arguments, not one.
  • Argument `:callback' now takes a function of one (1) argument, not
    two.
  • Added optional argument `:eval'.

  The design is always changing in response to my needs, so feel free to
  file an issue or email!  It's instructive to hear about other people's
  needs.


1.1 Future work
───────────────

  I may write yet another variant.

  Something that came with experience is that it's best to make a new
  variant library for a narrow use-case, rather than complicate one
  library with different code flows.  When it comes to this type of
  library, you really want to keep it easy to reason about!

  Ideas as of [2025-10-06 Mon]:

  File IPC
        Sending input and output by writing and reading files, instead
        of through the pipe connection.

        Theory: performance can sometimes be a lot better, with large
        inputs and outputs.  I would guess it depends a lot on the
        machine.

        Drawback: if the data sent is sensitive, those files probably
        should be encrypted, and that could negate any performance
        benefit.

  Worker daemons
        Keeping subprocesses alive forever, so they are available at
        beck and call – think worker daemons.

        That's basically implemented in "el-job-old", and partly why it
        got so hairy, but it could be remade to put this usage
        front-and-center, with a "happy path" UX.

        At this time, I do not have a demanding use-case to experiment
        with, to discover what that happy path should be, how the
        affordances should be.

        If you need this now, I recommend [async.el].


[async.el] <https://github.com/jwiegley/emacs-async>


2 README for 2.4.8
══════════════════

2.1 Design rationale
────────────────────

  I wanted to shorten the round-trip as much as possible, *between the
  start of an async task and having the results*.

  For example, say you have some lisp that collects completion
  candidates, and you want to run it asynchronously because the lisp you
  wrote isn't always fast enough to avoid the user's notice, but you'd
  still like it to return as soon as possible.


2.1.1 Processes stay alive
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  In the above example, a user might only delay a fraction of a second
  between opening the minibuffer and beginning to type, so there's scant
  room for overhead like spinning up subprocesses that load a bunch of
  libraries before getting to work.

  Thus, el-job keeps idle subprocesses for up to 30 seconds after a job
  finishes, awaiting more input.

  An aesthetic drawback is cluttering your task manager with many
  processes named "emacs".

  Users who tend to run system commands such as `pkill emacs' may find
  that the command occasionally "does not work", because it actually
  killed an el-job subprocess, instead of the Emacs they see on screen.


2.1.2 Emacs 30 `fast-read-process-output'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Some other libraries, like the popular [async.el], are designed around
  a custom process filter.

  Since Emacs 30, it's a good idea to instead use the /built-in/ process
  filter when performance is critical, and el-job does so.  Quoting
  [NEWS.30]:

  ┌────
  │ ** The default process filter was rewritten in native code.
  │ The round-trip through the Lisp function
  │ 'internal-default-process-filter' is skipped when the process filter is
  │ the default one.  It is reimplemented in native code, reducing GC churn.
  │ To undo this change, set 'fast-read-process-output' to nil.
  └────


[async.el] <https://github.com/jwiegley/emacs-async/>

[NEWS.30]
<https://github.com/emacs-mirror/emacs/blob/master/etc/NEWS.30>


2.2 News 2.4
────────────

  • Jobs must now have `:inputs'.  If `:inputs' nil and there was
    nothing queued, `el-job-launch' will no-op and return the symbol
    `inputs-were-empty'.


2.3 News 2.3
────────────

  • Some renames to follow Elisp convention
    • `el-job:timestamps' and friends now `el-job-timestamps'.


2.4 News 2.1
────────────

  • DROP SUPPORT Emacs 28
    • It likely has not been working for a while anyway.  Maybe works on
      the [v0.3 branch], from 0.3.26+.


[v0.3 branch] <https://github.com/meedstrom/el-job/tree/v0.3>


2.5 News 2.0
────────────

  • Jobs must now have `:id' (no more anonymous jobs).
  • Pruned many code paths.


2.6 News 1.1
────────────

  • Changed internals so that all builds of Emacs can be expected to
    perform similarly well.


2.7 News 1.0
────────────

  • No longer keeps processes alive forever.  All jobs are kept alive
    for up to 30 seconds of disuse, then reaped.
  • Pruned many code paths.
  • Many arguments changed, and a few were removed.  Consult the
    docstring of `el-job-launch' again.


2.8 Limitations
───────────────

  1. The return value from the `:funcall-per-input' function must always
     be a list with a fixed length, where the elements are also lists.

     For example, org-mem passes `:funcall-per-input
     #'org-mem-parser--parse-file' to el-job, and if you look in
     [org-mem-parser.el] for the defun of `org-mem-parser--parse-file',
     it always returns a list of 5 items:

     ┌────
     │ (list (if missing-file (list missing-file)) ; List of 0 or 1 item
     │       (if file-mtime (list file-mtime))     ; List of 0 or 1 item
     │       found-entries                         ; List of many items
     │       org-node-parser--found-links          ; List of many items
     │       (if problem (list problem))))         ; List of 0 or 1 item
     └────

     It may look clunky to return sub-lists of only one item, but you
     could consider it a minor expense in exchange for simpler library
     code.

  2. Some data types cannot be exchanged with the children: those whose
     printed form look like `#<...>'.  For example, `#<buffer
     notes.org>', `#<obarray n=94311>', `#<marker at 3102 in
     README.org>'.

     IIUC, this sort of data only has meaning within the current process
     – so even if you could send it, it would not be usable by the
     recipient anyway.

  3. For now, this library tends to be applicable only to a narrow set
     of use-cases, since you can only pass one `:inputs' list which
     would tend to contain a single kind of thing, e.g. it could be a
     list of files to visit, to be split between child processes.  In
     many potential use-cases, you'd actually want multiple input lists
     and split them differently, and that's not supported yet.


[org-mem-parser.el]
<https://github.com/meedstrom/org-mem/blob/main/org-mem-parser.el>
