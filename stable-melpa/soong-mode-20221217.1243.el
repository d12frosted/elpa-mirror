;;; soong-mode.el --- Major mode for editing Soong build files -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Sergey Bobrenok <bobrofon@gmail.com>

;; Author: Sergey Bobrenok <bobrofon@gmail.com>
;; Keywords: languages
;; URL: https://github.com/bobrofon/soong-mode
;; Package-Requires: ((emacs "27.1"))
;; Version: 1.0.0

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides support for Soong build system (used in Android).  See
;; https://android.googlesource.com/platform/build/soong/+/refs/heads/master/README.md
;; for Soong introduction.

;;; Code:

(require 'python)

(defconst soong--keywords-constants '("true" "false")
  "Soong constants.")

(defconst soong--keywords-attributes
  '("aaptflags"
    "aapt_include_all_resources"
    "additional_certificates"
    "additional_manifests"
    "address"
    "aidl"
    "all"
    "allow_undefined_symbols"
    "android_libs"
    "android_license_conditions"
    "android_license_files"
    "android_license_kinds"
    "android_static_libs"
    "app_image"
    "arch"
    "arm"
    "arm64"
    "asflags"
    "asset_dirs"
    "auto_gen_config"
    "certificate"
    "cfi"
    "cflags"
    "check_elf_files"
    "clang"
    "clang_asflags"
    "clang_cflags"
    "compile_multilib"
    "conlyflags"
    "cppflags"
    "cpp_std"
    "darwin"
    "data"
    "device_specific"
    "dex_preopt"
    "diag"
    "dont_merge_manifests"
    "dxflags"
    "enabled"
    "enforce_uses_libs"
    "errorprone"
    "exclude_filter"
    "exclude_srcs"
    "export_header_lib_headers"
    "export_include_dirs"
    "export_package_resources"
    "export_shared_lib_headers"
    "export_static_lib_headers"
    "fixed"
    "flags"
    "fuzzer"
    "generated_sources"
    "header_libs"
    "host"
    "host_ldlibs"
    "host_required"
    "include_dirs"
    "include_filter"
    "init_rc"
    "installable"
    "instruction_set"
    "instrumentation_for"
    "jacoco"
    "jarjar_rules"
    "javacflags"
    "java_resource_dirs"
    "java_resources"
    "java_version"
    "jetifier"
    "jni_libs"
    "keep_symbols"
    "ldflags"
    "lib32"
    "lib64"
    "libs"
    "lineage"
    "linux_glibc"
    "local_include_dirs"
    "local_module_path"
    "logtags"
    "manifest"
    "min_sdk_version"
    "multilib"
    "name"
    "native_coverage"
    "never"
    "no_aapt_flags"
    "nocrt"
    "none"
    "not_darwin"
    "not_linux_glibc"
    "not_windows"
    "obfuscate"
    "optimize"
    "optional"
    "optional_uses_libs"
    "overrides"
    "owner"
    "package_splits"
    "pack_relocations"
    "pdk"
    "platform_apis"
    "plugins"
    "prebuilt"
    "preprocessed"
    "privileged"
    "product_specific"
    "product_variables"
    "profile"
    "profile_guided"
    "proguard_flags"
    "proguard_flags_files"
    "proprietary"
    "proto"
    "recover"
    "relative_install_path"
    "renderscript"
    "required"
    "resource_dirs"
    "rtti"
    "sanitize"
    "sdk_version"
    "shared_libs"
    "srcs"
    "static_executable"
    "static_libs"
    "stem"
    "stl"
    "strip"
    "suffix"
    "system_ext_specific"
    "system_shared_libs"
    "tags"
    "target"
    "target_api"
    "target_required"
    "test_config"
    "test_suites"
    "theme"
    "thread"
    "tidy"
    "tidy_checks"
    "tidy_flags"
    "type"
    "unbundled_build"
    "undefined"
    "unit_test"
    "use_clang_lld"
    "use_embedded_dex"
    "use_embedded_native_libs"
    "uses_libs"
    "vendor"
    "vendor_available"
    "version"
    "version_script"
    "vintf_fragments"
    "whole_static_libs"
    "windows"
    "x86"
    "x86_64"
    "yacc")
  "Soong well-known attributes names.")

