Customization:
ess-view-data-backend-list: dplyr (default), dplyr+DT, data.table+magrittr
ess-view-data-print-backend-list: print (default), kable
ess-view-data-save-backend-list: write.csv (default), readr::write_csv,
                                 data.table::fwrite kable
ess-view-data-complete-backend-list: jsonlite
ess-view-data-read-string: ess-completing-read (default), completing-read,
                           ido-completing-read, ivy-completing-read

Utils:
NOTE: it will make a copy of the data and then does the following action
ess-view-data-print: the main function to view data

Example: In a ess-r buffer or a Rscript buffer, `M-x ess-view-data-print`
and input `mtcars`.

ess-view-data-set-backend: change backend
ess-view-data-toggle-maxprint: toggle limitation of lines per page to print

ess-view-data-verbs

Example: In the ESS-V buffer, `M-x ess-view-data-verbs` and select the verb
to do with.

ess-view-data-filter

Example: In the ESS-V buffer, `M-x ess-view-data-filter`, `cyl <RET> mpg` to
select columns and <C-j> to finish input.  An indirect buffer pops up and
'data-masking' Expressions can be edited.

ess-view-data-select / ess-view-data-unselect

Example: In the ESS-V buffer, `M-x ess-view-data-select`, `cyl <RET> mpg` to
select columns and <C-j> to finish input.

ess-view-data-sort
ess-view-data-group / ess-view-data-ungroup
ess-view-data-mutate
ess-view-data-slice
ess-view-data-wide2long / ess-view-data-long2wide
ess-view-data-update
ess-view-data-reset

Example: In the ESS-V buffer, `M-x ess-view-data-reset`, an indirect buffer
pops up and the action history can be edited.

ess-view-data-unique
ess-view-data-count

Example: In the ESS-V buffer, `M-x ess-view-data-count`, `cyl <RET> mpg` to
select columns and <C-j> to finish input.  In the updated buffer with count
information, `M-x ess-view-data-print` to go back.

ess-view-data-summarise
ess-view-data-overview
ess-view-data-goto-page / -next-page / -preious-page / -first-page /
                          -last-page / -page-number
ess-view-data-save
