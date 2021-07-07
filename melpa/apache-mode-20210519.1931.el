;;; apache-mode.el --- Major mode for editing Apache httpd configuration files

;; Copyright (c) 2004, 2005 Karl Chen <quarl@nospam.quarl.org>
;; Copyright (c) 1999 Jonathan Marten  <jonathan.marten@uk.sun.com>

;; Author: Karl Chen <quarl@nospam.quarl.org>
;; Maintainer: USAMI Kenta <tadsan@zonu.me>
;; Homepage: https://github.com/emacs-php/apache-mode
;; License: GPL-2.0-or-later
;; Keywords: languages, faces
;; Package-Version: 20210519.1931
;; Package-Commit: f2c11aac2f5fc598123e04f4604bea248689a117
;; Version: 2.2.0

;; apache-mode.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.
;;
;; It is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along
;; with your copy of Emacs; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Commentary:
;;
;; apache-mode is a major mode for editing Apache HTTP Server Configuration files.
;; https://httpd.apache.org/docs/2.4/en/configuring.html
;;
;; This mode supports Apache HTTP Server 2.4 and major modules.

;;; History:
;;
;; 1999-10 Jonathan Marten <jonathan.marten@uk.sun.com>
;;   initial version
;;
;; 2004-09-12 Karl Chen <quarl@nospam.quarl.org>
;;   rewrote pretty much everything using define-derived-mode; added support
;;   for Apache 2.x; fixed highlighting in GNU Emacs; created indentation
;;   function
;;
;; 2005-06-29 Kumar Appaiah <akumar_NOSPAM@ee.iitm.ac.in>
;;   use syntax table instead of font-lock-keywords to highlight comments.
;;
;; 2015-08-23 David Maus <dmaus@ictsoc.de>
;;   update list of directives for Apache 2.4
;;
;; 2018-07-23 USAMI Kenta <tadsan@pixiv.com>
;;   more update list of directives for Apache 2.4
;;

;;; Code:

