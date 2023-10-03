This package implements a W3C WebDriver compatible client,
known as a "local end", in ELisp.

See the specification in https://www.w3.org/TR/webdriver/

This means you can remotely control any web browser that implements the
server side of the protocol linked above.

To start controlling a remote browser, you can:
- Create an instance of `webdriver-session' and run
`webdriver-session-start'.  This will use the value stored in
`webdriver-default-service' to start running a compatible service.
- Alternatively, you can create a custom instance of `webdriver-service'
and pass it as a :service argument when creating an instance of
`webdriver-session'.

See the list of endpoints supported with the corresponding ELisp function
to see the things you can do.

List of Endpoints supported:
Command Name -> ELisp function
New Session -> `webdriver-session-start'
Delete Session -> `webdriver-session-stop'
Status -> `webdriver-service-status'
Get Timeouts -> `webdriver-get-timeouts'
Set Timeouts -> `webdriver-set-timeouts'
Navigate To -> `webdriver-goto-url'
Get Current URL -> `webdriver-get-current-url'
Back -> `webdriver-go-back'
Forward -> `webdriver-go-forward'
Refresh -> `webdriver-refresh'
Get Title -> `webdriver-get-title'
Get Window Handle -> `webdriver-get-window-handle'
Close Window -> `webdriver-close-window'
Switch to Window -> `webdriver-switch-to-window'
Get Window Handles -> `webdriver-get-window-handles'
New Window -> `webdriver-create-new-window'
Switch To Frame -> `webdriver-switch-to-frame'
Switch To Parent Frame -> `webdriver-switch-to-parent-frame'
Get Window Rect -> `webdriver-get-window-rect'
Set Window Rect -> `webdriver-set-window-rect'
Maximize Window -> `webdriver-maximize-window'
Minimize Window -> `webdriver-minimize-window'
Fullscreen Window -> `webdriver-fullscreen-window'
Get Active Element -> `webdriver-get-active-element'
Get Element Shadow Root -> `webdriver-get-element-shadow-root'
Find Element -> `webdriver-find-element'
Find Elements -> `webdriver-find-elements'
Find Element From Element -> `webdriver-find-element-from-element'
Find Elements From Element -> `webdriver-find-elements-from-element'
Find Element From Shadow Root -> `webdriver-find-element-from-shadow-root'
Find Elements From Shadow Root -> `webdriver-find-elements-from-shadow-root'
Is Element Selected -> `webdriver-element-selected-p'
Get Element Attribute -> `webdriver-get-element-attribute'
Get Element Property -> `webdriver-get-element-property'
Get Element CSS Value -> `webdriver-get-element-css-value'
Get Element Text -> `webdriver-get-element-text'
Get Element Tag Name -> `webdriver-get-element-tag-name'
Get Element Rect -> `webdriver-get-element-rect'
Is Element Enabled -> `webdriver-element-enabled-p'
Get Computed Role -> `webdriver-element-get-computed-role'
Get Computed Label -> `webdriver-element-get-computed-label'
Element Click -> `webdriver-element-click'
Element Clear -> `webdriver-element-clear'
Element Send Keys -> `webdriver-element-send-keys'
Get Page Source -> `webdriver-get-page-source'
Execute Script -> `webdriver-execute-synchronous-script'
Execute Async Script -> `webdriver-execute-asynchronous-script'
Get All Cookies -> `webdriver-get-all-cookies'
Get Named Cookie -> `webdriver-get-cookie'
Add Cookie -> `webdriver-add-cookie'
Delete Cookie -> `webdriver-delete-cookie'
Delete All Cookies -> `webdriver-delete-all-cookies'
Perform Actions -> `webdriver-perform-actions'
Release Actions -> `webdriver-release-actions'
Dismiss Alert -> `webdriver-dismiss-alert'
Accept Alert -> `webdriver-accept-alert'
Get Alert Text -> `webdriver-get-alert-text'
Send Alert Text -> `webdriver-send-alert-text'
Take Screenshot -> `webdriver-take-screenshot'
Take Element Screenshot -> `webdriver-take-element-screenshot'
Print Page -> `webdriver-print-page'

Here is a usage example:
(let ((session (make-instance 'webdriver-session)))
  (webdriver-session-start session)
  (webdriver-goto-url session "https://www.example.org")
  (let ((element
         (webdriver-find-element session (make-instance 'webdriver-by
                                                        :strategy "tag name"
                                                        :selector "h1"))))
    (message (webdriver-get-element-text session element)))
  (webdriver-session-stop session))

If you want to request the remote end for certain capabilities, you can do
that using a `webdriver-capabilities' object, and adding options to it.
For example, for a headless Firefox session, you can use:
(let ((caps (make-instance 'webdriver-capabilities-firefox)))
  (webdriver-capabilities-firefox-add-arg caps "-headless" t)
  (make-instance 'webdriver-session :requested-capabilities caps))
This adds the "-headless" argument as part of :args in the
:moz:firefoxOptions.  The third argument t says to add this requested
capability as an alwaysMatch capability.
