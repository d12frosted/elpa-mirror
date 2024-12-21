DICOM files are typically used for medical imaging (US, CT, MRI, PET).  This
package adds the ability to view such files in Emacs.  The images and
metadata are displayed in regular Emacs buffers.  The package registers
itself in `auto-mode-alist' for DICOMDIR and DICOM images (file extension
*.dcm or *.ima).  Furthermore the command `dicom-open' opens DICOMDIR or
DICOM image files interactively.

The package relies on a few external programs, which are all widely available
on Linux distributions.

- `convert' from the ImageMagick suite
- `ffmpeg' for video conversion
- `dcm2xml' from the dcmtk DICOM toolkit
- `mpv' for video playing