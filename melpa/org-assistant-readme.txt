org-assistant provides support for accessing chat APIs such as
ChatGPT in the context of an org notebook.

It provides a function named org-assistant that serves as
entrypoint for displaying an org assistant buffer.  Also, it can be
used in any org file by using a src block like #+BEGIN_SRC
assistant or #+BEGIN_SRC ?.

The API Key is looked up via org-assistant-auth-function, which has
meen tested using the MacOS Keychain.  Alternatively,
org-assistant-auth-function can be a string and directly set to
your API key.

org-assistant uses the org tree in order to generate the message
list whenever sending information to the chat endpoint.  It will
only use messages from the branch of the tree that the block that
initiated the request is in.  It does not include example blocks or
source blocks that appear later in the org buffer than the
initiating block.  Example blocks are treated as being responses
from the assistant by default if they occur after user messages.
If the example block is before any user source block, they are
treated as system messages to the assistant instead.

### Example
<example>
* User Question
#+BEGIN_SRC ?
Hi
#+END_SRC

AI Response
#+BEGIN_EXAMPLE
Hello! How can I assist you today?
#+END_EXAMPLE
</example>
