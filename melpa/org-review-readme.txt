
This allows to schedule reviews of org entries.

Entries will be scheduled for review if their NEXT_REVIEW or their
LAST_REVIEW property is set. The next review date is the
NEXT_REVIEW date, if it is present, otherwise it is computed from
the LAST_REVIEW property and the REVIEW_DELAY period, such as
"+1m". If REVIEW_DELAY is absent, a default period is used. Note
that the LAST_REVIEW property is not considered as inherited, but
REVIEW_DELAY is, allowing to set it for whole subtrees.

Checking of review dates is done through an agenda view, using the
`org-review-agenda-skip' skipping function. This function is based
on `org-review-toreview-p', that returns `nil' if no review is
necessary (no review planned or it happened recently), otherwise it
returns the date the review was first necessary (NEXT_REVIEW, or
LAST_REVIEW + REVIEW_DELAY, if it is in the past).

To mark an entry as reviewed, use the function
`org-review-insert-last-review' to set the LAST_REVIEW date to the
current date. If `org-review-sets-next-date' is set (which is the
default), this function also computes the date of the next review
and inserts it as NEXT_REVIEW.

Example use.

1 - To display the things to review in the agenda.

  (setq org-agenda-custom-commands (quote ( ...
       ("R" "Review projects" tags-todo "-CANCELLED/"
        ((org-agenda-overriding-header "Reviews Scheduled")
        (org-agenda-skip-function 'org-review-agenda-skip)
        (org-agenda-cmp-user-defined 'org-review-compare)
        (org-agenda-sorting-strategy '(user-defined-down)))) ... )))

2 - To set a key binding to review from the agenda

  (add-hook 'org-agenda-mode-hook (lambda () (local-set-key (kbd "C-c
       C-r") 'org-review-insert-last-review)))

; Changes

2016-08-18: better detection of org-agenda buffers
2014-05-08: added the ability to specify next review dates

TODO
- be able to specify a function to run when marking an item reviewed
