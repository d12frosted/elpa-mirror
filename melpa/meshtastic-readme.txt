Emacs chat client for Meshtastic LoRa mesh networks.
Connects to a Meshtastic device over serial USB via a Python bridge.

Requires the meshtastic Python package:
  pip install meshtastic

Configure `meshtastic-serial-port' in your init file, then:

  M-x meshtastic           - welcome screen
  M-x meshtastic-channels  - list channels
  M-x meshtastic-nodes     - list nodes by hops

Messages received since the bridge started are buffered in memory
and shown when a chat buffer is opened.
