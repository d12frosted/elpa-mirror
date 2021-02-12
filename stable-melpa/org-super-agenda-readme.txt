This package lets you "supercharge" your Org daily/weekly agenda.
The idea is to group items into sections, rather than having them
all in one big list.

Now you can sort-of do this already with custom agenda commands,
but when you do that, you lose the daily/weekly aspect of the
agenda: items are no longer shown based on deadline/scheduled
timestamps, but are shown no-matter-what.

So this package filters the results from
`org-agenda-finalize-entries', which runs just before items are
inserted into agenda views.  It runs them through a set of filters
that separate them into groups.  Then the groups are inserted into
the agenda buffer, and any remaining items are inserted at the end.
Empty groups are not displayed.

The end result is your standard daily/weekly agenda, but arranged
into groups defined by you.  You might put items with certain tags
in one group, habits in another group, items with certain todo
keywords in another, and items with certain priorities in another.
The possibilities are only limited by the grouping functions.

The primary use of this package is for the daily/weekly agenda,
made by the `org-agenda-list' command, but it also works for other
agenda views, like `org-tags-view', `org-todo-list',
`org-search-view', etc.

Here's an example which you can test by evaluating the `let' form:

(let ((org-super-agenda-groups
       '(;; Each group has an implicit boolean OR operator between its selectors.
         (:name "Today" ; Optionally specify section name
                :time-grid t ; Items that appear on the time grid
                :todo "TODAY") ; Items that have this TODO keyword
         (:name "Important"
                ;; Single arguments given alone
                :tag "bills"
                :priority "A")
         ;; Set order of multiple groups at once
         (:order-multi (2 (:name "Shopping in town"
                                 ;; Boolean AND group matches items that match all subgroups
                                 :and (:tag "shopping" :tag "@town"))
                          (:name "Food-related"
                                 ;; Multiple args given in list with implicit OR
                                 :tag ("food" "dinner"))
                          (:name "Personal"
                                 :habit t
                                 :tag "personal")
                          (:name "Space-related (non-moon-or-planet-related)"
                                 ;; Regexps match case-insensitively on the entire entry
                                 :and (:regexp ("space" "NASA")
                                               ;; Boolean NOT also has implicit OR between selectors
                                               :not (:regexp "moon" :tag "planet")))))
         ;; Groups supply their own section names when none are given
         (:todo "WAITING" :order 8) ; Set order of this section
         (:todo ("SOMEDAY" "TO-READ" "CHECK" "TO-WATCH" "WATCHING")
                ;; Show this group at the end of the agenda (since it has the
                ;; highest number). If you specified this group last, items
                ;; with these todo keywords that e.g. have priority A would be
                ;; displayed in that group instead, because items are grouped
                ;; out in the order the groups are listed.
                :order 9)
         (:priority<= "B"
                      ;; Show this section after "Today" and "Important", because
                      ;; their order is unspecified, defaulting to 0. Sections
                      ;; are displayed lowest-number-first.
                      :order 1)
         ;; After the last group, the agenda will display items that didn't
         ;; match any of these groups, with the default order position of 99
         )))
  (org-agenda nil "a"))

You can adjust the `org-super-agenda-groups' to create as many different
groups as you like.
