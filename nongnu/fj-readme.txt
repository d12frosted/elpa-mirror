


1 fj.el
═══════

  This repo contains some basic functions for interacting with a Forgejo
  instance (such as [codeberg.org]) from within Emacs.

  It doesn't interact with `forge' / `magit', which don't implement
  Gitea/Forgejo support for now (though this will likely change, see
  <https://github.com/magit/forge/discussions/771>). Nor does it attempt
  to follow their wonderful design.

  It just aims to cover a few of the bread and butter functions that
  will save you switching to the browser 80% of the time.


[codeberg.org] <https://codeberg.org>


2 getting started
═════════════════

2.1 authentication
──────────────────

  To get going, first set `fj-host', and `fj-user'.

  To authorize your account, call `fj-create-token', which will prompt
  you for your password, create an API access token, and copy it to your
  kill ring. Alternatively you can obtain an access token from your
  profile settings on your Forgejo instance (in user settings, under
  "applications").

  Once you have your token, call `fj-token' (or any interactive function
  such as `fj-list-issues'). You will be prompted for your access token,
  and when you enter it, `fj.el' will also offer to save it in your
  auth-sources file (`~/.authinfo.gpg' or similar; see variable
  `auth-sources'). Once saved, you should be good to go.

  Alternatively, you can set `fj-token-use-auth-source' to `nil' and
  simply set `fj-token' to your token (unencrypted option).

  Finally, if you were previously using the unencrypted `fj-token'
  method and want to use auth sources, simply remove the code that sets
  `fj-token' in your init config, and follow the steps above.

  If you run into any auth issues, feel free to open an issue or contact
  me.


2.2 basic views
───────────────

  Once you are authenticated, try `fj-list-own-repos' to view your
  repos, or `fj-list-issues' to view issues of the current repo, or with
  completing-read of a repo is no repo is found.

  If you are already viewing a repo and want to force the prompt to
  choose another, call `fj-list-issues' with a prefix arg (`C-u').

  You can also call `fj-list-own-issues' to view all issues across your
  repos, and `fj-watched-repos' to see your watched repos.

  To use a different instance for a given repo, set `fj-host',
  `fj-user', and `fj-token' in your `.dir-locals.el' file.


3 repositories
══════════════

  Current repository detection should work partially automatically. If
  you find you are still being asked for the repo when calling a command
  from inside a repo with a Forgejo remote, check to make sure the local
  root directory matches the name of the Forgejo repo!


4 features
══════════

  Forgejo's API is vast. Currently `fj.el' just implements a few basic
  things:


4.1 repos and repo listings
───────────────────────────

  • create new (remote) repo
  • delete a repo


  • search and list instance repos
  • list a user's repos
  • fork a repo
  • star a repo
  • watch a repo
  • copy clone URL of repo
  • view a repo's readme
  • view a repo's commit log
  • list repo's stargazers
  • list repo's watchers


4.2 rich create/edit issue/comment interface
────────────────────────────────────────────


4.3 issues/PRs as listings
──────────────────────────

  • list repo issues and PRs
  • list issues in any repo you own
  • list issues you have authored in any repo
  • cycle between issues/PRs/all
  • cycle between open/closed/all issues/PRs
  • sort issues/PRs (serverside)
  • quick jump to any issue/PR or repo in a listing with `imenu'.
  • search in repo issues/PRs


  • act on an issue/PR from the listing (edit, edit title, comment,
    close, reopen, delete, add label)


4.4 viewing issues/PRs
──────────────────────

  • view issue/PR discussion
  • act on issue/PR (as above, plus reply or delete comment)
  • jump to mentioned user, issue or commit.
  • display all issue/PR timeline items (references, commits, merges,
    close/reopen, edit, etc.)
  • display diff of any commit
  • display diff of entire PR
  • PR review discussion
  • PR review diffs
  • merge PR
  • browse URL of view or entry at point
  • add reactions to item at point
  • add labels to item.


4.5 notifications
─────────────────

  • view your notifications
  • jump to relevant item
  • toggle between viewing unread and all notifications


4.6 user/repo settings
──────────────────────

  • update repo settings transient menu
  • update user settings transient menu


  • view followers
  • view users followed


4.7 other features
──────────────────

4.7.1 create remote links from local source files
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you want to insert a link to a line in your source files, consider
  using <https://github.com/sshaw/git-link>.


4.7.2 syntax highlighting for code blocks
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you want verbatim code blocks in comments to have syntax
  highlighting, consider installing
  <https://github.com/xuchunyang/shr-tag-pre-highlight.el>. `fj-.el'
  uses `shr' for rendering, and `shr-tag-pre-highlight' adds syntax
  highlighting support to `shr'. You may also need to customize
  `shr-tag-pre-highlight-lang-modes' to ensure the languages you want
  will work.


