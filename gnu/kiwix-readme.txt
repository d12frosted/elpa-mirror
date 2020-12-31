* Intro

Searching offline Wikipedia through Kiwix.

[[kiwix.el Ivy async completion.png]]

[[kiwix.el with EWW.png]]

This =kiwix.el= supports query =kiwix-tools='s =kiwix-serve= server through URL API.

The =kiwix-serve= server can be started from command-line if you have =kiwix-tools=
installed, or from Docker container [fn:1].

* Install

** Install Kiwix

*** Docker

Reference this issue as background info: https://github.com/kiwix/kiwix-tools/issues/257

#+begin_src sh :eval no
docker pull kiwix/kiwix-serve
#+end_src

*** Flatpak
    :PROPERTIES:
    :URL:      https://wiki.kiwix.org/wiki/Flatpak
    :END:

#+begin_src org
,#+begin_src sh :dir /sudo::/tmp
# Install Flatpak (on Debian/Ubuntu)
sudo pacman -S flatpak

# Install Flathub (for the dependencies)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Download the Kiwix Desktop Flatpak
wget https://download.kiwix.org/release/kiwix-desktop/org.kiwix.desktop.2.0-beta2.flatpak
,#+end_src

,#+begin_src sh :dir /tmp :eval no
# Install Kiwix Desktop
flatpak install org.kiwix.desktop.2.0-beta2.flatpak
,#+end_src

,#+begin_src sh :eval no
# Run Kiwix Desktop (but Kiwix should be available through your app launcher anyway)
flatpak run org.kiwix.desktop
,#+end_src
#+end_src

*** Download

- https://sourceforge.net/projects/kiwix
- http://www.kiwix.org/wiki/Software

*** Linux

**** Arch

#+begin_src org
,#+begin_src sh :dir /sudo:: :results none
aurman -S --noconfirm kiwix-bin
,#+end_src
#+end_src

*** Web Browser

**** Firefox

https://addons.mozilla.org/en-US/firefox/addon/kiwix-offline/

**** Chrome

https://chrome.google.com/webstore/detail/kiwix/donaljnlmapmngakoipdmehbfcioahhk

** MELPA

#+begin_src emacs-lisp :eval no
(use-package kiwix
  :ensure t
  :after org
  :commands (kiwix-launch-server kiwix-at-point)
  :custom ((kiwix-server-use-docker t)
           (kiwix-server-port 8089)
           (kiwix-default-library "wikipedia_en_all_2016-02.zim"))
  :hook (org-load . org-kiwix-setup-link))
#+end_src

* Setup

If you use kiwix-serve Docker container, you can create an Systemd unit service
to auto start Docker container. Here is the systemd unit config file:

** Dockerize kiwix-tools (kiwix-serve, etc)
   :PROPERTIES:
   :URL:      https://hub.docker.com/r/kiwix/kiwix-serve
   :ISSUE:    https://github.com/kiwix/kiwix-tools/issues/257
   :Pull-Request: https://github.com/kiwix/kiwix-tools/pull/268
   :Attachments: screenshot_1.png screenshot_2.png
   :ID:       e82e194f-2cc8-45eb-a378-f8bd6d7c6b1a
   :END:

#+begin_src sh :async
docker pull kiwix/kiwix-serve
#+end_src

#+RESULTS[<2019-03-24 08:33:29> ace542940af6e465f90f0a3a8515e876fd267ad5]:
#+begin_example
Using default tag: latest
latest: Pulling from kiwix/kiwix-serve
8e402f1a9c57: Pulling fs layer
7024865ce0e2: Pulling fs layer
ad4c9cfc45dc: Pulling fs layer
c4d62acdb073: Pulling fs layer
c4d62acdb073: Waiting
8e402f1a9c57: Verifying Checksum
8e402f1a9c57: Download complete
7024865ce0e2: Verifying Checksum
7024865ce0e2: Download complete
8e402f1a9c57: Pull complete
7024865ce0e2: Pull complete
c4d62acdb073: Verifying Checksum
c4d62acdb073: Download complete
ad4c9cfc45dc: Verifying Checksum
ad4c9cfc45dc: Download complete
ad4c9cfc45dc: Pull complete
c4d62acdb073: Pull complete
Digest: sha256:8837effa1a4fce750dc373d58b47063b368228331ccacb267c6ae7d3e311e66c
Status: Downloaded newer image for kiwix/kiwix-serve:latest
#+end_example

https://github.com/kiwix/kiwix-tools/blob/master/docker/server/Dockerfile

#+begin_src org
,#+begin_src dockerfile
FROM alpine:latest
LABEL maintainer Emmanuel Engelhart <kelson@kiwix.org>

# Install kiwix-serve
WORKDIR /
RUN apk add --no-cache curl bzip2
RUN curl -kL https://download.kiwix.org/release/kiwix-tools/kiwix-tools_linux-x86_64-1.1.0.tar.gz | tar -xz && \
    mv kiwix-tools*/kiwix-serve /usr/local/bin && \
    rm -r kiwix-tools*

