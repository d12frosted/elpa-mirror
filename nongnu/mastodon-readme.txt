


1 README
════════

  `mastodon.el' is an Emacs client for the AcitivityPub social networks
  that implement the Mastodon API. For info see [joinmastodon.org].


[joinmastodon.org] <https://joinmastodon.org/>

1.1 Installation
────────────────

  You can install `mastodon.el' from ELPA, MELPA, or directly from this
  repo. It is also available as a GUIX package.


1.1.1 ELPA
╌╌╌╌╌╌╌╌╌╌

  You should be able to directly install with:

  `M-x package-refresh-contents RET'

  `M-x package-install RET mastodon RET'


1.1.2 MELPA
╌╌╌╌╌╌╌╌╌╌╌

  Add `MELPA' to your archives:

  ┌────
  │ (require 'package)
  │ (add-to-list 'package-archives
  │ 	     '("melpa" . "http://melpa.org/packages/") t)
  └────

  Update and install:

  `M-x package-refresh-contents RET'

  `M-x package-install RET mastodon RET'


1.1.3 Repo
╌╌╌╌╌╌╌╌╌╌

  Clone this repository and add the lisp directory to your load path.
  Then, require it and go.

  ┌────
  │ (add-to-list 'load-path "/path/to/mastodon.el/lisp")
  │ (require 'mastodon)
  └────

  Or, with `use-package':

  ┌────
  │ (use-package mastodon
  │   :ensure t)
  └────

  The minimum Emacs version is now 27.1. But if you are running an older
  version it shouldn't be very hard to get it working.


1.1.4 Emoji
╌╌╌╌╌╌╌╌╌╌╌

  `mastodon-mode' will enable [Emojify] if it is loaded in your Emacs
  environment, so there's no need to write your own hook
  anymore. `emojify-mode' is not required.


[Emojify] <https://github.com/iqbalansari/emacs-emojify>


1.1.5 Discover
╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `mastodon-mode' can provide a context menu for its keybindings if
  [Discover] is installed. It is not required.

  if you have Discover, add the following to your Emacs init
  configuration:

  ┌────
  │ (require 'mastodon-discover)
  │ (with-eval-after-load 'mastodon (mastodon-discover))
  └────

  Or, with `use-package':

  ┌────
  │ (use-package mastodon
  │   :ensure t
  │   :config
  │   (mastodon-discover))
  └────


[Discover] <https://github.com/mickeynp/discover.el>


1.2 Usage
─────────

1.2.1 Logging in to your instance
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You need to set 2 variables in your init file to get started:

  1. `mastodon-instance-url'
  2. `mastodon-active-user'

  (see their doc strings for details). For example If you want to post
  toots as "example_user@social.instance.org", then put this in your
  init file:

  ┌────
  │ (setq mastodon-instance-url "https://social.instance.org"
  │       mastodon-active-user "example_user")
  └────

  Then *restart* Emacs and run `M-x mastodon'. Make sure you are
  connected to internet before you do this. If you have multiple
  mastodon accounts you can activate one at a time by changing those two
  variables and restarting Emacs.

  If you were using mastodon.el before 2FA was implemented and the above
  steps do not work, delete the old file specified by
  `mastodon-client--token-file' and restart Emacs and follow the steps
  again.


