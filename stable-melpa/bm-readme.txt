; Description:

  This package was created because I missed the bookmarks from M$
  Visual Studio. I find that they provide an easy way to navigate
  in a buffer.

  bm.el provides visible, buffer local, bookmarks and the ability
  to jump forward and backward to the next bookmark.

  Features:
   - Toggle bookmarks with `bm-toggle' and navigate forward and
     backward in buffer with `bm-next' and `bm-previous'.

   - Different wrapping modes, see `bm-wrap-search' and
     `bm-wrap-immediately'. Use `bm-toggle-wrapping' to turn
     wrapping on/off. Wrapping is only available when
     `bm-cycle-all-buffers' is nil.

   - Navigate between bookmarks only in current buffer or cycle
     through all buffers. Use `bm-cycle-all-buffers' to enable
     looking for bookmarks across all open buffers. When cycling
     through bookmarks in all open buffers, the search will always
     wrap around.

   - Setting bookmarks based on a regexp, see `bm-bookmark-regexp'
     and `bm-bookmark-regexp-region'.

   - Setting bookmark based on line number, see `bm-bookmark-line'.

   - Goto line position or start of line, see `bm-goto-position'.

   - Persistent bookmarks (see below). Use
     `bm-toggle-buffer-persistence' to enable/disable persistent
     bookmarks (buffer local).

   - List bookmarks with annotations and context in a separate
     buffer, see `bm-show' (current buffer) and `bm-show-all' (all
     open buffers). See `bm-show-mode-map' for key bindings.

   - Remove all bookmarks in current buffer with
     `bm-remove-all-current-buffer' and all bookmarks in all open
     buffers with `bm-remove-all-all-buffers'.

   - Annotate bookmarks, see `bm-bookmark-annotate' and
     `bm-bookmark-show-annotation'. The annotation is displayed in
     the message area when navigating to a bookmark. Set the
     variable `bm-annotate-on-create' to t to be prompted for an
     annotation when bookmark is created.

   - Different bookmark styles, fringe-only, line-only or both, see
     `bm-highlight-style'. It is possible to have fringe-markers on
     left or right side.

   - Display the number of bookmarks in the current buffer in the
     mode line, see `bm-modeline-info' and
     `bm-modeline-display-total'.


; Known limitations:

  This package is developed and tested on GNU Emacs 26.x. It should
  also work on all GNU Emacs newer than version 21.x.

  There are some incompatibilities with lazy-lock when using
  fill-paragraph. All bookmark below the paragraph being filled
  will be lost. This issue can be resolved using the
  `jit-lock-mode' introduced in GNU Emacs 21.1



