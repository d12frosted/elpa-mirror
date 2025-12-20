This package uses the gptel library to add LLM integration into
forge.  Currently, it adds functionality for generating pull-request
descriptions when creating PRs via `forge-create-pullreq'.

Features:
- Generate PR descriptions based on git diffs between branches
- Automatically uses existing buffer content (e.g., PR templates) as structure
- Optional rationale input for better context
- Customizable prompts and templates

Usage:
1. Call `gptel-forge-prs-install' to set up keybindings
2. When creating a PR with forge, use:
   - M-g to generate a PR description
   - M-r to generate with rationale

When forge inserts a PR template into the buffer, gptel-forge-prs will
automatically use it as a structure when generating the description.