5 dependencies
══════════════

  • `magit-post', `magit-process' (for obtaining current repo)
  • [fedi.el]
  • `markdown-mode'
  • [tp.el]


[fedi.el] <https://codeberg.org/martianh/fedi.el>

[tp.el] <https://codeberg.org/martianh/tp.el>


6 limitations
═════════════

6.1 performance
───────────────

  Unfortunately `fj.el' is pretty slow at loading issues/PRs with lots
  of comments and other timeline elements. The relevant code was
  recently re-written to be partly async, and the rendering of HTML in
  item bodies was recently overhauled, but the performance is still
  terrible. This leads me to believe it is actually to do with the
  Forgejo API (as for example, my abominable old rendering code worked
  for 100+ items with Lemmy, but couldn't do 30 items in a timely manner
  with Forgejo.)

  There is a defcustom, `fj-timeline-default-items', with a default
  value of 15, meaning we load 15 timeline elements by default. If you
  find the performance is no problem on longer items, you can increase
  this value. (The default apart from this setting would be 30.)


6.2 general design
──────────────────

  `fj.el' started out as a tiny package around my general use-case:
  working with repos I own and that have few if any collaborators and
  only one remote. Working with other repos was added later, and some
  workflows and commands still need adjusting in this regard. If you
  find `fj.el' generates a lot of friction with your workflow, feel free
  to let me know. (It's not easy hacking in the vague direction what I
  imagine other people's workflows to be.)


7 contributions
═══════════════

  Contributions are welcome, as is feedback about your needs.

  Please PR into branch `dev' (`main' is for releases), and let me know
  if you're hacking on something.

  Currently the project has just evolved organically out of my own needs
  (and my own libraries), which are likely different to yours.


8 supporting `fj.el'
════════════════════

  If you'd like to support continued development of `fj.el', I accept
  donations via paypal: [paypal.me/martianh].

  I also accept support via liberapay:



  If you would prefer a different payment method, please write to me at
  <mousebot {at} disroot.org> and I can provide IBAN or other bank
  account details.

  I don't have a tech worker's income, so even a small tip would help
  out.


[paypal.me/martianh] <https://paypal.me/martianh>


9 screenshots
═════════════

  User repos listing:

  <file:Screenshot-user.png>

  Issue view followed by repo issues listing:

  <file:Screenshot-issues.png>

  Repo search listing:

  <file:Screenshot-search.png>

  Repo settings transient:

  <file:Screenshot-transient.png>

  Syntax highlighting (optional dependency):

  <file:screenshot-syntax-highlight.png>

  Diffs (as code as as reviews):

  <file:screenshot-diff.png>


