			   ━━━━━━━━━━━━━━━━━━
			    ORG-TRANSCLUSION
			   ━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Installation
2. Getting Started
3. Usage
.. 1. Org-transclusion mode, activate, and deactivate
.. 2. Org links supported
.. 3. Controlling levels of headlines in transclusions
.. 4. Filtering Org elements per transclusion
..... 1. Combining `:only-contents' and `:exclude-elements'
..... 2. Notes on excluding the headline element
.. 5. Live-sync edit
.. 6. Transclude source file into src-block
.. 7. Transclude range of lines for text and source files
..... 1. `:lines' property to specify a range of lines
..... 2. `:end' property to specify a search term to dynamically look for the end of a range
.. 8. Extensions - Support `org-indent-mode'
4. Customizing
.. 1. Customizable filter to exclude certain Org elements
.. 2. Include the section before the first headline (Org file only)
.. 3. Faces & fringe bitmap
..... 1. Face for the `#+transclude' keyword
..... 2. Faces for the fringes next to transcluded region and source region
.. 4. Keybindings
5. Tips
.. 1. Moving from 0.0.x to 0.1.x
6. Known Limitations
7. Changelog
.. 1. 1.0.0 (initial version on [ELPA])
.. 2. 0.2.2
.. 3. 0.2.1
.. 4. 0.2.0
.. 5. 0.1.2
.. 6. 0.1.1
.. 7. 0.1.0
8. Credits
.. 1. Original idea by John Kitchin
.. 2. Text-Clone
9. Development
.. 1. Notes on pull requests and FSF copy right assignment
10. License


<file:https://img.shields.io/badge/License-GPLv3-blue.svg>
[Transclusion] is the ability to include content from one file into
another by reference. Org-transclusion is an Org Mode version of it. It
lets you insert a copy of text content via a file link or ID link within
an Org file. It is my take on the [idea by John Kitchin].

When I start writing a long-form material, I want to begin with looking
through my notes and assemble relevant ones to form a basis of the first
draft quickly. As I organise my notes in a repository, I also want to
avoid having multiple copies of notes flying around.

Transclusion helps me do this.

I am dabbling in the [Zettelkasten method] with using [Org-roam] to feed
my ideas into the repository. As such, although Org-transclusion is a
standalone package, I would like to keep workflow seamless between
Org-roam and Org-transclusion.

<file:./resources/2021-09-10-transclusion.gif> *Figure 1*. Animation to
show transclusion from the buffer on the right

<file:./resources/2021-05-01-org-transclusion-0.1.0-live-sync.gif>
*Figure 2*. Animation to show live sync from transclusion to source

<file:./resources/demo9-title.png> *Figure 3* [Video demo on v0.2.1 on
YouTube] demonstrating new features to transclude a source file into a
src-block and function to specify a range of text/source lines

Recent videos
      ⁃ [Video demo on v0.2.0 on YouTube] featuring minor breaking
        changes and new transclusion filters

Older videos
      ⁃ [Video demo on v0.1.1 on YouTube] featuring basic syntax and
        live-sync edit


[Transclusion] <https://en.wikipedia.org/wiki/Transclusion>

[idea by John Kitchin] See section 8.1

[Zettelkasten method]
<https://writingcooperative.com/zettelkasten-how-one-german-scholar-was-so-freakishly-productive-997e4e0ca125>

[Org-roam] <https://www.orgroam.com/>

[Video demo on v0.2.1 on YouTube] <https://youtu.be/ueaPiA622wA>

[Video demo on v0.2.0 on YouTube] <https://youtu.be/idlFzWeygwA>

[Video demo on v0.1.1 on YouTube] <https://youtu.be/idlFzWeygwA>


