This uses Elpher to browse Gemini sites and Gemini Mode to edit
them using the Titan protocol.

- https://thelambdalab.xyz/elpher/
- https://git.carcosa.net/jmcbray/gemini.el

Add gemini-write support to `elpher' and `gemini-mode' in your init
file by enabling the minor mode:

(gemini-write-mode 1)

Use 'e' to edit a Gemini page on a site that has Titan enabled. Use
'C-c C-c' to save. Customize 'gemini-write-tokens' to set
passwords, tokens, or whatever you need in order to edit sites.
