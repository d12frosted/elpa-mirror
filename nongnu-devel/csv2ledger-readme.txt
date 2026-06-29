This package aims to make it easier to convert CSV files with bank statements
to Ledger entries.

To get started, you will at the very least need to set `c2l-base-account' and
`c2l-csv-columns'.  With these variables set up, you can try to convert a CSV
file with the commands `c2l-convert-buffer' or `c2l-convert-region'.  These
commands will convert each transaction in the buffer or region, asking you
for each which balancing (or target) account to use.  Make sure to set
`c2l-account-file' to the ledger file that contains your account definitions,
so that when Emacs asks you for an account, it can offer the accounts in your
ledger file as completion targets.

For more convenience, set up a file with account matchers and point the
variable `c2l-account-matchers-file' to it.  This will allow `csv2ledger' to
try and find a target account for each transaction automatically without user
intervention.  Also look at the variable `c2l-target-match-fields' to improve
account matching for your CSV files.  Additionally, you can set
`c2l-fallback-account' if you do not wish to be asked for a target account
for each transaction for which `csv2ledger' could not find one and instead
prefer to correct the resulting ledger entries afterwards.

Normally, a ledger entry starts with a date and the payee, but if you receive
money, your CSV file may list you as the payee.  To use the sender instead in
such cases, set the variable `c2l-account-holder' to a regular expression
matching your name (i.e., whatever appears as the payee in your CSV file when
you receive money).

If you need to make any kind of changes to the data in your CSV file or wish
to customise the format of your ledger entries, look at the variables
`c2l-field-modify-functions', `c2l-transaction-modify-functions' and
`c2l-entry-function'.

Lastly, the variable `c2l-auto-cleared' controls whether transactions are
marked as "cleared" or not, and `c2l-alignment-column' controls the position
of the amount in the transaction.

For more detailed information, see the README at
<https://codeberg.org/joostkremers/csv2ledger>.