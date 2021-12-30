		       ━━━━━━━━━━━━━━━━━━━━━━━━━
			ORG-TRANSCLUSION README
		       ━━━━━━━━━━━━━━━━━━━━━━━━━


Org-transclusion lets you insert a copy of text content via a file link
or ID link within an Org file. It lets you have the same content present
in different buffers at the same time without copy-and-pasting it. Edit
the source of the content, and you can refresh the transcluded copies to
the up-to-date state. Org-transclusion keeps your files clear of the
transcluded copies, leaving only the links to the original content.

A complete [user manual] is available online or Emacs in-system as an
Info document (`C-h i' and find the `Org-transclusion' node).

For installation and minimum configuration, refer to [Installation]
below or the corresponding section in the user manual.

[Getting Started] in the user manual will get you started in 5 minutes.

Below are images and videos demonstrating some of the key features of
Org-transclusion.

<https://github.com/nobiot/org-transclusion/blob/main/resources/2021-09-10-transclusion.gif?raw=true>

*Figure 1*. Animation to show creation of a transclusion from an ID link

<https://github.com/nobiot/org-transclusion/blob/main/resources/2021-05-01-org-transclusion-0.1.0-live-sync.gif?raw=true>

*Figure 2*. Animation to show live sync from transclusion to source

<https://github.com/nobiot/org-transclusion/blob/main/resources/demo9-title.png?raw=true>

*Figure 3*. [Video demo on v0.2.1 on YouTube] demonstrating new features
 to transclude a source file into a src-block and function to specify a
 range of text/source line

• Older videos

  ⁃ [Video demo on v0.2.0 on YouTube] featuring minor breaking changes
    and new transclusion filters

  ⁃ [Video demo on v0.1.1 on YouTube] featuring basic syntax and
    live-sync edit


[user manual] <https://nobiot.github.io/org-transclusion/>

[Installation] See section 2

[Getting Started]
<https://nobiot.github.io/org-transclusion/#Getting-Started>

[Video demo on v0.2.1 on YouTube] <https://youtu.be/ueaPiA622wA>

[Video demo on v0.2.0 on YouTube] <https://youtu.be/idlFzWeygwA>

[Video demo on v0.1.1 on YouTube] <https://youtu.be/idlFzWeygwA>


1 Example Use Cases & Main Features
═══════════════════════════════════

  Here is a summary of some real use cases that users have shared with
  the author, including his own.

  Book writing
        You have a collection of notes. You can quickly transclude
        paragraphs and sections from your notes and put together a
        draft. As transclusions are links, it's easy to re-organize them
        into different sequences to see which way works the best.

  Academic writing
        You have a collection of quotes and notes from your research and
        literature review. Transclude relevant elements of quotes and
        notes into different papers. You can keep your collection as the
        central repository of your research.

  Technical writing
        You write technical documents for software. Transclude relevant
        lines of code into the document. As the code is only
        transcluded, you can keep the document up-to-date as the code
        evolves.

  Project status reports
        You work on multiple projects at the same time and need to
        report to different project managers. Transclude relevant parts
        of your work notes and logs into respective project reports. You
        can keep a single collection of your work notes and logs.

  Main Features:

  • Insert a copy of text content via a file link or ID link into an Org
    file

  • Work with any text file such as program source code, plain text,
    Markdown, or other Org files

  • Keep the file system clear of the copies of text content –
    Org-transclusion tries hard to save only the links to the file
    system

  • For Org files, use different headline levels from the source Org
    file

  • For Org files, use filters to include only relevant elements
    (e.g. filter out properties in the transclusions)

  • For program source and plain text files, transclude a certain lines
    or dynamically specify the from/to lines to keep the transclusion
    always up-to-date with the evolving source files

  • For program source files, transclude parts or whole code directly
    into Org's source block to leverage the rich Org features including
    noweb style syntax

  • Extend Org-transclusion with its extension framework


2 Installation
══════════════

  This package is available on:

  • [GNU ELPA] (releases only; equivalent to MELPA-Stable)
  • [GNU-devel ELPA] (unreleased development branch; equivalent to
    MELPA)

  GNU ELPA should be already set up in your Emacs by default. If you
  wish to add GNU-devel ELPA, simply add its URL to `package-archives'
  like this:

  ┌────
  │ (add-to-list 'package-archives '("gnu-devel" . "https://elpa.gnu.org/devel/") t)
  └────

  Refresh the archive with `M-x package-refresh-contents RET' and you
  can do `M-x package-install RET org-transclusion' to install
  it. Alternatively, you can use `package-list-packages'.

  After installation, you can start using Org-transclusion with no
  additional configuration. Below are some example keybindings that can
  be put into your Emacs configuration.

  ┌────
  │ (define-key global-map (kbd "<f12>") #'org-transclusion-add)
  │ (define-key global-map (kbd "C-n t") #'org-transclusion-mode)
  └────

  For Doom users, you would need to do something like this below to
  install the package and configure the keybindings.

  ┌────
  │ ;; ~/.doom.d/package.el
  │ (package! org-transclusion)
  └────

  ┌────
  │ ;; ~/.doom.d/config.el
  │ (use-package! org-transclusion
  │   :after org
  │   :init
  │   (map!
  │    :map global-map "<f12>" #'org-transclusion-add
  │    :leader
  │    :prefix "n"
  │    :desc "Org Transclusion Mode" "t" #'org-transclusion-mode))
  └────


[GNU ELPA] <https://elpa.gnu.org/packages/org-transclusion.html>

[GNU-devel ELPA] <https://elpa.gnu.org/devel/org-transclusion.html>


3 Contributing
══════════════

  • Get involved in a discussion in [Org-roam forum] (the package is
    originally aimed for its users, me included)

  • Create issues, discussion, and/or pull requests. All welcome.

  Org-transclusion is part of GNU ELPA and thus copyrighted by the [Free
  Software Foundation] (FSF). This means that anyone who is making a
  substantive code contribution will need to "assign the copyright for
  your contributions to the FSF so that they can be included in GNU
  Emacs" ([Org Mode website]).

  Thank you.


[Org-roam forum]
<https://org-roam.discourse.group/t/prototype-transclusion-block-reference-with-emacs-org-mode/830>

[Free Software Foundation] <http://fsf.org>

[Org Mode website] <https://orgmode.org/contribute.html#copyright>


4 License
═════════

  Org-transclusion is licensed under a GPLv3 license. For a full copy of
  the license, refer to [LICENSE].


[LICENSE] <./LICENSE>
