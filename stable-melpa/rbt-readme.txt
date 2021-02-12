
Useful commands:
rbt-status --> shows your current open reviewboard items

rbt-review --> when no arguments are supplied, we try to review the current last diff on git HEAD.
  If you are currently hovering over a number, we try to use that as a review id
   This is useful if you are looking at rbt-status, then run rbt-review when looking at r/123

rbt-review-commit --> useful when your cursor is currently over a git commit hash id

rbt-review-with-selected --> useful when you don't remember the review id,
  and want to be prompted which review to use.

rbt-review-close --> useful when your cursor is currently over a review id

rbt-review-discard --> useful when your cursor is currently over a review id
