TXL provides machine translation through DeepL's REST API.
Minimally the user needs to specify a pair of languages in the
customization variable `txl-languages' and an authentication key
for DeepL's REST API via `txl-deepl-api-url'.

The command `txl-translate-region-or-paragraph' translates the
marked region or, if no region is active, the paragraph to the
respective other language.  The current language is detected using
the package guess-language.  The retrieved translation is shown in
a separate buffer where it can be reviewed and edited.  The
original text can be replaced with the (edited) translation via
<C-c C-c>.  The translation can be dismissed (without touching the
original text) using <C-c C-k>.  If a prefix argument is given
(<C-u>), the text will be translated round-trip to the other
language and back.
