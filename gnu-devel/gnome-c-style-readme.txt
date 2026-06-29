gnome-c-style
======

gnome-c-style is an Emacs minor mode for editing C source code in [GNOME C coding style](https://developer.gnome.org/programming-guidelines/stable/c-coding-style.html.en).
In particular, it is useful to properly line-up [function arguments](https://developer.gnome.org/programming-guidelines/stable/c-coding-style.html.en#functions) and
[function declarations in header files](https://developer.gnome.org/programming-guidelines/stable/c-coding-style.html.en#header-files).

Install
------

* `M-x package-install gnome-c-style`
* Add the following line to `~/.emacs.d/init.el`:

```
(add-hook 'c-mode-hook 'gnome-c-style-mode)
```

Usage
------

| Key         | Command                                                   |
--------------|-----------------------------------------------------------|
| C-c C-g a   | Align argument list at the current point                  |
| C-c C-g r   | Align function declarations in the current region         |
| C-c C-g C-g | Compute optimal alignment columns from the current region |
| C-c C-g g   | Guess alignment columns from the current region           |
| C-c C-g f   | Set alignment column to the current point                 |
| C-c C-g c   | Insert `module_object`                                    |
| C-c C-g C   | Insert `MODULE_OBJECT`                                    |
| C-c C-g C-c | Insert `ModuleObject`                                     |
| C-c C-g s   | Insert custom snippet                                     |

Example
------

If you have the following code in a header file:
```c
GGpgCtx *g_gpg_ctx_new (GError **error);

typedef void (*GGpgProgressCallback) (gpointer user_data,
                                      const gchar *what,
                                      gint type,
                                      gint current,
                                      gint total);

void g_gpg_ctx_set_progress_callback (GGpgCtx *ctx,
                                      GGpgProgressCallback callback,
                                      gpointer user_data,
                                      GDestroyNotify destroy_data);
void g_gpg_ctx_add_signer (GGpgCtx *ctx, GGpgKey *key);
guint g_gpg_ctx_get_n_signers (GGpgCtx *ctx);
GGpgKey *g_gpg_ctx_get_signer (GGpgCtx *ctx, guint index);
void g_gpg_ctx_clear_signers (GGpgCtx *ctx);
```

Mark the region, type `C-c C-g C-g`, and you will see the optimum
alignment columns:

```
identifier-start: 9, arglist-start: 41, arglist-identifier-start: 64
```

Then, mark the region again, type `C-c C-g r`, and you will get the
code aligned:

```c
GGpgCtx *g_gpg_ctx_new                   (GError              **error);

typedef void (*GGpgProgressCallback) (gpointer user_data,
                                      const gchar *what,
                                      gint type,
                                      gint current,
                                      gint total);

void     g_gpg_ctx_set_progress_callback (GGpgCtx              *ctx,
                                          GGpgProgressCallback  callback,
                                          gpointer              user_data,
                                          GDestroyNotify        destroy_data);
void     g_gpg_ctx_add_signer            (GGpgCtx              *ctx,
                                          GGpgKey              *key);
guint    g_gpg_ctx_get_n_signers         (GGpgCtx              *ctx);
GGpgKey *g_gpg_ctx_get_signer            (GGpgCtx              *ctx,
                                          guint                 index);
void     g_gpg_ctx_clear_signers         (GGpgCtx              *ctx);
```

Note that the `typedef` statement is skipped as it is not a function
declaration.
