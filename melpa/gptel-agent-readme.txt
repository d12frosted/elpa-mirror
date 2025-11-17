This is a collection of tools and prompts to use gptel "agentically" with any
LLM, to autonomously perform tasks.

It has access to
- the web (via basic web search, URL fetching and YouTube video metadata),
- local files (read/write/edit),
- the state of Emacs (documentation and Elisp evaluation),
- and Bash, if you are in a POSIX-y environment.

To use gptel-agent in a dedicated buffer:

- Set `gptel-model' and `gptel-backend' to use your preferred LLM.

- Run M-x `gptel-agent'.  This will open a buffer with the agent preset
  loaded.

- Use gptel as usual, calling `gptel-send' etc.

- If you change the system prompt, tools or other settings in this buffer, you
  can reset the agent state by (re)applying the "gptel-agent" preset from
  gptel's menu.

To use gptel-agent anywhere in Emacs:

- As with gptel, you can use gptel-agent in any buffer.  Just apply the
  "gptel-agent" preset in the buffer, or include "@gptel-agent" in a prompt.

gptel-agent can delegate tasks to "sub-agents".  Sub-agents can be specified
in Markdown or Org files in a directory.  To see how to specify agents,
examine the "agents" directory in this package.  You can add your directory
of agents to `gptel-agent-dirs', which see.

Please note: gptel-agent uses significantly more tokens than the average
gptel LLM interaction.
