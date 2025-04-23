`votd` is a simple package that 1) fetches the Verse of the Day
from BibleGateway and formats it to be displayed as the Emacs
dashboard footer or *scratch* buffer message, 2) allows users to
insert any requested Bible verse or passage at the current point in
the buffer, and 3) opens a browser tab to listen to the requested
chapter.

Usage:
(votd-get-verse) fetches the verse of the day from https://biblegateway.com/.
(votd-get-passage) fetches a specified passage and inserts it at point.
(votd-listen-passage) opens the audio URL for the requested passage.
