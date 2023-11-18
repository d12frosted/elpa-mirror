0.0.1 Version 0.4
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌


1 About
═══════

  GNU Emacs [sourcehut] API client.

  `srht' provides bindings to the Sourcehut REST API as well as commands
  for interacting with it. It currently supports two services:
  `git.sr.ht' — git hosting and `paste.sr.ht' — ad-hoc text file
  hosting.


[sourcehut] <https://sr.ht>


2 Installation
══════════════

2.1 With Guix
─────────────

  ┌────
  │ git clone https://git.sr.ht/~akagi/srht.el srht
  │ cd srht
  │ guix package -f guix.scm
  └────


2.2 Manual
──────────

  `srht' depends on the HTTP library `plz' which is available in
  ELPA. After installing it, place files from /lisp folder in
  `load-path'.


3 Setup
═══════

  To use this client, you need to generate a personal access tokens
  ([Oauth] and [Oauth2]). Oauth token will have unrestricted access to
  all sr.ht APIs and can be used like a normal access token to
  authenticate legacy API requests.

  After creating the tokens:


[Oauth] <https://meta.sr.ht/oauth/personal-token>

[Oauth2] <https://meta.sr.ht/oauth2>

3.1 oauth token
───────────────

  ┌────
  │ (setq srht-token OAUTH-TOKEN)
  └────

  It is also possible to store the token using `auth-source.el', the
  host must be set to sr.ht.

  ┌────
  │ machine sr.ht password TOKEN
  └────


3.2 oauth2 token
────────────────

  To store the token use `auth-source.el', the host must be set to
  git.sr.ht.

  ┌────
  │ machine git.sr.ht password TOKEN
  └────
  Strongly encouraged for the user to limit the scope of access that is
  provided by an authentication token.  Currently srht-git.el requires
  at least REPOSITORIES, PROFILE scopes for git.sr.ht. When creating an
  oauth2 token, you can select scopes from the "Limit scope of access
  grant" menu.


3.3 rest
────────

  You also need to set srht-username:
  ┌────
  │ (setq srht-username USERNAME)
  └────

  If you are using a self-hosted instanse:

  ┌────
  │ (setq srht-domain '(DOMAIN ...))
  └────


4 Commands
══════════

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Function                Description                           
  ───────────────────────────────────────────────────────────────
   `srht-git-repo-update'  Update information for git repository 
   `srht-git-repo-delete'  Delete existing git repository        
   `srht-git-repo-create'  Create git repository                 
   `srht-paste-link'       Kill the link of the selected paste   
   `srht-paste-delete'     Detete paste with SHA                 
   `srht-paste-region'     Paste region or buffer to sourcehut   
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


5 Copyright assignment
══════════════════════

  This package is part of [GNU Emacs], being distributed in [GNU ELPA].
  Contributions to this project must follow GNU guidelines, which means
  that, as with other parts of Emacs, patches of more than a few lines
  must be accompanied by having assigned copyright for the contribution
  to the FSF.  Contributors who wish to do so may contact
  [emacs-devel@gnu.org] to request the assignment form.


[GNU Emacs] <https://www.gnu.org/software/emacs/>

[GNU ELPA] <https://elpa.gnu.org/>

[emacs-devel@gnu.org] <mailto:emacs-devel@gnu.org>


6 License
═════════

  GPLv3