10 commands index
═════════════════

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Binding    Command                         Description                                                         
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────
              fj-add-issue-to-milestone       Add issue at point or in current view to milestone.                 
   r          fj-add-reaction                 Add reaction to issue, PR or comment at point.                      
              fj-browse-commit                Browse commit with SHA in REPO by OWNER.                            
   b          fj-browse-view                  Browse URL of view at point.                                        
              fj-commits-mode                 Major mode for viewing repo commits.                                
   C-c C-k    fj-compose-cancel               Kill new-post buffer/window. Does not POST content.                 
              fj-compose-comment-mode         Minor mode for composing comments.                                  
              fj-compose-mode                 Minor mode for composing issues.                                    
   C-c C-l    fj-compose-read-labels          Read a label in the issue compose buffer.                           
   C-c RET    fj-compose-read-milestone       Read an existing milestone in the compose buffer.                   
   C-c C-o    fj-compose-read-owner           Read a repo owner.                                                  
   C-c C-r    fj-compose-read-repo            Read a repo for composing a issue or comment.                       
   C-c C-t    fj-compose-read-title           Read an issue title.                                                
   C-c C-S-l  fj-compose-remove-labels        Remove labels from item being composed.                             
   C-c S-RET  fj-compose-remove-milestone     Remove milestone from item being composed.                          
   C-c C-c    fj-compose-send                 Submit the issue or comment to your Forgejo instance.               
   C          fj-copy-item-url                Copy URL of current item, either issue or PR.                       
   U          fj-copy-pr-url                  Copy upstream Pull Request URL with branch name.                    
   c          fj-create-issue                 Create issue in current repo or repo at point in tabulated listing. 
              fj-create-milestone             Create a milestone for REPO by OWNER.                               
              fj-create-token                 Create an access token for `fj-user' on `fj-host'.                  
   C-c C-d    fj-cycle-sort-or-relation       Call `fj-own-items-cycle-relation' or `fj-list-issues-sort'.        
   C-c C-c    fj-cycle-state                  Cycle item state listing of open, closed, and all.                  
   C-c C-s    fj-cycle-type                   Cycle item type listing of issues, pulls, and all.                  
              fj-delete-repo                  Delete repo at point, if you are its owner.                         
              fj-delete-repo-tag              Prompt for a repo tag and delete it on the server.                  
   <return>   fj-do-link-action               Do the action of the link at POS.                                   
   <mouse-2>  fj-do-link-action-mouse         Do the action of the link at point.                                 
              fj-fetch-pull-as-branch         From a PR view, fetch it as a new git branch using magit.           
              fj-fork-repo                    Fork repo entry at point.                                           
              fj-fork-to-parent               From a repo TL listing, jump to the parent repo.                    
              fj-get-pull-commits             Return the data for the commits of the current pull.                
              fj-git-link-code-range          Call `git-link'.                                                    
              fj-inspect-item-data            Browse the JSON data of item at point.                              
              fj-issue-compose                Compose a new post.                                                 
              fj-issue-get-labels             Get labels on ISSUE in REPO by OWNER.                               
              fj-issue-tl-mode                Major mode for browsing a tabulated list of issues.                 
   v          fj-issues-tl-view               View current issue from tabulated issues listing.                   
   k          fj-item-close                   Close the item at point or being viewed.                            
   c, C       fj-item-comment                 Comment on the item at point or being viewed.                       
   K          fj-item-delete                  Delete the item at point or being viewed.                           
   e          fj-item-edit                    Edit the item at point or being viewed.                             
   t          fj-item-edit-title              Edit the title of the item at point or being viewed.                
   l          fj-item-label-add               Comment on the item at point or being viewed.                       
              fj-item-label-remove            Comment on the item at point or being viewed.                       
   n          fj-item-next                    Go to next item or notification.                                    
   p          fj-item-prev                    Goto previous item or notification.                                 
   o          fj-item-reopen                  Reopen the item at point or being viewed.                           
              fj-item-view                    View item NUMBER from REPO of OWNER.                                
              fj-item-view-mode               Major mode for viewing items.                                       
   >          fj-item-view-more               Load more items to the timeline, if it has more items.              
   C-M-q      fj-kill-all-buffers             Kill all fj buffers.                                                
              fj-list-authored-issues         Return issues authored by `fj-user', in any repo.                   
              fj-list-authored-pulls          Return pulls authored by `fj-user', in any repo.                    
   I          fj-list-issues                  List issues for current REPO with default sorting.                  
              fj-list-issues-+-pulls          List issues and pulls for REPO by OWNER, filtered by STATE.         
              fj-list-issues-all              Display all ISSUES for REPO by OWNER in tabulated list view.        
              fj-list-issues-by-label         List issues in REPO by OWNER, filtering by label.                   
              fj-list-issues-by-milestone     List issues in REPO by OWNER, filtering by milestone.               
              fj-list-issues-closed           Display closed ISSUES for REPO by OWNER in tabulated list view.     
   s          fj-list-issues-search           Search current repo issues for QUERY.                               
              fj-list-issues-sort             Reload current issues listing, prompting for a sort type.           
   W          fj-list-own-issues              List issues in repos owned by `fj-user'.                            
              fj-list-own-pulls               List pulls in repos owned by `fj-user'.                             
   O          fj-list-own-repos               List repos for `fj-user'.                                           
   C-c C-x    fj-list-own-repos-read          List repos for `fj-user', prompting for an order type.              
   P          fj-list-pulls                   List pulls for REPO by OWNER, filtered by STATE.                    
              fj-list-repos                   List repos for `fj-user' extended by `fj-extra-repos'.              
              fj-list-user-repos              View repos of current entry user from tabulated repos listing.      
              fj-mark-notification-read       Mark notification at point as read.                                 
              fj-mark-notification-unread     Mark notification at point as unread.                               
              fj-mark-notifs-read             Mark all notifications read.                                        
   M          fj-merge-pull                   Merge pull request of current view or at point.                     
   .          fj-next-page                    Load the next page of the current view.                             
   <tab>      fj-next-tab-item                Jump to next tab item.                                              
              fj-notifications-mode           Major mode for viewing notifications.                               
   C-c C-s    fj-notifications-subject-cycle  Cycle notifications by `fj-notifications-subject-types'.            
   C-c C-c    fj-notifications-unread-toggle  Switch between showing all notifications, and only showing unread.  
              fj-own-items-cycle-relation     Cycle the relation for own issues view.                             
              fj-owned-issues-tl-mode         Major mode for browsing a tabulated list of issues.                 
   ,          fj-prev-page                    Load the previous page.                                             
   <backtab>  fj-prev-tab-item                Jump to prev tab item.                                              
              fj-pull-req-comment             Add comment to PULL in REPO.                                        
              fj-remove-reaction              Remove a reaction from issue, PR or comment at point.               
   L          fj-repo-commit-log              Render log of commits for REPO by OWNER.                            
   u, L       fj-repo-copy-clone-url          Add the clone_url of repo at point to the kill ring.                
              fj-repo-create                  Create a new repo.                                                  
              fj-repo-create-label            Create a new label for REPO by OWNER.                               
              fj-repo-delete-label            Delete a label for REPO by OWNER.                                   
              fj-repo-get-labels              Return labels JSON for REPO by OWNER.                               
   RET        fj-repo-list-issues             View issues of current repo from tabulated repos listing.           
   M-RET      fj-repo-list-pulls              View issues of current repo from tabulated repos listing.           
   r          fj-repo-readme                  Display readme file of current repo.                                
   s, S       fj-repo-search                  Search repos for QUERY, and display a tabulated list of results.    
              fj-repo-search-topic            Search repo topics for QUERY, and display a tabulated list.         
              fj-repo-stargazers              Render stargazers for REPO by OWNER.                                
              fj-repo-tl-mode                 Mode for displaying a tabulated list of repo search results.        
   R          fj-repo-update-settings         A transient for setting current repo settings.                      
              fj-repo-watchers                Render watchers for REPO by OWNER.                                  
   *          fj-star-repo                    Star or UNSTAR current repo from tabulated user repos listing.      
              fj-stargazers-completing        Prompt for a repo stargazer, and view their repos.                  
              fj-starred-repos                List your starred repos.                                            
   B          fj-tl-browse-entry              Browse URL of tabulated list entry at point.                        
              fj-token                        Fetch user access token from auth source, or try to add one.        
              fj-unstar-repo                  Unstar current repo from tabulated user repos listing.              
              fj-unwatch-repo                 Watch repo at point or in current view.                             
              fj-update-repo                  Update current repo settings.                                       
              fj-update-topics                Update repo topics on the server.                                   
              fj-update-user-settings         Update current user settings on the server.                         
              fj-user-followers               View users who follow USER or `fj-user'.                            
              fj-user-following               View users that USER or `fj-user' is following.                     
              fj-user-repo-tl-mode            Mode for displaying a tabulated list of user repos.                 
              fj-user-repos                   View a tabulated list of respos for USER.                           
   U          fj-user-update-settings         A transient for setting current user settings.                      
              fj-users-mode                   Major mode for viewing users.                                       
              fj-view-commit-diff             View a diff of a commit at point.                                   
   N          fj-view-notifications           View notifications for `fj-user'.                                   
              fj-view-notifications-all       View all notifications for `fj-user'.                               
   D          fj-view-pull-diff               View a diff of the entire current PR.                               
   g          fj-view-reload                  Try to reload the current view based on its major-mode.             
              fj-watch-repo                   Watch repo at point or in current view.                             
              fj-watched-repos                List your watched repos.                                            
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


11 variables index
══════════════════

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Custom variable               Description                                                   
  ─────────────────────────────────────────────────────────────────────────────────────────────
   fj-compose-comment-mode-hook  Hook run after entering or leaving `fj-compose-comment-mode'. 
   fj-compose-mode-hook          Hook run after entering or leaving `fj-compose-mode'.         
   fj-issues-sort-default        Default sort parameter for repo issues listing.               
   fj-own-repos-default-order    The default order parameter for `fj-list-own-repos'.          
   fj-timeline-default-items     The default number of timeline items to load.                 
   fj-token-use-auth-source      Whether to use an auth-source file.                           
   fj-use-emojify                Whether to enable `emojify-mode' in item views.               
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
