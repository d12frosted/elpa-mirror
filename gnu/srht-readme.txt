0.0.1 Version 0.1.0
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌


1 About
═══════

  GNU Emacs [sourcehut] API client.


[sourcehut] <https://sr.ht>


2 Installation
══════════════

2.1 With Guix
─────────────

  ┌────
  │ git clone https://git.sr.ht/~akagi/srht.el srht
  │ cd srth
  │ guix package -f guix.scm
  └────


2.2 Manual
──────────

  `srht' depends on the HTTP library `plz' which is available in
  ELPA. After installing it, place files from /lisp folder in
  `load-path'.


3 Setup
═══════

  To use this client, you need to [generate] a personal access
  token. This token will have unrestricted access to all sr.ht APIs and
  can be used like a normal access token to authenticate API requests.

  After creating the token:

  ┌────
  │ (setq srht-token TOKEN)
  └────

  It is also possible to store the token using `auth-source.el', the
  host must be set to sr.ht.

  ┌────
  │ machine sr.ht password TOKEN
  └────

  You also need to set srht-username:

  ┌────
  │ (setq srht-username USERNAME)
  └────


[generate] <https://meta.sr.ht/oauth/personal-token>


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


5 License
═════════

  GPLv3
