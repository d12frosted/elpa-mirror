Cabledolphin captures network traffic to and from Emacs Lisp
processes, and writes it into a PCAPNG file, which can be read by
tools such as tcpdump and Wireshark.

Since Cabledolphin extracts the data on the Emacs Lisp level, it
writes the packet capture in cleartext even if the connection is
TLS-encrypted.

While it doesn't get hold of actual packet headers, it synthesises
TCP/IP headers to the minimum extent required to keep Wireshark
happy.

Available commands:

- `cabledolphin-trace-new-connections': start capturing packets for
  any new connections whose name matches a certain regexp.

- `cabledolphin-trace-existing-connection': start capturing packets
  for an existing connection.

- `cabledolphin-set-pcap-file': change the file that data is
  written to.

- `cabledolphin-stop': stop capturing, and stop matching new
  connections.

If you prefer output in "classic" PCAP format, set
`cabledolphin-output-type' to `pcap' before calling
`cabledolphin-set-pcap-file'.
