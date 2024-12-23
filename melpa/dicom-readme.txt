DICOM stands for Digital Imaging and Communications in Medicine.  DICOM files
are typically used for medical imaging with different modalities like US, CR,
CT, MRI or PET.  This package adds the ability to view such files in Emacs.
The images and metadata are displayed in regular Emacs buffers.  The package
registers itself in `auto-mode-alist' and `magic-mode-alist' for DICOMDIR
directory files and DICOM images (file extension *.dcm or *.ima).
Furthermore the command `dicom-open' opens DICOMDIR directory files or DICOM
image files interactively.

Emacs must be compiled with support for PNG, SVG and XML.  The package relies
on external programs from the dcmtk DICOM toolkit, which are all widely
available on Linux distributions.

- `dcm2xml' and `dcmj2pnm' from the dcmtk DICOM toolkit
- `ffmpeg' for video conversion (optional)
- `mpv' for video playing (optional)
