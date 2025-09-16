The quick-fasd Emacs package integrates the Fasd tool within the Emacs
environment. Fasd, a command-line utility, enhances the productivity of users
by providing fast access to frequently used files and directories. Inspired
by tools such as autojump, z, and v, Fasd functions by maintaining a dynamic
index of files and directories you access, allowing you to reference them
quickly from the command line.

After installing quick-fasd in Emacs, you can easily navigate your file
system directly within Emacs by using Fasd's fast-access capabilities. For
example, you can open recently accessed files or quickly jump to frequently
used directories without leaving the Emacs environment.

Here's how the package works:
- `quick-fasd-mode' adds a hook to `find-file-hook' and `dired-mode-hook' to
  automatically add all visited files and directories to Fasd's database.
- The user can invoke the `quick-fasd-find-path' function, which prompts for
  input and display available candidates from the Fasd index, enabling rapid
  and efficient file navigation.
