
`github-review` lets you submit GitHub code review with Emacs.

With `github-review-start` you can pull the content of a pull request into a buffer
as a diff with comments corresponding to the PR description.
In that buffer you can add comment (global and inline) that you want to make on the pull request.
Once done, you can submit these comments as a code review with one of:
- `github-review-approve`
- `github-review-comment`
- `github-review-reject`.
