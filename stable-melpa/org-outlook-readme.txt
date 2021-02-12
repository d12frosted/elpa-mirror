
* Introduction:
Org mode lets you organize your tasks. However, sometimes you may wish
to integrate org-mode with outlook since your company forces you to
use Microsoft Outlook.  [[file:org-outlook.el][org-outlook.el]] allows:

- Creating Tasks from outlook items:
  - org-outlook-task. All selected items in outlook will be added to a
    task-list at current point. This version requires org-protocol and
    org-protocol.vbs.  The org-protocol.vbs has can be generated with
    the interactive function `org-outlook-create-vbs'.

  - If your organization has blocked all macro access OR you want to
    have an action for a saved =.msg= email, org-outlook also adds
    drag and drop support allowing =.msg= files to become org tasks.
    This is enabled by default, but can be disabled by
    `org-outlook-no-dnd'

  - With blocked emails, you may wish to delete the emails in a folder
    after the task is completed.  This can be accomplished with
    `org-protocol-delete-msgs'.  If you use it frequently, you may
    wish to bind it to a key, like


  (define-key org-mode-map (kbd "C-c d") 'org-protocol-delete-msgs)



- Open Outlook Links in org-mode

  - Requires org-outlook-location to be customized when using Outlook
    2007 (this way you don’t have to edit the registry).

This is based loosely on:
http://superuser.com/questions/71786/can-i-create-a-link-to-a-specific-email-message-in-outlook


Note that you may also add tasks using visual basic directly. The script below performs the following actions:

   - Move email to Personal Folders under folder "@ActionTasks" (changes GUID)
   - Create a org-mode task under heading "* Tasks" for the file `f:\Documents\org\gtd.org'
   - Note by replacing "@ActionTasks", "* Tasks" and
     `f:\Documents\org\gtd.org' you can modify this script to your
     personal needs.

The visual basic script for outlook can be created by calling `M-x org-outlook-create-vbs'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
