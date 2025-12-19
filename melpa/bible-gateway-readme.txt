bible-gateway is a simple package that fetches the verse of the
day, as well as any requested verse, passage, and chapter in both
text and audio format from https://BibleGateway.com

Usage:

`bible-gateway-get-verse' fetches the verse of the day for use as
an emacs-dashboard footer or a scratch buffer message.

M-x `bible-gateway-get-passage' fetches a Bible passage and inserts
it at point. It can be called both interactively from
\\[execute-extended-command] or programmatically with the book name
and verse(s) as arguments.

M-x `bible-gateway-listen-passage' plays a Bible chapter from KJV
Zondervan Audio in the browser.
