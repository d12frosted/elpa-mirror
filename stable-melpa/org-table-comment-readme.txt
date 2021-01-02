
This allows you to create org-tables in languages that do not have
block comments.  For example in elisp:

|------+----------------+----+-------|
|      |                |    | <5>   |
| This | is             | a  | table |
| that | may be created | in | orgtbl-comment-mode |
|------+----------------+----+-------|

or

|------+----------------+----+---------------------|
| This | is             | a  | table               |
| that | may be created | in | orgtbl-comment-mode |
|------+----------------+----+---------------------|

It also supports single-comment radio tables, for example in LaTeX
the following now works if you are using the overlays driver for
org-table-comment:

% BEGIN RECEIVE ORGTBL salesfigures
% END RECEIVE ORGTBL salesfigures

% #+ORGTBL: SEND salesfigures orgtbl-to-latex
% |-------+------+---------+---------|
% | Month | Days | Nr sold | per day |
% |-------+------+---------+---------|
% | Jan   |   23 |      55 |     2.4 |
% | Feb   |   21 |      16 |     0.8 |
% | March |   22 |     278 |    12.6 |
% |-------+------+---------+---------|
% #+TBLFM: $4=$3/$2;.1f

When editing the table, pressing C-c C-c produces the LaTeX table, as follows:

% BEGIN RECEIVE ORGTBL salesfigures
\begin{tabular}{lrrr}
\hline
Month & Days & Nr sold & per day \\
\hline
Jan & 23 & 55 & 2.4 \\
Feb & 21 & 16 & 0.8 \\
March & 22 & 278 & 12.6 \\
\hline
\end{tabular}
% END RECEIVE ORGTBL salesfigures

% #+ORGTBL: SEND salesfigures orgtbl-to-latex
% |-------+------+---------+---------|
% | Month | Days | Nr sold | per day |
% |-------+------+---------+---------|
% | Jan   |   23 |      55 |     2.4 |
% | Feb   |   21 |      16 |     0.8 |
% | March |   22 |     278 |    12.6 |
% |-------+------+---------+---------|
% #+TBLFM: $4=$3/$2;.1f

NOTE: This requires `comment-region' and `uncomment-region' to work
properly in the mode you are using.  Also filling/wrapping in the
mode needs to not wrap the orgbls.

TODO: Make killing and cutting cut the appropriate lines when
inside org-comment-table.

Eventually this could allow for R radio tables..?

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
