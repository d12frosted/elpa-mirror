[ARCHIVED] Org Password Manager

Leandro Facchinetti <me@leafac.com>

Password manager for Org Mode.

Version         0.0.1
--------------------------------------------------------------------
Documentation   https://www.leafac.com/software/org-password-manager
--------------------------------------------------------------------
License         GNU General Public License Version 3
--------------------------------------------------------------------
Code of Conduct Contributor Covenant v1.4.0
--------------------------------------------------------------------
Distribution    MELPA
--------------------------------------------------------------------
Source          https://git.leafac.com/org-password-manager
--------------------------------------------------------------------
Bug Reports     Write emails to org-password-manager@leafac.com.
--------------------------------------------------------------------
Contributions   Send patches and pull requests via email to
org-password-manager@leafac.com.
--------------------------------------------------------------------

1. Overview

Use GnuPG to encrypt the Org Mode files that contains credentials
instead of storing sensitive information in plain text.

Use Org Mode files to store credentials and retrieve them securely.
Integrate with pwgen to generate passwords.

2. Installation

Available from MELPA, add the repository to Emacs and install with
M-x package-install. Password creation requires pwgen.

3. Usage

This section assumes the default configuration.

Add credentials as properties named USERNAME and PASSWORD to headings in
Org Mode files. For example:

* [[http://example.com][My favorite website]]
:PROPERTIES:
:USERNAME: leandro
:PASSWORD: chunky-tempeh
:END:

* SSH key
:PROPERTIES:
:PASSWORD: tofu
:END:

Passwords are cleared from the clipboard after 30 seconds.

Retrieve usernames with C-c C-p u (org-password-manager-get-username)
and passwords with C-c C-p p (org-password-manager-get-password). If
point is not under a heading that contains credentials, Org Password
Manager asks for a heading. To force this behavior even when the point
is under a heading that contains credentials, use the C-u argument (for
example, C-u C-c C-p u).

Generate passwords with C-c C-p g
(org-password-manager-generate-password). To customize the parameters to
pwgen, use the C-u argument (C-u C-c C-p g).

4. Configuration

For the default configuration with the keybindings covered in the Usage
section, add the following to the Emacs configuration:

(add-hook 'org-mode-hook 'org-password-manager-key-bindings)

To customize the key bindings, start with the following code:

(defun org-password-manager-key-bindings ()
"Binds keys for org-password-manager."
(local-set-key (kbd "C-c C-p u") 'org-password-manager-get-username)
(local-set-key (kbd "C-c C-p p") 'org-password-manager-get-password)
(local-set-key (kbd "C-c C-p
g") 'org-password-manager-generate-password))

For Interactive Do (ido) support, add the following to the Emacs
configuration:

(setq org-completion-use-ido t)

For advanced configuration, refer to
M-x customize-group org-password-manager.

5. Changelog

This section documents all notable changes to Org Password Manager. It
follows recommendations from Keep a CHANGELOG and uses Semantic
Versioning. Each released version is a Git tag.

5.1. Archived · 2018-02-27

This project is archived and no longer maintained.

5.2. 0.0.1 · 2015-07-29

5.2.1. Added

* Core functionality.
