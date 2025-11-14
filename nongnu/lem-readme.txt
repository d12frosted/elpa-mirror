


1 lem.el
════════

  `lem.el' is an Emacs client library and interface for Lemmy, the
  federated link-aggregator and discussion platform (alternative to
  reddit, lobsters, etc.). For information about Lemmy, see
  [join-lemmy.org].


[join-lemmy.org] <http://join-lemmy.org>


2 install
═════════

  `lem.el' is on MELPA, so you can install it from there.

  Add `MELPA' to your archives:

  ┌────
  │ (require 'package)
  │ (add-to-list 'package-archives
  │ 	     '("melpa" . "http://melpa.org/packages/") t)
  └────

  Update and install:

  `M-x package-refresh-contents RET'

  `M-x package-install RET lem RET'

  Otherwise you can pull from this repo, main or develop branch, add to
  load-path, and require.


3 logging in
════════════

  First set `lem-instance-url' to your lemmy instance.

  Then the first time you call `lem' you'll be asked for your username
  and password.  If `lem-use-totp' is set to a non-nil value, you will
  also be asked for your TOTP.

  Upon logging in, your authentication details will be saved in a
  plstore under your emacs directory. You "shouldn't" have to provide
  your password again (unless server-side updates require new login).

  If you don't want to have to provide your username, add `(setq
  lem-current-user "yourusername")' to your init file.


4 encrypted authentication tokens
═════════════════════════════════

  If you'd like to encrypt your authentication token in the plstore, set
  `lem-encrypt-auth-tokens' to non-nil, delete the file
  `~/.emacs.d/lem.plstore', and log in again. For this to work you
  probably need to set `plstore-encrypt-to' to a valid GPG key.


5 usage
═══════

5.1 basic commands
──────────────────

  A full command index is available at the end of this readme, but here
  are a few commands to get you going. You can also view the keybindings
  of `lem-mode-map' by hitting `?' from a `lem.el' buffer.

  • `I' - `lem-ui-view-instance' - load the instance view.
  • `S' - jump to one of your subscribed communities.
  • `C' - `lem-ui-browse-communities' - browse communities in a sortable
    table.
  • `/' - switch between live `lem.el' buffers.


  • `N' - `lem-post-compose' - compose a new post.
  • `r' - `lem-post-comment' - reply to post or comment at point.


  • `RET' - `lem-ui-view-item-at-point' - load view of item at point,
    e.g. on a post, view its full thread.
  • `n' / `p' - next/previous item
  • `TAB' / `<backtab>' - next/previous tab item (hyperlink, etc.)
  • `h' - search, for communities, posts, comments, users.

  • `B' - view your inbox (mentions, replies, private messages)
  • `O' - view your own profile
  • `A' - view your saved (bookmarked) items


  • `l' - like item at point
  • `a' - save item at point
  • `d' - delete item at point
  • `e' - edit item at point
  • `c' - jump to current item's community
  • `u' - jump to current item's user


  • `s' - subscribe to community


5.2 sorting views
─────────────────

  Lemmy makes heavy use of sorting. Item (posts, comments, users,
  communities) views can be ordered according to various
  factors. `lem.el' implements this sorting in three main cycling
  commands, which work in most views:

  • `C-c C-c' - `lem-ui-cycle-listing-type' - cycle between results from
    local/subscribed/all/moderated communities. To directly set a
    listing type, call `lem-ui-choose-listing-type'. In your inbox view,
    cycle between replies, mentions, and private messages.
  • `C-c C-s' - `lem-ui-cycle-sort' - cycle between sort types (new,
    hot, active, top, old, etc.). To directly set sort, call `o', or
    `lem-ui-choose-sort'. Full sort type lists are found in
    `lem-sort-types' and `lem-comment-sort-types', the list is chosen
    according to the present view.
  • `C-c C-v' - `lem-ui-cycle-items' - toggle between posts or comments,
    and optionally overview if the view supports it (e.g. user
    views). In the inbox, cycle between inbox items.

  Additionally, for search there is:

  • `C-c C-h' - `lem-ui-cycle-search' - cycle between search result
    types for the current query (users, posts, comments, communities).


