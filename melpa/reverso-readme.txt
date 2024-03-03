Emacs client for the https://reverso.net service.  The service
doesn't offer an official API, so this package accesses it with
whatever means possible.

The implemented features are as follows:
- Translation (run `reverso-translate')
- "Context" or bilingual concordances (run `reverso-context')
- Grammar check (run `reverso-grammar')
- Synonyms search (run `reverso-synonyms')
- Verb conjugation (run `reverso-conjugation')
There's also `reverso-grammar-buffer', which does grammar check in
the current buffer and displays the result with overlays.

The `reverso' command is the entrypoint to all the functionality.

The Elisp API of the listed features is as follows:
- `reverso--translate'
- `reverso--get-context'
- `reverso--get-grammar'
- `reverso--get-context'
- `reverso--get-synonyms'
- `reverso--get-conjugation'

Also check out the README file at
<https://github.com/SqrtMinusOne/reverso.el>