;; Requires
(eval-when-compile
  (require 'regexp-opt))

(defvar apache-indent-level 4
  "*Number of spaces to indent per level.")

(defvar apache-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_   "_"    table)
    (modify-syntax-entry ?-   "_"    table)
    (modify-syntax-entry ?\(  "()"   table)
    (modify-syntax-entry ?\)  ")("   table)
    (modify-syntax-entry ?<   "(>"   table)
    (modify-syntax-entry ?>   ")<"   table)
    (modify-syntax-entry ?\"  "\""   table)
    (modify-syntax-entry ?,   "."    table)
    (modify-syntax-entry ?#   "<"    table)
    (modify-syntax-entry ?\n  ">#"   table)
    table))

;;;###autoload
(define-derived-mode apache-mode fundamental-mode "Apache"
  "Major mode for editing Apache configuration files."

  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-start-skip) "#\\W*")
  (set (make-local-variable 'comment-column) 48)

  (set (make-local-variable 'indent-line-function) 'apache-indent-line)

  (set (make-local-variable 'font-lock-defaults)
       '(apache-font-lock-keywords nil t
                             ((?_ . "w")
                              (?- . "w"))
                             beginning-of-line)))

;; Font lock
(defconst apache-font-lock-keywords
  (purecopy
   (eval-when-compile
    ;; see syntax table for comment highlighting

    ;; (list "^[ \t]*#.*" 0 'font-lock-comment-face t)
     `((,(concat                       ; sections
          "^[ \t]*</?"
          (regexp-opt
           '("Directory"          ; core
             "DirectoryMatch"
             "Else"
             "ElseIf"
             "Files"
             "FilesMatch"
             "If"
             "IfDefine"
             "IfModule"
             "Limit"
             "LimitExcept"
             "Location"
             "LocationMatch"
             "Proxy"
             "ProxyMatch"
             "VirtualHost"
             "AuthnProviderAlias" ; mod_authn_core
             "AuthzProviderAlias" ; mod_authz_core
             "RequireAll"
             "RequireAny"
             "RequireNone"
             "Macro"              ; mod_macro
             "Perl"               ; mod_perl
             "IfVersion"          ; mod_version
             )
           'words)
          ".*?>")
        1 'font-lock-function-name-face)
       (,(concat                       ; directives
          "^[ \t]*"
          (regexp-opt
           '("AcceptFilter"                                    ; core
             "AcceptMutex"
             "AcceptPathInfo"
             "AccessConfig"
             "AccessFileName"
             "AddDefaultCharset"
             "AddModule"
             "AllowEncodedSlashes"
             "AllowOverride"
             "AllowOverrideList"
             "AuthName"
             "AuthType"
             "BindAddress"
             "BS2000Account"
             "CGIMapExtension"
             "CGIPassAuth"
             "ClearModuleList"
             "ContentDigest"
             "CoreDumpDirectory"
             "DefaultRuntimeDir"
             "DefaultType"
             "Define"
             "DocumentRoot"
             "EBCDICConvert"
             "EBCDICConvertByType"
             "EBCDICKludge"
             "EnableMMAP"
             "EnableSendfile"
             "Error"
             "ErrorDocument"
             "ErrorLog"
             "ErrorLogFormat"
             "FileETag"
             "ForceType"
             "GprofDir"
             "Group"
             "HostnameLookups"
             "IdentityCheck"
             "Include"
             "IncludeOptional"
             "KeepAlive"
             "KeepAliveTimeout"
             "LimitInternalRecursion"
             "LimitRequestBody"
             "LimitRequestFields"
             "LimitRequestFieldsize"
             "LimitRequestLine"
             "LimitXMLRequestBody"
             "Listen"
             "ListenBacklog"
             "LockFile"
             "LogLevel"
             "MaxClients"
             "MaxKeepAliveRequests"
             "MaxRangeOverlaps"
             "MaxRangeReversals"
             "MaxRanges"
             "MaxRequestsPerChild"
             "MaxSpareServers"
             "MergeTrailers"
             "MinSpareServers"
             "Mutex"
             "NameVirtualHost"
             "Options"
             "PidFile"
             "Port"
             "Protocol"
             "Require"
             "ResourceConfig"
             "RLimitCPU"
             "RLimitMEM"
             "RLimitNPROC"
             "Satisfy"
             "ScoreBoardFile"
             "ScriptInterpreterSource"
             "SeeRequestTail"
             "SendBufferSize"
             "ServerAdmin"
             "ServerAlias"
             "ServerName"
             "ServerPath"
             "ServerRoot"
             "ServerSignature"
             "ServerTokens"
             "ServerType"
             "SetHandler"
             "SetInputFilter"
             "SetOutputFilter"
             "StartServers"
             "ThreadsPerChild"
             "ThreadStackSize"
             "TimeOut"
             "TraceEnable"
             "UnDefine"
             "UseCanonicalName"
             "UseCanonicalPhysicalPort"
             "User"
             "AuthLDAPAuthorizePrefix"                         ; mod_ authnz_ldap
             "AuthLDAPBindAuthoritative"
             "AuthLDAPCharsetConfig"
             "AuthLDAPCompareAsUser"
             "AuthLDAPInitialBindAsUser"
             "AuthLDAPInitialBindPattern"
             "AuthLDAPMaxSubGroupDepth"
             "AuthLDAPRemoteUserAttribute"
             "AuthLDAPSearchAsUser"
             "AuthLDAPSubGroupAttribute"
             "AuthLDAPSubGroupClass"
             "Allow"                                           ; mod_access
             "Deny"
             "Order"
             "Action"                                          ; mod_actions
             "Script"
             "Alias"                                           ; mod_alias
             "AliasMatch"
             "Redirect"
             "RedirectMatch"
             "RedirectPermanent"
             "RedirectTemp"
             "ScriptAlias"
             "ScriptAliasMatch"
             "AllowMethods"                                    ; mod_allowmethods
             "AuthAuthoritative"                               ; mod_auth
             "AuthUserFile"
             "AuthGroupFile"
             "Anonymous"                                       ; mod_auth_anon
             "Anonymous_Authoritative"
             "Anonymous_LogEmail"
             "Anonymous_MustGiveEmail"
             "Anonymous_NoUserID"
             "Anonymous_VerifyEmail"
             "AuthBasicAuthoritative"                          ; mod_auth_basic
             "AuthBasicFake"
             "AuthBasicProvider"
             "AuthBasicUseDigestAlgorithm"
             "AuthDBAuthoritative"                             ; mod_auth_db
             "AuthDBGroupFile"
             "AuthDBUserFile"
             "AuthDBMAuthoritative"                            ; mod_auth_dbm
             "AuthDBMGroupFile"
             "AuthDBMType"
             "AuthDBMUserFile"
             "AuthDigestAlgorithm"                             ; mod_auth_digest
             "AuthDigestDomain"
             "AuthDigestFile"
             "AuthDigestGroupFile"
             "AuthDigestNcCheck"
             "AuthDigestNonceFormat"
             "AuthDigestNonceLifetime"
             "AuthDigestProvider"
             "AuthDigestQop"
             "AuthDigestShmemSize"
             "AuthFormAuthoritative"                           ; mod_auth_form
             "AuthFormBody"
             "AuthFormDisableNoStore"
             "AuthFormFakeBasicAuth"
             "AuthFormLocation"
             "AuthFormLoginRequiredLocation"
             "AuthFormLoginSuccessLocation"
             "AuthFormLogoutLocation"
             "AuthFormMethod"
             "AuthFormMimetype"
             "AuthFormPassword"
             "AuthFormProvider"
             "AuthFormSitePassphrase"
             "AuthFormSize"
             "AuthFormUsername"
             "AuthLDAPAuthoritative"                           ; mod_auth_ldap
             "AuthLDAPBindDN"
             "AuthLDAPBindPassword"
             "AuthLDAPCompareDNOnServer"
             "AuthLDAPDereferenceAliases"
             "AuthLDAPEnabled"
             "AuthLDAPFrontPageHack"
             "AuthLDAPGroupAttribute"
             "AuthLDAPGroupAttributeIsDN"
             "AuthLDAPRemoteUserIsDN"
             "AuthLDAPStartTLS"
             "AuthLDAPUrl"
             "AuthDBDUserPWQuery"                              ; mod_authn_dbd
             "AuthDBDUserRealmQuery"
             "AuthnCacheContext"                               ; mod_authn_socache
             "AuthnCacheEnable"
             "AuthnCacheProvideFor"
             "AuthnCacheSOCache"
             "AuthnCacheTimeout"
             "AuthnzFcgiCheckAuthnProvider"                    ; mod_authnz_fgci
             "AuthnzFcgiDefineProvider"
             "AuthMerging"                                     ; mod_authz_core
             "AuthzSendForbiddenOnFailure"
             "AuthzDBDLoginToReferer"                          ; mod_authz_dbd
             "AuthzDBDQuery"
             "AuthzDBDRedirectQuery"
             "AuthzDBMType"
             "AddAlt"                                          ; mod_autoindex
             "AddAltByEncoding"
             "AddAltByType"
             "AddDescription"
             "AddIcon"
             "AddIconByEncoding"
             "AddIconByType"
             "DefaultIcon"
             "FancyIndexing"
             "HeaderName"
             "IndexHeadInsert"
             "IndexIgnore"
             "IndexIgnoreReset"
             "IndexOptions"
             "IndexOrderDefault"
             "IndexStyleSheet"
             "ReadmeName"
             "BrowserMatch"                                    ; mod_browser
             "BrowserMatchNoCase"
             "BufferSize"                                      ; mod_buffer
             "CacheDefaultExpire"                              ; mod_cache
             "CacheDetailHeader"
             "CacheDisable"
             "CacheEnable"
             "CacheHeader"
             "CacheIgnoreCacheControl"
             "CacheIgnoreHeaders"
             "CacheIgnoreNoLastMod"
             "CacheIgnoreQueryString"
             "CacheIgnoreURLSessionIdentifiers"
             "CacheKeyBaseURL"
             "CacheLastModifiedFactor"
             "CacheLock"
             "CacheLockMaxAge"
             "CacheLockPath"
             "CacheMaxExpire"
             "CacheMaxFileSize"
             "CacheMinExpire"
             "CacheMinFileSize"
             "CacheOn"
             "CacheQuickHandler"
             "CacheStaleOnError"
             "CacheStoreExpired"
             "CacheStoreNoStore"
             "CacheStorePrivate"
             "CacheReadSize"                                   ; mod_cache_disk
             "CacheReadTime"
             "CacheSocache"                                    ; mod_cache_socache
             "CacheSocacheMaxSize"
             "CacheSocacheMaxTime"
             "CacheSocacheMinTime"
             "CacheSocacheReadSize"
             "CacheSocacheReadTime"
             "MetaDir"                                         ; mod_cern_meta
             "MetaFiles"
             "MetaSuffix"
             "ScriptLog"                                       ; mod_cgi
             "ScriptLogBuffer"
             "ScriptLogLength"
             "CGIDScriptTimeout"                               ; mod_cgid
             "ScriptLog"
             "ScriptLogBuffer"
             "ScriptLogLength"
             "ScriptSock"
             "CharsetDefault"                                  ; mod_charset_lite
             "CharsetOptions"
             "CharsetSourceEnc"
             "CookieLog"                                       ; mod_cookies
             "Dav"                                             ; mod_dav
             "DavDepthInfinity"
             "DavLockDB"
             "DavMinTimeout"
             "DavGenericLockDB"                                ; mod_dav_lock
             "DBDExptime"                                      ; mod_dbd
             "DBDInitSQL"
             "DBDKeep"
             "DBDMax"
             "DBDMin"
             "DBDParams"
             "DBDPersist"
             "DBDPrepareSQL"
             "DBDriver"
             "DeflateBufferSize"                               ; mod_deflate
             "DeflateCompressionLevel"
             "DeflateFilterNote"
             "DeflateInflateLimitRequestBody"
             "DeflateInflateRatioBurst"
             "DeflateInflateRatioLimit"
             "DeflateMemLevel"
             "DeflateWindowSize"
             "ModemStandard"                                   ; mod_dialup
             "AuthDigestFile"                                  ; mod_digest
             "DirectoryCheckHandler"                           ; mod_dir
             "DirectoryIndex"
             "DirectoryIndexRedirect"
             "DirectorySlash"
             "FallbackResource"
             "LoadFile"                                        ; mod_dld
             "LoadModule"
             "DumpIOInput"                                     ; mod_dumpio
             "DumpIOOutput"
             "ProtocolEcho"                                    ; mod_echo
             "PassEnv"                                         ; mod_env
             "SetEnv"
             "UnsetEnv"
             "AsyncRequestWorkerFactor"                        ; mod_event
             "Example"                                         ; mod_example
             "ExpiresActive"                                   ; mod_expires
             "ExpiresByType"
             "ExpiresDefault"
             "ExtFilterDefine"                                 ; mod_ext_filter
             "ExtFilterOptions"
             "CacheFile"                                       ; mod_file_cache
             "MMapFile"
             "AddOutputFilterByType"                           ; mod_filter
             "FilterChain"
             "FilterDeclare"
             "FilterProtocol"
             "FilterProvider"
             "FilterTrace"
             "Header"                                          ; mod_headers
             "RequestHeader"
             "HeartbeatAddress"                                ; mod_heartbeat
             "HeartbeatListen"
             "HeartbeatMaxServers"
             "HeartbeatStorage"
             "IdentityCheckTimeout"                            ; mod_ident
             "ImapBase"                                        ; mod_imap
             "ImapDefault"
             "ImapMenu"
             "SSIEndTag"                                       ; mod_include
             "SSIErrorMsg"
             "SSIETag"
             "SSILastModified"
             "SSILegacyExprParser"
             "SSIStartTag"
             "SSITimeFormat"
             "SSIUndefinedEcho"
             "XBitHack"
             "AddModuleInfo"                                   ; mod_info
             "ISAPICacheFile"                                  ; mod_isapi
             "ISAPIFakeAsync"
             "ISAPIFileCache"
             "ISAPIAppendLogToErrors"                          ; mod_isapi (Win32)
             "ISAPIAppendLogToQuery"
             "ISAPILogNotSupported"
             "ISAPIReadAheadBuffer"
             "LDAPCacheEntries"                                ; mod_ldap
             "LDAPCacheTTL"
             "LDAPCertDBPath"
             "LDAPConnectionPoolTTL"
             "LDAPConnectionTimeout"
             "LDAPLibraryDebug"
             "LDAPOpCacheEntries"
             "LDAPOpCacheTTL"
             "LDAPReferralHopLimit"
             "LDAPReferrals"
             "LDAPRetries"
             "LDAPRetryDelay"
             "LDAPSharedCacheFile"
             "LDAPSharedCacheSize"
             "LDAPTimeout"
             "LDAPTrustedClientCert"
             "LDAPTrustedGlobalCert"
             "LDAPTrustedMode"
             "LDAPVerifyServerCert"
             "AgentLog"                                        ; mod_log_agent
             "TransferLog"                                     ; mod_log_common
             "BufferedLogs"                                    ; mod_log_config
             "CookieLog"
             "CustomLog"
             "LogFormat"
             "TransferLog"
             "LogMessage"                                      ; mod_log_debug
             "ForensicLog"                                     ; mod_log_forensic
             "RefererIgnore"                                   ; mod_log_referer
             "RefererLog"
             "LogIOTrackTTFB"                                  ; mod_logio
             "LuaAuthzProvider"                                ; mod_lua
             "LuaCodeCache"
             "LuaHookAccessChecker"
             "LuaHookAuthChecker"
             "LuaHookCheckUserID"
             "LuaHookFixups"
             "LuaHookInsertFilter"
             "LuaHookLog"
             "LuaHookMapToStorage"
             "LuaHookTranslateName"
             "LuaHookTypeChecker"
             "LuaInherit"
             "LuaInputFilter"
             "LuaMapHandler"
             "LuaOutputFilter"
             "LuaPackageCPath"
             "LuaPackagePath"
             "LuaQuickHandler"
             "LuaRoot"
             "LuaScope"
             "UndefMacro"                                      ; mod_macro
             "Use"
             "AddCharset"                                      ; mod_mime
             "AddEncoding"
             "AddHandler"
             "AddInputFilter"
             "AddLanguage"
             "AddOutputFilter"
             "AddType"
             "DefaultLanguage"
             "ForceType"
             "ModMimeUsePathInfo"
             "MultiviewsMatch"
             "RemoveCharset"
             "RemoveEncoding"
             "RemoveHandler"
             "RemoveInputFilter"
             "RemoveLanguage"
             "RemoveOutputFilter"
             "RemoveType"
             "SetHandler"
             "TypesConfig"
             "MimeMagicFile"                                   ; mod_mime_magic
             "MMapFile"                                        ; mod_mmap_static
             "CacheNegotiatedDocs"                             ; mod_negotiation
             "ForceLanguagePriority"
             "LanguagePriority"
             "NWSSLTrustedCerts"                               ; mod_nw_ssl
             "NWSSLUpgradeable"
             "SecureListen"
             "PerlDispatchHandler"                             ; mod_perl 1
             "PerlFreshRestart"
             "PerlHandler"
             "PerlOpmask"
             "PerlRestartHandler"
             "PerlScript"
             "PerlSendHeader"
             "PerlSetupEnv"
             "PerlTaintCheck"
             "PerlTransHandler"
             "PerlWarn"
             "PerlAccessHandler"                               ; mod_perl 1+2
             "PerlAddVar"
             "PerlAuthenHandler"
             "PerlAuthzHandler"
             "PerlChildExitHandler"
             "PerlChildInitHandler"
             "PerlCleanupHandler"
             "PerlFixupHandler"
             "PerlHeaderParserHandler"
             "PerlInitHandler"
             "PerlLogHandler"
             "PerlModule"
             "PerlPassEnv"
             "PerlPostReadRequestHandler"
             "PerlRequire"
             "PerlSetEnv"
             "PerlSetVar"
             "PerlTypeHandler"
             "PerlInputFilterHandler"                          ; mod_perl 2
             "PerlInterpMax"
             "PerlInterpMaxRequests"
             "PerlInterpMaxSpare"
             "PerlInterpMinSpare"
             "PerlInterpScope"
             "PerlInterpStart"
             "PerlLoadModule"
             "PerlOpenLogsHandler"
             "PerlOptions"
             "PerlOutputFilterHandler"
             "PerlPostConfigHandler"
             "PerlPreConnectionHandler"
             "PerlProcessConnectionHandler"
             "PerlResponseHandler"
             "PerlSetInputFilter"
             "PerlSetOutputFilter"
             "PerlSwitches"
             "PerlTrace"
             "DTracePrivileges"                                ; mod_privileges
             "PrivilegesMode"
             "VHostCGIMode"
             "VHostCGIPrivs"
             "VHostGroup"
             "VHostPrivs"
             "VHostSecure"
             "VHostUser"
             "AllowCONNECT"                                    ; mod_proxy
             "BalancerGrowth"
             "BalancerInherit"
             "BalancerMember"
             "BalancerPersist"
             "CacheDefaultExpire"
             "CacheDirLength"
             "CacheDirLevels"
             "CacheForceCompletion"
             "CacheGcInterval"
             "CacheLastModifiedFactor"
             "CacheMaxExpire"
             "CacheRoot"
             "CacheSize"
             "NoCache"
             "NoProxy"
             "ProxyAddHeaders"
             "ProxyBadHeader"
             "ProxyBlock"
             "ProxyDomain"
             "ProxyErrorOverride"
             "ProxyHTMLURLMap"
             "ProxyIOBufferSize"
             "ProxyMaxForwards"
             "ProxyPass"
             "ProxyPassInherit"
             "ProxyPassInterpolateEnv"
             "ProxyPassMatch"
             "ProxyPassReverse"
             "ProxyPassReverseCookieDomain"
             "ProxyPassReverseCookiePath"
             "ProxyPreserveHost"
             "ProxyReceiveBufferSize"
             "ProxyRemote"
             "ProxyRemoteMatch"
             "ProxyRequests"
             "ProxySet"
             "ProxySourceAddress"
             "ProxyStatus"
             "ProxyTimeout"
             "ProxyVia"
             "ProxyExpressDBMFile"                             ; mod_proxy_express
             "ProxyExpressDBMType"
             "ProxyExpressEnable"
             "ProxyFtpDirCharset"                              ; mod_proxy_ftp
             "ProxyFtpEscapeWildcards"
             "ProxyFtpListOnWildcard"
             "ProxyHTMLBufSize"                                ; mod_proxy_html
             "ProxyHTMLCharsetOut"
             "ProxyHTMLDocType"
             "ProxyHTMLEnable"
             "ProxyHTMLEvents"
             "ProxyHTMLExtended"
             "ProxyHTMLFixups"
             "ProxyHTMLInterp"
             "ProxyHTMLLinks"
             "ProxyHTMLMeta"
             "ProxyHTMLStripComments"
             "ProxySCGIInternalRedirect"                       ; mod_proxy_scgi
             "ProxySCGISendfile"
             "PythonAccessHandler"                             ; mod_python
             "PythonAuthenHandler"
             "PythonAuthzHandler"
             "PythonAutoReload"
             "PythonCleanupHandler"
             "PythonConnectionHandler"
             "PythonDebug"
             "PythonEnablePdb"
             "PythonFixupHandler"
             "PythonHandler"
             "PythonHandlerModule"
             "PythonHeaderParserHandler"
             "PythonImport"
             "PythonInitHandler"
             "PythonInputFilter"
             "PythonInterpPerDirective"
             "PythonInterpPerDirectory"
             "PythonInterpreter"
             "PythonLogHandler"
             "PythonOptimize"
             "PythonOption"
             "PythonOutputFilter"
             "PythonPath"
             "PythonPostReadRequestHandler"
             "PythonTransHandler"
             "PythonTypeHandler"
             "ReflectorHeader"                                 ; mod_reflector
             "RemoteIPHeader"                                  ; mod_remoteip
             "RemoteIPInternalProxy"
             "RemoteIPInternalProxyList"
             "RemoteIPProxiesHeader"
             "RemoteIPTrustedProxy"
             "RemoteIPTrustedProxyList"
             "RequestReadTimeout"                              ; mod_reqtimeout
             "KeptBodySize"                                    ; mod_request
             "RewriteBase"                                     ; mod_rewrite
             "RewriteCond"
             "RewriteEngine"
             "RewriteLock"
             "RewriteLog"
             "RewriteLogLevel"
             "RewriteMap"
             "RewriteOptions"
             "RewriteRule"
             "InputSed"                                        ; mod_sed
             "OutputSed"
             "Session"                                         ; mod_session
             "SessionEnv"
             "SessionExclude"
             "SessionHeader"
             "SessionInclude"
             "SessionMaxAge"
             "SessionCookieName"                               ; mod_session_cookie
             "SessionCookieName2"
             "SessionCookieRemove"
             "SessionCryptoCipher"                             ; mod_session_crypto
             "SessionCryptoDriver"
             "SessionCryptoPassphrase"
             "SessionCryptoPassphraseFile"
             "SessionDBDCookieName"                            ; mod_session_dbd
             "SessionDBDCookieName2"
             "SessionDBDCookieRemove"
             "SessionDBDDeleteLabel"
             "SessionDBDInsertLabel"
             "SessionDBDPerUser"
             "SessionDBDSelectLabel"
             "SessionDBDUpdateLabel"
             "BrowserMatch"                                    ; mod_setenvif
             "BrowserMatchNoCase"
             "SetEnvIf"
             "SetEnvIfExpr"
             "SetEnvIfNoCase"
             "LoadFile"                                        ; mod_so
             "LoadModule"
             "CheckCaseOnly"                                   ; mod_speling
             "CheckSpelling"
             "SSLBanCipher"                                    ; mod_ssl
             "SSLCACertificateFile"
             "SSLCACertificatePath"
             "SSLCacheServerPath"
             "SSLCacheServerPort"
             "SSLCacheServerRunDir"
             "SSLCADNRequestFile"
             "SSLCADNRequestPath"
             "SSLCARevocationCheck"
             "SSLCARevocationFile"
             "SSLCARevocationPath"
             "SSLCertificateChainFile"
             "SSLCertificateFile"
             "SSLCertificateKeyFile"
             "SSLCheckClientDN"
             "SSLCipherSuite"
             "SSLCompression"
             "SSLCryptoDevice"
             "SSLDenySSL"
             "SSLDisable"
             "SSLEnable"
             "SSLEngine"
             "SSLEngineID"
             "SSLExportClientCertificates"
             "SSLFakeBasicAuth"
             "SSLFIPS"
             "SSLHonorCipherOrder"
             "SSLInsecureRenegotiation"
             "SSLKeyNoteTrustedAssertion"
             "SSLKeyNoteTrustedIssuerTemplate"
             "SSLLog"
             "SSLLogLevel"
             "SSLMutex"
             "SSLNoCAList"
             "SSLOCSPDefaultResponder"
             "SSLOCSPEnable"
             "SSLOCSPOverrideResponder"
             "SSLOCSPResponderTimeout"
             "SSLOCSPResponseMaxAge"
             "SSLOCSPResponseTimeSkew"
             "SSLOCSPUseRequestNonce"
             "SSLOpenSSLConfCmd"
             "SSLOptions"
             "SSLPassPhraseDialog"
             "SSLProtocol"
             "SSLProxyCACertificateFile"
             "SSLProxyCACertificatePath"
             "SSLProxyCARevocationCheck"
             "SSLProxyCARevocationFile"
             "SSLProxyCARevocationPath"
             "SSLProxyCheckPeerCN"
             "SSLProxyCheckPeerExpire"
             "SSLProxyCheckPeerName"
             "SSLProxyCipherSuite"
             "SSLProxyEngine"
             "SSLProxyMachineCertificateChainFile"
             "SSLProxyMachineCertificateFile"
             "SSLProxyMachineCertificatePath"
             "SSLProxyProtocol"
             "SSLProxyVerify"
             "SSLProxyVerifyDepth"
             "SSLRandomFile"
             "SSLRandomFilePerConnection"
             "SSLRandomSeed"
             "SSLRenegBufferSize"
             "SSLRequire"
             "SSLRequireCipher"
             "SSLRequiredCiphers"
             "SSLRequireSSL"
             "SSLSessionCache"
             "SSLSessionCacheTimeout"
             "SSLSessionTicketKeyFile"
             "SSLSessionTickets"
             "SSLSRPUnknownUserSeed"
             "SSLSRPVerifierFile"
             "SSLStaplingCache"
             "SSLStaplingErrorCacheTimeout"
             "SSLStaplingFakeTryLater"
             "SSLStaplingForceURL"
             "SSLStaplingResponderTimeout"
             "SSLStaplingResponseMaxAge"
             "SSLStaplingResponseTimeSkew"
             "SSLStaplingReturnResponderErrors"
             "SSLStaplingStandardCacheTimeout"
             "SSLStrictSNIVHostCheck"
             "SSLUserName"
             "SSLUseStapling"
             "SSLVerifyClient"
             "SSLVerifyDepth"
             "ExtendedStatus"                                  ; mod_status
             "Substitute"                                      ; mod_substitute
             "SubstituteMaxLineLength"
             "SuexecUserGroup"                                 ; mod_suexec
             "ChrootDir"                                       ; mod_unixd
             "Suexec"
             "UserDir"                                         ; mod_userdir
             "CookieDomain"                                    ; mod_usertrack
             "CookieExpires"
             "CookieName"
             "CookieStyle"
             "CookieTracking"
             "VirtualDocumentRoot"                             ; mod_vhost_alias
             "VirtualDocumentRootIP"
             "VirtualScriptAlias"
             "VirtualScriptAliasIP"
             "WatchdogInterval"                                ; mod_watchdog
             "xml2EncAlias"                                    ; mod_xml2enc
             "xml2EncDefault"
             "xml2StartParse"
             "CoreDumpDirectory"                               ; mpm_common
             "EnableExceptionHook"
             "GracefulShutdownTimeout"
             "Group"
             "Listen"
             "ListenBackLog"
             "LockFile"
             "MaxClients"
             "MaxConnectionsPerChild"
             "MaxMemFree"
             "MaxRequestsPerChild"
             "MaxRequestWorkers"
             "MaxSpareThreads"
             "MaxThreadsPerChild"
             "MinSpareThreads"
             "NumServers"
             "PidFile"
             "ReceiveBufferSize"
             "ScoreBoardFile"
             "SendBufferSize"
             "ServerLimit"
             "StartServers"
             "StartThreads"
             "ThreadLimit"
             "ThreadsPerChild"
             "User"
             "MaxClientsVHost"                                 ; mpm_itk
             "Listen"                                          ; mpm_netware
             "ListenBacklog"
             "MaxRequestsPerChild"
             "MaxSpareThreads"
             "MaxThreads"
             "MinSpareThreads"
             "SendBufferSize"
             "StartThreads"
             "ThreadStackSize"
             "AssignUserId"                                    ; mpm_perchild
             "ChildPerUserId"
             "CoreDumpDirectory"
             "Group"
             "Listen"
             "ListenBacklog"
             "LockFile"
             "MaxRequestsPerChild"
             "MaxSpareThreads"
             "MaxThreadsPerChild"
             "MinSpareThreads"
             "NumServers"
             "PidFile"
             "ScoreBoardFile"
             "SendBufferSize"
             "StartThreads"
             "User"
             "ServerEnvironment"                               ; mpm_peruser
             "AcceptMutex"                                     ; mpm_prefork
             "CoreDumpDirectory"
             "Listen"
             "ListenBacklog"
             "LockFile"
             "MaxRequestsPerChild"
             "PidFile"
             "ScoreBoardFile"
             "SendBufferSize"
             "ServerLimit"
             "StartServers"
             "User"
             "CoreDumpDirectory"                               ; mpm_winnt
             "Listen"
             "ListenBacklog"
             "MaxRequestsPerChild"
             "PidFile"
             "SendBufferSize"
             "ThreadsPerChild"
             "CoreDumpDirectory"                               ; mpm_worker
             "Group"
             "Listen"
             "ListenBacklog"
             "LockFile"
             "MaxClients"
             "MaxRequestsPerChild"
             "MaxSpareThreads"
             "MinSpareThreads"
             "PidFile"
             "ScoreBoardFile"
             "SendBufferSize"
             "ServerLimit"
             "StartServers"
             "ThreadLimit"
             "ThreadsPerChild"
             "User"
             "DefaultMode"                                     ; (obsolete)
             "DocTitle"
             "DocTrailer"
             "HeadPrefix"
             "HeadSuffix"
             "HideSys"
             "HideURL"
             "HTMLDir"
             "HTTPLogFile"
             "LastURLs"
             "PrivateDir"
             "TopSites"
             "TopURLs")
           'words))
        1 'font-lock-keyword-face)
       (,(regexp-opt
          '("Off"
            "On"
            "add"                                             ; (general)
            "All"
            "allow"
            "any"
            "append"
            "AuthConfig"
            "Basic"
            "CONNECT"
            "default"
            "DELETE"
            "deny"
            "Digest"
            "double"
            "downgrade-1.0"
            "email"
            "env"
            "error"
            "ExecCGI"
            "FancyIndexing"
            "fcntl"
            "FileInfo"
            "flock"
            "FollowSymLinks"
            "force-response-1.0"
            "formatted"
            "from"
            "full"
            "GET"
            "gone"
            "group"
            "IconsAreLinks"
            "Includes"
            "IncludesNOEXEC"
            "Indexes"
            "inetd"
            "inherit"
            "INode"
            "Limit"
            "map"
            "Minimal"
            "MTime"
            "MultiViews"
            "mutual-failure"
            "nocontent"
            "nokeepalive"
            "none"
            "off"
            "on"
            "Options"
            "OS"
            "os2sem"
            "permanent"
            "POST"
            "pthread"
            "PUT"
            "referer"
            "ScanHTMLTitles"
            "seeother"
            "semi-formatted"
            "set"
            "standalone"
            "SuppressDescription"
            "SuppressLastModified"
            "SuppressSize"
            "SymLinksIfOwnerMatch"
            "sysvsem"
            "temp"
            "tpfcore"
            "unformatted"
            "unset"
            "URL"
            "user"
            "uslock"
            "valid-user"
            "3DES"                                            ; cipher stuff
            "ADH"
            "ADH-DES-CBC-SHA"
            "ADH-DES-CBC3-SHA"
            "ADH-RC4-MD"
            "ADH-RC4-MD5"
            "aDSS"
            "aNULL"
            "aRSA"
            "DES"
            "DES-CBC-MD5"
            "DES-CBC-SHA"
            "DES-CBC3-MD5"
            "DES-CBC3-SHA"
            "DES-CFB-M1"
            "DH"
            "DH-DSS-DES-CBC-SHA"
            "DH-DSS-DES-CBC3-SHA"
            "DH-RSA-DES-CBC-SHA"
            "DH-RSA-DES-CBC3-SHA"
            "DSS"
            "EDH"
            "EDH-DSS-DES-CBC-SHA"
            "EDH-DSS-DES-CBC3-SHA"
            "EDH-RSA-DES-CBC-SHA"
            "EDH-RSA-DES-CBC3-SHA"
            "egd"
            "eNULL"
            "EXP"
            "EXP-ADH-DES-CBC-SHA"
            "EXP-ADH-RC4-MD5"
            "EXP-DES-CBC-SHA"
            "EXP-DH-DSS-DES-CBC-SHA"
            "EXP-DH-RSA-DES-CBC-SHA"
            "EXP-EDH-DSS-DES-CBC-SHA"
            "EXP-EDH-RSA-DES-CBC"
            "EXP-EDH-RSA-DES-CBC-SHA"
            "EXP-RC2-CBC-MD5"
            "EXP-RC4-MD5"
            "EXPORT40"
            "EXPORT56"
            "file"
            "FZA-FZA-CBC-SHA"
            "FZA-NULL-SHA"
            "FZA-RC4-SHA"
            "HIGH"
            "IDEA"
            "IDEA-CBC-MD5"
            "IDEA-CBC-SHA"
            "kDHd"
            "kDHr"
            "kEDH"
            "kRSA"
            "LOW"
            "MD5"
            "MEDIUM"
            "NULL"
            "NULL-MD5"
            "NULL-SHA"
            "RC2"
            "RC2-CBC-MD5"
            "RC4"
            "RC4-64-MD5"
            "RC4-MD5"
            "RC4-SHA"
            "RSA"
            "SHA"
            "SHA1"
            "send-as-is"                                      ; mod_asis
            "cgi-script"                                      ; mod_cgi
            "imap-file"                                       ; mod_imap
            "server-info"                                     ; mod_info
            "isapi-isa"                                       ; mod_isapi
            "ldap-status"                                     ; mod_ldap
            "perl-script"                                     ; mod_perl
            "python-program"                                  ; mod_python
            "All"                                             ; mod_ssl
            "builtin"
            "CompatEnvVars"
            "connect"
            "dbm"
            "debug"
            "egd"
            "error"
            "exec"
            "ExportCertData"
            "FakeBasicAuth"
            "file"
            "info"
            "none"
            "off"
            "on"
            "optional"
            "optional_no_ca"
            "OptRenegotiate"
            "require"
            "sem"
            "shm"
            "shmcb"
            "shmht"
            "ssl-accurate-shutdown"
            "ssl-unclean-shutdown"
            "SSLv2"
            "SSLv3"
            "startup"
            "StdEnvVars"
            "StrictRequire"
            "TLSv1"
            "trace"
            "warn"
            "server-status"                                   ; mod_status
            )
          'words)
        1 'font-lock-type-face))))
  "Expressions to highlight in Apache config buffers.")

(defun apache-indent-line ()
  "Indent current line of Apache code."
  (interactive)
  (let ((savep (> (current-column) (current-indentation)))
        (indent (max (apache-calculate-indentation) 0)))
    (if savep
        (save-excursion (indent-line-to indent))
      (indent-line-to indent))))

(defun apache-previous-indentation ()
  "Return the previous (non-empty/comment) indentation.  Doesn't save position."
  (let (indent)
    (while (and (null indent)
                (zerop (forward-line -1)))
      (unless (looking-at "[ \t]*\\(#\\|$\\)")
        (setq indent (current-indentation))))
    (or indent 0)))

(defun apache-calculate-indentation ()
  "Return the amount the current line should be indented."
  (save-excursion
    (forward-line 0)
    (if (bobp)
        0
      (let ((ends-section-p (looking-at "[ \t]*</"))
            (indent (apache-previous-indentation)) ; moves point!
            (previous-starts-section-p (looking-at "[ \t]*<[^/]")))
        (if ends-section-p
            (setq indent (- indent apache-indent-level)))
        (if previous-starts-section-p
            (setq indent (+ indent apache-indent-level)))
        indent))))

;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("/\\.htaccess\\'" . apache-mode))
  (add-to-list 'auto-mode-alist '("/\\(?:access\\|httpd\\|srm\\)\\.conf\\'" . apache-mode))
  (add-to-list 'auto-mode-alist '("/apache2/.+\\.conf\\'" . apache-mode))
  (add-to-list 'auto-mode-alist '("/httpd/conf/.+\\.conf\\'" . apache-mode))
  (add-to-list 'auto-mode-alist '("/apache2/sites-\\(?:available\\|enabled\\)/" . apache-mode)))

(provide 'apache-mode)
;;; apache-mode.el ends here
