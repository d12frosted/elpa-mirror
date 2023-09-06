Provides a minor-mode for org-mode and a global minor-mode that allows you to
interact with the OpenAI API, with Stable Diffusion, as well as various local LLMs.

It allows you to:
- "chat" with a language model from within an org mode buffer
- generate images
- has support for speech input and output
- #+begin_ai..#+end_ai blocks for org-mode
- various commands usable everywhere

See see https://github.com/rksm/org-ai for the full set of features and setup
instructions.

At the minimum, you will want something like:

(use-package org-ai
  :ensure
  :commands (org-ai-mode org-ai-global-mode)
  :init
  (add-hook 'org-mode-hook #'org-ai-mode)
  (org-ai-global-mode))

You will need an OpenAI API key. It can be stored in the format
  machine api.openai.com login org-ai password <your-api-key>
in your ~/.authinfo.gpg file (or other auth-source) and will be picked up
when the package is loaded.

For the speech input/output setup please see
https://github.com/rksm/org-ai/blob/master/README.md#setting-up-speech-input--output

Available commands:

- Inside org-mode / #+begin_ai..#+end_ai blocks:
    - C-c C-c to send the text to the OpenAI API and insert a response
    - Press C-c <backspace> (org-ai-kill-region-at-point) to remove the chat part under point.
    - org-ai-mark-region-at-point will mark the region at point.
    - org-ai-mark-last-region will mark the last chat part.

- Speech input/output. Talk with your AI!
    - In org-mode / #+begin_ai..#+end_ai blocks:
      - C-c r to record and transcribe speech via whisper.el in org blocks.
    - Everywhere else:
        - Enable speech input with org-ai-talk-input-toggle for other commands (see below).
    - Enable speech output with org-ai-talk-output-enable. Speech output uses os internal speech synth (macOS) or espeak otherwise.
    - See [Setting up speech input / output](#setting-up-speech-input--output) below for more details.

- Non-org-mode commands
    - org-ai-on-region: Ask a question about the selected text or tell the AI to do something with it.
    - org-ai-refactor-code: Tell the AI how to change the selected code, a diff buffer will appear with the changes.
    - org-ai-on-project: Query / modify multiple files at once. Will use projectile if available.
    - org-ai-prompt: prompt the user for a text and then print the AI's response in current buffer.
    - org-ai-summarize: Summarize the selected text.
    - org-ai-explain-code: Explain the selected code.

- org-ai-open-account-usage-page show how much money you burned.
- org-ai-install-yasnippets install snippets for #+begin_ai..#+end_ai blocks.
- org-ai-open-request-buffer for debugging, open the request buffer.
