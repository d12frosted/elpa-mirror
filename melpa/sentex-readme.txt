This package uses breaking and non-breaking sentence-ending rules ported
from OmegaT and Okapi Framework.

It provides `sentex-forward-sentence', `sentex-backward-sentence', and
`sentex-kill-sentence'. They aim to act like the built-in functions, but to
intelligently ignore things like "e.g.", "i.e.", or "Mr." as ends of sentences.

Customize `sentex-ruleset-framework' to select which framework to use.
Call `sentex-set-language-for-buffer', or set `sentex-current-language'
to choose what language's rules to use. Different frameworks support
different languages, so if your language doesn't appear in the options, try
using a different one.