1.2.2 Timelines
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `M-x mastodon'

  Opens a `*mastodon-home*' buffer in the major mode and displays
  toots. If your credentials are not yet saved, you will be prompted for
  email and password.  The app registration process will take place if
  your `mastodon-token-file' does not contain `:client_id' and
  `:client_secret'.


◊ 1.2.2.1 Keybindings

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Key                     Action                                                                          
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────
                           *Help*                                                                          
   `?'                     Show discover menu of all bindings, if `discover' is available                  
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────
                           *Timeline actions*                                                              
   `n'                     Go to next item (toot, notification, user)                                      
   `p'                     Go to previous item (toot, notification, user)                                  
   `M-n=/=<tab>'           Go to the next interesting thing that has an action                             
   `M-p=/=<S-tab>'         Go to the previous interesting thing that has an action                         
   `F'                     Open federated timeline (1 prefix arg: hide-replies, 2 prefix args: media only) 
   `H'                     Open home timeline  (1 prefix arg: hide-replies)                                
   `L'                     Open local timeline (1 prefix arg: hide-replies, 2 prefix args: media only)     
   `N'                     Open notifications timeline                                                     
   `@'                     Open mentions-only notifications timeline                                       
   `u'                     Update current timeline                                                         
   `T'                     Open thread for toot at point                                                   
   `#'                     Prompt for tag and open its timeline                                            
   `A'                     Open author profile of toot at point                                            
   `P'                     Open profile of user attached to toot at point                                  
   `O'                     View own profile                                                                
   `U'                     update your profile bio note                                                    
   `;'                     view instance description for toot at point                                     
   `:'                     view followed tags and load a tag timeline                                      
   `C-:'                   view timeline of all followed tags                                              
   `,'                     view favouriters of toot at point                                               
   `.'                     view boosters of toot at point                                                  
   `/'                     switch between mastodon buffers                                                 
   `Z'                     report user/toot at point to instances moderators                               
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────
                           *Other views*                                                                   
   `s'                     search (posts, users, tags) (NB: only posts you have interacted with)           
   `I', `c', `d'           view, create, and delete filters                                                
   `R', `a', `j'           view/accept/reject follow requests                                              
   `G'                     view follow suggestions                                                         
   `V'                     view your favourited toots                                                      
   `K'                     view bookmarked toots                                                           
   `X'                     view/edit/create/delete lists                                                   
   `S'                     view your scheduled toots                                                       
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────
                           *Toot actions*                                                                  
   `t'                     Compose a new toot                                                              
   `c'                     Toggle content warning content                                                  
   `b'                     Boost toot under `point'                                                        
   `f'                     Favourite toot under `point'                                                    
   `k'                     toggle bookmark of toot at point                                                
   `r'                     Reply to toot under `point'                                                     
   `v'                     Vote on poll at point                                                           
   `C'                     copy url of toot at point                                                       
   `C-RET'                 play video/gif at point (requires `mpv')                                        
   `e'                     edit your toot at point                                                         
   `E'                     view edits of toot at point                                                     
   `i'                     (un)pin your toot at point                                                      
   `d'                     delete your toot at point, and reload current timeline                          
   `D'                     delete and redraft toot at point, preserving reply/CW/visibility                
   (`S-C-') `W', `M', `B'  (un)follow, (un)mute, (un)block author of toot at point                         
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────
                           *Profile view*                                                                  
   `C-c C-c'               cycle between statuses, statuses without boosts, followers, and following       
                           `mastodon-profile--account-account-to-list' (see lists view)                    
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────
                           *Notifications view*                                                            
   `a', `j'                accept/reject follow request                                                    
   `C-k'                   clear notification at point                                                     
                           see `mastodon-notifications--get-*' functions for filtered views                
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────
                           *Quitting*                                                                      
   `q'                     Quit mastodon buffer, leave window open                                         
   `Q'                     Quit mastodon buffer and kill window                                            
   `C-M-q'                 Quit and kill all mastodon buffers                                              
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


◊ 1.2.2.2 Toot byline legend

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Marker             Meaning                
  ───────────────────────────────────────────
   `(🔁)' (or `(B)')  I boosted this toot    
   `(⭐)' (or `(F)')  I favourited this toot 
   `(🔖)' (or (`K'))  I bookmarked this toot 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1.2.3 Composing toots
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `M-x mastodon-toot' (or `t' from a mastodon.el buffer) opens a new
  buffer/window in `text-mode' and `mastodon-toot' minor mode. Enter the
  contents of your toot here. `C-c C-c' sends the toot. `C-c C-k'
  cancels. Both actions kill the buffer and window. Further keybindings
  are displayed in the buffer, and in the following subsection.

  Replies preserve visibility status/content warnings, and include
  boosters by default.

  Server's max toot length, and attachment previews, are shown.

  You can download and use your instance's custom emoji
  (`mastodon-toot--download-custom-emoji',
  `mastodon-toot--enable-custom-emoji').

  The compose buffer uses `text-mode' so any configuration you have for
  that mode will be enabled. If any of your existing config conflicts
  with `mastodon-toot', you can disable it in the
  `mastodon-toot-mode-hook'. For example, the default value of that hook
  is as follows:

  ┌────
  │ (add-hook 'mastodon-toot-mode-hook
  │ 	  (lambda ()
  │ 	      (auto-fill-mode -1)))
  └────


◊ 1.2.3.1 Keybindings

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Key        Action                             
  ───────────────────────────────────────────────
   `C-c C-c'  Send toot                          
   `C-c C-k'  Cancel toot                        
   `C-c C-w'  Add content warning                
   `C-c C-v'  Change toot visibility             
   `C-c C-n'  Add sensitive media/nsfw flag      
   `C-c C-a'  Upload attachment(s)               
   `C-c !'    Remove all attachments             
   `C-c C-e'  Add emoji (if `emojify' installed) 
   `C-c C-p'  Create a poll                      
   `C-c C-l'  Set toot language                  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


◊ 1.2.3.2 Autocompletion of mentions and tags

  Autocompletion of mentions and tags is provided by
  `completion-at-point-functions' (capf) backends.
  `mastodon-toot--enable-completion' is enabled by default. If you want
  to enable `company-mode' in the toot compose buffer, set
  `mastodon-toot--use-company-for-completion' to `t'. (`mastodon.el'
  used to run its own native company backends, but these have been
  removed in favour of capfs.)

  If you don’t run `company' and want immediate, keyless completion,
  you’ll need to have another completion engine running that handles
  capfs. A common combination is `consult' and `corfu'.


◊ 1.2.3.3 Draft toots

  • Compose buffer text is saved as you type, kept in
    `mastodon-toot-current-toot-text'.
  • `mastodon-toot--save-draft': save the current toot as a draft.
  • `mastodon-toot--open-draft-toot': Open a compose buffer and insert
    one of your draft toots.
  • `mastodon-toot--delete-draft-toot': Delete a draft toot.
  • `mastodon-toot--delete-all-drafts': Delete all your drafts.


1.2.4 Other commands and account settings:
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  In addition to `mastodon', the following three functions are
  autoloaded and should work without first loading `mastodon.el':
  • `mastodon-toot': Compose new toot
  • `mastodon-notifications-get': View all notifications
  • `mastodon-url-lookup': Attempt to load a URL in `mastodon.el'. URL
    may be at point or provided in the minibuffer.


  • `mastodon-tl--view-instance-description': View information about the
    instance that the author of the toot at point is on.
  • `mastodon-tl--view-own-instance': View information about your own
    instance.
  • `mastodon-search--trending-tags': View a list of trending hashtags
    on your instance.
  • `mastodon-search--trending-statuses': View a list of trending
    statuses on your instance.


  • `mastodon-tl--add-toot-account-at-point-to-list': Add the account of
    the toot at point to a list.


  • `mastodon-tl--dm-user': Send a direct message to one of the users at
    point.


  • `mastodon-profile--add-private-note-to-account': Add a private note
    to another user’s account.
  • `mastodon-profile--view-account-private-note': View a private note
    on a user’s account.


  • `mastodon-profile--show-familiar-followers': Show a list of
    “familiar followers” for a given account. Familiar followers are
    accounts that you follow, and that follow the account.


  • `mastodon-tl--follow-tag': Follow a tag (works like following a
    user)
  • `mastodon-tl--unfollow-tag': Unfollow a tag
  • `mastodon-tl--list-followed-tags': View a list of tags you're
    following.
  • `mastodon-tl--followed-tags-timeline': View a timeline of all your
    followed tags.
  • `mastodon-tl--some-followed-tags-timleine': View a timeline of
    multiple tags, from your followed tags or any other.


  • `mastodon-switch-to-buffer': switch between mastodon buffers.


  • `mastodon-profile--update-display-name': Update the display name for
    your account.
  • `mastodon-profile--update-user-profile-note': Update your bio note.
  • `mastodon-profile--update-meta-fields': Update your metadata fields.
  • `mastodon-profile--set-default-toot-visibility': Set the default
    visibility for your toots.
  • `mastodon-profile--account-locked-toggle': Toggle the locked status
    of your account. Locked accounts have to manually approve follow
    requests.
  • `mastodon-profile--account-discoverable-toggle': Toggle the
    discoverable status of your account. Non-discoverable accounts are
    not listed in the profile directory.
  • `mastodon-profile--account-bot-toggle': Toggle whether your account
    is flagged as a bot.
  • `mastodon-profile--account-sensitive-toggle': Toggle whether your
    posts are marked as sensitive (nsfw) by default.


1.2.5 Customization
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  See `M-x customize-group RET mastodon' to view all customize options.

  • Timeline options:
    • Use proportional fonts
    • Default number of posts displayed
    • Timestamp format
    • Relative timestamps
    • Display user avatars
    • Avatar image height
    • Enable image caching
    • Hide replies in timelines
    • Show toot stats in byline

  • Compose options:
    • Completion style for mentions and tags
    • Enable custom emoji
    • Display toot being replied to
    • Set default reply visibility


1.2.6 Commands and variables index
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  An index of all user-facing commands and custom variables is available
  here: [mastodon-index.org].


[mastodon-index.org] <file:mastodon-index.org>


1.2.7 Alternative timeline layout
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The incomparable Nicholas Rougier has written an alternative timeline
  layout for `mastodon.el'.

  The repo is at [mastodon-alt].


[mastodon-alt] <https://github.com/rougier/mastodon-alt>


1.2.8 Live-updating timelines: `mastodon-async-mode'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  (code taken from [mastodon-future].)

  Works for federated, local, and home timelines and for
  notifications. It's a little touchy, one thing to avoid is trying to
  load a timeline more than once at a time. It can go off the rails a
  bit, but it's still pretty cool. The current maintainer of
  `mastodon.el' is unable to debug or improve this feature.

  To enable, it, add `(require 'mastodon-async)' to your `init.el'. Then
  you can view a timeline with one of the commands that begin with
  `mastodon-async--stream-'.


[mastodon-future] <https://github.com/alexjgriffith/mastodon-future.el>


1.2.9 Translating toots
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can translate toots with `mastodon-toot--translate-toot-text' (`a'
  in a timeline). At the moment this requires [lingva.el], a little
  interface I wrote to [lingva.ml], to be installed to work.

  You could easily modify the simple function to use your Emacs
  translator of choice (`libretrans.el' , `google-translate', `babel',
  `go-translate', etc.), you just need to fetch the toot's content with
  `(mastodon-tl--content toot)' and pass it to your translator function
  as its text argument. Here's what `mastodon-toot--translate-toot-text'
  looks like:

  ┌────
  │ (defun mastodon-toot--translate-toot-text ()
  │   "Translate text of toot at point.
  │   Uses `lingva.el'."
  │     (interactive)
  │     (let* ((toot (mastodon-tl--property 'toot-json)))
  │       (if toot
  │ 	  (lingva-translate nil (mastodon-tl--content toot))
  │ 	(message "No toot to translate?"))))
  └────


[lingva.el] <https://codeberg.org/martianh/lingva.el>

[lingva.ml] <https://lingva.ml>


1.2.10 Bookmarks and `mastodon.el'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `mastodon.el' doesn’t currently implement its own bookmark record and
  handler, which means that emacs bookmarks will not work as is. Until
  we implement them, you can get bookmarks going immediately by using
  [bookmark+.el].


[bookmark+.el]
<https://github.com/emacsmirror/emacswiki.org/blob/master/bookmark%2b.el>


1.3 Dependencies
────────────────

  Hard dependencies (should all install with `mastodon.el'):
  • `request' (for uploading attachments), [emacs-request]
  • `persist' for storing some settings across sessions

  Optional dependencies (install yourself, `mastodon.el' can use them):
  • `emojify' for inserting and viewing emojis
  • `mpv' and `mpv.el' for viewing videos and gifs
  • `lingva.el' for translating toots


[emacs-request] <https://github.com/tkf/emacs-request>


1.4 Network compatibility
─────────────────────────

  `mastodon.el' should work with ActivityPub servers that implement the
  Mastodon API.

  Apart from Mastodon itself, it is currently known to work with:
  • Pleroma ([pleroma.social])
  • Akkoma ([akkoma.social])
  • Gotosocial ([gotosocial.org])

  It does not support the non-Mastodon API servers Misskey
  ([misskey.io]) and Firefish ([joinfirefish.org], formerly Calkey), but
  it should fully support displaying and interacting with posts and
  users on those platforms.

  If you attempt to use `mastodon.el' with a server and run into
  problems, feel free to open an issue.


[pleroma.social] <https://pleroma.social/>

[akkoma.social] <https://akkoma.social/>

[gotosocial.org] <https://gotosocial.org/>

[misskey.io] <https://misskey.io/>

[joinfirefish.org] <https://joinfirefish.org/>


1.5 Contributing
────────────────

  PRs, issues, feature requests, and general feedback are very welcome!


1.5.1 Bug reports
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  1. `mastodon.el' has bugs, as well as lots of room for improvement.
  2. I receive very little feedback, so if I don't run into the bug it
     often doesn't get fixed.
  3. If you run into something that seems broken, first try running
     `mastodon.el' in emacs with no init file (i.e. `emacs -q'
     (instructions and code for doing this are [here]) to see if it also
     happens independently of your own config (it probably does).
  4. Enable debug on error (`toggle-debug-on-error'), make the bug
     happen again, and copy the backtrace that appears.
  5. Open an issue here and explain what is going on. Provide your emacs
     version and what kind of server your account is on.


[here] <https://codeberg.org/martianh/mastodon.el/issues/300>


1.5.2 Fixes and features
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  1. Create an [issue] detailing what you'd like to do.
  2. Fork the repository and create a branch off of `develop'.
  3. Run the tests and ensure that your code doesn't break any of them.
  4. Create a pull request referencing the issue created in step 1.


[issue] <https://codeberg.org/martianh/mastodon.el/issues>


1.5.3 Coding style
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • This library uses an unconvential double dash (`--') between file
    namespaces and function names, which contradicts normal Elisp
    style. This needs to be respected until the whole library is
    changed.
  • Use `aggressive-indent-mode' or similar to keep your code indented.
  • Single spaces end sentences in docstrings.
  • There's no need for a blank line after the first docstring line (one
    is added automatically when documentation is displayed).


1.6 Supporting `mastodon.el'
────────────────────────────

  If you'd like to support continued development of `mastodon.el', I
  accept donations via paypal: [paypal.me/martianh]. If you would prefer
  a different payment method, please write to me at <martianhiatus [at]
  riseup [dot] net> and I can provide IBAN or other bank account
  details.

  I don't have a tech worker's income, so even a small tip would help
  out.


[paypal.me/martianh] <https://paypal.me/martianh>


1.7 Contributors
────────────────

  `mastodon.el' is the work of a number of people.

  Some significant contributors are:

  • <https://github.com/jdenen> [original author]
  • <http://atomized.org>
  • <https://alexjgriffith.itch.io>
  • <https://github.com/hdurer>
  • <https://codeberg.org/Red_Starfish>
