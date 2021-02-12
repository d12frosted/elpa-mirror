
This package is aimed on minimizing the effort of interacting with
the command tools involved in transforming files.

For instance, once in a blue moon you might need to transform a
large flac file based on a cue file into smaller flac files, or mp3
files for that matter.

Case 1: if you're doing it for the first time, you'll search the
internet for a command tool that does this job, and for particular
switches.

Case 2: you've done it before.  The problem is that when you want to
do the transform for the second time, you have likely forgotten all
the command switches and maybe even the command itself.

The solution is to write the command to a Makefile when you find it
the first time around.  This particular Makefile you should save to
./recipes/cue/split/Makefile.

Case 3: you have a Makefile recipe.  Just navigate to the dispatch
file (*.cue in this case) with `dired' and press "," which is bound
to `make-it-so'.  You'll be prompted to select a transformation
recipe that applies to *.cue files.  Select "split".  The following
steps are:

  1. A staging directory will be created in place of the input
  files and they will be moved there.

  2. Your selected Makefile template will be copied to the staging
  directory and opened for you to tweak the parameters.

  3. When you're done, call `compile' to make the transformation.
  It's bound to [f5] in `make-mode' by this package.

  4. If you want to cancel at this point, discarding the results of
  the transformation (which is completely safe, since they can be
  regenerated), call `mis-abort', bound to "C-M-,".

  5. If you want to keep both the input and output files, call
  `mis-finalize', bound to "C-,".

  6. If you want to keep only the output files, call `mis-replace',
  bound to "C-M-.".  The original files will be moved to trash.

  7. Finally, consider contributing Makefile recipes to allow
  other users to skip Case 1 and Case 2.
