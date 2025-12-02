bible-gateway is a simple package that fetches the verse of the
day, as well as any requested verse, passage, and chapter in both
text and audio format from https://BibleGateway.com

Usage:

`bible-gateway-get-verse' fetches the verse of the day for use as
an emacs-dashboard footer or a scratch buffer message.

`bible-gateway-get-verse-in-eu' is similar to
`bible-gateway-get-verse' but scrapes the verse of the day from the
BibleGateway website for users in EU where the API is not
accessible.

`bible-gateway-get-passage' fetches a specific passage and inserts
it at point. It can be called both interactively from M-x or
programmatically with the book name and verse(s) as arguments.

M-x `bible-gateway-listen-passage-in-browser' plays a specific
audio chapter in the browser.
