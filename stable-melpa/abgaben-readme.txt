abgaben.el (German for what students return when given assignments)
is a set of functions for dealing with assignments.  It assumes
that you use mu4e for your mails and org-mode for notes.

You should add something like this to your configuration:
(add-to-list 'mu4e-view-attachment-actions
'("gAbGabe speichern" . abgaben-capture-submission) t)
and of course customize the variables of this package.

The basic workflow is as follows:
You receive mails with assignments from your students
You use an attachment action (A g  if you used the example above) where you
 - select the group this assignment belongs to
   e.g. you have several different courses or (as I usually have)
   two groups for your practical
 - select the current week
It then saves that attachment to ABGABEN-ROOT-FOLDER/[group]/[week]/
and creates the directories as needed.
the the assignment is a .zip or .tar.gz file, it will automatically be
unpacked into a new directory.
After that, it produces a new heading in your ABGABEN-ORG-File
under ABGABEN-HEADING / [group] / [week]
containing a link to the saved attachment and the email.
(Note: The ABGABEN-HEADING / [group] heading needs to exist already,
	   the week heading will be created if it does not exist)

You can then open the PDFs from your org file and annotate them.
After your annotations, you can use
abgaben-export-pdf-annot-to-org to export your annotations as
subheadings of the current assignment.  This export will capture
all points you have given by matching your annotation lines to
abgaben-points-re and summing the points achieved and achievable
points.

You can then invoke abgaben-prepare-reply to open the original
mail.  You will have a reply in your kill-ring prepared with your
annotations exported as text and the annotated pdf as attachment.

Press reply, yank, send, your are done!
