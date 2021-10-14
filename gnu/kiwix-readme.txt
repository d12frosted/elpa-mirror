Table of Contents
─────────────────

1. Intro
2. License & Contribution
3. Install
.. 1. Install Kiwix
..... 1. Docker
..... 2. Flatpak
..... 3. Download
..... 4. Linux
..... 5. Web Browser
.. 2. GNU ELPA & MELPA
4. Setup kiwix-serve
.. 1. Dockerize kiwix-tools (kiwix-serve, etc)
..... 1. create a systemd unit for kiwix-serve Docker service
5. Config
.. 1. use-package
..... 1. for local kiwix-serve server
..... 2. for local Docker server
..... 3. for remote Docker server
6. Usage
.. 1. Use in Emacs
.. 2. Org Mode integration
.. 3. EWW integration
.. 4. Async search completion keywords candidates
7. Changelog
.. 1. DONE implemented async instantly input suggestion completion in Ivy
8. Test
9. How does this extension work?
.. 1. integrate with Emacs
..... 1. core
..... 2. steps
..... 3. auto start kiwix HTTP server
..... 4. search
..... 5. more advanced?


<a href="<https://melpa.org/#/kiwix>"><img alt="MELPA"
src="<https://melpa.org/packages/kiwix-badge.svg>"></a>

<a href="<https://www.gnu.org/licenses/gpl-3.0>"><img
src="<https://img.shields.io/badge/License-GPLv3-blue.svg>"
alt="License: GPL v3" /></a>

<a href="<https://cla-assistant.io/stardiviner/kiwix.el>"><img
src="<https://cla-assistant.io/readme/badge/stardiviner/kiwix.el>"
alt="CLA assistant" /></a>


