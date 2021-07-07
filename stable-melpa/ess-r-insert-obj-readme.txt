This package contains utilities to help insert variable (column) names or
values in ESS-R. The listing is as follows.

## Utils:
To help insert Data.frame-like object:
- M-x ess-r-insert-obj-dt-name

To help insert Variable (Column) name: with `C-u C-u`, it prompts for the dt
name to search in.
- M-x ess-r-insert-obj-col-name
- M-x ess-r-insert-obj-col-name-all

To help insert values: with `C-u C-u`, it prompts for the dt name to search
in, or with `C-u`, it prompts for column/variable name to search in.
- M-x ess-r-insert-obj-value
- M-x ess-r-insert-obj-value-all

## Customization
### ess-r-insert-obj-complete-backend-list
- jsonlite
### ess-r-insert-obj-read-string
- ess-completing-read (default)
- completing-read
- ido-completing-read
- ivy-completing-read
