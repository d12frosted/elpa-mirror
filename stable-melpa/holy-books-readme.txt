This library provides common desirable features using the Org interface for
when writing about the Quran and the Bible:

0. Links “quran:chapter:verse|colour|size|no-info-p”, or just “quran:chapter:verse”
   for retrieving a verse from the Quran. Use “Quran:chapter:verse” to HTML export
   as a tooltip. The particular translation can be selected by altering the
   HOLY-BOOKS-QURAN-TRANSLAITON variable.

1. Likewise, “bible:book:chapter:verse”.
   The particular version can be selected by altering the
   HOLY-BOOKS-BIBLE-VERSION variable.

2. Two functions, HOLY-BOOKS-QURAN and HOLY-BOOKS-BIBLE that do the heavy
   work of the link types.

3. A link type to produce the Arabic basmallah; e.g., “basmala:darkgreen|20px|span”.

Minimal Working Example:

Sometimes I want to remember the words of the God of Abraham. In English Bibles,
His name is “Elohim”, whereas in Arabic Bibles and the Quran, His name is
“Allah”. We can use links to quickly access them, such as Quran:7:157|darkgreen
and bible:Deuteronomy:18:18-22|darkblue.  Arab-speaking Christians and Muslims
use the Unicode symbol [[green:ﷲ]] to refer to Him ---e.g., they would write ﷲ ﷳ ,
“Allah akbar”, to declare the greatness of God-- and, as the previous passage
says “in the name of the Lord”, there is a nice calligraphic form that is used
by Arabic speakers when starting a task, namely [[basmala:darkgreen|20px|span]]
---this is known as the ‘basmalallah’, which is Arabic for “name of God”.
(Using capitalised ‘Quran:⋯’ and ‘Bible:⋯’ results in tooltips.)

This file has been tangled from a literate, org-mode, file.
