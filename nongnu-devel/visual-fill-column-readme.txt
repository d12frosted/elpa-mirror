# Visual Fill Column #

`visual-fill-column-mode` is a small Emacs minor mode that mimics the effect of `fill-column` in `visual-line-mode`. Instead of wrapping lines at the window edge, which is the standard behaviour of `visual-line-mode`, it wraps lines at `fill-column` (or `visual-fill-column-width`, if set).  That is, it turns the view on the left into the view on the right, without changing the contents of the file:

 Without Visual Fill Column     | With Visual Fill Column
--------------------------------- | -------------------------------
 ![screenshot before](before.png) | ![screenshot after](after.png)


## Installation ##

Visual Fill Column can be installed from [NonGNU Elpa](http://elpa.nongnu.org/). In Emacs versions 28 and above, simply type `M-x package-install RET visual-fill-column-mode RET`.


## Usage ##

`visual-fill-column-mode` wraps long lines at `fill-column` without adding newlines to the buffer. Its primary (though not exclusive) purpose is to soft-wrap text in buffers that use `visual-line-mode`. The most straightforward way to achieve this is to add the function `visual-fill-column-for-vline` to `visual-line-mode-hook`:

```
(add-hook 'visual-line-mode-hook #'visual-fill-column-for-vline)
```

This function ensures that `visual-fill-column-mode` is enabled and disabled in conjunction with `visual-line-mode`. Note that you should *not* add `visual-fill-column-mode` to `visual-line-mode-hook`, because then `visual-fill-column-mode` is not disabled when you disable `visual-line-mode`. This also means that if you use `use-package`, you should not use the `:hook` keyword, because it will add `-hook` to the name of the function. Instead, put the `add-hook` invocation under `:config`.

`visual-fill-column-mode` can also be used independently from `visual-line-mode`, for example to centre text in a buffer. In this case, use the command `visual-fill-column-mode` to activate it.

There is also a globalised mode `global-visual-fill-column-mode`. This mode turns on `visual-fill-column-mode` in every buffer that visits a file. Activate it either through Customize or by calling it as a function in your init file. In buffers that do not visit a file, `visual-fill-column-mode` may be disruptive, so `global-visual-fill-column-mode` is restricted to file-visiting buffers. (You can, of course still activate `visual-fill-column-mode` manually for such buffers, of course.)

Another option is to add the function `visual-fill-column-mode` to mode hooks in order to activate it in specific modes. This works well from major mode hooks, but be aware of an issue that occurs if you add `visual-fill-column-mode` to a *minor* mode hook: a minor mode's hook is run not only when the minor mode is activated, but also when the minor mode is deactivated.

This means that if you add `visual-fill-column-mode` to `<some>-mode-hook`, deactivating `<some>-mode` will **not** deactivate `visual-fill-column-mode`. Instead, `visual-fill-column-mode` will be activated a second time. Unfortunately, there is no good way to handle this situation: a function run from a hook cannot determine whether the hook's mode is being activated or deactivated. If you only ever activate `<some>-mode`, you won't run into this issue. Otherwise, you can take look at the definition of the function `visual-fill-column-for-vline` and adapt it to your use-case.


## Deprecating `visual-line-fill-column-mode` ##

The minor mode `visual-line-fill-column-mode` was provided to activate and deactivate `visual-line-mode` and `visual-fill-column-mode` in conjunction. This minor mode has been deprecated; instead, use the method described above, i.e., adding the function `visual-fill-column-for-vline` to `visual-line-mode-hook`, to achieve the same effect.


## Wrap prefix ##

In `auto-fill-mode`, there is an option `adaptive-fill-mode`, which ensures that if the first line of a paragraph is indented or has, e.g., a mail quote prefix (`> `), this is applied to the entire paragraph. To get the same effect using `visual-line-mode` + `visual-fill-column-mode`, you can use `visual-wrap-prefix-mode` or, if you're using Emacs 29 or earlier, the package [`adaptive-wrap`](https://elpa.gnu.org/packages/adaptive-wrap.html), which is available from GNU Elpa. The effect of these packages is shown in the following two images:

 Without `visual-wrap`     | With `visual-wrap`
--------------------------------- | -------------------------------
 ![without adaptive-wrap](no-adaptive-wrap.png) | ![with adaptive-wrap](adaptive-wrap.png)

Just like `visual-fill-column-mode`, this effect is just visual, the actual buffer content is not affected.


## Centering the text ##

Another use case for Visual Fill Column is to centre the text in a window:

![screenshot after](centred.png)

This effect is achieved by setting the user option `visual-fill-column-center-text`. You can use the Customize interface or `setopt` to set a default value. In addition, the effect can also be toggled on a per-buffer basis using the command `visual-fill-column-toggle-center-text`. 

Keep in mind that `visual-fill-column-mode` is not dependent on `visual-line-mode`, so it can be used to center text in buffers that use `auto-fill-mode` or in programming modes.

Note: If you are interested in a fully distraction-free writing environment, that not only centres the text but also removes the window decorations, the mode line etc., take a look at [`writeroom-mode`](https://github.com/joostkremers/writeroom-mode).


## How it works ##

`visual-fill-column-mode` works by widening the window margins. This reduces the area that is available for text display, creating the appearance that the text is wrapped at `fill-column`. In the default configuration, only the right margin is widened, mimicking the effect of `auto-fill-mode`. In buffers that are explicitly right-to-left (i.e., those where `bidi-paragraph-direction` is set to `right-to-left`), the left margin is expanded, so that the text appears at the window’s right side. When `visual-fill-column-center-text` is set, both margins are widened.

The amount by which the margins are widened depends on the window width and is automatically adjusted when the window’s width changes (e.g., when the window is split in two side-by-side windows).


## Splitting a Window ##

If you have a wide screen (more specifically, if your Emacs frame is wide), Visual Fill Column has the unfortunate effect that if you pop up, say, a `*Help*` or `*Completions*` buffer or something similar, the popped-up window appears below the active buffer, not next to it, as you might otherwise expect.

This is due to the fact that Emacs uses the width of the text area to determine whether a window can be split into two side-by-side windows, and since `visual-fill-column-mode` narrows the text area, Emacs thinks there is not enough room to do a side-by-side split and so opts for putting the new window below the current one.

To remedy this situation, you can set the option `visual-fill-column-enable-sensible-window-split`. When this option is set, the variable `split-window-preferred-function` is set to the function `visual-fill-column-split-window-sensibly`, which first removes the margins, widening the text area again, and then calls `split-window-sensibly` to do the actual splitting.

This option does not affect the ability to split windows manually. Even if you keep `visual-fill-column-enable-sensible-window-split` unset, you can still split a window into two side-by-side windows by invoking e.g., `split-window-right` (`C-x 3`).


## Adjusting Text Size ##

The width of the margins is adjusted for the text size: larger text size means smaller margins. However, interactive adjustments to the text size (e.g., with `text-size-adjust`) cannot be detected by `visual-fill-column-mode`, therefore if you adjust the text size while `visual-fill-column-mode` is active, the margins won't be adjusted. To remedy this, you can force a redisplay, e.g., by switching buffers, by splitting and unsplitting the window or by calling `redraw-display`.

Alternatively, you can advise the function `text-size-adjust` with the function `visual-fill-column-adjust`:

    (advice-add 'text-scale-adjust :after #'visual-fill-column-adjust)

Note that this functionality is controlled by the option `visual-fill-column-adjust-for-text-scale`. If this is set to `nil`, the margins are not adjusted for the text size.


## Customisation ##

The customisation group `visual-fill-column` has several options that can be used to customise the package.

The following options are buffer-local, the values you set in your init file are default values:

**`visual-fill-column-width`** — Column at which to wrap lines. If set to `nil` (the default), use the value of `fill-column` instead.

**`visual-fill-column-center-text`** — If set to `t`, centre the text area in the window. By default, the text is displayed at the window’s (left) edge, mimicking the effect of `fill-column`.

**`visual-fill-column-extra-text-width`** — Extra columns added to the left and right side of the text area. This should be a cons cell of two integers `(<left> . <right>)`. If `visual-fill-column-center-text` is `t`, the text area is centred before the extra columns are added. This is currently used by `writeroom-mode` to add room for line numbers without shifting the text off-centre.

**`visual-fill-column-fringes-outside-margins`** — If set to `t`, put the fringes outside the margins. Widening the margin would normally cause the fringes to be pushed inward, because by default, they appear between the margins and the text. This effect may be visually less appealing, therefore, `visual-fill-column-mode` places the fringes outside the margins. If you prefer to have the fringes inside the margins, unset this option.

The following options are global, so that they apply to all buffers with `visual-fill-column-mode` enabled:

**`visual-fill-column-enable-sensible-window-split`** — Allow pop-up windows to create a side-by-side window split, if possible. See the discussion above.

**`visual-fill-column-adjust-for-text-scale`** — Take text scaling into account when computing the width of the margins.

**`visual-fill-column-mode-map`** — Keymap for mouse events in the left and right margins, to make sure that scrolling or clicking on the margins does what you'd expect (rather than cause an "event not bound" error).
