This package implements `fxrd-mode', a major mode for editing files with
fixed field widths.  These files are commonly used in the financial
industry, such as in ACH transactions.  This package provides:

- `nacha-mode': a mode for editing NACHA (ACH transaction) files
- `rm37-mode': a mode for editing RM37 (Mastercard rebate transaction) files
- `tso6-mode': a mode for editing TSO6 (Mastercard rebate confirmation) files
- `cbnot-mode': a mode for editing CBNOT (Amex chargeback notification) files

In each mode, the current field is highlighted with
`fxrd-current-field-face', and the field's name is shown in the
modeline.  All fields with errors are highlighted with
`fxrd-invalid-field-face', and if the current field has an error, the error
is also displayed in the modeline.

In each of these modes, the following commands are available:

- M-<right> (`fxrd-next-field') and M-<left> (`fxrd-previous-field') move to
  the next and previous fields, respectively.
- C-. (`fxrd-next-error') moves to the next invalid field.

Installation:

Installation via MELPA is easiest.