(defconst soong--keywords-targets
  '("android_app"
    "android_app_import"
    "cc_benchmark"
    "cc_benchmark_host"
    "cc_binary"
    "cc_binary_host"
    "cc_defaults"
    "cc_genrule"
    "cc_library"
    "cc_library_headers"
    "cc_library_host_shared"
    "cc_library_host_static"
    "cc_library_shared"
    "cc_library_static"
    "cc_object"
    "cc_prebuilt_binary"
    "cc_prebuilt_library_shared"
    "cc_prebuilt_library_static"
    "cc_test"
    "cc_test_host"
    "cc_test_library"
    "cts_host_java_library"
    "cts_package"
    "cts_support_package"
    "cts_target_java_library"
    "java_import"
    "java_library"
    "java_library_host"
    "java_library_host_dalvik"
    "java_library_installable"
    "prebuilt_etc"
    "runtime_resource_overlay")
  "Soong builtin targets type names.")

(defconst soong-font-lock-keywords-1
  ;; function declarations, file directives, strings and comments
  `()
  "Value of `font-lock-keywords' in `soong-mode' on font lock level 1.")

(defconst soong-font-lock-keywords-2
  `(,@soong-font-lock-keywords-1
    ;; keywords, type names, named constants
    (,(regexp-opt soong--keywords-constants
                  'symbols)
     . 'font-lock-constant-face)
    (,(regexp-opt soong--keywords-attributes
                  'symbols)
     . 'font-lock-keyword-face))
  "Value of `font-lock-keywords' in `soong-mode' on font lock level 2.")

(defconst soong-font-lock-keywords-3
  `(,@soong-font-lock-keywords-2
    ;; builtin function names
    (,(regexp-opt soong--keywords-targets
                  'symbols)
     . 'font-lock-builtin-face))
  "Value of `font-lock-keywords' in `soong-mode' on font lock level 3.")

(defconst soong-font-lock-keywords soong-font-lock-keywords-3
  "Default value of `font-lock-keywords' in `soong-mode'.")

(defconst soong-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; C++ style comments
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    table)
  "Syntax table for `soong-mode'.")

;;; Stuff to discover path to bpfmt tool.
;;
;; Usually, Android.bp files are inside the AOSP source tree and bpfmt from the
;; same source tree should be used. Although it should also be possible to use
;; bpfmt from PATH (at least for Android.bp files outside of AOSP tree).
;; The base idea is looking for prebuilts/build-tools/*/bin/bpfmt file starting
;; from all parent directories.

(defun soong--path-join (&rest entries)
  "Joins multiple path components in a single string in OS-independent way.
ENTRIES is a sequence of strings.
Every string should be a name of a directory, except the last one.
The last one can be a name of a file."
  (directory-file-name
   (seq-reduce #'concat (mapcar #'file-name-as-directory entries) "")))

(defun soong--get-aosp-bin-dir ()
  "Get directory name for arch-specific binary prebuilts within AOSP repository."
  (cond ((eq system-type 'gnu/linux) "linux-x86")
        ((eq system-type 'darwin) "darwin-x86")))

(defun soong--get-aosp-bpfmt-default-relpath ()
  "Get default relative path to AOSP version of bpfmt."
  (let ((bin-dir (soong--get-aosp-bin-dir)))
    (when bin-dir (soong--path-join "prebuilts" "build-tools" bin-dir "bin" "bpfmt"))))

(defun soong--find-aosp-root ()
  "Try to locate root path to the current AOSP source tree."
  (let ((current (buffer-file-name))
        (bpfmt-relpath (soong--get-aosp-bpfmt-default-relpath)))
    (when (and current bpfmt-relpath)
      (locate-dominating-file
       current
       (lambda (root)
         (file-exists-p (concat root bpfmt-relpath)))))))

(defun soong--find-aosp-bpfmt ()
  "Try to locate bpfmt inside of the current AOSP source tree."
  (let ((root (soong--find-aosp-root))
        (bpfmt-relpath (soong--get-aosp-bpfmt-default-relpath)))
    (if root (concat root bpfmt-relpath)
      ;; use system version as a default
      "bpfmt")))

(defcustom soong-bpfmt-path nil
  "Path to bpfmt (.bp files format) tool.
If nil, auto-detected version will be used."
  :type 'string
  :group 'soong
  :link '(custom-manual "(soong-mode.el) Customization"))

(defun soong--bpfmt-path ()
  "Return path to bpfmt tool."
  (if soong-bpfmt-path soong-bpfmt-path
    (soong--find-aosp-bpfmt)))

;;; Formatting

(defcustom soong-bpfmt-sort-arrays nil
  "Specifies whether to sort arrays during formatting."
  :type 'boolean
  :group 'soong
  :link '(custom-manual "(soong-mode.el) Customization"))

(defun soong--build-bpfmt-args ()
  "Make command line arguments to run bpfmt tool."
  (mapcar #'shell-quote-argument
          (if soong-bpfmt-sort-arrays
              (list "-o" "-s")
            (list "-o"))))

(defun soong-reformat-buffer ()
  "Apply bpfmt formatting to the current buffer."
  (interactive)
  (let (visible-buffer
        output-buffer
        status)
    (setq visible-buffer (current-buffer))
    (with-temp-buffer
      (setq output-buffer (current-buffer))
      (set-buffer visible-buffer)
      (setq status (apply #'call-process-region
                          (append (list (point-min) (point-max)
                                        (soong--bpfmt-path)
                                        nil
                                        (list output-buffer shell-command-default-error-buffer)
                                        nil)
                                  (soong--build-bpfmt-args))))
      (when (eq status 0)
        (replace-buffer-contents output-buffer)
        ;; If current buffer is already formatted, bpfmt will do nothing.
        ;; And it is useful to be at least a little verbose in this situation.
        (message "bpfmt applied")))))

(defvar soong-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c =") #'soong-reformat-buffer)
    map)
  "Keymap for `soong-mode'.")

(defcustom soong-bpfmt-reformat-on-save nil
  "If not nil, bpfmt formatting will be automatically applied on buffer save."
  :type 'boolean
  :group 'soong
  :link '(custom-manual "(soong-mode.el) Customization"))

(defun soong--before-save-hook ()
  "Reformat current buffer if `soong-reformat-on-save' is enabled."
  (when soong-bpfmt-reformat-on-save
    (soong-reformat-buffer)))

;;; Completion

(defun soong-completion-at-point ()
  "Soong `completion-at-point' implementation."
  (let ((bounds (bounds-of-thing-at-point 'sexp)))
    (when bounds
      (list (car bounds)
            (cdr bounds)
            (append soong--keywords-constants
                    soong--keywords-attributes
                    soong--keywords-targets)
            :exclusive 'no))))

;;;###autoload
(define-derived-mode soong-mode prog-mode "Soong"
  "Major mode for editing Soong build files."
  ;; Soong convention is to use 4 spaces for indentation.
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode nil)
  ;; And it has Python indentation rules.
  (setq-local python-indent-offset 4)
  (setq-local indent-line-function #'python-indent-line-function)
  (setq-local indent-region-function #'python-indent-region)
  (setq-local electric-indent-inhibit t)
  (setq-local font-lock-defaults '((soong-font-lock-keywords
                                    soong-font-lock-keywords-1
                                    soong-font-lock-keywords-2
                                    soong-font-lock-keywords-3)))
  (add-hook 'before-save-hook #'soong--before-save-hook nil t)
  ;; Comments
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  ;; Completion
  (add-hook 'completion-at-point-functions
            #'soong-completion-at-point
            'append))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.bp\\'" . soong-mode))

(provide 'soong-mode)
;;; soong-mode.el ends here
