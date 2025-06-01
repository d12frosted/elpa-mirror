`bible-gateway` is a simple package that 1) fetches the verse of
the day from BibleGateway and formats it to be displayed as the
emacs-dashboard footer or *scratch* buffer message, 2) allows users
to insert any requested Bible verse or passage at the current point
in the buffer, and 3) retrieves any audio chapter from KJV and
plays it in a browser tab or using EMMS.

Usage:

`(bible-gateway-get-verse)' fetches the verse of the day for
use as an emacs-dashboard footer or a scratch buffer message.

`(bible-gateway-get-passage)' fetches a specific passage and
inserts it at point.

`(bible-gateway-listen-passage-in-browser)' plays an audio chapter
in the browser.

`(bible-gateway-listen-passage-with-emms)' plays an audio chapter
using EMMS.
