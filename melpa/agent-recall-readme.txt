
agent-recall provides search, browsing, and session resume capabilities
for agent-shell conversation transcripts.

agent-shell (https://github.com/xenodium/agent-shell) automatically
saves full conversation transcripts as Markdown files in
`.agent-shell/transcripts/' directories within your projects.  Over
time these accumulate into a rich knowledge base of AI interactions,
but there's no built-in way to search across them or resume past
conversations.

agent-recall maintains a persistent index of all transcripts,
provides fast full-text search powered by ripgrep, and can resume
past agent-shell sessions from any transcript.  The index grows
automatically as you use agent-shell (via a mode hook) and can
be rebuilt from scratch with `agent-recall-reindex'.

Quick start:

  ;; First-time setup: build the index
  (setq agent-recall-search-paths '("~/projects" "~/work"))
  M-x agent-recall-reindex

  ;; Search all transcripts
  M-x agent-recall-search

  ;; Browse transcripts by project and date
  M-x agent-recall-browse

  ;; Resume a past conversation
  M-x agent-recall-resume

  ;; See stats about your transcript collection
  M-x agent-recall-stats

  ;; Auto-activate transcript-mode when visiting transcripts
  (global-agent-recall-transcript-mode 1)

Session resume setup (optional):

  ;; Embed session IDs in new transcripts for instant resume
  (add-hook 'agent-shell-mode-hook #'agent-recall-track-sessions)

  ;; Backfill session IDs into existing transcripts
  M-x agent-recall-backfill          ; dry-run (preview only)
  C-u C-u M-x agent-recall-backfill  ; write session IDs
