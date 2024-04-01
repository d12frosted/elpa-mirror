
`claude-shell' is a comint-based shell to interact with Anthrophic's Claude
AI. It is based on `shell-maker' providing a convenience layer on top of
comint. It strives to be similar in functionality and spirit to
`chatgpt-shell' (https://github.com/xenodium/chatgpt-shell) just for Claude
models.

`claude-shell' provides an interactive chat with Claude in a dedicated shell
buffer. It also integrates with the rest of Emacs to allow seamlessly calling
out to Claude on-demand. Similar to the many AI copilots around.

You must set `claude-shell-api-token' to your API token before using it.

Run `claude-shell' to get an interactive Claude shell.
