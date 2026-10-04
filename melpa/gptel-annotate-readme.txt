`gptel-annotate' is an extension for `gptel' that allows you to use Large
Language Models (LLMs) to annotate buffers or files with suggestions,
warnings, or notes.  It usees Emacs' built-in Flymake minor mode to
display the LLM-generated diagnostics.

Usage:

There are two ways: as a command or as a gptel preset.  The latter is
generally more useful.

To annotate a file or buffer, run `M-x gptel-annotate'.  This command prompts
for the instructions to send to the LLM and the target sources (files or
buffers) to annotate.  By default, it annotates the current buffer, but with
a prefix argument (`C-u') it lets you specify multiple buffers and files.

When used in a regular chat session you can omit the instructions to read
them from the prompt in the chat buffer instead.

In addition to the interactive command, `gptel-annotate' can be used
directly within any prompt by applying the `gptel-annotate'
preset, by inserting `@gptel-annotate' followed by file or buffer names in
the prompt.  For instance, consider this hypothetical prompt:

------------------------------------------------------------------------
*prompt*: Highlight any flaws in the design and architecture of the
work-in-progress "sidle" and "viewport" libraries, ignoring any low level
issues that will be caught by the byte-compiler.

@gptel-annotate sidle.el "viewport.el"
------------------------------------------------------------------------

When typed anywhere in Emacs and sent with `gptel-send', this request will
include the contents of the buffers (or files) "sidle.el" and "viewport.el",
and the LLM's targeted responses will be displayed as flymake annotations in
these two buffers.  (Using "quotes" around the buffer/file names is
recommended.)

You can also include the @gptel-annotate cookie without specifying any
buffers or files, and the LLM will attempt to annotate the right buffer based
on the conversation context.  This is useful if the LLM has already examined
the source location in earlier conversation turns.  Example:

------------------------------------------------------------------------
*prompt*: Provide a short summary of each link in the blog
post, along with a readability rating out of 10.  @gptel-annotate
------------------------------------------------------------------------

Presumably, it is clear in this context which buffer "blog post" refers to.

The LLM's response is parsed, and annotations are automatically
applied to the relevant buffers as Flymake diagnostics.
