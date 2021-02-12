This package lets you run and kill SSH tunnels.  To use it:

- Set the variable `ssh-tunnels-configurations', e.g.:

  (setq ssh-tunnels-configurations
        '((:name "my local tunnel"
           :local-port 1234
           :remote-port 3306
           :login "me@host")
          (:name "my remote tunnel"
           :type "-R"
           :local-port 1234
           :remote-port 3306
           :login "me@host")))

- Type M-x ssh-tunnels RET

- You should see the list of tunnels; running tunnels will have 'R'
  in their state column

- To run the tunnel at the current line, type r

- To kill a running tunnel, type k

- You may want to temporarily change a tunnel's local port.  To do
  that you may provide a prefix argument to the run command, for
  example by typing C-u 1235 r
