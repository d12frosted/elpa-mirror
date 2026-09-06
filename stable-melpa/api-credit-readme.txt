Display AI API account balances in the Emacs mode line.  This
package is deliberately provider-agnostic: adding support for a new
AI API is usually just a few lines added to
`api-credit--providers'.

Currently bundled providers: OpenRouter (USD), DeepSeek (CNY),
Moonshot (CNY).  However the design makes it trivial to add many
others - OpenAI, Anthropic, Mistral, Cohere, Gemini, Groq,
Perplexity, and any provider that exposes a balance or usage
endpoint.

If you use a service not listed above, please contribute a
provider entry.  Each entry lives in `api-credit--providers' and
consists of:

  (MY-PROVIDER
   :name "My Provider"
   :currency "$"
   :host  "api.myprovider.com"
   :url   "https://api.myprovider.com/v1/credits"
   :recharge-url "https://dashboard.myprovider.com/top-up" ; optional
   :parser 'api-credit--parse-my-provider)

The parser function receives the JSON response (already converted
into an alist) and returns the numeric balance.  That is typically
all that is required to add a new vendor.

Setup: add entries to ~/.authinfo or ~/.authinfo.gpg:

  machine openrouter.ai password sk-or-v1-...
  machine deepseek.com password sk-...
  machine moonshot.cn password sk-...
  machine api.myprovider.com password sk-...

Then enable `api-credit-mode' globally.

Features:
- Automatic polling with configurable interval
- Cycle through providers or jump to specific one
- Error resilience (shows stale data indicator on fetch failure)
- No browser required, pure Emacs Lisp
- Extensible provider registry (`api-credit--providers')

New contributors are welcome.  This package aims to become a
universal AI balance monitor, so please help extend it to the APIs
you use.