# Configure kiwix-serve
VOLUME /data
ENV PORT 80
EXPOSE $PORT

# Run kiwix-serve
WORKDIR /data
ENTRYPOINT ["/usr/local/bin/kiwix-serve", "--port", "$PORT"]
,#+end_src
#+end_src

How to run?

Given =wikipedia.zim= ([[#ZIM][Zim database files]]) resides in =/tmp/zim/=, execute the
following command:

#+begin_src sh :eval no
# if you don't have libraries index file "library.xml"
docker container run -d --name kiwix-serve -v /tmp/zim:/data -p 8080:80 kiwix/kiwix-serve wikipedia.zim
# if you have libraries index file "library.xml"
docker container run -d --name kiwix-serve -v /tmp/zim:/data -p 8080:80 kiwix/kiwix-serve --library library.xml
#+end_src

*NOTE*: You can generate the libraries index file "library.xml" with following command:

#+begin_src sh
cd ~/.www.kiwix.org/kiwix/nsz6b6tr.default/data/library/

for zim in $(ls *.zim); do
  kiwix-manage library.xml add $zim
done
#+end_src

*NOTE*: Using the libraries index file method, you can have all libraries served
in Docker container instead of just one library.

If you put ZIM files in other places not =/tmp/zim/=, you can use follow my command:

#+NAME: create kiwix-serve container with custom port
#+begin_src sh :session "*kiwix-serve*"
docker container run -d \
       --name kiwix-serve \
       -v ~/.www.kiwix.org/kiwix/nsz6b6tr.default/data/library:/data \
       -p 8089:80 \
       kiwix/kiwix-serve wikipedia_zh_all_2015-11.zim
#+end_src

Visit http://localhost:8080 or http://localhost:8089 (if you exposed different
port).

For easy launch the docker run command, you can add command alias in shell profile:

#+begin_src shell :eval no
alias kiwix-docker-wikipedia_zh_all="docker container run --name kiwix-serve -d -v ~/.www.kiwix.org/kiwix/nsz6b6tr.default/data/library:/data -p 8089:80 kiwix/kiwix-serve wikipedia_zh_all_2015-11.zim"
alias kiwix-docker-wikipedia="docker container run --name kiwix-serve -d -v ~/.www.kiwix.org/kiwix/nsz6b6tr.default/data/library:/data -p 8089:80 kiwix/kiwix-serve wikipedia.zim"
#+end_src

*** create a systemd unit for kiwix-serve Docker service

#+begin_src org
,#+begin_src systemd :tangle "~/.config/systemd/user/kiwix-serve.timer"
[Unit]
Description=Start kiwx-serve Docker container server at system startup after 5 minutes

[Timer]
OnBootSec=2min
Unit=kiwix-serve.service

[Install]
WantedBy=default.target
,#+end_src

,#+begin_src systemd :tangle "~/.config/systemd/user/kiwix-serve.service"
[Unit]
Description=kiwix-serve Docker server
After=docker.service

[Service]
Type=simple
ExecStart=/usr/bin/docker container start -i kiwix-serve
ExecStop=/usr/bin/docker container stop kiwix-serve

[Install]
WantedBy=default.target
,#+end_src
#+end_src

*NOTE*: You need to use option =-i= for =docker container start= command to avoid
systemd auto exit and stop =kiwix-serve= container.

#+begin_src sh :results output
systemctl --user enable kiwix-serve.timer
systemctl --user status kiwix-serve.timer | cat
#+end_src

#+RESULTS[<2019-03-24 11:45:40> 6470584177f091e79067f9fd96a97c340e00a41f]:
: ● kiwix-serve.timer - Start kiwx-serve Docker container server at system startup after 5 minutes
:    Loaded: loaded (/home/stardiviner/.config/systemd/user/kiwix-serve.timer; enabled; vendor preset: enabled)
:    Active: inactive (dead)
:   Trigger: n/a

#+begin_src sh
systemctl --user start kiwix-serve.service
#+end_src

#+begin_src sh
systemctl --user status kiwix-serve.service | cat
#+end_src

#+RESULTS[<2019-03-24 12:00:49> 10a33f8521fa2c72e8c1107559e1fb18b58d7da2]:
: ● kiwix-serve.service - kiwix-serve Docker server
:    Loaded: loaded (/home/stardiviner/.config/systemd/user/kiwix-serve.service; disabled; vendor preset: enabled)
:    Active: active (running) since Sun 2019-03-24 12:00:14 CST; 34s ago
:  Main PID: 2587 (docker)
:    CGroup: /user.slice/user-1000.slice/user@1000.service/kiwix-serve.service
:            └─2587 /usr/bin/docker container start -i kiwix-serve
: 
: Mar 24 12:00:14 dark systemd[694]: Started kiwix-serve Docker server.

*NOTE*: Because =kiwix-serve.service= use command =docker container start
kiwix-serve=, so that the container =kiwix-serve= must already been created by
[[create kiwix-serve container with custom port][this command]], you can check whether the container is created:

#+begin_src sh :results output
docker container ls | head -n 1
docker container ls --all | grep "kiwix-serve" | cat
#+end_src

#+RESULTS[<2019-03-24 11:50:36> e28015e8e78015623bd53ae596015949dc80c549]:
: CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
: b47533ecd7f6        kiwix/kiwix-serve               "/usr/local/bin/kiwi…"   3 hours ago         Exited (137) 2 minutes ago                                      kiwix-serve
: e2f201e655ac        kiwix/kiwix-serve               "/usr/local/bin/kiwi…"   3 hours ago         Created                                                         distracted_hofstadter

* Load

** use-package

#+begin_src emacs-lisp
(use-package kiwix
  :ensure t
  :after org
  :commands (kiwix-launch-server kiwix-at-point)
  :init (require 'org-kiwix)
  (setq kiwix-server-use-docker t
              kiwix-server-port 8089
              kiwix-default-library "wikipedia_en_all_2016-02.zim" ; "wikipedia_zh_all_2015-11.zim"
              kiwix-default-browser-function 'eww))
#+end_src

* Usage

** Use in Emacs

=[M-x kiwix-at-point]=

** Org Mode integration

=[C-c C-l]= to insert link.

The link format is like this:

#+BEGIN_EXAMPLE
[[wikipedia:(library):search][description]]
#+END_EXAMPLE

The =(library)= can be =wikipedia_en=, =wikipedia_zh=, =wiktionary_en=, or =en=, =zh= etc.

** EWW integration

Set following option in your config to use EWW in Emacs as your default _for
Kiwix only_.

#+begin_src emacs-lisp
(setq kiwix-default-browser-function 'eww-browse-url)
#+end_src

#+RESULTS[<2019-10-15 18:32:09> 3b9749599d792fb0ea5cd3566095ae16f1fc7f30]:
: eww-browse-url

[[kiwix.el with EWW.png]]

** Async search completion keywords candidates

[[kiwix.el Ivy async completion.png]]

* Changelog

** DONE implemented async instantly input suggestion completion in Ivy
   CLOSED: [2019-10-08 Tue 22:07]
   :LOGBOOK:
   - State "DONE"       from              [2019-10-08 Tue 22:07]
   :END:

This feature is very subtle :)

* Test

- [[wikipedia:Operations%20Research][Operations Research]] :: query contains space.
- [[wikipedia:Operations%20research][Operations research]] :: the second word is not capitalized.
- [[wikipedia:%E4%B8%AD%E5%9B%BD][中国]] :: non-english query
- [[wikipedia:meta-circular%20interpreter][meta-circular interpreter]] :: only capitalize the first word.

* How does this extension work?

** integrate with Emacs

*** core

I found Kiwix will return a URL like this:

#+BEGIN_EXAMPLE
http://127.0.0.1:8000/wikinews_en_all_2015-11/A/Big_Linux_Beta_3_released.html
____________________  _____________________  __  _____________________________

< server address >    < library >                <one of the returned results>
#+END_EXAMPLE

*** steps

1. auto start ~kiwix-serve~ HTTP server.
2. query/search on kiwix server.
   1. open kiwix server index page to input to search. (But this is slow, waste time)
   2. use http language binding library to query on kiwix HTTP server.
      1. select library in library list page.
      2. after load a library, simulate type query string in the search input
         box, the submit to search.
      3. return the result page HTML or page URL.
      4. view the result with page URL or page HTML with Emacs browser.

*** auto start kiwix HTTP server

Here is a simple script, you can put it in Linux "*auto-start*".

#+begin_src org
,#+BEGIN_SRC sh :tangle "~/scripts/kiwix-server.sh"
#!/usr/bin/env sh

/usr/lib/kiwix/bin/kiwix-serve --library --port=8000 --daemon ~/.www.kiwix.org/kiwix/8ip89lik.default/data/library/library.xml
,#+END_SRC
#+end_src

*** search

1. kiwix-search command -> return a list of results.

   #+begin_src org
   ,#+BEGIN_SRC sh
   /usr/lib/kiwix/bin/kiwix-search ~/.www.kiwix.org/kiwix/8ip89lik.default/data/index/wikinews_en_all_2015-11.zim.idx linux
   ,#+END_SRC
   #+end_src

2. use one element of list as part of the URL.

   http://127.0.0.1:8000/wikinews_en_all_2015-11/A/Big_Linux_Beta_3_released.html

   #+begin_src org
   ,#+BEGIN_SRC emacs-lisp
   (browse-url (concat "http://127.0.0.1:8000/" "LIBRARY" "/A/" "RESULT"))
   ,#+END_SRC
   #+end_src

*** more advanced?

If you want more advanced functions, you can use communicate kiwix HTTP server
with RESTful API.

- I don't know what Emacs library to use.
- Or you can use other language to do this, like Ruby or Python etc.

* Footnotes

[fn:1] https://github.com/kiwix/kiwix-tools/issues/257
