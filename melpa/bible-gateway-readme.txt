bible-gateway is a simple package that fetches content from
BibleGateway.com. It can:

- Fetch and display the Bible verse of the day
- Insert Bible passages/chapters at point
- Open audio chapters in your browser
- Search the Bible by keyword and display results in a dedicated buffer with
  clickable references and pagination

Usage:

`bible-gateway-get-verse' fetches the verse of the day for use as
an emacs-dashboard footer or a scratch buffer message.

M-x `bible-gateway-get-passage' fetches a Bible passage and inserts
it at point. It can be called both interactively from
\\[execute-extended-command] or programmatically with the book name
and verse(s) as arguments.

M-x `bible-gateway-listen-passage' plays a Bible chapter from KJV
Zondervan Audio in the browser.

M-x `bible-gateway-search' prompts for a search query, fetches results
from BibleGateway, and displays them in a dedicated buffer.
