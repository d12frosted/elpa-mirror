This package tries to replicate as closely as possible the GTD workflow.
This package, and this readme, assume familiarity with GTD. There are many
resources out there to learn how to use the framework. If you are new to GTD,
this package may be unpleasant to use.

Assuming the keybindings below are used, here is how you could use org-gtd:
GTD uses one basic axiom: everything that comes your way goes into the inbox.
You do this with ~C-c d c~.
You also have to regularly process the inbox, which you do with ~C-c d p~.

When you process the inbox, you will see each inbox item, one at a time,
with an interface letting you decide what to do with the item:

- *Quick Action* :: You've taken care of this action just now. Choose this to mark the item as DONΕ and archive it.
- *Throw out* :: This is not actionable and it's not knowledge for later. Choose this to mark the item as CANCELED and archive it.
- *Project* :: This is a multi-step action. I'll describe how to handle these below.
- *Calendar* :: This is a single item to be done at a given date or time. You'll be presented with org-mode's date picker, then it'll refile the item. You'll find this in the agenda later.
- *Delegate* :: Let someone else do this. Write the name of the person doing it, and choose a time to check up on that item.
- *Single action* :: This is a one-off to be done when possible. You can add tags to help you.
- *Reference* :: This is knowledge to be stored away. I'll describe how to handle these below.
- *Incubate* :: no action now, review later

When processing each item you'll get a chance to add tags and other such
metadata. This package will add keywords (e.g. NEXT, TODO, DONE) for you,
so don't worry about them. Do the work that only you can do, and let this
package handle the bookkeeping.

A "project" is defined as an org heading with a set of children headings.

When you are processing the inbox and creating a project, Emacs enters a
recursive edit mode to let you define and refine the project.
When finished, press ~C-c c~ to exit the recursive edit and go back to
processing the inbox.

One of the ways to see what's next for you to do is to see all the next
actions ( ~C-c d n~ ).

Sometimes things break. Use ~C-c d s~ to find all projects that don't have a
NEXT item, which is to say, all projects that the package will not surface
and help you finish.

Here's a commented block showing a possible
configuration for this package.

  ;; these are the interactive functions you're likely to want to use as you go about GTD.
  (global-set-key (kbd "C-c d c") 'org-gtd-capture) ;; add item to inbox
  (global-set-key (kbd "C-c d p") 'org-gtd-process-inbox) ;; process entire inbox
  (global-set-key (kbd "C-c d a") 'org-agenda-list) ;; see what's on your plate today
  (global-set-key (kbd "C-c d n") 'org-gtd-show-all-next) ;; see all NEXT items
  (global-set-key (kbd "C-c d s") 'org-gtd-show-stuck-projects) ;; see projects that don't have a NEXT item

  (setq org-gtd-directory "~/gtd/") ;; where org-gtd will put its files
  ;; the above happens to also be the default location, if left uncustomized.

  ;; assuming you don't have another setup, use this line as written
  ;; otherwise, push the org-gtd-directory to your existing agenda files
  (setq org-agenda-files `(,org-gtd-directory))

  ;; assuming you don't have existing capture templates
  ;; otherwise, push these to your existing capture templates
  ;; and of course, you can adjust the keys "i" and "l"
  (setq org-capture-templates `(("i" "GTD item"
                                 entry (file ,(org-gtd--path org-gtd-inbox-file-basename))
                                 "* %?\n%U\n\n  %i"
                                 :kill-buffer t)
                                ("l" "GTD item with link to where you are in Emacs now"
                                 entry (file ,(org-gtd--path org-gtd-inbox-file-basename))
                                 "* %?\n%U\n\n  %i\n  %a"
                                 :kill-buffer t)))

  ;; package: https://www.nongnu.org/org-edna-el/
  ;; org-edna is used to make sure that when a project task gets DONE,
  ;; the next TODO is automatically changed to NEXT.
  (setq org-edna-use-inheritance t)
  (org-edna-load)

  ;; package: https://github.com/Malabarba/org-agenda-property
  ;; this is so you can see who an item was delegated to in the agenda
  (setq org-agenda-property-list '("DELEGATED_TO"))
  ;; I think this makes the agenda easier to read
  (setq org-agenda-property-position 'next-line)
