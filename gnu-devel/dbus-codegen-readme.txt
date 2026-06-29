This package provides macros and functions to make D-Bus
client/server implementation easy, inspired by the `gdbus-codegen'
utility in GLib.  To get it work, `lexical-binding' must be
enabled.

* Client support

A proxy object representing a D-Bus client can be defined with
either `dbus-codegen-define-proxy' or `dbus-codegen-make-proxy'.

`dbus-codegen-define-proxy' takes a static XML definition of a
D-Bus service and generates code at compile time.  This is good for
stable D-Bus services.  On the other hand,
`dbus-codegen-make-proxy' uses D-Bus introspection and retrieves a
D-Bus service definition from a running service itself.  This is
good for debugging or for unstable D-Bus services.

** Example

Suppose the following code:

(dbus-codegen-define-proxy test-proxy
                           "\
<node>
  <interface name='org.example.Test'>
    <method name='OpenFile'>
      <arg type='s' name='path' direction='in'/>
    </method>
    <signal name='Changed'>
      <arg type='s' name='a_string'/>
    </signal>
    <property type='s' name='Content' access='read'/>
  </interface>
</node>"
                           "org.example.Test")

The `dbus-codegen-define-proxy' macro expands to a definition a
struct `test-proxy' with a slot `content', which corresponds to the
"Content" property.  The slot value will be initialized when the
proxy is created and updated when the server sends a notification.
The proxy can always retrieve the value with the function
`PROXY-retrieve-PROPERTY-property'.

The macro also defines the following wrapper functions:

- `test-proxy-create'
  constructor of the proxy
- `test-proxy-destroy'
  destructor of the proxy
- `test-proxy-open-file'
  wrapper around calling the "OpenFile" method
- `test-proxy-open-file-asynchronously'
  asynchronous wrapper around calling the "OpenFile" method
- `test-proxy-send-changed-signal'
  wrapper around sending the "Changed" signal
- `test-proxy-register-changed-signal'
  wrapper around registering a handler for the "Changed" signal
- `test-proxy-retrieve-content-property'
  retrieve the value of the "Content" property

In addition to those, the macro also defines a generic function
`test-proxy-handle-changed-signal' to allow a class-wide signal
handler definition.

To register a class-wide signal handler, define a method
`test-proxy-handle-changed-signal' with `cl-defmethod', like this:

(cl-defmethod test-proxy-handle-changed-signal ((proxy test-proxy) string)
  ... do something with PROXY and STRING ...)

* Server support

A skeleton object representing a D-Bus server can be defined with
`dbus-codegen-define-skeleton'.

`dbus-codegen-define-skeleton' takes a static XML definition of a
D-Bus service and generates code at compile time.

** Example

Suppose the following code:

(dbus-codegen-define-skeleton test-skeleton
                           "\
<node>
  <interface name='org.example.Test'>
    <method name='OpenFile'>
      <arg type='s' name='path' direction='in'/>
    </method>
    <signal name='Changed'>
      <arg type='s' name='a_string'/>
    </signal>
    <property type='s' name='Content' access='read'/>
  </interface>
</node>"
                           "org.example.Test")

The `dbus-codegen-define-skeleton' macro expands to a definition a
struct `test-skeleton' with a slot `content', which corresponds to the
"Content" property.

The macro also defines the following wrapper functions:

- `test-skeleton-create'
  constructor of the skeleton
- `test-skeleton-destroy'
  destructor of the skeleton
- `test-skeleton-register-open-file-method'
  wrapper around registering a handler for the "OpenFile" method
- `test-skeleton-send-changed-signal'
  wrapper around sending the "Changed" signal
- `test-skeleton-register-changed-signal'
  wrapper around registering a handler for the "Changed" signal
- `test-skeleton-register-content-property'
  wrapper around registering a value of the "Content" property

In addition to those, the macro also defines a generic function
`test-skeleton-handle-open-file-method' to allow a class-wide method
handler definition.

To register a class-wide method handler, define a method
`test-skeleton-handle-open-file-method' with `cl-defmethod', like this:

(cl-defmethod test-skeleton-handle-open-file-method ((skeleton test-skeleton)
                                                     string)
  ... do something with SKELETON and STRING ...)

* TODO

- function documentation generation from annotations