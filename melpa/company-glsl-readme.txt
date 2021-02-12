Provides a company completion backend glslangValidator and filtered
lists provided by `glsl-mode'.

Download & build `glslangValidator' from KhronosGroup:
https://github.com/KhronosGroup/glslang

Setup:
(use-package company-glsl
  :config
  (when (executable-find "glslangValidator")
    (add-to-list 'company-backends 'company-glsl)))