1 Intro
═══════

  Searching offline Wikipedia through Kiwix.





  This `kiwix.el' supports query `kiwix-tools''s `kiwix-serve' server
  through URL API.

  The `kiwix-serve' server can be started from command-line if you have
  `kiwix-tools' installed, or from Docker container [1].


2 License & Contribution
════════════════════════

  This kiwix.el is under GPLv3 license. If you want to contribute or
  Pull Request, you need to have signed FSF copyright paper. Here is the
  start

  <https://www.gnu.org/prep/maintain/maintain.html#Copyright-Papers>


3 Install
═════════

3.1 Install Kiwix
─────────────────

3.1.1 Docker
╌╌╌╌╌╌╌╌╌╌╌╌

  Reference this issue as background info:
  <https://github.com/kiwix/kiwix-tools/issues/257>

  ┌────
  │ docker pull kiwix/kiwix-serve
  └────


3.1.2 Flatpak
╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ #+begin_src sh :dir /sudo::/tmp
  │ # Install Flatpak (on Debian/Ubuntu)
  │ sudo pacman -S flatpak
  │ 
  │ # Install Flathub (for the dependencies)
  │ flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  │ 
  │ # Download the Kiwix Desktop Flatpak
  │ wget https://download.kiwix.org/release/kiwix-desktop/org.kiwix.desktop.2.0-beta2.flatpak
  │ #+end_src
  │ 
  │ #+begin_src sh :dir /tmp :eval no
  │ # Install Kiwix Desktop
  │ flatpak install org.kiwix.desktop.2.0-beta2.flatpak
  │ #+end_src
  │ 
  │ #+begin_src sh :eval no
  │ # Run Kiwix Desktop (but Kiwix should be available through your app launcher anyway)
  │ flatpak run org.kiwix.desktop
  │ #+end_src
  └────


3.1.3 Download
╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • <https://sourceforge.net/projects/kiwix>
  • <http://www.kiwix.org/wiki/Software>


3.1.4 Linux
╌╌╌╌╌╌╌╌╌╌╌

◊ 3.1.4.1 Arch

  ┌────
  │ #+begin_src sh :dir /sudo:: :results none
  │ aurman -S --noconfirm kiwix-bin
  │ #+end_src
  └────


3.1.5 Web Browser
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

◊ 3.1.5.1 Firefox

  <https://addons.mozilla.org/en-US/firefox/addon/kiwix-offline/>


◊ 3.1.5.2 Chrome

  <https://chrome.google.com/webstore/detail/kiwix/donaljnlmapmngakoipdmehbfcioahhk>


3.2 GNU ELPA & MELPA
────────────────────

  kiwix.el now is available on GNU ELPA & MELPA.

  • <https://elpa.gnu.org/packages/kiwix.html>
  • <https://melpa.org/#/kiwix>

  ┌────
  │ (use-package kiwix
  │   :ensure t
  │   :after org
  │   :commands (kiwix-launch-server kiwix-at-point)
  │   :custom ((kiwix-server-use-docker t)
  │ 	   (kiwix-server-port 8089)
  │ 	   (kiwix-default-library "wikipedia_en_all_2016-02.zim"))
  │   :hook (org-load . org-kiwix-setup-link))
  └────


4 Setup kiwix-serve
═══════════════════

  If you use kiwix-serve Docker container, you can create an Systemd
  unit service to auto start Docker container. Here is the systemd unit
  config file:


4.1 Dockerize kiwix-tools (kiwix-serve, etc)
────────────────────────────────────────────

  ┌────
  │ docker pull kiwix/kiwix-serve
  └────

  <https://github.com/kiwix/kiwix-tools/blob/master/docker/server/Dockerfile>

  ┌────
  │ #+begin_src dockerfile
  │ FROM alpine:latest
  │ LABEL maintainer Emmanuel Engelhart <kelson@kiwix.org>
  │ 
  │ # Install kiwix-serve
  │ WORKDIR /
  │ RUN apk add --no-cache curl bzip2
  │ RUN curl -kL https://download.kiwix.org/release/kiwix-tools/kiwix-tools_linux-x86_64-1.1.0.tar.gz | tar -xz && \
  │     mv kiwix-tools*/kiwix-serve /usr/local/bin && \
  │     rm -r kiwix-tools*
  │ 
  │ # Configure kiwix-serve
  │ VOLUME /data
  │ ENV PORT 80
  │ EXPOSE $PORT
  │ 
  │ # Run kiwix-serve
  │ WORKDIR /data
  │ ENTRYPOINT ["/usr/local/bin/kiwix-serve", "--port", "$PORT"]
  │ #+end_src
  └────

  How to run?

  Given `wikipedia.zim' () resides in `/tmp/zim/', execute the following
  command:

  ┌────
  │ # if you don't have libraries index file "library.xml"
  │ docker container run -d --name kiwix-serve -v /tmp/zim:/data -p 8080:80 kiwix/kiwix-serve wikipedia.zim
  │ # if you have libraries index file "library.xml"
  │ docker container run -d --name kiwix-serve -v /tmp/zim:/data -p 8080:80 kiwix/kiwix-serve --library library.xml
  └────

  *NOTE*: You can generate the libraries index file "library.xml" with
   following command:

  ┌────
  │ cd ~/.www.kiwix.org/kiwix/nsz6b6tr.default/data/library/
  │ 
  │ for zim in $(ls *.zim); do
  │   kiwix-manage library.xml add $zim
  │ done
  └────

  *NOTE*: Using the libraries index file method, you can have all
  libraries served in Docker container instead of just one library.

  If you put ZIM files in other places not `/tmp/zim/', you can use
  follow my command:

  ┌────
  │ docker container run -d \
  │        --name kiwix-serve \
  │        -v ~/.www.kiwix.org/kiwix/nsz6b6tr.default/data/library:/data \
  │        -p 8089:80 \
  │        kiwix/kiwix-serve wikipedia_zh_all_2015-11.zim
  └────

  Visit <http://localhost:8080> or <http://localhost:8089> (if you
  exposed different port).

  For easy launch the docker run command, you can add command alias in
  shell profile:

  ┌────
  │ alias kiwix-docker-wikipedia_zh_all="docker container run --name kiwix-serve -d -v ~/.www.kiwix.org/kiwix/nsz6b6tr.default/data/library:/data -p 8089:80 kiwix/kiwix-serve wikipedia_zh_all_2015-11.zim"
  │ alias kiwix-docker-wikipedia="docker container run --name kiwix-serve -d -v ~/.www.kiwix.org/kiwix/nsz6b6tr.default/data/library:/data -p 8089:80 kiwix/kiwix-serve wikipedia.zim"
  └────


4.1.1 create a systemd unit for kiwix-serve Docker service
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ #+begin_src systemd :tangle "~/.config/systemd/user/kiwix-serve.timer"
  │ [Unit]
  │ Description=Start kiwx-serve Docker container server at system startup after 5 minutes
  │ 
  │ [Timer]
  │ OnBootSec=2min
  │ Unit=kiwix-serve.service
  │ 
  │ [Install]
  │ WantedBy=default.target
  │ #+end_src
  │ 
  │ #+begin_src systemd :tangle "~/.config/systemd/user/kiwix-serve.service"
  │ [Unit]
  │ Description=kiwix-serve Docker server
  │ After=docker.service
  │ 
  │ [Service]
  │ Type=simple
  │ ExecStart=/usr/bin/docker container start -i kiwix-serve
  │ ExecStop=/usr/bin/docker container stop kiwix-serve
  │ 
  │ [Install]
  │ WantedBy=default.target
  │ #+end_src
  └────

  *NOTE*: You need to use option `-i' for `docker container start'
  command to avoid systemd auto exit and stop `kiwix-serve' container.

  ┌────
  │ systemctl --user enable kiwix-serve.timer
  │ systemctl --user status kiwix-serve.timer | cat
  └────

  ┌────
  │ systemctl --user start kiwix-serve.service
  └────

  ┌────
  │ systemctl --user status kiwix-serve.service | cat
  └────

  *NOTE*: Because `kiwix-serve.service' use command `docker container
  start kiwix-serve', so that the container `kiwix-serve' must already
  been created by [this command], you can check whether the container is
  created:

  ┌────
  │ docker container ls | head -n 1
  │ docker container ls --all | grep "kiwix-serve" | cat
  └────


