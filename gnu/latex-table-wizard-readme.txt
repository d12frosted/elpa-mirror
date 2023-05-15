This package provides you with commands to smartly navigate and
edit large and complex LaTeX table-like environments with a
transient.el-based interface.  Table-like environments are portions
of text delimited by a pair of matching "\begin" and "\end" macros
that organize output text into aligned colums.

The entry point of the package is

    M-x latex-table-wizard

while point is inside of a table(-like) environment.  From there, you
can do several things such as:

  + navigate "logically" (that is, move by cells);
  + insert or kill rows or column;
  + move arbitrary cells or groups of cells around;
  + align the table in different ways (however alignment is not
    needed for the functionalities above).

Standard LaTeX2e table environments are supported out of the box,
but you can define additional ones.  The entry point for
customization is

    M-x latex-table-wizard-customize

The keybinding set by default in the transient prefix are inspired
to some extent by Emacs defaults.  If you want to change these
keybindings you should change the value of the variable
latex-table-wizard-transient-keys.

By default, the syntax this package expects is the one of standards
LaTeX tabular environments, whereby "&" separates columns and "\\"
separates rows.  Additional, or different, types of table-like
environments (with their own syntax separators) can be added by the
user.  This is done by adding mappings to
latex-table-wizard-new-environments-alist.  Suppose I want to
define a new table like environment whose name is "mytable", whose
column and row separators are strings like "\COL" and "\ROW", and
the LaTeX macro to add a horizontal line is "\myhline{}":

   \begin{mytable}
       ...
   \end{mytable}

For latex-table-wizard to handle this table, just add the following
cons cell to latex-table-wizard-new-environments-alist:

   '("mytable" . (:col '("\\COL")
                  :row '("\\ROW")
                  :lines '("myhline")))

Each value is a list of strings to allow for more than one macro to
have the same function.

See the Info page for a complete overview of the package.