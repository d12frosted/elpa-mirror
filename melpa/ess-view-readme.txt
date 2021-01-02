When working with big R dataframes, the console is impractical for looking at
its content; a spreadsheet software is a much more convenient tool for this task.
This package allows users to have a look at R dataframes in an external
spreadsheet software.

If you simply want to have a look at a dataframe simply hit (inside a buffer running
an R process)

C-x w

and you will be asked for the name of the object (dataframe) to
view... it's a simple as that!

If you would like to modify the dataframe within the spreadsheet
software and then have the modified version loaded back in the
original R dataframe, use:

C-x q

When you've finished modifying the dataset, save the file (depending
on the spreadsheet software you use, you may be asked if you want to
save the file as a csv file and/or you want to overwrite the original
file: the answer to both question is yes) and the file content will be
saved in the original R dataframe.


If these functions are called with the prefix argument 0, then the dataframes
will be exported with their row.names, eg. use:

C-u 0 C-x w  (to see the object)

C-u 0 C-x q  (to see it and then have it saved back in the R dataframe)

