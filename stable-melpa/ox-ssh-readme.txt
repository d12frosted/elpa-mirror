SSH configuration export for org-mode.

Commands
`ox-ssh' provides the following interactive commands:
- `org-ssh-export-as-config' Exports to a temporary buffer
- `org-ssh-export-to-config' Exports to file with the extension .ssh_config
- `org-ssh-export-overwrite-user-config' Exports file, overwrites user's =~/.ssh/config=.
  Prompts user with yes/no option before doing so.
These commands are also exposed through the `org-export-dispatch' menu.

Variables
- `org-ssh-header' An optional header that will be added to the
  beginning of the export. This can be used for comments or rules
  that apply to all hosts.
- `org-ssh-export-suffix' The suffix that will be added to exported file.
  Defaults to ".ssh_config".

Usage
Export headings with specific properties as entries in an SSH
configuration file. These properties correspond with the client
configuration options for SSH.

For a heading to be exported as a host, it must have either a
HOSTNAME or IP property. If an entry has both, IP takes
precedence. It can also contain one or more
optional parameters, listed in the table below.

| ssh_config(5) option             | ox-ssh property                          |
|----------------------------------+------------------------------------------|
| AddKeysToAgent                   | SSH_ADD_KEYS_TO_AGENT                    |
| AddressFamily                    | SSH_ADDRESS_FAMILY                       |
| BatchMode                        | SSH_BATCH_MODE                           |
| BindInterface                    | SSH_BIND_INTERFACE                       |
| CanonicalDomains                 | SSH_CANONICAL_DOMAINS                    |
| CanonicalizeFallbackLocal        | SSH_CANONICALIZE_FALLBACK_LOCAL          |
| CanonicalizeHostname             | SSH_CANONICALIZE_HOSTNAME                |
| CanonicalizeMaxDots              | SSH_CANONICALIZE_MAX_DOTS                |
| CanonicalizePermittedCNAMEs      | SSH_CANONICALIZE_PERMITTED_CNAMES        |
| CASignatureAlgorithms            | SSH_CA_SIGNATURE_ALGORITHMS              |
| CertificateFile                  | SSH_CERTIFICATE_FILE                     |
| ChallengeResponseAuthentication  | SSH_CHALLENGE_RESPONSE_AUTHENTICATION    |
| CheckHostIP                      | SSH_CHECK_HOST_IP                        |
| Ciphers                          | SSH_CIPHERS                              |
| ClearAllForwardings              | SSH_CLEAR_ALL_FORWARDINGS                |
| Compression                      | SSH_COMPRESSION                          |
| ConnectionAttempts               | SSH_CONNECTION_ATTEMPTS                  |
| ConnectTimeout                   | SSH_CONNECT_TIMEOUT                      |
| ControlMaster                    | SSH_CONTROL_MASTER                       |
| ControlPath                      | SSH_CONTROL_PATH                         |
| ControlPersist                   | SSH_CONTROL_PERSIST                      |
| DynamicForward                   | SSH_DYNAMIC_FORWARD                      |
| EnableSSHKeysign                 | SSH_ENABLE_SSH_KEYSIGN                   |
| EscapeChar                       | SSH_ESCAPE_CHAR                          |
| ExitOnForwardFailure             | SSH_EXIT_ON_FORWARD_FAILURE              |
| FingerprintHash                  | SSH_FINGERPRINT_HASH                     |
| ForwardAgent                     | SSH_FORWARD_AGENT                        |
| ForwardX11                       | SSH_FORWARD_X11                          |
| ForwardX11Timeout                | SSH_FORWARD_X11_TIMEOUT                  |
| ForwardX11Trusted                | SSH_FORWARD_X11_TRUSTED                  |
| GatewayPorts                     | SSH_GATEWAY_PORTS                        |
| GlobalKnownHostsFile             | SSH_GLOBAL_KNOWN_HOSTS_FILE              |
| GSSAPIAuthentication             | SSH_GSSAPI_AUTHENTICATION                |
| GSSAPIDelegateCredentials        | SSH_GSSAPI_DELEGATE_CREDENTIALS          |
| HashKnownHosts                   | SSH_HASH_KNOWN_HOSTS                     |
| HostBasedAuthentication          | SSH_HOST_BASED_AUTHENTICATION            |
| HostBasedKeyTypes                | SSH_HOST_BASED_KEY_TYPES                 |
| HostKeyAlgorithms                | SSH_HOST_KEY_ALGORITHMS                  |
| HostKeyAlias                     | SSH_HOST_KEY_ALIAS                       |
| Hostname                         | SSH_HOSTNAME                             |
| IdentitiesOnly                   | SSH_IDENTITIES_ONLY                      |
| IdentityAgent                    | SSH_IDENTITY_AGENT                       |
| IdentityFile                     | SSH_IDENTITY_FILE                        |
| IgnoreUnknown                    | SSH_IGNORE_UNKNOWN                       |
| Include                          | SSH_INCLUDE                              |
| IPQoS                            | SSH_IP_QOS                               |
| KbdInteractiveAuthentication     | SSH_KBD_INTERACTIVE_AUTHENTICATION       |
| KbdInteractiveDevices            | SSH_KBD_INTERACTIVE_DEVICES              |
| KexAlgorithms                    | SSH_KEX_ALGORITHMS                       |
| LocalCommand                     | SSH_LOCAL_COMMAND                        |
| LocalForward                     | SSH_LOCAL_FORWARD                        |
| LogLevel                         | SSH_LOG_LEVEL                            |
| MACs                             | SSH_MACS                                 |
| NoHostAuthenticationForLocalhost | SSH_NO_HOST_AUTHENTICATION_FOR_LOCALHOST |
| NumberOfPasswordPrompts          | SSH_NUMBER_OF_PASSWORD_PROMPTS           |
| PasswordAuthentication           | SSH_PASSWORD_AUTHENTICATION              |
| PermitLocalCommand               | SSH_PERMIT_LOCAL_COMMAND                 |
| PKCS11Provider                   | SSH_PKCS11_PROVIDER                      |
| Port                             | SSH_PORT                                 |
| PreferredAuthentications         | SSH_PREFERRED_AUTHENTICATIONS            |
| ProxyCommand                     | SSH_PROXY_COMMAND                        |
| ProxyJump                        | SSH_PROXY_JUMP                           |
| ProxyUseFdPass                   | SSH_PROXY_USE_FD_PASS                    |
| PubkeyAcceptedKeyTypes           | SSH_PUBKEY_ACCEPTED_KEY_TYPES            |
| PubkeyAuthentication             | SSH_PUBKEY_AUTHENTICATION                |
| RekeyLimit                       | SSH_REKEY_LIMIT                          |
| RemoteCommand                    | SSH_REMOTE_COMMAND                       |
| RemoteForward                    | SSH_REMOTE_FORWARD                       |
| RequestTTY                       | SSH_REQUEST_TTY                          |
| RevokedHostKeys                  | SSH_REVOKED_HOST_KEYS                    |
| SecurityKeyProvider              | SSH_SECURITY_KEY_PROVIDER                |
| SendEnv                          | SSH_SEND_ENV                             |
| ServerAliveMaxCount              | SSH_SERVER_ALIVE_MAX_COUNT               |
| ServerAliveInterval              | SSH_SERVER_ALIVE_INTERVAL                |
| SetEnv                           | SSH_SET_ENV                              |
| StreamLocalBindMask              | SSH_STREAM_LOCAL_BIND_MASK               |
| StreamLocalBindUnlink            | SSH_STREAM_LOCAL_BIND_UNLINK             |
| StrictHostKeyChecking            | SSH_STRICT_HOST_KEY_CHECKING             |
| SyslogFacility                   | SSH_SYSLOG_FACILITY                      |
| TCPKeepAlive                     | SSH_TCP_KEEP_ALIVE                       |
| Tunnel                           | SSH_TUNNEL                               |
| TunnelDevice                     | SSH_TUNNEL_DEVICE                        |
| UpdateHostKeys                   | SSH_UPDATE_HOST_KEYS                     |
| User                             | SSH_USER                                 |
| UserKnownHostsFile               | SSH_USER_KNOWN_HOSTS_FILE                |
| VerifyHostKeyDNS                 | SSH_VERIFY_HOST_KEY_DNS                  |
| VisualHostKey                    | SSH_VISUAL_HOST_KEY                      |
| XAuthLocation                    | SSH_X_AUTH_LOCATION                      |
