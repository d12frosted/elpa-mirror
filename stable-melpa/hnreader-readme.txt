This package renders hackernews website at https://news.ycombinator.com/ in
an org buffer. Almost everything works. Features that are not supported are
account related features. You cannot add comment, downvote or upvote.

; Dependencies
`promise' and `request' are required.
user must have `org-mode' 9.2 or later installed also.

; Commands
hnreader-news: Load news page.
hnreader-past: Load past page.
hnreader-ask: Load ask page.
hnreader-show: Load show page.
hnreader-newest: Load new link page.
hnreader-more: Load more.
hnreader-back: Go back to previous page.
hnreader-comment: read an HN item url such as https://news.ycombinator.com/item?id=1

; Customization
hnreader-history-max: max number history items to remember.
hnreader-view-comments-in-same-window: if nil then will not create new window
when viewing comments

; Changelog
0.2.1 2021-10-18 update css class grab for entry title
