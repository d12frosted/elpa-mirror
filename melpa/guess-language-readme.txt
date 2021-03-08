Guess-language is a buffer-local minor mode.  It guesses the
language of the current paragraph when flyspell detects an
incorrect word and changes Ispell's dictionary and typo-mode (if
present) accordingly.  If the language settings change, flyspell is
rerun but only on the current paragraph.  Guess-language thus
supports documents using multiple languages.

If the paragraph is shorter than some user-defined value, none of
the above happens because there is likely not enough text to guess
the language correctly.

Custom functions can be triggered when a new language is detected
such that users can do things like changing the input method when
needed.

The detection algorithm is based on counts of character trigrams. At this
time, supported languages are Arabic, Czech, Danish, Dutch, English,
Esperanto, Finnish, French, German, Italian, Norwegian, Polish, Portuguese,
Russian, Serbian, Slovak, Slovenian, Spanish, Swedish and Vietnamese. Adding
further languages is very easy and this package already contains language
statistics for 49 additional languages.
