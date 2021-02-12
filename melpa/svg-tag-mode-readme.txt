This minor mode replaces keywords or expressions with SVG rounded
box labels that are fully customizable.

Usage example:
--------------

1. Replace :TODO: keyword with default face/padding/radius

   (setq svg-tag-tags '((":TODO:"  (svg-tag-make "TODO")))
   (svg-tag-mode)


2. Replace any letter between () with a circle

   (defun svg-tag-round (text)
     (svg-tag-make (substring text 1 -1) nil 1 1 12))
   (setq svg-tag-tags '(("([0-9])" svg-tag-round)))
   (svg-tag-mode)
