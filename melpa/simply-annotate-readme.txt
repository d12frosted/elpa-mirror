
A lightweight annotation system for Emacs that allows
you to add persistent notes to any text file without modifying the
original content.  Enhanced with threading, collaboration, and org-mode integration.

Quick Start:

(use-package simply-annotate
 :bind ("C-c A" . simply-annotate-mode))

1. Open any file
2. Enable annotation mode: =C-c A=
3. Select text and press =M-s j= to create your first annotation
4. Create some more annotations
5. Navigate with =M-n= (next) and =M-p= (previous)

Threading & Collaboration:

* Replies
- Press =M-s r= to add a reply to any annotation
- Creates threaded conversations for code reviews

* Status Management
- Press =M-s s= to set status (open, in-progress, resolved, closed)
- Press =M-s p= to set priority (low, normal, high, critical)
- Press =M-s t= to add tags for organization

* Author Management
- Configure team members: (setq simply-annotate-author-list '("John" "Jane" "Bob"))
- Set prompting behavior: (setq simply-annotate-prompt-for-author 'threads-only)
- Press =M-s a= to change annotation author

* Editing
- Press =M-s e= to edit the current annotation
- Edit in a sexp form and then C-c C-c to save
- Any data field can be edited

* Org-mode Integration
- Press =M-s o= to export annotations to org-mode files
- Each thread becomes a TODO item with replies as sub-entries

Configuration Examples:

;; Single user (default)
(setq simply-annotate-prompt-for-author nil)

;; Team collaboration
(setq simply-annotate-author-list '("John Doe" "Jane Smith" "Bob Wilson"))
(setq simply-annotate-prompt-for-author 'threads-only)
(setq simply-annotate-remember-author-per-file t)