1 Installation
══════════════

  This package is not available on MELPA or ELPA. Manual installation is
  required.

  Download or clone this repo, put all the `.el' files in it into your
  load-path, and put something like this in your init file.

  ┌────
  │ (with-eval-after-load 'org
  │   (add-to-list  'load-path "path/to/org-transclusion/")
  │   (require 'org-transclusion)
  │   (define-key global-map (kbd "<f12>") #'org-transclusion-add)
  │   (define-key global-map (kbd "C-n t") #'org-transclusion-mode))
  └────

  It is important that you get all the `.el' files ready, not just
  `org-transclusion.el'. As at the time of this writing, the live-sync
  feature is contained in `text-clone.el' (also available in this repo)
  and some new features and extensions are made available as separate
  `.el' files. You will need to have all the `.el' files to use
  Org-transclusion as a package.

  If you use Doom and packages such as Straight, etc. to install files
  from GitHub repositories, you can do something like this below (it's
  an example using Doom's `package!' macro).

  ┌────
  │ ;; In ~/.doom.d/package.el
  │ (package! org-transclusion
  │   :recipe (:host github
  │ 	   :repo "nobiot/org-transclusion"
  │ 	   :branch "main"
  │ 	   :files ("*.el")))
  └────

  For Doom, add `use-package!' to load the package by adding something
  like this in the code excerpt below in your `config.el'.

  As of v0.2.0, some commands are defined with `autoload'. This means
  that adding some properties such as `:defer' lets you lazy-load the
  `org-transclusion' package. Please consult Doom's documentation for
  further instruction (I don't use Doom, but I have lightly tested this
  snippet). There are other ways to configure Doom; also refer to
  comments in [issue #79] (thank you, @Ma-Nu-El).

  ┌────
  │ ;; In ~/.doom.d/config.el
  │ (use-package! org-transclusion
  │   :defer
  │   :after org
  │   :init
  │   (map!
  │    :map global-map "<f12>" #'org-transclusion-add
  │    :leader
  │    :prefix "n"
  │    :desc "Org Transclusion Mode" "t" #'org-transclusion-mode))
  └────


[issue #79] <https://github.com/nobiot/org-transclusion/issues/79>


2 Getting Started
═════════════════

  The basic idea of Org-transclusion is simple: insert a copy of text
  content via a file link or ID link within an Org file. This is an Org
  Mode version of [transclusion].

  To transclude content via a reference, use one of the following
  commands:

  • `org-transclusion-make-from-link'
  • `org-transclusion-add'
  • `org-transclusion-add-all'

  For example, if you have an ID link in your Org file like this:

  ┌────
  │ [[id:20210501T171427.051019][Bertrand Russell]]
  └────

  Put your cursor somewhere on this link and call `M-x
  org-transclusion-make-from-link'. That inserts a "transclusion"
  keyword like this in the next empty line:

  ┌────
  │ #+transclude: [[id:20210501T171427.051019][Bertrand Russell]]
  └────

  Put your cursor somewhere on this keyword line and call `M-x
  org-transclusion-add', and you will see the content the ID points to
  be copied over, replacing the `transclude' keyword.

  <file:./resources/2021-05-09T190918.png>

  The transcluded text is *read-only* but you can copy it and export it
  as normal text. Org-transclusion remembers where it has transcluded
  the text from (its source buffer).  You can call a number of useful
  commands with a single letter (by default).

  For example, you can press `o' to open the source buffer of the
  transclusion at point, or `O' (capital "o") to move to it. Press `g'
  to refresh the transclusion. Press `e' to start live-sync edit. For
  more detail, inspect the documentation of each command.

  This single-letter-context-menu is defined in
  `org-transclusion-map'. The default keybindings are shown below. Adapt
  them to your liking, especially if you use vim keybindings with Evil
  Mode, etc.

  ┌────
  │ key             binding
  │ ---             -------
  │ 
  │ C-c             Prefix Command
  │ TAB             org-cycle
  │ D               org-transclusion-demote-subtree
  │ O               org-transclusion-move-to-source
  │ P               org-transclusion-promote-subtree
  │ d               org-transclusion-remove
  │ e               org-transclusion-live-sync-start
  │ g               org-transclusion-refresh
  │ o               org-transclusion-open-source
  │ 
  │ C-c C-c         org-ctrl-c-ctrl-c
  │ 
  └────

  This should get you started with Org-transclusion. There are more
  options and customizing options available for you to fine-tune the
  text contents you transclude. More about them in README below.

  As your next step, I recommend the section on [filtering Org elements
  per transclusion], which shows features that give you the power to
  control what part of the source to transclude in the way you like and
  let you experiment on the fly.


[transclusion] <https://en.wikipedia.org/wiki/Transclusion>

[filtering Org elements per transclusion] See section 3.4


3 Usage
═══════