; Installation:

  To use bm.el, put it in your load-path and add
  the following to your .emacs

  (require 'bm)

or

  (autoload 'bm-toggle   "bm" "Toggle bookmark in current buffer." t)
  (autoload 'bm-next     "bm" "Goto bookmark."                     t)
  (autoload 'bm-previous "bm" "Goto previous bookmark."            t)



; Configuration:

  To make it easier to use, assign the commands to some keys.

  M$ Visual Studio key setup.
    (global-set-key (kbd "<C-f2>") 'bm-toggle)
    (global-set-key (kbd "<f2>")   'bm-next)
    (global-set-key (kbd "<S-f2>") 'bm-previous)

  Click on fringe to toggle bookmarks, and use mouse wheel to move
  between them.
    (global-set-key (kbd "<left-fringe> <mouse-5>") 'bm-next-mouse)
    (global-set-key (kbd "<left-fringe> <mouse-4>") 'bm-previous-mouse)
    (global-set-key (kbd "<left-fringe> <mouse-1>") 'bm-toggle-mouse)

  If you would like the markers on the right fringe instead of the
  left, add the following to line:

  (setq bm-marker 'bm-marker-right)


  Mode line:

  Since there are number of different packages that helps with
  configuring the mode line, it is hard to provide integrations.
  Below is two examples on how to add it to the standard Emacs mode
  line:

    (add-to-list 'mode-line-position '(:eval (bm-modeline-info)) t)

  or

    (setq global-mode-string '(:eval (bm-modeline-info)))




; Persistence:

  Bookmark persistence is achieved by storing bookmark data in a
  repository when a buffer is killed. The repository is saved to
  disk on exit. See `bm-repository-file'. The maximum size of the
  repository is controlled by `bm-repository-size'.

  The buffer local variable `bm-buffer-persistence' decides if
  bookmarks in a buffer is persistent or not. Non-file buffers
  can't have persistent bookmarks, except for *info* and
  indirect buffers.

  Bookmarks are non-persistent as default. To have bookmarks
  persistent as default add the following line to .emacs.

  ;; make bookmarks persistent as default
  (setq-default bm-buffer-persistence t)

  Use the function `bm-toggle-buffer-persistence' to toggle
  bookmark persistence.

  To have automagic bookmark persistence we need to add some
  functions to the following hooks. Insert the following code
  into your .emacs file:

  If you are using desktop or other packages that restore buffers
  on start up, bookmarks will not be restored. When using
  `after-init-hook' to restore the repository, it will be restored
  *after* .emacs is finished. To load the repository when bm is
  loaded set the variable `bm-restore-repository-on-load' to t,
  *before* loading bm (and don't use the `after-init-hook').

  ;; Make sure the repository is loaded as early as possible
  (setq bm-restore-repository-on-load t)
  (require 'bm)

  ;; Loading the repository from file when on start up.
  (add-hook' after-init-hook 'bm-repository-load)

  ;; Restoring bookmarks when on file find.
  (add-hook 'find-file-hooks 'bm-buffer-restore)

  ;; Saving bookmark data on killing a buffer
  (add-hook 'kill-buffer-hook 'bm-buffer-save)

  ;; Saving the repository to file when on exit.
  ;; kill-buffer-hook is not called when Emacs is killed, so we
  ;; must save all bookmarks first.
  (add-hook 'kill-emacs-hook '(lambda nil
                                  (bm-buffer-save-all)
                                  (bm-repository-save)))

  ;; Update bookmark repository when saving the file.
  (add-hook 'after-save-hook 'bm-buffer-save)

  ;; Restore bookmarks when buffer is reverted.
  (add-hook 'after-revert-hook 'bm-buffer-restore)


  The `after-save-hook' and `after-revert-hook' is not necessary to
  use to achieve persistence, but it makes the bookmark data in
  repository more in sync with the file state.

  The `after-revert-hook' might cause trouble when using packages
  that automatically reverts the buffer (like vc after a check-in).
  This can easily be avoided if the package provides a hook that is
  called before the buffer is reverted (like `vc-before-checkin-hook').
  Then new bookmarks can be saved before the buffer is reverted.

  ;; make sure bookmarks is saved before check-in (and revert-buffer)
  (add-hook 'vc-before-checkin-hook 'bm-buffer-save)



; Acknowledgements:

 - The use of overlays for bookmarks was inspired by highline.el by
   Vinicius Jose Latorre <vinicius(at)cpqd.com.br>.
 - Thanks to Peter Heslin for notifying me on the incompability
   with lazy-lock.
 - Thanks to Christoph Conrad for adding support for goto line
   position in bookmarks and simpler wrapping.
 - Thanks to Jan Rehders for adding support for different bookmark
 - styles.
 - Thanks to Dan McKinley <mcfunley(at)gmail.com> for inspiration
   to add support for listing bookmarks in all buffers,
   `bm-show-all'. (http://www.emacswiki.org/cgi-bin/wiki/bm-ext.el)
 - Thanks to Jonathan Kotta <jpkotta(at)gmail.com> for mouse
   support and fringe markers on left or right side.
 - Thanks to Juanma Barranquero <lekktu(at)gmail.com> for making
   `bm-show' an electric window, cleaning up the code, finding and
   fixing bugs and correcting spelling errors.
 - Thanks to jixiuf <jixiuf(at)gmail.com> for adding LIFO support
   to bookmark navigation. See `bm-in-lifo-order' for more
   information.
