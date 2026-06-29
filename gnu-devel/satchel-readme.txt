A satchel is a persisted list of paths that are considered important for
the ongoing work.  Thus, we rely on git branch names to distinguish between
satchels.  The use case is as follows:

* Create a branch and start the ongoing work.
* Discover what files are important, place them in a satchel.
* When exploring the code base in the current project, you can more easily now
  jump to the important files, thus saving time.
* Realize you need to work on a different branch - switch to it.
  Now the satchel is automatically scoped to the new branch.
  If there are files there, jump to them.

 So to clarify, satchel persists a set of files residing under a project as
 defined by `project'.  In addition, we use git branches to delimit between
 different sets of files.