3.1 Org-transclusion mode, activate, and deactivate
───────────────────────────────────────────────────

  Org-transclusion is a local minor mode; however, you do not need to
  explicitly call `org-transclusion-mode'. The minor mode is intended to
  be just a convenient wrapper to let you easily toggle between
  `activate' and `deactivate'.

  As you saw in the [Getting Started section] above, calling
  `org-transclusion-add' or `org-transclusion-add-all' is enough to add
  transclusions in your current buffer.

  The minor mode is automatically turned on locally for your current
  buffer through one of these commands. All it does is to call
  `org-transclusion-activate' to activate hooks and some other
  variables. Their main purpose is to keep files in the filesystem clear
  of the transcluded content.

  Turn off the minor mode or use `org-transclusion-deactivate'; you will
  remove all the transclusions in the current buffer and clear the hooks
  and other setup variables.

  If you prefer, you can use `org-transclusion-mode' as your entry
  command for transclusion. When customizable variable
  `org-transclusion-add-all-on-activate' is non-nil (it is `t' by
  default), turning on the minor mode calls the
  `org-transclusion-add-all' command to attempt to add all transclusions
  automatically in the current buffer.

  You can control whether or not transclusions are to be added
  automatically per transclude keyword. By default,
  `org-transclusion-add-all' (it is also used by
  `org-transclusion-mode') will work on every transclude keyword in the
  buffer. Add `:disable-auto' property to a keyword as shown in the
  example below; `add-all' skips transclude keywords with it.

  ┌────
  │ #+transclude: [[file:path/to/file.org]] :disable-auto
  └────

  You can override the `:disable-auto' property by manually calling
  `org-transclusion-add' at point.


[Getting Started section] See section 2


3.2 Org links supported
───────────────────────

  Transclusion has been tested to work for the following types of links:

  • File link for an entire org file/buffer;
    e.g. `[[file:~/org/file.org][My Org Notes]]'
  • File link with `::*heading'
  • File link with `::#custom-id'
  • File link with `::name' for blocks (e.g. blocked quotations),
    tables, and links
  • File link with `::dedicated-target'; this is intended for linking to
    a paragraph. See below.
  • ID link `id:uuid'
  • File link for non-org files (tested with `.txt' and `.md'); for
    these, the whole buffer gets transcluded

  Note search-options `::/regex/' and `::number' do not work as
  intentended.

  For transcluding a specific paragraph, there are two main ways: Org
  Mode's [dedicated-target] and `:only-contents' property.

  For dedicated targets, the target paragraph must be identifiable by a
  dedicated target with a `<<paragraph-id>>':

  ┌────
  │ Lorem ipsum dolor sit amet, consectetur adipiscing elit.
  │ Suspendisse ac velit fermentum, sodales nunc in,
  │ tincidunt quam. <<paragraph-id>>
  └────

  It is generally assumed that the `paragraph-id' is placed after its
  content, but it is not an absolute requirement; it can be in the
  beginning (before the content) or in the middle of it.

  For the `:only-contents' property, refer to sub-section [Filtering Org
  elements per transclusion].


[dedicated-target]
<https://orgmode.org/manual/Internal-Links.html#Internal-Links>

[Filtering Org elements per transclusion] See section 3.4


3.3 Controlling levels of headlines in transclusions
────────────────────────────────────────────────────

  You can specify a different level of transcluded headlines than that
  of the source Org file.

  Use the `:level' property with a value of single digit number from 1
  to 9 like this example below.

  ┌────
  │ #+transclude: [[file:path/to/file.org::*Headline]] :level 2
  └────

  The top level of the transcluded headline will set to the value of
  `:level' property – in this example, level 2 regardless of that in the
  source. When the headline contains sub-headlines, they will be all
  automatically promoted or demoted to align according to how many
  levels the top of the subtree will move.

  When you transclude an entire Org file, it may contain multiple
  subtrees. In such cases, the top-most level among the subtrees will be
  set according to the `:level' property; the rest of headlines in the
  buffer will align accordingly.


