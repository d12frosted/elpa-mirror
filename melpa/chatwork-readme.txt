chatwork.el provides chatwork-mode for sending messages to ChatWork.

Set your ChatWork API token, which you can get from
https://www.chatwork.com/service/packages/chatwork/subpackages/api/apply_beta.php

Example:

 (setq chatwork-token "YOUR CHATWORK API TOKEN")

`chatwork' command open a draft buffer for selected room.
Write a message, then type `C-cC-c'.
