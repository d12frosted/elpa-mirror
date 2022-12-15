This package provides you with commands to smartly navigate and
edit LaTeX table-like environments with a transient.el-based
interface.  Table-like environments are portions of text delimited
by a pair of matching "\begin" and "\end" macros that organize
output text into aligned colums.

With this package you can navigate and edit these tables easily
even if the source text is not aligned (although there is a command
to align them), because you will have movement commands that
specfically target cells in the four directions of motion in a
logical way.  This means that these movement and edit commands see
the table as a set of pairs of values (for column and row) instead
of as a buffer substring.

This package tries to be smart and parse the table without being
fooled by the presence of embedded environments and embedded tables
(that is, a table inside of the cell of a table).

The only command you need to remember (and perhaps bind a
conveniente key to) is latex-table-wizard-do.  This command calls a
transient prefix called latex-table-wizard-prefix, so that all the
other commands will be available from a prompt in the echo area.
All the commands provided by this package (including
latex-table-wizard-do) assume that point is inside of the
table-like environment you want to edit when they are called.

The keybinding set by default in the transient prefix are inspired
to some extent by Emacs defaults.  If you want to change these
keybindings you should change the value of the variable
latex-table-wizard-transient-keys.  See the info page for
explanations.

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

 '("mytable" . (:col '("\\COL") :row '("\\ROW") :lines '("myhline")))

Each value is a list of strings to allow for more than one macro to
have the same function.  See the info page for explanations.