3.4 Filtering Org elements per transclusion
───────────────────────────────────────────

  You can control what elements to include in many different ways with
  using various filters. The filters work in two layers: customizable
  variable and properties per transclude keyword.

  The following two customizable variables are applicable to all
  transclusions globally. You can think of them as the global default.

  `org-transclusion-exclude-elements'
        This customizable variable globally defines the exclusion filter
        for elements. It is a list of symbols; the acceptable values can
        be seen by inspecting `org-element-all-elements'. The default is
        to exclude `property-drawer'.

        Refer also to the [sub-section on this user option].

  `org-transclusion-include-first-section'
        This customizing variable globally defines whether or not to
        include the first section of the source Org file. The first
        section is the part before the first headline – that's the
        section that typically contains `#+title', `#+author', and so
        on. Many people also write notes in it without adding any
        headlines. Note that this user option's default is now `t'
        (changed from `nil' as users seem to spend time to "correct"
        this issue). Turn it to `t' if you wish to transclude the
        content from the first section of your Org files. If you wish to
        exclude the "meta data" defined by `#+title' and others, exclude
        `keyword' as described in this section – these meta data are
        defined with using the `keyword' element of Org Mode.

        Refer also to the [sub-section on this user option].

  In addition to the global user options above, you can fine-tune the
  default exclusion filter per transclusion. Add following properties to
  transclusions you wish to apply additional filters.

  `:only-contents'
        This property lets you exclude titles of headlines when you
        transclude a subtree (headline); you transclude only the
        contents. When the subtree contains sub-headlines, all the
        contents will be transcluded.

        Add `:only-contents' without any value like this example:

  ┌────
  │ #+transclude: [[file:path/to/file.org]] :only-contents
  └────

  `:exclude-elements'
        This property lets you *add* elements to exclude per
        transclusion on top of the variable
        `org-transclusion-exclude-elements' defines. You cannot *remove*
        the ones defined by it; thus, it is intended that you use the
        customizable variable as your global default and fine-tune it by
        the property per transclusion.

        Add `:exclude-elements' with a list of elements (each one as
        defined by `org-element-all-elements') separated by a space
        inside double quotation marks like this example:

  ┌────
  │ #+transclude: [[file:path/to/file.org]] :exclude-elements "drawer keyword"
  └────


[sub-section on this user option] See section 4.1

[sub-section on this user option] See section 4.2

3.4.1 Combining `:only-contents' and `:exclude-elements'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can combine `:only-contents' and `:exclude-elements' to control
  how you transclude a subtree. Refer to the example screen shots below
  (the colored labels are added to the images for illustration purposes
  and not part of the Emacs buffers).

  <file:./resources/2021-06-05_v0.2.0-01.png> *Figure 1*. *Left*. Three
  transclusions with different properties; *Right*. Source to be
  transcluded

  <file:./resources/2021-06-05_v0.2.0-02.png> *Figure 2*. *Left*. Only
  the root-level headline is transcluded

  <file:./resources/2021-06-05_v0.2.0-03.png> *Figure
  3*. *Left*. Content of the entire subtree, including sub-headlines, is
  transcluded

  <file:./resources/2021-06-05_v0.2.0-04.png> *Figure
  3*. *Left*. Combined; only the content of top-level headline is
  transcluded


3.4.2 Notes on excluding the headline element
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you add `headline' as a list of elements to exclude, you exclude
  sub-headlines within your subtrees. You will still transclude the
  contents of the top-most level of the subtrees.

  If you are transcluding only one subtree, this should be intuitive. If
  you transclude a whole buffer, you might be transcluding multiple
  subtrees. In some cases, this can be a little anti-intuitive. In the
  following examples, you will be transcluding three subtrees – even
  though the first headline levels are lower than the third one, the
  first two are still the top-most level of their own respective
  subtrees.

  ┌────
  │ ** Headline 1
  │    Content of Headline 1
  │ ** Headline 2
  │    Content of Headline 2
  │ * Headline 3
  │   Content of Headline
  └────


3.5 Live-sync edit
──────────────────

  *Experimental.* You can start live-sync edit by pressing `e' (by
   default) on a text element you want to edit. This will put a colored
   overlay on top of the region being live-synced and brings up another
   buffer that visits the source file of the transclusion. The source
   buffer will also have a corresponding overlay to the region being
   edited and live-synced.

  If you have other windows open, they will be temporarily hidden –
  Org-transclusion will remembers your current window layout and
  attempts to recover it when you exit live-sync edit.

  In the live-sync edit region, you can freely type to edit the
  transclusion or source regions; they will sync simultaneously.

  Once done with editing, press `C-c C-c' to exit live-sync edit. The
  key is bound to `org-transclusion-live-sync-exit'. It will turn off
  the live sync edit but keep the transclusion on.

  In the live-sync edit region, the normal `yank' command (`C-y') is
  replaced with a special command
  `org-transclusion-live-sync-paste'. This command lets the pasted text
  inherit the text-properties of the transcluded region correctly; the
  normal yank does not have this feature and thus causes some
  inconvenience in live-sync edit. If you use vim keybindings
  (e.g. `evil-mode'), it is advised that you review the default
  keybindings. You can customize the local keybindings for the live-sync
  region by `org-transclusion-live-sync-map'.

  *Note*: that during live-sync edit, file's content gets saved to the
   filesystem as is – i.e. the transcluded text will be saved instead of
   the `#+transclude:' keyword. If you kill buffer or quit Emacs, other
   hooks will still remove the transclusion to keep the file clear of
   the transcluded copy, leaving only the keyword in the file system.

  ┌────
  │ (substitute-command-keys "\\{org-transclusion-live-sync-map}")
  └────

  ┌────
  │ key                   binding
  │ ---                   -------
  │ 
  │ C-c                   Prefix Command
  │ C-y                   org-transclusion-live-sync-paste
  │ 
  │ C-c C-c               org-transclusion-live-sync-exit
  │ 
  │ *Also inherits ‘org-mode-map’
  └────


