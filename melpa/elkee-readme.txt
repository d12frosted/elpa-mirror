Native KeePass client for Emacs

Quickstart: `elkee-find-creds' and `elkee-list-creds' docstrings.

Elkee, unlike other KeePass clients, strives for requiring zero third-party
binaries, and working wherever Emacs works due to being written in ELisp. No
C#, no C++, no linking against libs, no shell exec, just pure ELisp. Working
Emacs (and optionally a good package manager) should be the only thing
needed.

It's not there yet. For the first clean implementation it needs three
critical parts: ChaCha20 (RFC7539), Blake2 (RFC7693) and Argon2 (RFC9106).
Currently only Argon2 remains and its implementation is already in progress,
soon replacing the last requirement for the binary.

Fortunately, argon2 binary is present on all large platforms Emacs is
available on including Android (via Termux and/or copy-paste out of it), so
the only requirement is to have it on $PATH.

The targeted container is KeePass 2.x KDBX file, that means:

| KeePass | KDBX |
|---------|------|
| 2.00    | 1.0  |
| 2.07    | 1.1  |
| 2.08    | 1.2  |
| 2.09    | 2.0  |
| 2.11    | 2.4  |
| 2.15    | 3.0  |
| 2.20    | 3.1  |
| 2.35    | 4.0  |
| 2.48    | 4.1  |

of which KDBX 4.x is implemented at the moment. Writing to the KDBX file is
currently not supported and is of a lesser priority than supporting the
reading of other KDBX versions due to other means available for Windows,
Linux, MacOS and Android including various synchronization methods across
machines where KDBX editing is faster and more comfortable.

Out of all KDBX 4.x algorithms available, only the chain
ChaCha20-Blake2-Argon2 is supported at the moment, but contributions are
welcome.
