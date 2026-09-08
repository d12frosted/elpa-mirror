Display AI API account balances in the Emacs mode line.  This
package is deliberately provider-agnostic: adding support for a new
AI API is usually just a few lines added to
`api-credit--providers'.

Currently bundled providers: OpenRouter (USD), DeepSeek (CNY),
Moonshot (CNY).  The supported pattern is: one authenticated
GET request with a plain API key (Bearer token) that answers
"how much do I have left?".  Any provider fitting that pattern
can be added the same way.

The major Chinese cloud platforms (Baidu Qianfan, Volcengine
Ark, Tencent Hunyuan, iFlytek Spark) are likewise absent:
their model keys cannot read the cloud-side balance, which
requires each vendor's signed authentication.

Some major providers are intentionally absent because they offer
no public balance API queryable with a regular API key: OpenAI
(its legacy /v1/dashboard/billing/* routes were unofficial and
are no longer reliable), Anthropic (the Admin API reports usage
only and requires a separate admin key) and Google Gemini
(billing is only available through the OAuth-protected Google
Cloud Billing API).

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
  machine api.deepseek.com password sk-...
  machine api.moonshot.cn password sk-...
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
