org-assistant provides support for accessing chat APIs such as
ChatGPT in the context of an org notebook.

<img src="screenshots/example.gif" alt="example" width="400" />

## Installation

Org-assistant is available on [MELPA](http://stable.melpa.org/#/org-assistant)

<kbd>M-x</kbd> `package-install` <kbd>[RET]</kbd> `org-assistant` <kbd>[RET]</kbd>

## Usage

It provides a function named org-assistant that serves as
entrypoint for displaying an org assistant buffer.  Also, it can be
used in any org file by using a src block like #+BEGIN_SRC
assistant or #+BEGIN_SRC ?.

The API Key is looked up via org-assistant-auth-function, which has
meen tested using the MacOS Keychain.  Alternatively,
org-assistant-auth-function can be a string and directly set to
your API key.
<example>
(setq org-assistant-auth-function "<YOUR_API_KEY>")
</example>
Calling `org-assistant' interactively will generate an org-assistant buffer for you.
It can be set to a keybinding for quick use like below:
<example>
(global-set-key (kbd "C-x C-o") #'org-assistant)
</example>

### Conversation Evaluation Rules
- The org tree is traversed up in order to generate the message
list when sending information to the chat endpoint.
- It will only use messages from the branch of the tree that the block that
initiated the request is in.
- It does not include example blocks or source blocks that appear later in
the org buffer than the initiating block.
- noweb support is enabled for all blocks in the conversation based on the
initiating block having the :noweb flag set.
- Example blocks are treated as being responses from the assistant by default
if they occur after user messages.
- If the example block is before any user source block, they are
treated as system messages to the assistant instead.

See [org-babel-execute:assistant](https://github.com/tyler-dodge/org-assistant#org-babel-executeassistant)
for more details.

### Example
<example>
* Chat User Question
#+BEGIN_SRC ?
Hi
#+END_SRC

AI Response
#+BEGIN_SRC assistant :sender assistant
Hello! How can I assist you today?
#+END_SRC
</example>

When the output is set to png file, the image generation APIs are
called instead.
<example>
* Image Generation User Question
#+BEGIN_SRC ? :file sphere.png
Generate a sphere
#+END_SRC

AI Response
#+RESULTS:
file:sphere.png
</example>

You can introspect the sent conversation using the :echo flag.
<example>
* Branching Echo
#+BEGIN_SRC ?
This is the user.  Repeat verbatim only: "This is the system"
#+END_SRC

#+RESULTS:
#+BEGIN_SRC assistant :sender assistant
"This is the system"
#+END_SRC

** Branch A
#+BEGIN_SRC ? :echo
Response A
#+END_SRC

#+RESULTS:
#+BEGIN_SRC assistant :sender assistant
(user . "This is the user.  Repeat verbatim only: \"This is the system\"")
(assistant . "\"This is the system\"")
(user . "Response A")
#+END_SRC

** Branch B
#+BEGIN_SRC ? :echo
Response B
#+END_SRC

#+RESULTS:
#+BEGIN_SRC assistant :sender assistant
(user . "This is the user.  Repeat verbatim only: \"This is the system\"")
(assistant . "\"This is the system\"")
(user . "Response B")
#+END_SRC
</example>

## Comparison With Other AI Packages
### [org-assistant.el](https://github.com/tyler-dodge/org-assistant) and [org-ai.el](https://github.com/rksm/org-ai)
- [org-ai.el](https://github.com/rksm/org-ai) is focused more on runtime interaction with AI
- [org-assistant.el](https://github.com/tyler-dodge/org-assistant) is focused more on reproducible sessions
    via org babel
- [org-assistant.el](https://github.com/tyler-dodge/org-assistant) supports branching conversations
- [org-assistant.el](https://github.com/tyler-dodge/org-assistant) is not meant to be used downstream
     as a library for AI endpoint interactions.
- In [org-assistant.el](https://github.com/tyler-dodge/org-assistant), all interaction is async using org-babel, which allows
    for notebook style prompt development
- In [org-ai.el](https://github.com/rksm/org-ai), interaction is synchronous and inline,
    which is better for in-editor use cases
- [org-ai.el](https://github.com/rksm/org-ai) supports a lot of other AI use cases like text to speech

### [org-assistant.el](https://github.com/tyler-dodge/org-assistant) and [gptel](https://github.com/karthink/gptel)
- Most of the same differences and similarities apply from
    [org-assistant.el](https://github.com/tyler-dodge/org-assistant) and [org-ai.el](https://github.com/rksm/org-ai)

### Feel free to add a pull request detailing the differences if there is a package I missed
