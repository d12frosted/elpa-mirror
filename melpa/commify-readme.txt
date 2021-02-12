
This package provides a simple command to toggle a number under the cursor
between having grouped digits and not.  For example, if the buffer is as
shown with the cursor at the '*':

Travel expense is 4654254654*

invoking commify-toggle will change the buffer to:

Travel expense is 4,654,254,654*

Calling commify-toggle again removes the commas.  The cursor can also be
anywhere in the number or immediately before or after the number.
commify-toggle works on floating or scientific numbers as well, but it only
ever affects the digits before the decimal point.  Afterwards, the cursor
will be placed immediately after the affected number.

Commify now optionally works with hexadecimal, octal, and binary numbers,
with variables for independently setting the group char and group size for
those bases.  They are recognized by prefixes "0x", "0o", and "0b",
respectively, but these can also be set.  See the README at the github page
for details.

You can configure these variables:
  - commify-group-char (default ",") to the char used for grouping
  - commify-group-size (default 3) to number of digits per group
  - commify-decimal-char (default ".") to the char used as a decimal point.

Bind the main function to a convenient key in you init.el file:

   (key-chord-define-global ",," 'commify-toggle)
