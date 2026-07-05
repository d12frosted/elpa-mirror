Hutch provides AI-powered code review integrated with magit.
It reviews staged changes, unpushed commits, and branch diffs
using an LLM (via gptel) with tool-calling for codebase context.

Configure a gptel backend as `hutch-backend', then invoke a review
via `M-x hutch-magit-review'.

To bind it inside the `magit-diff' transient, call
`hutch-add-review-binding' in your init file:

  (with-eval-after-load 'magit
    (hutch-add-review-binding)) ;; default key: "R"
    ;; or pick your own key:
    ;; (hutch-add-review-binding "K")

That adds the suffix next to `magit-diff-dwim', so it appears under
the chosen key inside the diff popup.

Example backends:

  ;; Anthropic
  (setq hutch-backend
        (gptel-make-anthropic "Claude"
          :key (getenv "ANTHROPIC_API_KEY")
          :models '(claude-sonnet-4-6)))

  ;; OpenAI
  (setq hutch-backend
        (gptel-make-openai "OpenAI"
          :key (getenv "OPENAI_API_KEY")
          :models '(gpt-5.5)))