3.6 Transclude source file into src-block
─────────────────────────────────────────

  You can transclude a source file into an Org's src block. Use the
  `:src' property and specify the language you would like to use like
  this:

  ┌────
  │ #+transclude: [[file:../../test/python-1.py]] :src python
  └────

  The content you specify in the link gets wrapped into a src-block with
  the language like this:

  ┌────
  │ #+begin_src python
  │ [... content of python-1.py]
  │ #+end_src
  └────

  Use `:rest' property to define additional properties you would like to
  add for the src-block. The double quotation marks are mandatory for
  the `:rest' property.

  ┌────
  │ #+transclude: [[file:../../test/python-3.py]]  :src python :rest ":session :results value"
  └────

  The source block will have the additional properties:
  ┌────
  │ #+begin_src python :session :results value
  └────


3.7 Transclude range of lines for text and source files
───────────────────────────────────────────────────────

3.7.1 `:lines' property to specify a range of lines
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can specify a range of lines to transclude from a source and text
  file. Use the `:lines' property like this.

  ┌────
  │ #+transclude: [[file:../../test/test.txt]] :lines 3-5
  └────

  The rage is specified by the number "3-5"; in this case, lines from 3
  to 5, both lines inclusive.

  To transclude a single line, have the the same number in both places
  (e.g. 10-10, meaning line 10 only).

  One of the numbers can be omitted.  When the first number is omitted
  (e.g. -10), it means from the beginning of the file to line
  10. Likewise, when the second number is omitted (e.g. 10-), it means
  from line 10 to the end of file.

  You can combine the `:lines' property with the `:src' property to
  transclude only a certain range of source files (Example 1 below).

  For Org's file links, you can use [search options] specified by the
  "::" (two colons) notation. When a search finds a line that includes
  the string, the Org-transclude counts it as the starting line 1 for
  the `:lines' property.

  Example 1: This transcludes the four lines of the source file from the
  line that contains string "id-1234" (including that line counted as
  line 1).
  ┌────
  │ #+transclude: [[file:../../test/python-1.py::id-1234]] :lines 1-4 :src python
  └────

  Example 2: This transcludes only the single line that contains the
  line found by the search option for text string "Transcendental
  Ontology"
  ┌────
  │ #+transclude: [[file:../../test/test.txt::Transcendental Ontology]] :lines 1-1
  └────

  Note search-options `::/regex/' and `::number' do not work as
  intended.


[search options] <https://orgmode.org/manual/Search-Options.html>