[this command] See listing 1


5 Config
════════

5.1 use-package
───────────────

5.1.1 for local kiwix-serve server
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (use-package kiwix
  │   :ensure t
  │   :after org
  │   :commands (kiwix-launch-server kiwix-at-point)
  │   :bind (:map document-prefix ("w" . kiwix-at-point))
  │   :custom ((kiwix-server-type 'kiwix-serve-local)
  │ 	   (kiwix-server-url "http://127.0.0.1")
  │ 	   (kiwix-server-port 8089)
  │ 	   (kiwix-zim-dir (expand-file-name "/path/to/kiwix_zim_libraries")))
  │   :hook (org-load . org-kiwix-setup-link)
  │   :init (require 'org-kiwix)
  │   :config (add-hook 'org-load-hook #'org-kiwix-setup-link))
  └────


5.1.2 for local Docker server
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (use-package kiwix
  │   :ensure t
  │   :after org
  │   :commands (kiwix-launch-server kiwix-at-point)
  │   :bind (:map document-prefix ("w" . kiwix-at-point))
  │   :custom ((kiwix-server-type 'docker-local)
  │ 	   (kiwix-server-url "http://127.0.0.1")
  │ 	   (kiwix-server-port 8089)
  │ 	   (kiwix-zim-dir (expand-file-name "/path/to/kiwix_zim_libraries")))
  │   :hook (org-load . org-kiwix-setup-link)
  │   :init (require 'org-kiwix)
  │   :config (add-hook 'org-load-hook #'org-kiwix-setup-link))
  └────


5.1.3 for remote Docker server
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (use-package kiwix
  │   :ensure t
  │   :after org
  │   :commands (kiwix-launch-server kiwix-at-point)
  │   :bind (:map document-prefix ("w" . kiwix-at-point))
  │   :custom ((kiwix-server-type 'docker-remote)
  │ 	   (kiwix-server-url "http://192.168.31.251")
  │ 	   (kiwix-server-port 8089))
  │   :hook (org-load . org-kiwix-setup-link)
  │   :init (require 'org-kiwix)
  │   :config (add-hook 'org-load-hook #'org-kiwix-setup-link))
  └────


6 Usage
═══════

6.1 Use in Emacs
────────────────

  `[M-x kiwix-at-point]'


6.2 Org Mode integration
────────────────────────

  ┌────
  │ (require 'org-kiwix)
  └────

  `[C-c C-l]' to insert link.

  The link format is like this:

  ┌────
  │ [[wikipedia:(library):search][description]]
  └────

  The `(library)' can be `wikipedia_en', `wikipedia_zh',
  `wiktionary_en', or `en', `zh' etc.


6.3 EWW integration
───────────────────

  Set following option in your config to use EWW in Emacs as your
  default _for Kiwix only_.

  ┌────
  │ (setq kiwix-default-browser-function 'eww-browse-url)
  └────


6.4 Async search completion keywords candidates
───────────────────────────────────────────────


7 Changelog
═══════════

7.1 DONE implemented async instantly input suggestion completion in Ivy
───────────────────────────────────────────────────────────────────────

  This feature is very subtle :)


8 Test
══════


        query contains space.

        the second word is not capitalized.

        non-english query

        only capitalize the first word.


9 How does this extension work?
═══════════════════════════════

9.1 integrate with Emacs
────────────────────────

9.1.1 core
╌╌╌╌╌╌╌╌╌╌

  I found Kiwix will return a URL like this:

  ┌────
  │ http://127.0.0.1:8000/wikinews_en_all_2015-11/A/Big_Linux_Beta_3_released.html
  │ ____________________  _____________________  __  _____________________________
  │ 
  │ < server address >    < library >                <one of the returned results>
  └────


9.1.2 steps
╌╌╌╌╌╌╌╌╌╌╌

  1. auto start `kiwix-serve' HTTP server.
  2. query/search on kiwix server.
     1. open kiwix server index page to input to search. (But this is
        slow, waste time)
     2. use http language binding library to query on kiwix HTTP server.
        1. select library in library list page.
        2. after load a library, simulate type query string in the
           search input box, the submit to search.
        3. return the result page HTML or page URL.
        4. view the result with page URL or page HTML with Emacs
           browser.


9.1.3 auto start kiwix HTTP server
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Here is a simple script, you can put it in Linux "*auto-start*".

  ┌────
  │ #+BEGIN_SRC sh :tangle "~/scripts/kiwix-server.sh"
  │ #!/usr/bin/env sh
  │ 
  │ /usr/lib/kiwix/bin/kiwix-serve --library --port=8000 --daemon ~/.www.kiwix.org/kiwix/8ip89lik.default/data/library/library.xml
  │ #+END_SRC
  └────


9.1.4 search
╌╌╌╌╌╌╌╌╌╌╌╌

  1. kiwix-search command -> return a list of results.

     ┌────
     │ #+BEGIN_SRC sh
     │ /usr/lib/kiwix/bin/kiwix-search ~/.www.kiwix.org/kiwix/8ip89lik.default/data/index/wikinews_en_all_2015-11.zim.idx linux
     │ #+END_SRC
     └────

  2. use one element of list as part of the URL.

     <http://127.0.0.1:8000/wikinews_en_all_2015-11/A/Big_Linux_Beta_3_released.html>

     ┌────
     │ #+BEGIN_SRC emacs-lisp
     │ (browse-url (concat "http://127.0.0.1:8000/" "LIBRARY" "/A/" "RESULT"))
     │ #+END_SRC
     └────


9.1.5 more advanced?
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you want more advanced functions, you can use communicate kiwix
  HTTP server with RESTful API.

  • I don't know what Emacs library to use.
  • Or you can use other language to do this, like Ruby or Python etc.



Footnotes
─────────

[1] <https://github.com/kiwix/kiwix-tools/issues/257>
