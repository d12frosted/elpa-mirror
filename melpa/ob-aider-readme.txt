This library enables the use of Aider.el within Org mode Babel.
It allows sending prompts to an already running Aider.el comint buffer
directly from Org mode source blocks.

This integration enables seamless documentation of AI-assisted coding
sessions within Org mode documents, making it easier to create
reproducible workflows and tutorials.

Requirements:

- Emacs 27.1 or later
- Org mode 9.4 or later
- aider.el (https://github.com/tninja/aider.el)

Usage:

Add to your Emacs configuration:

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   (append org-babel-load-languages
           '((aider . t)))))

Then create an Aider source block in your Org file:

#+begin_src aider
Your prompt to Aider here...
#+end_src

Execute the block with C-c C-c to send the prompt to the active Aider session.
The response from Aider will be captured and displayed as the result.