3.7.2 `:end' property to specify a search term to dynamically look for the end of a range
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can add `:end' property and specify the search term as its value.
  Surround the search term with double quotation marks (mandatory).

  See Example 3 below. This transclusion will look for `id-1234' as the
  beginning line of the range as specified by the search option
  `::id-1234' in the link. With the `:end' property, the search term
  `id-1234 end here' defines the end of the range. The search looks for
  `id-123 end here' in the body text, and use the line one before the
  one where the text is find (thus, the transcluded range will not
  contain `id-1234 end here').

  You can also combined `:lines' property with `:end' property.  It will
  only displace the beginning, and the end part of the range (the second
  number after the hyphen "-") is ignored. In the same example, the
  beginning of the range is the one line after the line where "id-1234"
  is found; it's the "second line, or line 2".  Instead of transcluding
  until the end of the buffer, the end is defined by the `:end'
  property.

  Example 3:
  ┌────
  │ #+transclude: [[file:../../test/python-1.py::id-1234]] :lines 2- :src python :end "id-1234 end here"
  └────


3.8 Extensions - Support `org-indent-mode'
──────────────────────────────────────────

  Org-transclusion provides a simple extension framework, where you can
  use `customize' to selectively add new features. Currently there are
  two extensions provided. Support for `org-indent-mode' is an
  extension, which is inactive by default.

  (on by default) org-transclusion-src-lines
        Add features for `:src' and `:lines' properties to
        #+transclude. It is meant for non-Org files such as program
        source and text files
  (off by default) org-transclusion-indent-mode
        Support org-indent-mode

  <file:resources/2021-09-05T164930.png>

  If you use `customize', the features are loaded automatically. Note
  that it does not "unload" the feature until you relaunch Emacs.

  If you do not use `customize' (e.g. Doom), you may need to explicitly
  require an extension. For example, to activate
  `org-transclusion-indent-mode', you might need to add something like
  this in your configuration file.

  ┌────
  │ ;; Ensure that load-path to org-transclusion is already added
  │ ;; (add-to-list  'load-path "path/to/org-transclusion/")
  │ (add-to-list 'org-transclusion-extensions 'org-transclusion-indent-mode)
  │ (require 'org-transclusion-indent-mode)
  └────


4 Customizing
═════════════

  You can customize settings in the `org-transclusion' group.

  `org-transclusion-extensions'
        Defines extensions to be loaded with org-transclusion.el. If you
        use `customize', the extensions are loaded by it.  If you don't,
        you likely need to explicitly use `require' to load them.

  `org-transclusion-add-all-on-activate'
        Defines whether or not all the active transclusions (with `t')
        get automatically transcluded on minor mode activation
        (`org-transclusion-mode'). This does not affect the manual
        activation when you directly call `org-transclusion-activate'

  `org-transclusion-exclude-elements'
        See [sub-section] below

  `org-transclusion-include-first-section'
        See [sub-section] below

  `org-transclusion-open-source-display-action-list'
        You can customize the way the `org-transclusion-open-source'
        function displays the source buffer for the transclusion. You
        specify the "action" in the way defined by the built-in
        `display-buffer' function. Refer to its in-system documentation
        (with `C-h f') for the accepted values. `M-x customize' can also
        guide you with the types of values with the widget.

  `org-transclusion-mode-lighter'
        Define the lighter for Org-transclusion minor mode. The default
        is " OT".


[sub-section] See section 4.1

[sub-section] See section 4.2

4.1 Customizable filter to exclude certain Org elements
───────────────────────────────────────────────────────

  Set customizable variable `org-transclusion-exclude-elements' to
  define which elements to be *excluded* in the transclusion.

  The filter works for all supported types of links within an Org file
  when transcluding an entire Org file, and parts of it (headlines,
  custom ID, etc.). There is no filter for non-Org files.

  It is a list of symbols, and the default is `(property-drawer)'. The
  accepted values are the ones defined by `org-element-all-elements'
  (Org's standard set of elements; refer to its documentation for an
  exhaustive list).

  You can also fine-tune the exclusion filter per transclusion. Refer to
  the sub-section on [filtering Org elements per transclusion].


[filtering Org elements per transclusion] See section 3.4


4.2 Include the section before the first headline (Org file only)
─────────────────────────────────────────────────────────────────

  You can include the first section (section before the first headline)
  of an Org file. It is toggled via customizable variable
  `org-transclusion-include-first-section'. Its default value is
  `t'. Set it to `t' (or non-nil) to transclude the first section. It
  also works when the first section is followed by headlines.


4.3 Faces & fringe bitmap
─────────────────────────

4.3.1 Face for the `#+transclude' keyword
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can set your own face to the `#+transclude' keyword with using the
  `org-transclusion-keyword' face.


4.3.2 Faces for the fringes next to transcluded region and source region
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If the fringes that indicate transcluding and source regions are not
  visible in your system (e.g. Doom), try adding background and/or
  foreground colors to these custom faces.

  • org-transclusion-source-fringe
  • org-transclusion-fringe

  Here is an example image from [this issue]:

  <https://user-images.githubusercontent.com/12507865/118443158-de6a2480-b6eb-11eb-81d0-a2778ed5f779.png>

  To customize a face, it's probably the easiest to use `M-x
  customize-face'. If you want to use Elisp for some reason (e.g. on
  Doom), something like this below should set faces. Experiment with the
  colors of your choice. By default, the faces above have no values.

  ┌────
  │ (set-face-attribute
  │  'org-transclusion-fringe nil
  │  :foreground "green"
  │  :background "green")
  └────

  For colors, where "green" is, you can also use something like
  "#62c86a" (Emacs calls it "RGB triple"; you can refer to in-system
  manual Emacs > Colors). You might also like to refer to a list of
  currently defined faces in your Emacs by `list-faces-display'.

  Other faces:
  • org-transclusion-source
  • org-transclusion-source-edit
  • org-transclusion
  • org-transclusion-edit

  I do not know if bitmap can be customizable after it's been defined
  (TBC).
  org-transclusion-fringe-bitmap
        It is used for the fringe that indicates the transcluded
        region. It works only in a graphical environment (not in
        terminal).


[this issue] <https://github.com/nobiot/org-transclusion/issues/75>


4.4 Keybindings
───────────────

  • `org-transclusion-map'
  • `org-transclusion-live-sync-map'


5 Tips
══════

5.1 Moving from 0.0.x to 0.1.x
──────────────────────────────

  GitHub user @lytex has provided a [bash script] that converts old
  syntax to the new one [in this issue]. Thank you.

        I've made a bash one-liner to migrate from the old syntax
        to the new one (manages transclude and hlevel -> level),
        feel free to copy or link it in the docs


[bash script]
<https://github.com/lytex/doom.d/blob/3e48c37f6e6beadf69b57e803d6d2c282aee353d/utils/org-transclusion.sh>

[in this issue]
<https://github.com/nobiot/org-transclusion/issues/71#issuecomment-846618510>


6 Known Limitations
═══════════════════

  Note this section is still incomplete, far from being exhaustive for
  "known" limitations.

  • Org link's search-options `::/regex/' and `::number' do not work as
    intended.

  • For transclusions of Org elements or buffers, live-sync works only
    on the following elements: `center-block', `drawer',
    `dynamic-block', `latex-environment', `paragraph', `plain-list',
    `quote-block', `special-block', `table', and `verse-block'.

    It is known that live-sync does not work for the other elements;
    namely: `comment-block', `export-block', `example-block',
    `fixed-width', `keyword', `src-block', and `property-drawerd'.

    More technical reason for this limitation is documented in the
    docstring of function
    `org-transclusion-live-sync-enclosing-element'.

    Work is in progress to lift this limitation but I'm still
    experimenting different ideas.

  • A new extension has been added to support `org-indent-mode' Refer to
    [this section].

  • Refer to [this issue]. The symptom is that in your Doom and you get
    an error message that includes this: "progn: ‘recenter’ing a window
    that does not display current-buffer." Adding this in your
    configuration has been reported to fix the issue:

    `(advice-remove 'org-link-search
    '+org--recenter-after-follow-link-a)'

    It is probably rather drastic a measure. I will appreciate it if you
    find a less drastic way that works. Thank you.

  • Refer to [issue #20]. I don't intend to support this – refile the
    source, not the transcluded copy.

  • Refer to [issue #86]. You will get "Text-only" error when export
    tries to expand the noweb references into the source code.


[this section] See section 3.8

[this issue] <https://github.com/nobiot/org-transclusion/issues/52>

[issue #20] <https://github.com/nobiot/org-transclusion/issues/20>

[issue #86] <https://github.com/nobiot/org-transclusion/issues/86>


7 Changelog
═══════════

  Main features and changes only.


7.1 1.0.0 (initial version on [ELPA])
─────────────────────────────────────

  Feature
        • : `:end' property and a search term to dynamically define a
          range of lines to transclude for text and source code block

  Change
        • Now user option `org-transclusion-include-first-section''s
          default value is changed to `t'. This seems to be more
          intuitive for more users

  Fix
        • `org-transclusion-before-kill' now checks if the buffer to be
          killed contains any transclusion AND it is visting a file
          before saving. This fixes some issues related to temp buffers,
          etc.

        fix: search options for src-lines extension for `:lines',
        `:src', and `:end' properties


[ELPA] <https://elpa.gnu.org/>


7.2 0.2.2
─────────

  New Features
        • #+transclude font-lock and new face `org-transclusion-keyword'
        • Selective extensions with `org-transclusion-extensions'
        • (optional extension) Support for org-indent
  Fix
        • fix: #93 open-source error "Live sync cannot start here"


7.3 0.2.1
─────────

  New Features
        • Transclude a source file into a `src' block
        • Transclude a range of lines for text and source files
        • Main relevant commits:
          ⁃ 6e0e4bf * | feat: :src, :lines, :rest props (WIP)


7.4 0.2.0
─────────

  Breaking changes
        Refer to the updated README on new features and changed command
        names
        • Change names of commands
        • Remove t/nil to #+transclude: syntax
        • Add :disable-auto
        • Main relevant commits:
          ⁃ 2ba90f0 * break: change command and function names
          ⁃ 6cdd836 * | intrnl: v0.2.0 (breaking change)
          ⁃ 765d8ee * add :disable-auto

  New features and improvements
        Refer to the updated README on new features and changed command
        names
        • 7e5c839 * feat: exclude-elements
        • 765d8ee * add :disable-auto
        • afd6d80 * add: :only-contents
        • Fix #47 The first section itself does not get influenced by
          :level property.  The first headline, when present, is treated
          as the first headline, thus :exclude-element "headline"
          affects its sub-headlines; this means that the content of the
          first headline is transcluded even when with "headline" in the
          list of excluded elements.


7.5 0.1.2
─────────

  e08df47 * add: live-sync for non-Org text file
        So far Non-Org text files could be transcluded but live-sync was
        not available. This version enables live-sync for them. Only for
        the whole file at the moment (ability to specify parts of a text
        file is considered)

  a576b34 * add: text-clone library (rename)
        Live-sync features are now factored out into `text-clone' as a
        standalone library (available with `text-clone.el' also included
        in this repo). Refactored so that `org-transclusion' uses (and
        requires) `text-clone'.


7.6 0.1.1
─────────

  49f03b1 * feat: current-indentation
        Org-transclusion now keeps the original indentation of the
        keyword. When a transclusion text region is removed, its keyword
        will be indented as it was

  d55fc39 * chg: save-buffer hooks
        Instead of blindly deactivate and activate all transclusions
        with t flag, this variable is meant to provide mechanism to
        deactivate/activate only the transclusions currently in effect
        to copy a text content.

  64fd182 * add: remove live-sync overlays when deleted
        Closes issue [#8] Adding a mechanism to remove both of the
        live-sync overlays (transclusion and source) when transclusion
        is completely deleted. This solves the problem of a source
        overlay to be orphaned in such cases.


[#8] <https://github.com/nobiot/org-transclusion/issues/8>


7.7 0.1.0
─────────

  As described in this version.


8 Credits
═════════

8.1 Original idea by John Kitchin
─────────────────────────────────

  <https://github.com/alphapapa/transclusion-in-emacs#org-mode>

        {O} transcluding some org-elements in multiple places
        [2016-12-09 Fri] John Kitchin asks:

        I have an idea for how I could transclude “copies” or
        links to org-elements in multiple places and keep them up
        to date. A prototypical example of this is I have a set of
        org-contacts in one place, and I want to create a new list
        of people for a committee in a new place made of “copies”
        of the contact headlines. But I do not really want to
        duplicate the headlines, and if I modify one, I want it
        reflected in the other places. I do not want just links to
        those contacts, because then I can not do things with
        org-map-entries, and other org-machinery which needs the
        actual headlines/properties present. Another example might
        be I want a table in two places, but the contents of them
        should stay synchronized, ditto for a code block.

        This idea was inspired by
        <https://github.com/gregdetre/emacs-freex>.

        The idea starts with creating (wait for it…) a new link ;)
        In a document where I want to transclude a headline, I
        would enter something like:

        transclude:some-file.org::*headline title

        Then, I would rely on the font-lock system to replace that
        link with the headline and its contents (via the
        :activate-func link property), and to put an overlay on it
        with a bunch of useful properties, including modification
        hooks that would update the source if I change the the
        element in this document, and some visual indication that
        it is transcluded (e.g. light gray background/tooltip).

        I would create a kill-buffer hook function that would
        replace that transcluded content with the original link. A
        focus-in hook function would make sure the transcluded
        content is updated when you enter the frame. So when the
        file is not open, there is just a transclude link
        indicating what should be put there, and when it is open,
        the overlay modification hooks and focus hook should
        ensure everything stays synchronized (as long as external
        processes are not modifying the contents).

        It seems like this could work well for headlines, and
        named tables, src blocks, and probably any other element
        that can be addressed by a name/ID.


8.2 Text-Clone
──────────────

  `text-clone.el' is an extension of text-clone functions written as
  part of GNU Emacs in `subr.el'.  The first adaption to extend
  text-clone functions to work across buffers was published in
  StackExchange by the user named Tobias in March 2020. It can be found
  at
  <https://emacs.stackexchange.com/questions/56201/is-there-an-emacs-package-which-can-mirror-a-region/56202#56202>. The
  text-clone library takes this line of work further.


9 Development
═════════════

  • Get involved in a discussion in [Org-roam forum] (the package is
    originally aimed for its users, me included)

  • Create issues, discussion, and/or pull requests. All welcome.


[Org-roam forum]
<https://org-roam.discourse.group/t/prototype-transclusion-block-reference-with-emacs-org-mode/830>

9.1 Notes on pull requests and FSF copy right assignment
────────────────────────────────────────────────────────

  I am considering of submitting Org-transclusion for inclusion into the
  upstream Org Mode at some point, hopefully towards the end of year
  2021. This was suggested a while ago in a Reddit discussion.

  This means that anyone who is making a substantive code contribution
  will need to "assign the copyright for your contributions to the FSF
  so that they can be included in GNU Emacs" ([Org Mode website]).

  I have not started a conversation about it in the Org Mode mailing
  list nor have I done the formal procedure for the copy right
  assignment yet. It will be at the discretion of Org Mode's maintainers
  to decide on my request for inclusion when I submit it.

  Please consider this when you create a pull request for
  Org-transclusion.

  Thank you!


[Org Mode website] <https://orgmode.org/contribute.html#copyright.>


10 License
══════════

  This work is licensed under a GPLv3 license. For a full copy of the
  license, refer to [LICENSE].


[LICENSE] <./LICENSE>