5.3 sorting via widgets
───────────────────────

  Listing, sort, item, and search types are also visible and modifiable
  by drop-down widgets that appear near the top of a given view's
  buffer. A widget appears for each option that is applicable to the
  view. Click (or hit `RET') on a widget to change it and reload the
  view.


5.4 folding and navigating comment trees
────────────────────────────────────────

  `lem.el' has a number of comment tree navigating and folding (hiding)
  commands:

  • `M-p' - `lem-ui-prev-same-level' - navigate to the previous
    same-level comment
  • `M-n' - `lem-ui-next-same-level' - navigate to the next same-level
    comment
  • `M-u' - `lem-ui-branch-top-level' - move to the comment at the top
    of branch point is in


  • `f' - `lem-ui-comment-tree-fold' - toggle folding of current
    comment, and all its children (but not its parents); this is also
    called by clicking the "+" widget on a comment
  • `F' - `lem-ui-comment-fold-toggle' - toggle folding of current
    comment only
  • `M-f' - `lem-ui-fold-current-branch' - toggle folding of current
    branch (parents and children)
  • `C-M-f' - `lem-ui-fold-all-toggle' - toggle folding of all comments
    in buffer
  • `lem-ui-fold-all-comments' - fold all comments in buffer
  • `lem-ui-unfold-all-comments' - unfold all comments in buffer

  You can also un-/fold community descriptions in community views.


6 dependencies
══════════════

  • [fedi.el], a library to make writing a library of API requests
    easier.

  • [markdown-mode], which as per the `markdown-mode' docs also requires
    that you have a markdown command installed and available in your
    path in order to render HTML output.
    • `markdown-mode' and `lem.el' will not install this for you, you
      must do it yourself. Examples include `markdown' and
      `pandoc'. Currently `lem.el' recommends `markdown', as its HTML
      output is slightly easier for `shr.el' to render, but `pandoc'
      should also be fine. Once you have one installed, customize the
      variable `markdown-command' and point it to the exectuable. See
      `markdown-mode''s installation instructions for more details:
      [jrblevin/markdown-mode#installation].

  • `hierarchy.el' and `vtable.el' which should be included in your
    emacs.


[fedi.el] <https://codeberg.org/martianh/fedi.el>

[markdown-mode] <https://github.com/jrblevin/markdown-mode>

[jrblevin/markdown-mode#installation]
<https://github.com/jrblevin/markdown-mode#installation>


7 API, other frontends
══════════════════════

  `lem-api.el' is the API requests layer. All functions make requests
  and return JSON data pased into Elisp.

  The idea is that it's then possible to write different frontends so
  users can read lemmy posts in whatever forms they like. Possibilities
  are notmuch, gnus, md4rd, or elfeed.

  Most endpoints are implemented, as are most parameters for each
  endpoint.  There is an active todo list in `lem-api.el'.

  New endpoints are trivial to implement with the `lem-def-request'
  macro.

  `lem-ui.el' is our own interface layer. It takes inspiration and code
  from `mastodon.el', as that's what I know, and a lot of work has gone
  into it.


8 NB: API instability
═════════════════════

  The Lemmy developers have clearly stated that the current API version,
  v3, is unstable and will likely be subject to breaking changes. This
  will mean `lem.el' will have to play catch-up as things change.


9 contributions
═══════════════

  Contributions are welcome. Open an issue to explain if you're working
  on something, and if you want to work on `lem-ui.el' make sure that
  what you're doing can't just be pulled in from `mastodon.el' to save
  work.

  For pull requests, please always open them against the develop branch.

  Also feel free to get in touch if you want to use `lem-api.el' to
  build another frontend.


10 Supporting `lem.el'
══════════════════════

  If you'd like to support continued development of `lem.el', I accept
  donations via paypal: [paypal.me/martianh]. If you would prefer a
  different payment method, please write to me at <mousebot@disroot.org>
  and I can provide IBAN or other bank account details.

  I don't have a tech worker's income, so even a small tip would help
  out.


[paypal.me/martianh] <https://paypal.me/martianh>


11 screenshots
══════════════

  Instance view showing jump to community:

  [file:./lem.png]

  Community view (above), and rich post compose (below) showing
  community completion:

  [file:./lem-post.png]

  Rich browse communities interface showing listing and sort dropdown
  widgets (blue):

  [file:./lem-communities.png]


[file:./lem.png] <file:lem.png>

[file:./lem-post.png] <file:./lem-post.png>

[file:./lem-communities.png] <file:./lem-communities.png>


12 commands index
═════════════════

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Binding    Command                                 Description                                                               
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
              lem                                     Open lem, a Lemmy client.                                                 
   C-M-q      lem-kill-all-buffers                    Kill all lem.el buffers.                                                  
              lem-login-set-token                     Login and set current user details.                                       
              lem-mode                                Major mode for Lemmy, the federated link-aggregator and forum.            
   n          lem-next-item                           Move to next item.                                                        
   C-c C-k    lem-post-cancel                         Kill new-post buffer/window. Does not POST content.                       
   r          lem-post-comment                        Reply to a post or comment.                                               
              lem-post-comment-mode                   Minor mode for submitting comments to lemmy.                              
              lem-post-comment-simple                 Reply to post or comment at point.                                        
   N          lem-post-compose                        Compose a new post.                                                       
              lem-post-compose-simple                 Create and submit new post, reading strings in the minibuffer.            
              lem-post-create-community               Create a new community.                                                   
              lem-post-create-community-mode          Minor mode for creating new communities on lemmy.                         
              lem-post-edit                           Edit the post at point if possible.                                       
              lem-post-edit-comment                   Edit comment at point if possible.                                        
   e          lem-post-edit-post-or-comment           Try to edit item at point.                                                
              lem-post-item-author-private-message    Send a private message to the author of item at point.                    
              lem-post-mode                           Minor mode for submitting posts to lemmy.                                 
              lem-post-private-message                Send a private message to a user.                                         
              lem-post-read-community-display-name    Read community display name (title - can be changed later).               
              lem-post-read-community-name            Read community name (identifier - cannot be changed later).               
   C-c C-t    lem-post-read-title                     Read post title.                                                          
   C-c C-u    lem-post-read-url                       Read post URL.                                                            
   C-c C-o    lem-post-select-community               Select community to post to.                                              
   C-c C-l    lem-post-set-post-language              Prompt for a language and set `fedi-post-language'.                       
   C-c C-c    lem-post-submit                         Submit the post, comment, or community to lemmy.                          
   C-c C-n    lem-post-toggle-nsfw                    Toggle `fedi-post-content-nsfw'.                                          
              lem-post-toggle-restricted-to-mods      Toggle `lem-post-community-restricted-to-mods'.                           
   p          lem-prev-item                           Move to prev item.                                                        
              lem-shr-insert-image                    Insert the image under point into the buffer.                             
              lem-ui–follow-link-at-point             Follow link at point.                                                     
              lem-ui-block-community-at-point         Block community at point.                                                 
              lem-ui-block-item-instance              Block instance of item at point.                                          
              lem-ui-block-user                       Block author of item at point.                                            
   M-u        lem-ui-branch-top-level                 Move point to the top of the branch of comment at point.                  
   C          lem-ui-browse-communities               View Lemmy communities in a sortable tabulated list.                      
              lem-ui-choose-inbox-view                Prompt for an inbox view and load it.                                     
              lem-ui-choose-listing-type              Prompt for a listing type, and use it to reload current view.             
              lem-ui-choose-search-type               Choose a search type from `lem-search-types' and repeat current query.    
   o          lem-ui-choose-sort                      Prompt for a sort type, and use it to reload the current view.            
   F          lem-ui-comment-fold-toggle              Toggle invisibility of the comment at point.                              
   f          lem-ui-comment-tree-fold                Toggle invisibility of current comment and all its children.              
              lem-ui-copy-item-url                    Copy the URL (ap_id) of the post or comment at point.                     
              lem-ui-cycle-inbox                      Cycle inbox to next item view in `lem-inbox-types'.                       
   C-c C-v    lem-ui-cycle-items                      Switch between displaying posts or comments.                              
   C-c C-c    lem-ui-cycle-listing-type               Cycle view between `lem-listing-types'.                                   
              lem-ui-cycle-saved-items                Cycle saved items view or view type ITEM.                                 
   C-c C-h    lem-ui-cycle-search                     Cycle current search.                                                     
   C-c C-s    lem-ui-cycle-sort                       Cycle view between some `lem-sort-types'.                                 
              lem-ui-delete-comment                   Delete comment at point.                                                  
              lem-ui-delete-community                 Prompt for a community moderated by the current user and delete it.       
              lem-ui-delete-community-at-point        Delete community at point.                                                
              lem-ui-delete-post                      Delete post at point.                                                     
   d          lem-ui-delete-post-or-comment           Delete post or comment at point.                                          
              lem-ui-dislike-item                     Dislike (downvote) item at point.                                         
              lem-ui-edit-comment-brief               Edit comment at point if possible, in the minibuffer.                     
              lem-ui-feature-post                     Feature (pin) a post, either to its instance or community.                
              lem-ui-fold-all-comments                Fold all comments in current buffer.                                      
   C-M-f      lem-ui-fold-all-toggle                  Toggle folding status of all comments in the buffer.                      
              lem-ui-fold-community-description       Fold community description in community view.                             
   M-f        lem-ui-fold-current-branch              Toggle folding of comment at point and all its parents and children.      
              lem-ui-fold-whole-top-level-branch      Toggle folding the branch of comment at point.                            
              lem-ui-jump-to-moderated                Prompt for a community moderated by the current user and view it.         
   S          lem-ui-jump-to-subscribed               Prompt for a subscribed community and view it.                            
              lem-ui-like-item                        Like (upvote) item at point.                                              
   l          lem-ui-like-item-toggle                 Toggle like status of item at point.                                      
              lem-ui-mark-all-read                    Mark all replies as read.                                                 
              lem-ui-mark-private-message-read        Mark the private message at point as read.                                
              lem-ui-mark-reply-comment-read          Mark the comment-reply at point as read.                                  
              lem-ui-message-user-at-point            Send private message to user at point.                                    
              lem-ui-more                             Append more items to the current view.                                    
   M-n        lem-ui-next-same-level                  Move to next same level comment.                                          
   TAB        lem-ui-next-tab-item                    Jump to next tab item.                                                    
   M-p        lem-ui-prev-same-level                  Move to previous same level comment.                                      
   <backtab>  lem-ui-prev-tab-item                    Jump to prev tab item.                                                    
              lem-ui-print-json                       Fetch the JSON of item at point and pretty print it in a new buffer.      
   g          lem-ui-reload-view                      Reload the current view.                                                  
              lem-ui-remove-comment                   Remove the comment at point.                                              
              lem-ui-remove-post                      Remove the post at point.                                                 
              lem-ui-restore-comment                  Restore deleted comment at point.                                         
              lem-ui-restore-post                     Restore deleted post at point.                                            
              lem-ui-save-item                        Save item at point.                                                       
   a          lem-ui-save-item-toggle                 Toggle saved status of item at point.                                     
   SPC        lem-ui-scroll-up-command                Call `scroll-up-command', loading more toots if necessary.                
   h          lem-ui-search                           Search for QUERY, of SEARCH-TYPE, one of the types in `lem-search-types'. 
              lem-ui-search-in-community              Search in the current community.                                          
              lem-ui-search-in-user                   Search in the user currently viewed.                                      
              lem-ui-subscribe-to-community           Subscribe to a community, using ID or prompt for a handle.                
   s          lem-ui-subscribe-to-community-at-point  Subscribe to community at point.                                          
              lem-ui-subscribe-to-item-community      Subscribe to community of item at point.                                  
              lem-ui-unblock-community                Prompt for a blocked community, and unblock it.                           
              lem-ui-unblock-instance                 Prompt for a blocked instance and unblock it.                             
              lem-ui-unblock-user                     Prompt for a blocked user, and unblock them.                              
              lem-ui-unfeature-post                   Unfeature (unpin) post at point.                                          
              lem-ui-unfold-all-comments              Unfold all comment branches in the current buffer.                        
              lem-ui-unlike-item                      Unlike item at point.                                                     
              lem-ui-unsave-item                      Unsave item at point.                                                     
              lem-ui-unsubscribe-from-community       Prompt for a subscribed community and unsubscribe from it.                
              lem-ui-url-lookup                       Perform a webfinger lookup on URL and load the result in `lem.el'.        
              lem-ui-view-comment-post                View post of comment at point, or of POST-ID.                             
              lem-ui-view-communities                 View Lemmy communities.                                                   
   B          lem-ui-view-inbox                       View user inbox, for replies, mentions, and PMs to the current user.      
   I          lem-ui-view-instance                    View posts of current user's home instance.                               
              lem-ui-view-instance-full               View full instance details.                                               
   c          lem-ui-view-item-community              View community of item at point.                                          
   u          lem-ui-view-item-user                   View user of item at point.                                               
              lem-ui-view-mentions                    View reply comments to the current user.                                  
   O          lem-ui-view-own-profile                 View profile of the current user.                                         
              lem-ui-view-post-at-point               View post at point.                                                       
              lem-ui-view-private-messages            View reply comments to the current user.                                  
              lem-ui-view-replies                     View reply comments to the current user.                                  
              lem-ui-view-replies-unread              View unread replies.                                                      
   A          lem-ui-view-saved-items                 View saved items of the current user, or of user with ID.                 
   RET        lem-ui-view-thing-at-point              View post, community or user at point.                                    
              lem-vtable-revert-command               Re-query data and regenerate the table under point.                       
              lem-vtable-sort-by-current-column       Sort the table under point by the column under point.                     
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
