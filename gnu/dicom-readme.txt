           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             DICOM.EL - DICOM VIEWER - DIGITAL IMAGING AND
                       COMMUNICATIONS IN MEDICINE
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


DICOM stands for Digital Imaging and Communications in Medicine. DICOM
files are typically used for medical imaging with different modalities
like US, CR, CT, MRI or PET. This package adds the ability to view such
files in Emacs. The images and metadata are displayed in regular Emacs
buffers. The package registers itself in `auto-mode-alist' and
`magic-mode-alist' for `DICOMDIR' directory files and DICOM images (file
extension `*.dcm' or `*.ima'). Furthermore the command `dicom-open'
opens `DICOMDIR' directory files or DICOM image files interactively.


1 Installation
══════════════

  Dicom.el is available from [ELPA] or [MELPA] and can be installed via
  `M-x package-install RET dicom RET'.  After installation, you can open
  `DICOMDIR' and DICOM image files.

  Emacs must be compiled with support for PNG, SVG and XML. The package
  relies on external programs from the [DCMTK] DICOM toolkit, which is
  widely available on Linux distributions.

  • `dcm2xml' and `dcm2img' from the [DCMTK] DICOM toolkit
  • `magick' from [ImageMagick] (optional fallback)
  • `gdcmconv' from [Grassroots DICOM] (optional fallback)
  • `ffmpeg' for video conversion (optional for video)
  • `mpv' for video playing (optional for video)


[ELPA] <https://elpa.gnu.org/packages/dicom.html>

[MELPA] <https://melpa.org/#/dicom>

[DCMTK] <https://dcmtk.org/en/dcmtk/>

[ImageMagick] <https://imagemagick.org/>

[Grassroots DICOM] <https://sourceforge.net/projects/gdcm/>


2 Supported files
═════════════════

  The DICOM format is quite diverse. The `dcm2xml' tool can read the
  metadata of most uncorrupted DICOM files. It can still happen that the
  DICOM viewer is unable to display files, if the metadata records are
  not interpreted properly.  Furthermore the DICOM format supports a
  variety of underlying image formats and compressions, which might not
  be supported by the converter. In such cases, any help improving the
  package is welcome.
