Table of Contents
─────────────────

1. Emacs Bluetooth Mode
.. 1. Usage
..... 1. Key bindings
..... 2. Notes
.. 2. Plugins
..... 1. Bluetooth battery plugin
.. 3. News
..... 1. Bluetooth mode 0.4


1 Emacs Bluetooth Mode
══════════════════════

  This package provides a simple Bluetooth mode that can be used to
  manage Bluetooth devices on GNU/Linux using GNU Emacs.

  Implemented features are:
  • (un-)pairing devices
  • (dis-)connecting devices or single profiles of devices
  • discovery mode
  • setting device properties (alias, blocked, trusted)
  • setting adapter properties (powered, discoverable, pairable)
  • showing device information (alias, address, RSSI, class, services)
  • Imenu integration
  • a experimental plugin API to be used by other packages
  • a battery plugin that will show battery percentage and can issue a
    low battery warning (and serves as a minimum example of a plugin)

  The implementation is based on the Bluez DBus interface (see
  <https://www.bluez.org>).


1.1 Usage
─────────

  To install it, invoke `M-x package-install-file' on `bluetooth.el' and
  then use it with `M-x bluetooth-list-devices'.

  To use functions of this package from other code, call
  `bluetooth-init' from your Emacs init file.

  The mode assumes availability of Bluez on D-Bus.  Depending on the
  system configuration, Bluez may use the `:system' bus or the
  `:session' bus.  This can be configured by using `M-x customize' to
  set the `bluetooth-bluez-bus' variable in the
  `Communication/Bluetooth' menu to either the symbol `:system' or
  `:session', as appropriate.


1.1.1 Key bindings
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The following table lists the default key bindings:
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Key          Command                                                                                                
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   P            pair with a device                                                                                     
   c            connect to a device (may start pairing procedure); with a prefix argument, connect to a single profile 
   d            disconnect a device; with a prefix argument, disconnect a single profile                               
   a            set or reset a device's alias                                                                          
   t            toggle the trusted property of a device                                                                
   b            toggle the blocked property of a device (disconnects connected device)                                 
   k            remove a device (will disconnect and unpair)                                                           
   i            show device information, such as RSSI value, device class and services                                 
   A            show host adapter information                                                                          
   r            start discovery (scan) mode                                                                            
   R            stop discovery (scan) mode                                                                             
   D            toggle the discoverable property of the adapter                                                        
   x            toggle the pairable property of the adapter                                                            
   s            toggle the power supply of the adapter                                                                 
   n            next line                                                                                              
   p            previous line                                                                                          
   <            go to the beginning of the list                                                                        
   >            go to the end of the list                                                                              
   g            revert the buffer; this queries the bus for accessible devices                                         
   S            sort list by column at point                                                                           
   F            toggle device information follow mode                                                                  
   M            bring up the mode's transient menu                                                                     
   h or ?       describe the mode                                                                                      
   q            bury the buffer                                                                                        
   `M-x imenu'  invoke imenu to select a device                                                                        
   Q            Shutdown Bluetooth mode                                                                                
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1.1.2 Notes
╌╌╌╌╌╌╌╌╌╌╌

  • Discoverable mode is usually deactivated after 3 minutes, as
    configured in the `bluetoothd' configuration file
    (e.g. `/etc/bluetooth/main.conf'.)
  • Blocking a connected device will disconnect it.
  • If a device is trusted, authorisation of services is not required
    when connecting; devices are not trusted automatically.
  • Adapter commands always use the first adapter found in the system
    (i.e. reported by Bluez.)


1.2 Plugins
───────────

  Bluetooth mode offers an experimental plugin API, see
  `bluetooth-plugin.el' and `bluetooth-battery.el' for an example.
  ‘Experimental’ means that the API will likely change a few times.  But
  don't let that discourage you from writing a plugin, as any feedback
  from plugin authors will help improve and eventually stabilize the
  API.


1.2.1 Bluetooth battery plugin
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The battery plugin shows the battery information for devices that
  support the `org.bluez.Battery1' interface.  It will also warn about
  low battery levels if `bluetooth-battery-display-warning' is t and
  according to the level chosen with `bluetooth-battery-warning-level'.

  Note that some devices with batteries may not implement this
  interface.  This is sometimes true for HID devices that expose battery
  information through the HID interface, which is not used by
  `bluetooth-battery.el'.


1.3 News
────────

1.3.1 Bluetooth mode 0.4
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This version
  • reorganized the sources into several files
  • added a plugin mechanism
  • added battery plugin
  • added follow mode
  • added initialization function so Bluetooth mode can be initialized
    without bringing up the device list view
  • added error messages and command feedback
  • made list view customizable
  • cleaned up the code and made it more useful to other
    packages/plugins
  • a transient menu for main functions and plugins
