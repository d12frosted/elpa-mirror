[file:https://melpa.org/packages/age-badge.svg]


[file:https://melpa.org/packages/age-badge.svg]
<https://melpa.org/#/age>


1 age.el: age encryption support for Emacs
══════════════════════════════════════════

  age.el provides transparent [Age] file encryption and decryption in
  Emacs. It is based on the Emacs [EasyPG] code and offers similar Emacs
  file handling for [Age encrypted files].

  Using age.el you can, for example, maintain `.org.age' encrypted Org
  files, provide Age encrypted authentication information out of
  `.authinfo.age', and open/edit/save Age encrypted files via TRAMP.

  NOTE: a full featured [passage] Emacs package that functions with
  age.el is available [here].


[Age] <https://github.com/FiloSottile/age>

[EasyPG] <http://epg.osdn.jp/>

[Age encrypted files] <https://github.com/C2SP/C2SP/blob/main/age.md>

[passage] <https://github.com/FiloSottile/passage>

[here] <https://github.com/anticomputer/passage.el>


2 Usage
═══════

  Age is available on [melpa] and you can install it from there:

  ┌────
  │ (use-package age
  │   :ensure t
  │   :demand t
  │   :config
  │   (age-file-enable))
  └────

  Alternatively, put `age.el' in your `load-path' and:

  ┌────
  │ (require 'age)
  │ (age-file-enable)
  └────

  You can now open, edit, and save Age encryted files from Emacs as long
  as they end with the `.age' file extension. You can also `find-file'
  new Age files and they will be encrypted to the
  `age-default-recipient' on first save.

  Identities (private keys) and recipients (public keys) are maintained
  via the customizable `age-default-identity' and
  `age-default-recipient' variables. By default they are set to
  `~/.ssh/id_rsa' and `~/.ssh/id_rsa.pub' respectively.

  age.el tries to remain composable with the core philosophy of age
  itself and as such does not try to provide a kitchen sink worth of
  features.


[melpa] <https://melpa.org/#/age>


3 Example configuration
═══════════════════════

  You can find my current configuration for age.el below. I am using
  [age-yubikey-plugin] to supply an age identity off of a yubikey PIV
  slot. The slot is configured to require a touch (with a 15 second
  cache) for every age client query against the identity stored in that
  slot.

  This means that every age.el decrypt requires a physical touch for
  confirmation. The cache makes it such that e.g. decrypting a series of
  age encrypted org files in sequence only requires a single touch
  confirmation.

  This limits the amount of actively accessible encrypted data inside
  Emacs to only the things I physically confirm, and only for 15 second
  windows, but without having to type a passphrase at any point. This
  excludes any open buffers that have decrypted data in memory of
  course.

  The key scheme I employ encrypts against the public keys of two main
  identities. My aforementioned yubikey identity as well as a disaster
  recovery identity, who's private key is passphrase encrypted and kept
  in cold storage.

  You'll note that I've set `age-default-identity' and
  `age-default-recipient' to be lists. These two variables can be file
  paths, key strings, or lists that contain a mix of both. This allows
  you to easily encrypt to a series of identities in whatever way you
  choose to store and manage them.

  Note that I'm using [rage] as opposed to [age] as my age client. This
  is due the aforementioned lack of pinentry support in the reference
  age implemention, which rage does support.

  ┌────
  │ (use-package age
  │   :quelpa (age :fetcher github :repo "anticomputer/age.el")
  │   :ensure t
  │   :demand t
  │   :custom
  │   ;; you should customize these and not just setq them
  │   ;; while it won't break anything, age.el checks for
  │   ;; variable customizations to supersede auto configs
  │   ;; this only becomes an issue if you e.g. have both
  │   ;; rage and age installed on a system and want to
  │   ;; ensure that age-program is actually what is used
  │   ;; as opposed to the first found compatible version
  │   ;; of a supported Age client
  │   (age-program "rage")
  │   (age-default-identity "~/.ssh/age_yubikey")
  │   (age-default-recipient
  │    '("~/.ssh/age_yubikey.pub"
  │      "~/.ssh/age_recovery.pub"))
  │   :config
  │   (age-file-enable))
  └────

  I use the above configuration in combination with a version of
  `org-roam' that has the following patches applied:

  <https://patch-diff.githubusercontent.com/raw/org-roam/org-roam/pull/2302.patch>

  This patch enables `.org.age' discoverability in `org-roam' and beyond
  that everything just works the same as you're used to with `.org.gpg'
  files. This patch was merged into org-roam `main' on Dec 31, 2022, so
  any org-roam release post that date should provide you with age
  support out of the box.


[age-yubikey-plugin] <https://github.com/str4d/age-plugin-yubikey>

[rage] <https://github.com/str4d/rage>

[age] <https://github.com/FiloSottile/age>


4 Other fun examples
════════════════════

4.1 Encrypting a file to a given GitHub username's ssh keys
───────────────────────────────────────────────────────────

  ┌────
  │ (defun my/age-github-keys-for (username)
  │   "Turn GitHub USERNAME into a list of ssh public keys."
  │   (let* ((res (shell-command-to-string
  │                (format "curl -s https://api.github.com/users/%s/keys"
  │                        (shell-quote-argument username))))
  │          (json (json-parse-string res :object-type 'alist)))
  │     (cl-assert (arrayp json))
  │     (cl-loop for alist across json
  │              for key = (cdr (assoc 'key alist))
  │              when (and (stringp key)
  │                        (string-match-p "^\\(ssh-rsa\\|ssh-ed25519\\) AAAA" key))
  │              collect key)))
  │ 
  │ (defun my/age-save-with-github-recipient (username)
  │   "Encrypt an age file to the public keys of GitHub USERNAME."
  │   (interactive "MGitHub username: ")
  │   (cl-letf (((symbol-value 'age-default-recipient)
  │              (append (if (listp age-default-recipient)
  │                          age-default-recipient
  │                        (list age-default-recipient))
  │                      (my/age-github-keys-for username))))
  │     (save-buffer)))
  └────


4.2 Visual indicators of encryption and decryption in progress
──────────────────────────────────────────────────────────────

  Since I use a yubikey touch controlled age identity I find it useful
  to have a visual indication of when age.el is performing operations
  that might require me to touch the yubikey. The following advice adds
  visual notifications to `age-start-decrypt' and `age-start-encrypt'.

  I'm also using this as a way to get a good feel for just how much
  Emacs is interacting with my encrypted data.

  ┌────
  │ (require 'notifications)
  │ 
  │ (defun my/age-notify (msg &optional simple)
  │   (cond (simple
  │          (message (format "%s" msg)))
  │         ((eq system-type 'gnu/linux)
  │          (notifications-notify
  │           :title "age.el"
  │           :body (format "%s" msg)
  │           :urgency 'low
  │           :timeout 800))
  │         ((eq system-type 'darwin)
  │          (do-applescript
  │           (format "display notification \"%s\" with title \"age.el\"" msg)))
  │         (t
  │          (message (format "%s" msg)))))
  │ 
  │ (defun my/age-notify-decrypt (&rest args)
  │   (cl-destructuring-bind (context cipher) args
  │     (my/age-notify (format "Decrypting %s" (age-data-file cipher)) t)))
  │ 
  │ (defun my/age-notify-encrypt (&rest args)
  │   (cl-destructuring-bind (context plain recipients) args
  │     (my/age-notify (format "Encrypting %s" (age-data-file plain)) t)))
  │ 
  │ (defun my/age-toggle-decrypt-notifications ()
  │   (interactive)
  │   (cond ((advice-member-p #'my/age-notify-decrypt #'age-start-decrypt)
  │          (advice-remove #'age-start-decrypt #'my/age-notify-decrypt)
  │          (message "Disabled age decrypt notifications."))
  │         (t
  │          (advice-add #'age-start-decrypt :before #'my/age-notify-decrypt)
  │          (message "Enabled age decrypt notifications."))))
  │ 
  │ (defun my/age-toggle-encrypt-notifications ()
  │   (interactive)
  │   (cond ((advice-member-p #'my/age-notify-encrypt #'age-start-encrypt)
  │          (advice-remove #'age-start-encrypt #'my/age-notify-encrypt)
  │          (message "Disabled age encrypt notifications."))
  │         (t
  │          (advice-add #'age-start-encrypt :before #'my/age-notify-encrypt)
  │          (message "Enabled age encrypt notifications."))))
  │ 
  │ ;; we only care about decrypt notifications really
  │ (my/age-toggle-decrypt-notifications)
  │ (my/age-toggle-encrypt-notifications)
  └────


5 Known issues
══════════════

5.1 Lack of pinentry support in age reference implementation
────────────────────────────────────────────────────────────

  The [age reference implementation] does not support pinentry by
  design. Users are encouraged to use identity (private) keys and
  recipient (public) keys, and manage those secrets accordingly.


[age reference implementation] <https://github.com/FiloSottile/age>

5.1.1 Workaround: pinentry support through rage
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can work around this by using [rage] instead of age, which is a
  Rust based implementation of the [Age spec] which does support
  pinentry by default. age.el will work with rage as well. An example
  rage config may look like:

  ┌────
  │ (use-package age
  │   :ensure t
  │   :demand t
  │   :custom
  │   (age-program "rage")
  │   :config
  │   (age-file-enable))
  └────

  You will now be able to use passphrase protected Age identities and
  files.


[rage] <https://github.com/str4d/rage>

[Age spec] <https://github.com/C2SP/C2SP/blob/main/age.md>

◊ 5.1.1.1 Rage pinentry troubleshooting

  If you find that you are having trouble with rage's ability to decrypt
  pass phrase encrypted age identities or files, please ensure that the
  `pinentry' program in your PATH is actually the one you intend to use
  and that it is compatible with your Emacs workflow. If you have
  multiple pinentry programs available and want to ensure rage uses a
  particular one, you can set its `PINENTRY_PROGRAM' environment
  variable accordingly.

  For example, if you would like to ensure rage is using
  `pinentry-something' you can set `PINENTRY_PROGRAM' in your age.el
  configuration:

  ┌────
  │ (use-package age
  │   :ensure t
  │   :demand t
  │   :custom
  │   (age-program "rage")
  │   :config
  │   (setenv "PINENTRY_PROGRAM" "pinentry-something")
  │   (age-file-enable))
  └────

  Likewise, it is wise to check that whichever pinentry solution you
  decide on is actually available to and compatible with your Emacs
  environment.


5.1.2 Tip: configuring pinentry-emacs for minibuffer passphrase entry
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you'd like to keep your pinentry support inside of emacs entirely
  for whatever reason, you can use `pinentry-emacs' for a pinentry
  program that will prompt you inside of Emacs. Most distributions have
  a package for `pinentry-emacs' available, which provides a GNU
  pinentry executable with the Emacs flavor enabled.

  If your distribution does not provide an Emacs enabled build of GNU
  pinentry, you can find the GNU pinentry collection, which contains the
  Emacs flavor of pinentry as well [here].

  Warning: don't confuse GNU pinentry with this [pinentry-emacs
  shellscript] they are not the same thing.

  Note: if you're saying `file not found' errors when trying to use
  `pinentry' you'll also want to ensure the Emacs pinentry socket
  actually exists and is running by using the GNU ELPA [pinentry]
  package:

  ┌────
  │ (use-package pinentry
  │   :config
  │   (pinentry-start))
  └────

  A complete `pinentry-emacs` enabled configuration may then look
  something like below:

  ┌────
  │ (use-package pinentry
  │   :config
  │   (pinentry-start))
  │ 
  │ (use-package age
  │   :ensure t
  │   :demand t
  │   :custom
  │   (age-program "rage")
  │   :config
  │   (setenv "PINENTRY_PROGRAM" "pinentry-emacs")
  │   (age-file-enable))
  └────

  With both of those requirements satisfied, rage will use
  `pinentry-emacs' to prompt you for passphrases in the minibuffer.

  Note: If you set pinentry-emacs as your default `pinentry' executable
  in your PATH, this will attempt to use Emacs as your pinentry for all
  commandline use of the rage client as well.  You may prefer to keep
  e.g. `pinentry-ncurses' for this use case, so adjust your cli
  environment accordingly.


[here] <https://git.gnupg.org/cgi-bin/gitweb.cgi?p=pinentry.git>

[pinentry-emacs shellscript] <https://github.com/ecraven/pinentry-emacs>

[pinentry] <https://elpa.gnu.org/packages/pinentry.html>


5.2 Direct use of passphrase encrypted age files
────────────────────────────────────────────────

  This again requires you to use rage, or another age-spec compliant
  client that supports pinentry and follows the rage or age argument and
  error reporting conventions.

  By default, age.el will be able to open and save passphrase encrypted
  age files. It will detect the scrypt stanza in the age file and set
  the age.el handling context for passphrase mode accordingly.

  You can also programmatically force age.el into passphrase mode by
  binding `age-default-identity' and `age-default-recipient' to nil
  temporarily, e.g.:

  ┌────
  │ (defun my/age-open-with-passphrase (file)
  │   (interactive "fPassphrase encrypted age file: ")
  │   (cl-letf (((symbol-value 'age-default-identity) nil)
  │             ((symbol-value 'age-default-recipient) nil))
  │     (find-file file)))
  │ 
  │ (defun my/age-save-with-passphrase ()
  │   (interactive)
  │   (cl-letf (((symbol-value 'age-default-identity) nil)
  │             ((symbol-value 'age-default-recipient) nil))
  │     (save-buffer)))
  └────


5.3 org-roam support for age encrypted org files
────────────────────────────────────────────────

  Org-roam has merged <https://github.com/org-roam/org-roam/pull/2302>
  which provides `.org.age' discoverability support for org-roam, so if
  you update to the latest release from e.g. MELPA or the main branch,
  org-roam will function with .age encrypted org files.


5.4 pass (<https://passwordstore.org>) and its Emacs packages depend on gpg
───────────────────────────────────────────────────────────────────────────

  Please see <https://github.com/anticomputer/passage.el> for an age
  based drop-in replacement for pass and its associated Emacs packages.

  I use the following configuration that also rebinds the `pass'
  function to `passage' for convenience:

  ┌────
  │ (use-package passage
  │   :quelpa (passage :fetcher github :repo "anticomputer/passage.el")
  │   :ensure t
  │   :demand t
  │   :config
  │   ;; rebind function value for pass to passage
  │   (fset #'pass (lambda () (interactive) (passage))))
  └────


6 Disclaimer
════════════

  This is experimental software and subject to heavy feature iterations.


7 Why age over gpg?
═══════════════════

  This is, apparently, a heated topic and folks more qualified than me
  have commented on this in great detail over many years. The following
  blog post I think provides a good summary of the state of the debate
  regarding the OpenPGP specification:

  • [The PGP Problem]

  Thanks to reddit's `/u/a-huge-waste-of-time' for linking that
  reference.

  In true megalomaniac fashion I'll [quote myself] out of the age.el
  `/r/emacs' announcement thread when asked why I was looking to limit
  my use of gpg for my local file encryption needs inside Emacs.

        I wanted to reduce the amount of key management in my life
        to the bare minimum. I don't use gpg for its intended
        purpose (maintaining a web of trust with folks that you
        communicate with), but rather only use it for Emacs file
        encryption and things like password-store (which I'm
        replacing with <https://github.com/FiloSottile/passage>
        and will also port the Emacs pass frontend to work with).

        Age functions with ssh keys as well as its own key
        formats, so it hugely simplifies the amount of key
        material I have to maintain. Especially when managing key
        material on e.g. YubiKeys, maintaining Encryption,
        Authentication, and Signing subkeys and juggling what is
        essentially a personal PKI (not to mention bringing it
        along on every system) surrounding gpg's key trust
        relationship maintainance.

        I use e2e encrypted email and messaging services for
        encrypted communications and ssh keys to sign git commits.

        So with age I can also just use my ssh public key to
        encrypt and my ssh private key to decrypt my files. If I
        want to get fancy, I can use something like
        <https://github.com/str4d/age-plugin-yubikey> to provide
        the key material for my age operations (which should
        compose with age.el quite well also, i.e. you can have
        every decrypt operation have a touch requirement in Emacs
        that way).

        TL;DR: gpg is overly complex for my use case and I'm
        currently shoehorning gpg into a role it was never
        designed or intended to play. Complexity of use and secure
        use of cryptography don't compose well for most folks, so
        now that gpg no longer serves any real purpose in my
        environment, it's time to retire it from my dependency
        stack.

  Having said that, age.el is not intended to encourage you to abandon
  gpg. However, if you've been looking for a lighter weight alternative
  for Emacs encryption, it might be a good fit for you.


[The PGP Problem]
<https://latacora.micro.blog/2019/07/16/the-pgp-problem.html>

[quote myself]
<https://www.reddit.com/r/emacs/comments/zyd7bh/comment/j25ag7s/?utm_source=share&utm_medium=web2x&context=3>


8 License
═════════

  GPLv3

  This code was ported from the EasyPG Emacs code and the original
  author is Daiki Ueno <ueno@unixuser.org> who has assigned their
  copyright to the FSF.
