;;; pdb-mode.el --- Major mode for editing Protein Data Bank files

;; Copyright (C) 1997 Charlie Bond, University of Sydney
;;               2000-2002 Charlie Bond, University of Dundee
;;               2000 David Love, CLRC Daresbury Laboratory (marked sections)

;; Author: charles.bond@uwa.edu.au
;; Maintainer: aix.bing@gmail.com
;; URL: http://bondxray.org/software/pdb-mode/
;; Package-Version: 20150128.1751
;; Package-Commit: 855fb18ebb73b5df30c8d7677c2bcd0f361b138a
;; Version: 1.0
;; Keywords: data, pdb

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; PDB mode is set up to do a few useful things to PDB (Protein Data Bank)
;; format files.

;;; This package is known to work (insofar as it's tested) with Emacs 24.4

;;; Code:

(defvar pdb-mode-hook nil "Mode hook for pdb-mode")

(require 'easymenu)

(defvar pdb-mode nil
  "This buffer specific variable tells if the pdb mode is active." )
(make-variable-buffer-local 'pdb-mode)

;; initialise menu and hooks
(defvar pdb-mode-map (make-sparse-keymap))

(defconst pdb-mode-menu-def
  '("PDB"
    ("Select ..."
     ["Select chain"                 pdb-select-chain  t]
     ["Select current chain"         (pdb-select-chain "")  t]
     ["Select current residue"       pdb-select-residue  t]
     ["Select zone of residues"      pdb-select-zone  t])
    ("Navigate"
     ["Jump to next residue"         pdb-forward-residue  t]
     ["Jump to previous residue"     pdb-back-residue  t]
     ["Jump to next chain"           pdb-forward-chain  t]
     ["Jump to previous chain"       pdb-back-chain  t])
    ("Change Values"
     ["Set alternate conformer"      pdb-change-alternate  t]
     ["Set B-factor"                 pdb-change-bfactor  t]
     ["Set chain ID"                 pdb-change-chain  t]
     ["Set atom name"                pdb-change-name  t]
     ["Set occupancy"                pdb-change-occu  t]
     ["Set residue number"           pdb-change-residue  t]
     ["Set SEGID"                    pdb-change-segid  t]
     ["Set residue type"             pdb-change-type  t]
     ["Mutate residue(s)"            pdb-change-mutate t]
     ["Convert frac->orth"           pdb-change-frac2orth  t]
     ["Convert orth->frac"           pdb-change-orth2frac  t]
)
    ("Increment Values"
     ["Add value to B-factor"        pdb-increment-bfactor  t]
     ["Change centroid"              pdb-increment-centroid  t]
     ["Add value to residue number"  pdb-increment-residue  t]
     ["Add vector to xyz (orthogonal)" pdb-increment-xyz  t]
     ["Add vector to xyz (fractional)" pdb-increment-fractional  t]
     ["Scale coordinates"            pdb-scale-xyz  t]
     ["Scale B-factors"              pdb-scale-bfactor  t]
     ["Rotate xyz by 3x3 matrix"     pdb-increment-matrix  t]
     ["Rotate xyz by Euler triplet"  pdb-increment-euler  t])
    ("Renumber"
     ["Consecutive atom numbers"     pdb-renumber-atoms  t]
     ["Consecutive water residue numbers" pdb-renumber-waters  t])
    ("Tidy Up"
     ["Remove non-protein atoms"       pdb-tidy-amino  t]
     ["Convert ATOM -> HETATM"       pdb-tidy-atom2hetatm  t]
     ["Reduce to CA only"            pdb-tidy-ca  t]
     ["Remove hydrogens"         pdb-tidy-dehydrogenate  t]
     ["Convert HETATM -> ATOM"       pdb-tidy-hetatm2atom  t]
     ["Cut back to poly-ALA/GLY"         pdb-tidy-polyalanine  t]
     ["Remove all but ATOM/HETATM records" pdb-tidy-xyz  t])
    ("New..."
    ["amino acid(s)"            pdb-new-sequence t]
    ["DNA base(s)"           pdb-new-dnaseq t]
    ["PDB entry"           pdb-new-pdb t]
    ("HICUP compound"
      ["User defined..." pdb-new-hicup t]
      ["Selenomethionine" (pdb-new-hicup "mse") t]
     ("Nucleotide"
      ["ATP" (pdb-new-hicup "atp") t]
      ["ADP" (pdb-new-hicup "adp") t]
      ["AMP" (pdb-new-hicup "amp") t]
      ["CTP" (pdb-new-hicup "ctp") t]
      ["CDP" (pdb-new-hicup "cdp") t]
      ["CMP" (pdb-new-hicup "cmp") t]
      ["GTP" (pdb-new-hicup "gtp") t]
      ["GDP" (pdb-new-hicup "gdp") t]
      ["GMP" (pdb-new-hicup "gmp") t]
      ["NAD" (pdb-new-hicup "nad") t]
      ["NADP+" (pdb-new-hicup "nap") t]
      ["NADPH" (pdb-new-hicup "ndp") t]
      ["S-adenosylmethionine" (pdb-new-hicup "sam") t]
      ["FAD" (pdb-new-hicup "fad") t])
     ("Sugar"
      ["Glucose" (pdb-new-hicup "glc") t]
      ["Linear glucose" (pdb-new-hicup "glo") t]
      ["n-Glycosyl chain" (pdb-new-hicup "asf") t]
      ["NAG (N-acetyl glucosamine)" (pdb-new-hicup "nag") t]
      ["Fructose" (pdb-new-hicup "fru") t]
      ["Sucrose" (pdb-new-hicup "suc") t]
      ["Fucose" (pdb-new-hicup "fuc") t]
      ["Inositol hexaphosphate" (pdb-new-hicup "ihp") t])
     ("Small"
      ["Sodium" (pdb-new-hicup "na") t]
      ["Calcium" (pdb-new-hicup "ca") t]
      ["Magnesium" (pdb-new-hicup "mg") t]
      ["Zinc" (pdb-new-hicup "zn") t]
      ["Iron" (pdb-new-hicup "fe") t]
      ["Mercury" (pdb-new-hicup "hg") t]
      ["Chloride" (pdb-new-hicup "cl") t]
      ["Oxygen molecule" (pdb-new-hicup "o2") t]
      ["Ammonium (NH4+)" (pdb-new-hicup "nh4") t]
      ["Carbon dioxide" (pdb-new-hicup "co2") t]
      ["Acetate" (pdb-new-hicup "acy") t]
      ["Acetone" (pdb-new-hicup "acn") t]
      ["Sulfate (SO4)" (pdb-new-hicup "so4") t]
      ["Sulfite (SO3)" (pdb-new-hicup "so3") t]
      ["Azide" (pdb-new-hicup "azi") t]
      ["Phosphate" (pdb-new-hicup "po4") t]
      ["Nitrate" (pdb-new-hicup "no3") t]
      ["DMSO (dimethyl sulfoxide)" (pdb-new-hicup "dms") t]
      ["Urea" (pdb-new-hicup "ure") t])
     ("Organic"
      ["Citrate" (pdb-new-hicup "cit") t]
      ["Ascorbate" (pdb-new-hicup "asc") t]
      ["Salicylic acid" (pdb-new-hicup "sal") t]
      ["Tartaric acid" (pdb-new-hicup "tar") t]
      ["Benzoic acid" (pdb-new-hicup "box") t]
      ["Succinic acid" (pdb-new-hicup "sin") t]
      ["6-Amino hexanoic acid" (pdb-new-hicup "aha") t]
      ["2-Phenylethylamine" (pdb-new-hicup "pea") t]
      ["Beta-mercaptoethanol" (pdb-new-hicup "bme") t]
      ["DTT (1,4-dithiothreitol)" (pdb-new-hicup "dtt") t]
      ["Ethanol" (pdb-new-hicup "eoh") t]
      ["2-Propanol" (pdb-new-hicup "ipa") t]
      ["Ethanediol" (pdb-new-hicup "edo") t]
      ["MPD (2-methyl-2,4-pentanediol)" (pdb-new-hicup "mpd") t]
      ["Glycerol" (pdb-new-hicup "gol") t]
      ["Retinol" (pdb-new-hicup "rtl") t]
      ["Methylparaben" (pdb-new-hicup "mpb") t]
      ["Tylenol" (pdb-new-hicup "tyl") t]
      ["Camphor" (pdb-new-hicup "cam") t]
      ["Tris (tromethamine)" (pdb-new-hicup "trs") t])
     ("Miscellaneous"
      ["Aminopyridine" (pdb-new-hicup "4ap") t]
      ["Isoquinoline" (pdb-new-hicup "isq") t]
      ["AlF3" (pdb-new-hicup "af3") t]
      ["AlF4-" (pdb-new-hicup "alf") t]
      ["SC-58272 synthetic peptidic inhibitor" (pdb-new-hicup "mim") t]
      ["N1-carboxypiperazine" (pdb-new-hicup "bzp") t]
      ["4-(Acetylamino)-3-amino benzoic acid" (pdb-new-hicup "st3") t]
      ["Porphyrin Fe(III)" (pdb-new-hicup "por") t])
     ))
    ("Miscellaneous"
     ["  Submit to PRODRG"     pdb-new-prodrg  t]
    ["  Toggle Fontification" (font-lock-mode) :style toggle :selected font-lock-mode])))

;; initialise some variables
(eval-when-compile
  (defvar pdb-start-user-region nil "PDB Mode: Used by some functions")
  (defvar pdb-end-user-region nil "PDB Mode: Used by some functions")
  (defvar pdb-amino-lookup nil "PDB Mode: Lookup table to convert single-letter to three-letter amino acid codes")
  (defvar pdb-record-lookup nil "PDB Mode: Lookup table to access side-chain PDB coordinates for amino acids from their three-letter code.")
  (defvar pdb-mode-syntax-table nil "Syntax table in use in set file mode buffers.")
  (defvar pdb-font-lock-keywords nil "Table of set file font lock keywords."))

;; Some necessary data
(setq pdb-amino-lookup
      '(("A" . "ALA") ("C" . "CYS") ("D" . "ASP") ("E" . "GLU")
        ("F" . "PHE") ("G" . "GLY") ("H" . "HIS") ("I" . "ILE")
        ("K" . "LYS") ("L" . "LEU") ("M" . "MET") ("N" . "ASN")
        ("P" . "PRO") ("Q" . "GLN") ("R" . "ARG") ("S" . "SER")
        ("T" . "THR") ("V" . "VAL") ("W" . "TRP") ("Y" . "TYR")
        ("dA" . "A  ") ("dG" . "G  ") ("dT" . "T  ") ("dC" . "C  ")))
(setq pdb-record-lookup
      '(("ALA" . "ATOM      2  CB  ALA A   1      -0.532  -0.774  -1.196  1.00 20.00           C\n")
        ("ARG" .
         "ATOM      1  CB  ARG A   1      -0.526  -0.779  -1.207  1.00 20.00           C
ATOM      1  CG  ARG A   1      -2.041  -0.900  -1.254  1.00 20.00           C
ATOM      1  CD  ARG A   1      -2.494  -1.684  -2.476  1.00 20.00           C
ATOM      1  NE  ARG A   1      -3.946  -1.811  -2.537  1.00 20.00           N
ATOM      1  CZ  ARG A   1      -4.600  -2.437  -3.509  1.00 20.00           C
ATOM      1  NH1 ARG A   1      -3.929  -3.023  -4.492  1.00 20.00           N
ATOM      1  NH2 ARG A   1      -5.923  -2.518  -3.476  1.00 20.00           N\n")
        ("ASN" .
         "ATOM      1  CB  ASN A   1      -0.526  -0.778  -1.208  1.00 20.00           C
ATOM      1  CG  ASN A   1      -2.037  -0.888  -1.218  1.00 20.00           C
ATOM      1  OD1 ASN A   1      -2.638  -1.406  -0.276  1.00 20.00           O
ATOM      1  ND2 ASN A   1      -2.663  -0.345  -2.255  1.00 20.00           N\n")
              ("ASP" .
               "ATOM      1  CB  ASP A   1      -0.526  -0.779  -1.207  1.00 20.00           C
ATOM      1  CG  ASP A   1      -2.039  -0.881  -1.221  1.00 20.00           C
ATOM      1  OD1 ASP A   1      -2.585  -1.504  -2.156  1.00 20.00           O
ATOM      1  OD2 ASP A   1      -2.680  -0.356  -0.287  1.00 20.00           O\n")
              ("CYS" .
               "ATOM      1  CB  CYS A   1      -0.526  -0.779  -1.207  1.00 20.00           C
ATOM      1  SG  CYS A   1      -2.327  -0.928  -1.273  1.00 20.00           S\n")
              ("GLN" .
               "ATOM      1  CB  GLN A   1      -0.526  -0.778  -1.208  1.00 20.00           C
ATOM      1  CG  GLN A   1      -2.039  -0.907  -1.254  1.00 20.00           C
ATOM      1  CD  GLN A   1      -2.522  -1.683  -2.462  1.00 20.00           C
ATOM      1  OE1 GLN A   1      -2.803  -1.106  -3.513  1.00 20.00           O
ATOM      1  NE2 GLN A   1      -2.663  -2.995  -2.307  1.00 20.00           N\n")
              ("GLU" .
               "ATOM      1  CB  GLU A   1      -0.525  -0.778  -1.208  1.00 20.00           C
ATOM      1  CG  GLU A   1      -2.039  -0.902  -1.255  1.00 20.00           C
ATOM      1  CD  GLU A   1      -2.523  -1.677  -2.465  1.00 20.00           C
ATOM      1  OE1 GLU A   1      -2.792  -1.045  -3.508  1.00 20.00           O
ATOM      1  OE2 GLU A   1      -2.679  -2.911  -2.359  1.00 20.00           O\n")
              ("GLY" .
               "")
              ("HIS" .
               "ATOM      1  CB  HIS A   1      -0.525  -0.779  -1.208  1.00 20.00           C
ATOM      1  CG  HIS A   1      -2.017  -0.903  -1.245  1.00 20.00           C
ATOM      1  ND1 HIS A   1      -2.826   0.022  -1.867  1.00 20.00           N
ATOM      1  CE1 HIS A   1      -4.089  -0.341  -1.737  1.00 20.00           C
ATOM      1  NE2 HIS A   1      -4.129  -1.468  -1.049  1.00 20.00           N
ATOM      1  CD2 HIS A   1      -2.846  -1.841  -0.728  1.00 20.00           C\n")
              ("ILE" .
               "ATOM      1  CB  ILE A   1      -0.504  -0.800  -1.215  1.00 20.00           C
ATOM      1  CG1 ILE A   1      -2.032  -0.886  -1.201  1.00 20.00           C
ATOM      1  CG2 ILE A   1       0.111  -2.191  -1.229  1.00 20.00           C
ATOM      1  CD1 ILE A   1      -2.612  -1.659  -2.365  1.00 20.00           C\n")
              ("LEU" .
               "ATOM      1  CB  LEU A   1      -0.525  -0.777  -1.209  1.00 20.00           C
ATOM      1  CG  LEU A   1      -2.045  -0.935  -1.304  1.00 20.00           C
ATOM      1  CD1 LEU A   1      -2.727   0.424  -1.304  1.00 20.00           C
ATOM      1  CD2 LEU A   1      -2.425  -1.730  -2.544  1.00 20.00           C\n")
              ("LYS" .
               "ATOM      1  CB  LYS A   1      -0.526  -0.781  -1.206  1.00 20.00           C
ATOM      1  CG  LYS A   1      -2.041  -0.890  -1.262  1.00 20.00           C
ATOM      1  CD  LYS A   1      -2.494  -1.671  -2.486  1.00 20.00           C
ATOM      1  CE  LYS A   1      -4.008  -1.792  -2.534  1.00 20.00           C
ATOM      1  NZ  LYS A   1      -4.466  -2.556  -3.727  1.00 20.00           N\n")
              ("MET" .
               "ATOM      1  CB  MET A   1      -0.525  -0.780  -1.206  1.00 20.00           C
ATOM      1  CG  MET A   1      -2.039  -0.908  -1.252  1.00 20.00           C
ATOM      1  SD  MET A   1      -2.617  -1.831  -2.688  1.00 20.00           S
ATOM      1  CE  MET A   1      -4.389  -1.785  -2.430  1.00 20.00           C
ATOM      1  SE  MET A   1      -2.652  -1.887  -2.776  1.00 20.00           S
ATOM      1  CE2 MET A   1      -4.533  -1.839  -2.502  1.00 20.00           C\n")
              ("PHE" .
               "ATOM      1  CB  PHE A   1      -0.525  -0.779  -1.208  1.00 20.00           C
ATOM      1  CG  PHE A   1      -2.023  -0.890  -1.253  1.00 20.00           C
ATOM      1  CD1 PHE A   1      -2.784   0.081  -1.880  1.00 20.00           C
ATOM      1  CE1 PHE A   1      -4.161  -0.024  -1.934  1.00 20.00           C
ATOM      1  CZ  PHE A   1      -4.794  -1.087  -1.322  1.00 20.00           C
ATOM      1  CE2 PHE A   1      -4.048  -2.050  -0.672  1.00 20.00           C
ATOM      1  CD2 PHE A   1      -2.672  -1.940  -0.624  1.00 20.00           C\n")
              ("PRO" .
               "ATOM      1  CB  PRO A   1      -0.525  -0.582  -1.313  1.00 20.00           C
ATOM      1  CG  PRO A   1      -1.785   0.165  -1.573  1.00 20.00           C
ATOM      1  CD  PRO A   1      -1.548   1.557  -1.063  1.00 20.00           C\n")
              ("SER" .
               "ATOM      1  CB  SER A   1      -0.526  -0.778  -1.207  1.00 20.00           C
ATOM      1  OG  SER A   1      -0.146  -0.155  -2.421  1.00 20.00           O\n")
              ("THR" .
               "ATOM      1  CB  THR A   1      -0.504  -0.800  -1.216  1.00 20.00           C
ATOM      1  OG1 THR A   1      -0.087  -0.151  -2.424  1.00 20.00           O
ATOM      1  CG2 THR A   1      -2.021  -0.899  -1.197  1.00 20.00           C\n")
              ("TRP" .
               "ATOM      1  CB  TRP A   1      -0.525  -0.777  -1.208  1.00 20.00           C
ATOM      1  CG  TRP A   1      -2.019  -0.894  -1.243  1.00 20.00           C
ATOM      1  CD1 TRP A   1      -2.895  -0.028  -1.831  1.00 20.00           C
ATOM      1  NE1 TRP A   1      -4.184  -0.464  -1.649  1.00 20.00           N
ATOM      1  CE2 TRP A   1      -4.161  -1.635  -0.937  1.00 20.00           C
ATOM      1  CZ2 TRP A   1      -5.210  -2.445  -0.505  1.00 20.00           C
ATOM      1  CH2 TRP A   1      -4.888  -3.567   0.205  1.00 20.00           C
ATOM      1  CZ3 TRP A   1      -3.556  -3.890   0.499  1.00 20.00           C
ATOM      1  CE3 TRP A   1      -2.514  -3.089   0.069  1.00 20.00           C
ATOM      1  CD2 TRP A   1      -2.814  -1.925  -0.646  1.00 20.00           C\n")
              ("TYR" .
               "ATOM      1  CB  TYR A   1      -0.525  -0.779  -1.207  1.00 20.00           C
ATOM      1  CG  TYR A   1      -2.033  -0.894  -1.254  1.00 20.00           C
ATOM      1  CD1 TYR A   1      -2.799   0.051  -1.923  1.00 20.00           C
ATOM      1  CE1 TYR A   1      -4.177  -0.052  -1.971  1.00 20.00           C
ATOM      1  CZ  TYR A   1      -4.802  -1.121  -1.366  1.00 20.00           C
ATOM      1  CE2 TYR A   1      -4.061  -2.087  -0.720  1.00 20.00           C
ATOM      1  CD2 TYR A   1      -2.684  -1.975  -0.676  1.00 20.00           C
ATOM      1  OH  TYR A   1      -6.173  -1.228  -1.413  1.00 20.00           O\n")
              ("VAL" .
               "ATOM      1  CB  VAL A   1      -0.504  -0.802  -1.214  1.00 20.00           C
ATOM      1  CG1 VAL A   1       0.110  -2.194  -1.227  1.00 20.00           C
ATOM      1  CG2 VAL A   1      -2.023  -0.883  -1.206  1.00 20.00           C\n")
              ("A  " .
               "ATOM      1  N9  A   A   1       0.213   0.660   1.287  1.00 20.00
ATOM      2  C4  A   A   1       0.250   2.016   1.509  1.00 20.00
ATOM      3  N3  A   A   1       0.016   2.995   0.619  1.00 20.00
ATOM      4  C2  A   A   1       0.142   4.189   1.194  1.00 20.00
ATOM      5  N1  A   A   1       0.451   4.493   2.459  1.00 20.00
ATOM      6  C6  A   A   1       0.681   3.485   3.329  1.00 20.00
ATOM      7  N6  A   A   1       0.990   3.787   4.592  1.00 20.00
ATOM      8  C5  A   A   1       0.579   2.170   2.844  1.00 20.00
ATOM      9  N7  A   A   1       0.747   0.934   3.454  1.00 20.00
ATOM     10  C8  A   A   1       0.520   0.074   2.491  1.00 20.00\n")
              ("C  " .
               "ATOM      1  N1  C   A   1       0.212   0.668   1.294  1.00 20.00
ATOM      2  C6  C   A   1       0.193  -0.043   2.462  1.00 20.00
ATOM      3  C2  C   A   1       0.374   2.055   1.315  1.00 20.00
ATOM      4  O2  C   A   1       0.388   2.673   0.240  1.00 20.00
ATOM      5  N3  C   A   1       0.511   2.687   2.504  1.00 20.00
ATOM      6  C4  C   A   1       0.491   1.984   3.638  1.00 20.00
ATOM      7  N4  C   A   1       0.631   2.649   4.788  1.00 20.00
ATOM      8  C5  C   A   1       0.328   0.569   3.645  1.00 20.00\n")
              ("G  " .
               "ATOM      1  N9  G   A   1       0.214   0.659   1.283  1.00 20.00
ATOM      2  C4  G   A   1       0.254   2.014   1.509  1.00 20.00
ATOM      3  N3  G   A   1       0.034   2.979   0.591  1.00 20.00
ATOM      4  C2  G   A   1       0.142   4.190   1.110  1.00 20.00
ATOM      5  N2  G   A   1      -0.047   5.269   0.336  1.00 20.00
ATOM      6  N1  G   A   1       0.444   4.437   2.427  1.00 20.00
ATOM      7  C6  G   A   1       0.676   3.459   3.389  1.00 20.00
ATOM      8  O6  G   A   1       0.941   3.789   4.552  1.00 20.00
ATOM      9  C5  G   A   1       0.562   2.154   2.846  1.00 20.00
ATOM     10  N7  G   A   1       0.712   0.912   3.448  1.00 20.00
ATOM     11  C8  G   A   1       0.498   0.057   2.485  1.00 20.00\n")
              ("T  " .
               "ATOM      1  N1  T   A   1       0.214   0.668   1.296  1.00 20.00
ATOM      2  C6  T   A   1       0.171  -0.052   2.470  1.00 20.00
ATOM      3  C2  T   A   1       0.374   2.035   1.303  1.00 20.00
ATOM      4  O2  T   A   1       0.416   2.705   0.284  1.00 20.00
ATOM      5  N3  T   A   1       0.483   2.592   2.553  1.00 20.00
ATOM      6  C4  T   A   1       0.449   1.933   3.767  1.00 20.00
ATOM      7  O4  T   A   1       0.560   2.568   4.812  1.00 20.00
ATOM      8  C5  T   A   1       0.279   0.500   3.685  1.00 20.00
ATOM      9  C5A T   A   1       0.231  -0.299   4.949  1.00 20.00\n")
              ("U  " .
               "ATOM      5  N1  U   A   1       0.212   0.676   1.281  1.00 20.00
ATOM      6  C6  U   A   1       0.195  -0.023   2.466  1.00 20.00
ATOM      7  C2  U   A   1       0.370   2.048   1.265  1.00 20.00
ATOM      8  O2  U   A   1       0.390   2.698   0.235  1.00 20.00
ATOM      9  N3  U   A   1       0.505   2.629   2.502  1.00 20.00
ATOM     11  C4  U   A   1       0.497   1.990   3.725  1.00 20.00
ATOM     12  O4  U   A   1       0.629   2.653   4.755  1.00 20.00
ATOM     13  C5  U   A   1       0.329   0.571   3.657  1.00 20.00\n")
))


;; Set up font lock
(setq pdb-mode-syntax-table (make-syntax-table (standard-syntax-table)))
(make-face 'pdb-key1-face)
(set-face-background 'pdb-key1-face "grey95")
(make-face 'pdb-comment-face)
(set-face-foreground 'pdb-comment-face "grey50")
(if (string-match "GNU" (emacs-version))
    (progn
      (setq pdb-font-lock-keywords
        (list
         '("\\(^ATOM..\\|HETATM\\).....\\(.\\)....\\(.\\)...\\(.\\).\\(....\\)............\\(........\\)........\\(......\\)......\\(......\\)" (1  'pdb-key1-face) (2  'pdb-key1-face) (3  'pdb-key1-face) (4  'pdb-key1-face) (5  'pdb-key1-face) (6  'pdb-key1-face) (7 'pdb-key1-face) (8  'pdb-key1-face nil t))
         '("\\(^\\([B-G]\\|[I-Z]\\|AU\\|HE[AL]\\).*$\\)" 1 'pdb-comment-face t))))
  )

;;Final blast of commands on startup
(add-hook 'pdb-mode-hook (function
              (lambda()
                ;; If CRYST1 card is present, set pdb-cell-local as a list of 6 numbers
                ;; Spacegroup will be picked up too if present.
                (save-excursion
                  (goto-char (point-min))
                  (if (re-search-forward "^CRYST1" nil t)
                  (let ((str (buffer-substring (+ (point-at-bol) 7) (+ (point-at-bol) 55))))
                    (string-match "[0-9].*[0-9]" str)
                    (let ((str (split-string (match-string 0 str))))
                      (setq pdb-cell-local (list (string-to-number (elt str 0)) (string-to-number (elt str 1)) (string-to-number (elt str 2)) (string-to-number (elt str 3)) (string-to-number (elt str 4)) (string-to-number (elt str 5)))))
                    (setq pdb-spacegroup-local (buffer-substring (+ (point-at-bol) 55) (+ (point-at-bol) 64)))
                    (if (eq (elt pdb-orth2frac-local 0) 0)
                    (progn
                      (pdb-sub-orth2frac)
                      (pdb-sub-frac2orth)))))))))


;; PDB-MODE
;;; ###autoload
(defun pdb-mode ()
  "PDB mode is set up to do a few useful things to PDB (protein databank
format) files.
Other programs (MOLEMAN and PDBSET etc) do all this and more, but not
within an editor.
pdb-mode commands can be accessed from the menu bar PDB or from the minibuffer
(M-x pdb SPACE gives you a list of commands).
Some mouse/key bindings aid PDB file navigation:
C-middlemouse selects residue where button clicked.
C-pageup and C-pagedown jump to the previous/next residue.
C-M-pageup and C-M-pagedown jump to the previous/next chain."
  (interactive)

  ;; Set up mode stuff
  (kill-all-local-variables)

  (setq mode-name "PDB")
  (setq major-mode 'pdb-mode)
  (setq kill-whole-line t)

  ;; Set up menu stuff
  (use-local-map pdb-mode-map)
  (easy-menu-define pdb-mode-menu pdb-mode-map "Emacs menu for PDB mode"
            pdb-mode-menu-def)

  ;; Need this for Xemacs
  (easy-menu-add pdb-mode-menu)

  ;; Customise tabbing to match PDB definition - David Love
  (set (make-local-variable 'indent-line-function) #'tab-to-tab-stop)
  (set (make-local-variable 'tab-stop-list)
       '(;; ATOM
     6              ; serial no.
     11             ; Chemical symbol
     14             ; Remoteness indicator
     15             ; Branch designator
     16             ; Alternate location indicator
     17             ; Residue name
     20             ; Reserved
     21             ; Chain identifier
     22             ; Residue sequence number
     26             ; Code for inserting residue
     27             ; Reserved
     30             ; X
     38             ; Y
     46             ; Z
     54             ; Pdb-Occupancy
     60             ; Isotropic B-factor
     66             ; Reserved
     72             ; Segment identifier
     76             ; Element symbol
     78             ; Charge on atom
     80
     ))
;; Redefine some keys for easy navigation
  (local-set-key '[(control tab)] 'move-to-tab-stop)
  (local-set-key '[(control next)] 'pdb-forward-residue)
  (local-set-key '[(control prior)] 'pdb-back-residue)
  (local-set-key '[(control meta next)] 'pdb-forward-chain)
  (local-set-key '[(control meta prior)] 'pdb-back-chain)

  ;; Setup unit cell data - used for fractional coordinates
  (set (make-local-variable 'pdb-cell-local) (make-list 6 0))
  (set (make-local-variable 'pdb-spacegroup-local) "")
  (set (make-local-variable 'pdb-orth2frac-local) (make-list 9 0))
  (set (make-local-variable 'pdb-frac2orth-local) (make-list 9 0))

  (if (string-match "GNU Emacs" (emacs-version))
      (progn
    ;; Get font-lock to work
    (make-local-variable 'font-lock-defaults)
    (setq font-lock-defaults '(pdb-font-lock-keywords nil nil ((?_ . "w"))))
    ;; Bind C-mouse2 to select clicked residue
    (define-key pdb-mode-map [(control down-mouse-2)] 'pdb-sub-mouse-cmouse2)
    ;; Bind C-mmouse2 to select clicked chain
    (define-key pdb-mode-map [(control meta down-mouse-2)] 'pdb-sub-mouse-cmmouse2)
    ;; Some aliases
    (defalias 'point-at-bol 'line-beginning-position)
    (defalias 'point-at-eol 'line-end-position)
    (defun activate-region ()
      (exchange-point-and-mark)
      (exchange-point-and-mark))))

;; Individual Functions:
;; SELECT...
(defun pdb-select-chain  (pdb-test-string)
"PDB mode: Select current chain\n"
(interactive "sWhich chain ?(1 char. RET signifies current chain):")
(if (= 0 (length pdb-test-string))
    (progn
      (goto-char (point-at-bol))
      (re-search-forward "^\\(ATOM  \\|HETATM\\|ANISOU\\)" nil t)
      (setq pdb-test-string (buffer-substring (+ (point-at-bol) 21) (+ (point-at-bol) 22)))))
(pdb-sub-selectlocal (concat "..............." pdb-test-string)))

(defun pdb-select-residue  ( )
"PDB mode: Select current residue"
(interactive "")
(let ((str (concat "..........." (buffer-substring (+ (point-at-bol) 17) (+ (point-at-bol) 26)))))
  (pdb-sub-selectlocal str)))

(defun pdb-select-zone  (pdb-test-string)
"PDB mode: Select zone"
(interactive "sEnter zone ([Chain][Res1] [Chain][Res2]):")
(let (
      (vec (split-string pdb-test-string))
      (start-chain " ")
      (end-chain " ")
      (start-number 0)
      (end-number 0)
      (str ""))
  ;; Input is a 2 element array - need to grok chain and numbers from it
  (if (string-match "^[A-Z]" (elt vec 0))
      (setq start-chain (match-string 0 (elt vec 0))))
  (if (string-match "^[A-Z]" (elt vec 1))
      (setq pdb-end-chain (match-string 0 (elt vec 1))))
  (string-match "[-0-9]*$" (elt vec 0))
  (setq start-number (match-string 0 (elt vec 0)))
  (string-match "[-0-9]*$" (elt vec 1))
  (setq pdb-end-number (match-string 0 (elt vec 1)))
  ;; Find the ends
  (goto-char (point-min))
  (setq str (concat "^\\(ATOM  \\|HETATM\\)..............." start-chain (format "%4d" (string-to-number start-number))))
  (re-search-forward str nil (point) nil)
  (setq pdb-start-user-region (point-at-bol))
  (setq str (concat "^\\(ATOM  \\|HETATM\\)..............." pdb-end-chain (format "%4d" (string-to-number pdb-end-number))))
    (goto-char (point-max))
    (re-search-backward str nil (point) nil))
(setq pdb-end-user-region (+ (point-at-eol) 1))
(pdb-sub-markregion))

;; NAVIGATE
(defun pdb-forward-residue  ( )
  "PDB mode: Jump to start of next residue"
  (interactive "")
  (let ((str (concat "..... ....." (buffer-substring (+ (point-at-bol) 17) (+ (point-at-bol) 26)))))
    (re-search-forward "^\\(ATOM  \\|HETATM\\)" nil t)
    (goto-char (point-at-bol))
    ;; elisp has no not (regexp) search, so this is complicated
    (while (progn
             (re-search-forward "^\\(ATOM  \\|HETATM\\)" (point-max) (point) nil)
             (cond ((not (looking-at str))
                    (progn
                      (goto-char  (point-at-bol)))
                    nil)
                   (t)))))
  (goto-char (point-at-bol))
  (activate-region))

(defun pdb-forward-chain  ( )
  "PDB mode: Jump to start of next chain"
  (interactive "")
  (let ((str (concat "..............." (buffer-substring (+ (point-at-bol) 21) (+ (point-at-bol) 22)))))
    (re-search-forward "^\\(ATOM  \\|HETATM\\)" nil t)
    (goto-char (point-at-bol))
    (while (progn
         (re-search-forward "^\\(ATOM  \\|HETATM\\)" (point-max) (point) nil)
         (cond ((not (looking-at str))
            (progn
              ;; roll back to previous matching residue
              (goto-char  (point-at-bol)))
            nil)
           (t)))))
  (setq pdb-end-user-region (point-at-bol))
  ;; mark out region
  (goto-char pdb-end-user-region)
  (activate-region))

(defun pdb-back-residue  ( )
  "PDB mode: Jump to start of current/previous residue"
  (interactive "")
  (re-search-backward "^\\(ATOM  \\|HETATM\\)" nil t )
  (let ((str (concat "................." (buffer-substring (+ (point-at-bol) 17) (+ (point-at-bol) 26)))))
    (while (and
        (re-search-backward "^\\(ATOM  \\|HETATM\\)" nil t )
        (looking-at str)))
    (if (not (looking-at str)) (re-search-forward "^\\(ATOM  \\|HETATM\\)" nil t 2)))
  (setq pdb-end-user-region (point-at-bol))
  (goto-char pdb-end-user-region)
  (activate-region))

(defun pdb-back-chain  ( )
  "PDB mode: Jump to start of current/previous chain"
  (interactive "")
  (re-search-backward "^\\(ATOM  \\|HETATM\\)" nil t )
  (let ((str (concat "....................." (buffer-substring (+ (point-at-bol) 21) (+ (point-at-bol) 22)))))
    (while (and
        (re-search-backward "^\\(ATOM  \\|HETATM\\)" nil t )
        (looking-at str)))
    (if (not (looking-at str)) (re-search-forward "^\\(ATOM  \\|HETATM\\)" nil t 2)))
  (setq pdb-end-user-region (point-at-bol))
  (goto-char pdb-end-user-region)
  (activate-region))

;; CHANGE VALUES
(defun pdb-change-bfactor (b e pdb-test-number)
  "PDB mode: Change selected B-factors to requested value"
  (interactive "r\nnRequested B-factor (max 999.99): ")
  (if (> pdb-test-number 999.99) (error "ERROR[PDB]: Number too big"))
  (if ( <  pdb-test-number 0) (setq pdb-test-number 20 ))
  (setq pdb-test-number (format "%6.2f"  pdb-test-number))
  (pdb-sub-defineregion b e)
  (pdb-sub-change pdb-test-number 60 6)
  (pdb-sub-markregion))

(defun pdb-change-occu (b e pdb-test-number)
  "PDB mode: Change occupancy to requested value"
  (interactive "r\nnRequested occupancy: ")
  (if (>  pdb-test-number 99.99) (error "ERROR[PDB]: Number too big"))
  (if (>  pdb-test-number 1) (print "WARNING: Occupancy greater than 1.00" t))
  (if (< pdb-test-number 0) (setq pdb-test-number "0.00" ))
  (setq pdb-test-number (format "%5.2f" pdb-test-number))
  (pdb-sub-defineregion b e)
  (pdb-sub-change pdb-test-number 55 5)
  (pdb-sub-markregion))

(defun pdb-change-alternate (b e pdb-test-string)
  "PDB mode: Change alternate conformation ID of selected atoms"
  (interactive "r \ns:Alternate ID: ")
  (if (= (length pdb-test-string) 0)
      (error "ERROR[PDB]: One character please - try again"))
  (setq pdb-test-string (upcase  (substring pdb-test-string 0 1)))
  (pdb-sub-defineregion b e)
  (pdb-sub-change pdb-test-string 16 1)
  (pdb-sub-markregion))

(defun pdb-change-chain (b e pdb-test-string)
  "PDB mode: Change chain ID of selected atoms"
  (interactive "r \nsChain ID: ")
  (if (= (length pdb-test-string) 0)
      (error "ERROR[PDB]: One character please - try again"))
  (setq pdb-test-string (upcase  (substring pdb-test-string 0 1)))
  (pdb-sub-defineregion b e)
  (pdb-sub-change pdb-test-string 21 1)
  (pdb-sub-markregion))

(defun pdb-change-name (b e pdb-test-string)
  "PDB mode: Change selected atom names"
  (interactive "r \nsAtom Name (4 chars, space first if not metal): ")
  (if (/= (length pdb-test-string) 4)
      (error "ERROR[PDB]: 4 characters please. Space first if not a metal"))
  (setq pdb-test-string (upcase pdb-test-string))
  (pdb-sub-defineregion b e)
  (pdb-sub-change pdb-test-string 12 4)
  (pdb-sub-markregion))

(defun pdb-change-residue (b e pdb-test-number)
  "PDB mode: Change residue number to given value"
  (interactive "r \nnNew residue number:")
  (setq pdb-test-number (format "%4d" pdb-test-number))
  (pdb-sub-defineregion b e )
  (pdb-sub-change pdb-test-number 22 4)
  (pdb-sub-markregion))

(defun pdb-change-segid (b e pdb-test-string)
  "PDB mode: Add SEGID to selected atoms"
  (interactive "r \nsSEGID: ")
  (if ( = (length pdb-test-string) 0)
      (setq pdb-test-string (buffer-substring (+ (point-at-bol) 21) (+ (point-at-bol) 22))))
  (setq pdb-test-string (upcase pdb-test-string))
  (setq pdb-test-string (format "%-4s" pdb-test-string))
  (pdb-sub-defineregion b e )
  (pdb-sub-change pdb-test-string 72 4)
  (pdb-sub-markregion))

(defun pdb-change-type (b e pdb-test-string)
  "PDB mode: Change residue type of selected atoms"
  (interactive "r \nsNew Residue type: ")
  (if (< (length pdb-test-string) 3)
      (error "ERROR[PDB]: Three characters please - try again"))
  (setq pdb-test-string (upcase  (substring pdb-test-string 0 3)))
  (pdb-sub-defineregion b e)
  (pdb-sub-change pdb-test-string 17 3)
  (pdb-sub-markregion))

;; INCREMENT VALUES
(defun pdb-increment-bfactor (b e pdb-test-string)
  "PDB mode: Increment B-factor by given value"
  (interactive "r \nsNumber to add to B-factor:")
  (pdb-sub-defineregion b e)
  (while (< (point) pdb-end-user-region)
    (re-search-forward "^\\(ATOM\\|HETATM\\)" pdb-end-user-region 1 nil)
    (cond ((< (point) pdb-end-user-region)
       (pdb-sub-pad)
       (let (( str (buffer-substring (+ (point-at-bol) 60) (+ (point-at-bol) 66))))
         (setq  str  (+ (eval (string-to-number str)) (eval (string-to-number pdb-test-string))))
           (pdb-sub-change2 (format "%6.2f" str) 60 6)))))
  (pdb-sub-markregion))

(defun pdb-scale-bfactor (b e pdb-test-string)
  "PDB mode: Scale B-factor by given value"
  (interactive "r \nsNumber to scale B-factor by:")
  (pdb-sub-defineregion b e)
  (while (< (point) pdb-end-user-region)
    (re-search-forward "^\\(ATOM\\|HETATM\\)" pdb-end-user-region 1 nil)
    (cond ((< (point) pdb-end-user-region)
       (pdb-sub-pad)
       (let (( str (buffer-substring (+ (point-at-bol) 60) (+ (point-at-bol) 66))))
         (setq str  (* (eval (string-to-number str)) (eval (string-to-number pdb-test-string))))
           (pdb-sub-change2 (format "%6.2f" str) 60 6)))))
  (pdb-sub-markregion))

(defun pdb-increment-residue (b e pdb-test-string)
  "PDB mode: Increment residue number by given value"
  (interactive "r \nsNumber to increase residue number by:")
  (pdb-sub-defineregion b e)
  (while (< (point) pdb-end-user-region)
    (re-search-forward "^\\(ATOM\\|HETATM\\|ANISOU\\|TER   \\)" pdb-end-user-region 1 nil)
    (cond ((< (point) pdb-end-user-region)
       (pdb-sub-pad)
       (let ((str (buffer-substring (+ (point-at-bol) 22) (+ (point-at-bol) 26))))
         (let ((str (+ (eval (string-to-number str)) (eval (string-to-number pdb-test-string)))))
           (pdb-sub-change2 (format "%4d" str) 22 4))))))
  (pdb-sub-markregion))

(defun pdb-increment-fractional (b e pdb-test-string)
  "PDB mode: Translate selected atoms by given fractional vector"
  (interactive "r \nsGive fractional vector (3 numbers, space delimited):")
  (pdb-sub-defineregion b e)
  (pdb-change-orth2frac pdb-start-user-region pdb-end-user-region )
  (let* ((vec  (split-string pdb-test-string))
     (xadd (string-to-number (elt vec 0)))
     (yadd (string-to-number (elt vec 1)))
     (zadd (string-to-number (elt vec 2))))
    (pdb-increment-xyz pdb-start-user-region pdb-end-user-region (format "%f %f %f" xadd yadd zadd)))
  (pdb-change-frac2orth pdb-start-user-region pdb-end-user-region)
  (pdb-sub-markregion))

(defun pdb-scale-xyz (b e sf)
  "PDB mode: Scale coordinates by given factor.\nIf one number is given, x,y and z are scaled by this number.\n If 3 numbers given, they apply to x,y and z independently."
  (interactive "r \nsScale factor (1 number or 3 numbers:")
  (pdb-sub-defineregion b e)
  (let* ((sf (concat sf " " sf " " sf))
     (vec  (split-string sf))
     (xadd (string-to-number (elt vec 0)))
     (yadd (string-to-number (elt vec 1)))
     (zadd (string-to-number (elt vec 2))))
  (while (and (progn
    (re-search-forward "^\\(ATOM\\|HETATM\\)" pdb-end-user-region 1 nil))
          (not (progn
             (pdb-sub-pad)
             (let ((xyz (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54))))))
         (pdb-sub-change2 (format "%8.3f%8.3f%8.3f" (* xadd (elt xyz 0)) (* yadd (elt xyz 1)) (* zadd (elt xyz 2))) 30 24))))))
  (pdb-sub-markregion)))

(defun pdb-increment-xyz (b e pdb-test-string)
  "PDB mode: Translate selected atoms by given vector"
  (interactive "r \nsGive vector (3 numbers, space delimited):")
  (let* ((li (split-string pdb-test-string))
     (xadd (string-to-number (elt li 0)))
     (yadd (string-to-number (elt li 1)))
     (zadd (string-to-number (elt li 2))))
    (pdb-sub-defineregion b e)
    (while (and (progn
          (re-search-forward "^\\(ATOM\\|HETATM\\)" pdb-end-user-region 1 nil))
        (not (progn
               (pdb-sub-pad)
               (let ((str (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54))))))
             (pdb-sub-change2 (format "%8.3f%8.3f%8.3f" (+ (elt str 0) xadd) (+ (elt str 1) yadd) (+ (elt str 2) zadd)) 30 24)))))))
  (pdb-sub-markregion))

(defun pdb-change-frac2orth (b e)
  "PDB mode: Change fractional to orthogonal coordinates"
  (interactive "r")
  (pdb-sub-defineregion b e)
  (if (eq (elt pdb-cell-local 1) 0)
      (call-interactively 'pdb-data-cell))
  (while (< (point) pdb-end-user-region)
    (re-search-forward "^\\(ATOM\\|HETATM\\)" pdb-end-user-region 1 nil)
    (cond ((< (point) pdb-end-user-region)
       (pdb-sub-pad)
       (let* ((frac (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54)))))
          (newx (+ (* (elt pdb-frac2orth-local 0) (elt frac 0)) (* (elt pdb-frac2orth-local 1) (elt frac 1)) (* (elt pdb-frac2orth-local 2) (elt frac 2))))
          (newy (+ (* (elt pdb-frac2orth-local 4) (elt frac 1)) (* (elt pdb-frac2orth-local 5) (elt frac 2))))
          (newz (* (elt pdb-frac2orth-local 8) (elt frac 2))))
         (pdb-sub-change2 (format "%8.3f%8.3f%8.3f" newx newy newz) 30 24)))))
  (pdb-sub-markregion))

(defun pdb-change-orth2frac (b e)
  "PDB mode: Change  orthogonal to fractional coordinates"
  (interactive "r")
  (pdb-sub-defineregion b e)
  (if (eq (elt pdb-cell-local 1) 0)
      (call-interactively 'pdb-data-cell))
  (while (< (point) pdb-end-user-region)
    (re-search-forward "^\\(ATOM\\|HETATM\\)" pdb-end-user-region 1 nil)
    (cond ((< (point) pdb-end-user-region)
       (pdb-sub-pad)
       (let* ((orth (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54)))))
          (newx (+ (* (elt pdb-orth2frac-local 0) (elt orth 0)) (* (elt pdb-orth2frac-local 1) (elt orth 1)) (* (elt pdb-orth2frac-local 2) (elt orth 2))))
          (newy (+ (* (elt pdb-orth2frac-local 4) (elt orth 1)) (* (elt pdb-orth2frac-local 5) (elt orth 2))))
          (newz (* (elt pdb-orth2frac-local 8) (elt orth 2)))
          )
         (pdb-sub-change2 (format "%8.3f%8.3f%8.3f" newx newy newz) 30 24)))))
  (pdb-sub-markregion))

(defun pdb-increment-matrix (b e rm)
  "PDB mode: Rotate selected atoms by given 3x3 matrix"
  (interactive "r \nsGive matrix (9 numbers, space delimited):")
  (let* ((rm (split-string rm))
     (rm (list (string-to-number (elt rm 0)) (string-to-number (elt rm 1)) (string-to-number (elt rm 2)) (string-to-number (elt rm 3)) (string-to-number (elt rm 4)) (string-to-number (elt rm 5)) (string-to-number (elt rm 6)) (string-to-number (elt rm 7)) (string-to-number (elt rm 8)))))
    (pdb-sub-defineregion b e)
    (while (< (point) pdb-end-user-region)
      (re-search-forward "^\\(ATOM\\|HETATM\\)" pdb-end-user-region  1 nil)
      (cond ((< (point) pdb-end-user-region)
         (pdb-sub-pad)
         (let* ((xyz (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54)))))
            (nx (+ (* (nth 0 rm) (nth 0 xyz)) (* (nth 1 rm ) (nth 1 xyz)) (* (nth 2 rm ) (nth 2 xyz))))
            (ny (+ (* (nth 3 rm) (nth 0 xyz)) (* (nth 4 rm ) (nth 1 xyz)) (* (nth 5 rm ) (nth 2 xyz))))
            (nz (+ (* (nth 6 rm) (nth 0 xyz)) (* (nth 7 rm ) (nth 1 xyz)) (* (nth 8 rm ) (nth 2 xyz)))))
         (pdb-sub-change2 (format "%8.3f%8.3f%8.3f" nx ny nz) 30 24)
           )))))
  (pdb-sub-markregion))

(defun pdb-increment-euler (b e pdb-test-string)
  "PDB mode: Rotate selected atoms by given euler triplet"
  (interactive "r \nsGive eulers (3 numbers, space delimited):")
  (pdb-sub-defineregion b e)
  (let* ((pdb-test-vector (split-string pdb-test-string))
     (rad (/ 3.141593 180))
     (al (* rad (string-to-number (elt pdb-test-vector 0))))
     (be (* rad (string-to-number (elt pdb-test-vector 1))))
     (ga (* rad (string-to-number (elt pdb-test-vector 2))))
     (rm (list
          (- (* (cos al) (cos be) (cos ga)) (* (sin al) (sin ga)))
          (- (* -1 (cos al) (cos be) (sin ga)) (* (sin al) (cos ga)))
          (* (cos al) (sin be))
          (+ (* (sin al) (cos be) (cos ga)) (* (cos al) (sin ga)))
          (- (* (cos al) (cos ga)) (* (sin al) (cos be) (sin ga)))
          (* (sin al) (sin be))
          (* -1 (sin be) (cos ga))
          (* (sin be) (sin ga))
          (cos be)
          )))
    (message (format "Matrix: %f %f %f %f %f %f %f %f %f" (elt rm 0) (elt rm 1) (elt rm 2) (elt rm 3) (elt rm 4) (elt rm 5) (elt rm 6) (elt rm 7) (elt rm 8)))
    (pdb-increment-matrix b e (format "%f %f %f %f %f %f %f %f %f" (elt rm 0) (elt rm 1) (elt rm 2) (elt rm 3) (elt rm 4) (elt rm 5) (elt rm 6) (elt rm 7) (elt rm 8))))
  (pdb-sub-markregion))

(defun pdb-increment-centroid (b e pdb-test-string)
  "PDB mode: Translate selected atoms by given vector"
  (interactive "r \nsGive vector (3 numbers, space delimited):")
  (let* ((inc (split-string pdb-test-string))
     (inc (list (string-to-number (elt inc 0)) (string-to-number (elt inc 1)) (string-to-number (elt inc 2))))
     (vec (make-list 3 0))
     (cnt 0)
     (xyz (make-list 3 0))
     (str ""))
    ;; first pass to calculate average
    (pdb-sub-defineregion b e)
    (while (< (point) pdb-end-user-region)
      (re-search-forward "^\\(ATOM\\|HETATM\\)" pdb-end-user-region  1 nil)
      (cond ((< (point) pdb-end-user-region)
         ;; get current xyz
         (setq xyz (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54)))))
         ;; add current xyz to running total (vec)
         (setq vec (vector (+ (elt xyz 0) (elt vec 0)) (+ (elt xyz 1) (elt vec 1)) (+ (elt xyz 2) (elt vec 2))))
         ;; keep count of atoms
         (setq cnt (+ cnt 1)))))
    ;; calculate average xyz and store in pdb-test-vec
    (setq vec (vector (/ (elt vec 0) cnt)(/ (elt vec 1) cnt)(/ (elt vec 2) cnt)))
    (message (format "Old centroid: %8.3f %8.3f %8.3f" (elt vec 0) (elt vec 1) (elt vec 2)))
    ;; second pass to adjust numbers
    (goto-char pdb-start-user-region)
    (while (< (point) pdb-end-user-region)
      (re-search-forward "^\\(ATOM\\|HETATM\\)" pdb-end-user-region 1 nil)
      (cond ((< (point) pdb-end-user-region)
         (pdb-sub-pad)
         (setq str (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54)))))
         (pdb-sub-change2 (format "%8.3f%8.3f%8.3f" (- (elt str 0) (- (elt vec 0) (elt inc 0))) (- (elt str 1) (- (elt vec 1) (elt inc 1))) (- (elt str 2) (- (elt vec 2) (elt inc 2)))) 30 24))))
    (pdb-sub-markregion)))

;; RENUMBER
(defun pdb-renumber-atoms (b e pdb-start-number)
  "PDB mode: Renumber selected atoms consecutively"
  (interactive "r \nnRenumber atoms, starting at?:")
  (if ( =  pdb-start-number 0) (setq pdb-start-number 1))
  (pdb-sub-defineregion b e)
  (let ((i (- pdb-start-number 1)))
    (while (< (point) pdb-end-user-region)
      (re-search-forward "^\\(ATOM\\|HETATM\\|TER   \\|ANISOU\\)" pdb-end-user-region 1 nil)
      (unless (string= (buffer-substring (point-at-bol) (+ 6 (point-at-bol))) "ANISOU")
    (setq i (+ 1 i)))
      (cond ((< (point) pdb-end-user-region)
         (goto-char  (+ (point-at-bol) 11))
         (delete-backward-char 5)
         (insert (format "%5s" (int-to-string i))))))
    (pdb-sub-markregion)))

(defun pdb-renumber-waters (b e pdb-start-number)
  "PDB mode: Renumber selected waters consecutively"
  (interactive "r \nnRenumber waters, starting at?:")
  (if ( =  pdb-start-number 0) (setq pdb-start-number 1))
  (pdb-sub-defineregion b e)
  (let ((i (- pdb-start-number 1)))
    (while (< (point) pdb-end-user-region)
      (re-search-forward "^\\(ATOM\\|HETATM\\|TER   \\|ANISOU\\)" pdb-end-user-region 1 nil)
      (if (string-match (buffer-substring (point-at-bol) (+ 6 (point-at-bol))) "\\(ATOM  \\|HETATM\\)")
      (setq i (+ 1 i)))
      (cond ((< (point) pdb-end-user-region)
         (goto-char  (+ (point-at-bol) 26))
         (delete-backward-char 4)
         (insert-string (format "%4s" (int-to-string i))))))
    (pdb-sub-markregion)))

;;TIDY UP
(defun pdb-tidy-atom2hetatm (b e)
  "PDB mode: Replace selected ATOMs with HETATM"
  (interactive "r")
  (pdb-sub-defineregion b e)
  (goto-char pdb-start-user-region)
  (while (and (progn
        (re-search-forward "^ATOM" pdb-end-user-region 1 nil))
          (not (progn
             (beginning-of-line)
             (delete-char 6)
             (insert "HETATM")))))
  (pdb-sub-markregion))

(defun pdb-tidy-hetatm2atom (b e)
  "PDB mode: Replace selected HETATMS with ATOM"
  (interactive "r")
  (pdb-sub-defineregion b e)
  (goto-char pdb-start-user-region)
  (while (and (progn
        (re-search-forward "^HETATM" pdb-end-user-region 1 nil))
          (not (progn
             (beginning-of-line)
             (delete-char 6)
             (insert "ATOM  ")))))
  (pdb-sub-markregion))

(defun pdb-tidy-ca  ( b e )
  "PDB mode: Reduce to CAs only"
  (interactive "r" )
  (pdb-sub-defineregion b e)
  (while (< (point) pdb-end-user-region)
    (re-search-forward "^." pdb-end-user-region pdb-end-user-region nil)
    (if (and (< (point) pdb-end-user-region) (not (looking-at "TOM  .....  CA" )))
    (progn
      (beginning-of-line)
      (setq pdb-end-user-region (- pdb-end-user-region (+ 1 (- (point-at-eol) (point-at-bol)))))
      (kill-line))))
  (pdb-sub-markregion))

(defun pdb-tidy-dehydrogenate (b e )
  "PDB mode: Remove hydrogen atoms"
  (interactive "r" )
  (pdb-sub-defineregion b e)
  (while (< (point) e)
    (re-search-forward "^\\(ATOM  \\|HETATM\\)..... .H.*$" e 1 nil)
    (if (< (point) e)
    (progn
      (beginning-of-line)
      (setq pdb-end-user-region (- pdb-end-user-region (+ 1 (- (point-at-eol) (point-at-bol)))))
      (kill-line))))
  (pdb-sub-markregion))

(defun pdb-tidy-end ()
  "PDB mode: Add END after last ATOM/HETATM record"
  (interactive)
  (end-of-buffer)
  (re-search-backward "^\\(ATOM\\|HETATM\\)" nil 1 nil)
  (forward-line)
  (insert "END\n"))

(defun pdb-tidy-polyalanine  (b e)
  "PDB mode: Reduce to poly-ALA (leave GLY as GLY)"
  (interactive "r" )
  (pdb-sub-defineregion b e)
  (while (< (point) pdb-end-user-region)
    (re-search-forward "^." pdb-end-user-region pdb-end-user-region nil)
    (if  (not (looking-at "TOM  .....  \\(CA\\|C \\|O \\|N \\|CB\\)  \\(ALA\\|CYS\\|ASP\\|GLU\\|PHE\\|GLY\\|HIS\\|ILE\\|LYS\\|LEU\\|MET\\|ASN\\|PRO\\|GLN\\|ARG\\|SER\\|THR\\|VAL\\|TRP\\|TYR\\)" ))
    (progn
      (beginning-of-line)
      (setq pdb-end-user-region (- pdb-end-user-region (+ 1 (- (point-at-eol) (point-at-bol)))))
      (kill-line))
      (progn
    (if (and (< (point) e) (not( string= "GLY" (buffer-substring (+ (point-at-bol) 17) (+ (point-at-bol) 20)))))
        (progn
          (goto-char (+ (point-at-bol) 20))
          (delete-backward-char 3)
          (insert "ALA"))))))
  (pdb-sub-markregion))

(defun pdb-tidy-xyz ()
  "PDB mode: Delete all non-ATOM/HETATM records"
  (interactive)
  (beginning-of-buffer)
  (delete-non-matching-lines "^\\(ATOM\\|HETATM\\)"))

(defun pdb-tidy-alter ()
  "PDB mode: Delete all alternate conformers leaving only A"
  (interactive)
  (beginning-of-buffer)
  (delete-non-matching-lines "^\\(ATOM  \\|HETATM\\)..... ....\\( \\|A\\)"))

(defun pdb-tidy-amino ()
  "PDB mode: Delete all non-protein records"
  (interactive)
  (beginning-of-buffer)
  (delete-non-matching-lines "^\\(ATOM  .......... \\(ALA\\|CYS\\|ASP\\|GLU\\|PHE\\|GLY\\|HIS\\|ILE\\|LYS\\|LEU\\|MET\\|ASN\\|PRO\\|GLN\\|ARG\\|SER\\|THR\\|VAL\\|TRP\\|TYR\\)\\|HEA\\|AU\\|[B-G]\\|[I-Z]\\)"))

;; MISCELLANEOUS
(defun pdb-new-residue (pdb-test-number pdb-test-string)
  "PDB mode: Insert residue"
  (interactive "nResidue number: \nsResidue type: ")
  (if (< (length pdb-test-string) 1)
      (error "ERROR[PDB]: Sequence is required"))
  (setq pdb-test-string (cdr (assoc-ignore-case pdb-test-string pdb-amino-lookup)))
  (goto-char (point-at-bol))
  (setq pdb-start-user-region (point))
  (let ((str
     "ATOM      1  N   GLY A   1      -0.527   1.359   0.000  1.00 20.00           N
ATOM      2  CA  GLY A   1       0.000   0.000   0.000  1.00 20.00           C
ATOM      3  C   GLY A   1       1.525   0.000   0.000  1.00 20.00           C
ATOM      4  O   GLY A   1       2.155   1.057   0.000  1.00 20.00           O\n"))
    (let ((str (concat str (cdr (assoc-ignore-case pdb-test-string pdb-record-lookup)))))
      (insert-string str)))
  (setq pdb-end-user-region (point))
  (pdb-sub-markregion)
  (pdb-change-type pdb-start-user-region pdb-end-user-region pdb-test-string)
  (pdb-change-residue pdb-start-user-region pdb-end-user-region pdb-test-number)
  (setq pdb-test-number (+ pdb-test-number 1)))

(defun pdb-new-base (pdb-test-number pdb-test-string)
  "PDB mode: Insert base"
  (interactive "nResidue number: \nsBase type: ")
  (if (< (length pdb-test-string) 1)
      (error "ERROR[PDB]: Sequence is required"))
  (setq pdb-test-string (cdr (assoc-ignore-case (concat "d" pdb-test-string) pdb-amino-lookup)))
  (goto-char (point-at-bol))
  (setq pdb-start-user-region (point))
  (let ((str
     "ATOM      1  P   A   A   1       0.224  -4.365   2.383  1.00 20.00
ATOM      2  O1P A   A   1       1.336  -3.982   3.290  1.00 20.00
ATOM      3  O2P A   A   1       0.278  -5.664   1.666  1.00 20.00
ATOM      4  O5* A   A   1       0.042  -3.205   1.307  1.00 20.00
ATOM      5  C2* A   A   1       1.149  -0.891  -0.438  1.00 20.00
ATOM      6  C5* A   A   1      -1.014  -3.256   0.347  1.00 20.00
ATOM      7  C4* A   A   1      -0.913  -2.083  -0.600  1.00 20.00
ATOM      8  O4* A   A   1      -1.127  -0.853   0.133  1.00 20.00
ATOM      9  C1* A   A   1       0.000   0.000   0.000  1.00 20.00
ATOM     10  C3* A   A   1       0.445  -1.932  -1.287  1.00 20.00
ATOM     11  O3* A   A   1       0.272  -1.450  -2.624  1.00 20.00\n"))
    (let ((str (concat str (cdr (assoc-ignore-case pdb-test-string pdb-record-lookup)))))
      (insert-string str)))
  (setq pdb-end-user-region (point))
  (pdb-sub-markregion)
  (pdb-change-type pdb-start-user-region pdb-end-user-region pdb-test-string)
  (pdb-change-residue pdb-start-user-region pdb-end-user-region pdb-test-number)
  (setq pdb-test-number (+ pdb-test-number 1)))

(defun pdb-new-sequence (pdb-test-number pdb-test-string)
  "PDB mode: Create dummy residues from sequence.\nReads in start number and a single letter code sequence, ignoring anything but standard 20 amino acids"
  (interactive "nNumber of first residue: \nsInput sequence (single letter): ")
  (let ((i 0))
    (while (< i (length pdb-test-string))
      (let ((str (substring pdb-test-string i (1+ i))))
    (if (string-match str "ACDEFGHIKLMNPQRSTVWY")
        (progn (pdb-new-residue (+ pdb-test-number i) str)))
    (setq i (1+ i))))))

(defun pdb-new-dnaseq (pdb-test-number pdb-test-string)
  "PDB mode: Create dummy DNA bases from sequence.\nReads in start number and a single letter code sequence, ignoring anything but standard 4 bases"
  (interactive "nNumber of first residue: \nsInput sequence (single letter): ")
  (let ((i 0))
    (while (< i (length pdb-test-string))
      (let ((str (substring pdb-test-string i (1+ i))))
    (if (string-match str "ACGT")
        (progn (pdb-new-base (+ pdb-test-number i) str)))
    (setq i (1+ i))))))

(defun pdb-change-mutate (pdb-test-string)
  "PDB mode: Mutate current residue. Replaces residue with new one and r/t's onto N-CA-C."
  (interactive "sResidue type: ")
  (if (< (length pdb-test-string) 1)
      (error "ERROR[PDB]: Sequence is required"))
  (pdb-select-residue)
  (pdb-back-residue)
  (re-search-forward "^ATOM  .....  N ")
  (let ((start-point (point-at-bol))
    (pdb-test-string2 (cdr (assoc-ignore-case pdb-test-string pdb-amino-lookup)))
    (ntrue (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54)))))
    (chain (buffer-substring (+ (point-at-bol) 21) (+ (point-at-bol) 22)))
    (iresn (string-to-number (buffer-substring (+ (point-at-bol) 22) (+ (point-at-bol) 26)))))
    (re-search-forward "^ATOM  .....  CA")
    (let ((atrue (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54))))))
      (re-search-forward "^ATOM  .....  C ")
      (let ((ctrue (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54))))))
    (re-search-forward "^ATOM  .....  O ")
    (let ((otrue (list (string-to-number (buffer-substring (+ (point-at-bol) 30) (+ (point-at-bol) 38))) (string-to-number (buffer-substring (+ (point-at-bol) 38) (+ (point-at-bol) 46))) (string-to-number (buffer-substring (+ (point-at-bol) 46) (+ (point-at-bol) 54))))))
      (let* ((an1 (list (- (elt ntrue 0) (elt atrue 0)) (- (elt ntrue 1) (elt atrue 1)) (- (elt ntrue 2) (elt atrue 2))))
         (ac1 (list (- (elt ctrue 0) (elt atrue 0)) (- (elt ctrue 1) (elt atrue 1)) (- (elt ctrue 2) (elt atrue 2))))
         (an2 (list -0.527   1.359   0.000))
         (ac2 (list  1.525   0.000   0.000))
         (angle1 (pdb-sub-anglerad an1 an2))
         (vector1 (pdb-sub-cross an1 an2))
         (rm1 (pdb-sub-rot2mat angle1 vector1))
         (xyz2 (pdb-sub-vecxmat ac2 rm1))
         (ncx1 (pdb-sub-cross ac1 an1  ))
         (cx1 (pdb-sub-cross an1 ncx1))
         (ncx2 (pdb-sub-cross xyz2 an1 ))
         (cx2 (pdb-sub-cross an1 ncx2))
         (angle2 (* -1 (pdb-sub-anglerad cx1 cx2)))
         (vector2 an1)
         (rm2 (pdb-sub-rot2mat angle2 vector2))
         (rm3 (pdb-sub-matxmat rm2 rm1))
         )
        (pdb-forward-residue)
        (delete-region (point) (mark))
        (pdb-new-residue -999 pdb-test-string)
        (pdb-select-zone "A-999 A-999")
        (pdb-increment-matrix (mark) (point) (format "%f %f %f %f %f %f %f %f %f" (elt rm3 0) (elt rm3 1) (elt rm3 2) (elt rm3 3) (elt rm3 4) (elt rm3 5) (elt rm3 6) (elt rm3 7) (elt rm3 8)))
        (pdb-increment-xyz (mark) (point) (format "%f %f %f" (elt atrue 0) (elt atrue 1) (elt atrue 2)))
        (pdb-change-residue (mark)  (point) iresn)
        (pdb-change-chain  (mark) (point) chain)
        (goto-char start-point)
        (re-search-forward "^ATOM  .....  N ")
        (delete-region (+ (point-at-bol) 30) (+ (point-at-bol) 54))
        (goto-char  (+ (point-at-bol) 30))
        (insert-string (format "%8.3f%8.3f%8.3f" (elt ntrue 0) (elt ntrue 1) (elt ntrue 2)))
        (re-search-forward "^ATOM  .....  CA")
        (delete-region (+ (point-at-bol) 30) (+ (point-at-bol) 54))
        (goto-char  (+ (point-at-bol) 30))
        (insert-string (format "%8.3f%8.3f%8.3f" (elt atrue 0) (elt atrue 1) (elt atrue 2)))
        (re-search-forward "^ATOM  .....  C ")
        (delete-region (+ (point-at-bol) 30) (+ (point-at-bol) 54))
        (goto-char  (+ (point-at-bol) 30))
        (insert-string (format "%8.3f%8.3f%8.3f" (elt ctrue 0) (elt ctrue 1) (elt ctrue 2)))
        (re-search-forward "^ATOM  .....  O ")
        (delete-region (+ (point-at-bol) 30) (+ (point-at-bol) 54))
        (goto-char  (+ (point-at-bol) 30))
        (insert-string (format "%8.3f%8.3f%8.3f" (elt otrue 0) (elt otrue 1) (elt otrue 2)))))))))

(defun pdb-data-cell (pdb-test-string)
  "PDB mode: Define unit cell"
  (interactive "sPlease define unit cell (6 numbers, space delimited):")
  (string-match "[0-9].*[0-9]" pdb-test-string)
  ;; Store cell as pdb-cell-local
  (let ((str (split-string (match-string 0 pdb-test-string))))
    (setq pdb-cell-local (list (string-to-number (elt str 0)) (string-to-number (elt str 1)) (string-to-number (elt str 2)) (string-to-number (elt str 3)) (string-to-number (elt str 4)) (string-to-number (elt str 5)))))
  ;; Derive fractionalisation matrices
  (pdb-sub-orth2frac)
  (pdb-sub-frac2orth)
  ;; Write new or replace old CRYST1 record
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "^CRYST1" nil t 1)
    (progn (goto-char (point-at-bol))
           (kill-line)))
    (insert-string (concat "CRYST1" (format "%9.3f%9.3f%9.3f%7.2f%7.2f%7.2f %-s" (elt pdb-cell-local 0) (elt pdb-cell-local 1) (elt pdb-cell-local 2) (elt pdb-cell-local 3) (elt pdb-cell-local 4) (elt pdb-cell-local 5) pdb-spacegroup-local) "\n" ))))

(defun pdb-data-spacegroup (pdb-test-string)
  "PDB mode: Define spacegroup"
  (interactive "sPlease define spacegroup:")
  (setq pdb-spacegroup-local pdb-test-string))

;; Non-interactive Subroutines
;; pdb-specific
(defun pdb-sub-pad ()
  "PDB mode: Pad out end of each line to char 80 with sensible values"
  (let* ((str)
     (rectyp (buffer-substring (point-at-bol) (+ 6 (point-at-bol))))
     (diff (- (point-at-eol) (point-at-bol)))
     (diff2 (- 80 diff)))
    (cond ((string= rectyp "ATOM  ")
       (setq str "ATOM      1  CA  ALA A   1       0.000   0.000   0.000  1.00 20.00              "))
      ((string= rectyp  "HETATM")
       (setq str "HETATM    1  C1  UNK A   1       0.000   0.000   0.000  1.00 20.00              "))
      ((string= rectyp  "TER   ")
       (setq str "TER       1      ALA A   1                                                      "))
      ((string= rectyp  "ANISOU")
       (setq str "ANISOU    1  CA  ALA A   1     2564   3236   4519    555  -1067    578          ")))
    (if (< diff 80)
    (progn
      (goto-char (point-at-eol))
      (insert-string (substring str (* -1 diff2)))
      (setq pdb-end-user-region (+ diff2 pdb-end-user-region))))))

(defun pdb-sub-defineregion (b e)
  "PDB mode: Sort out region limits to cover complete records"
  (goto-char (- e 1))
  (cond ((< (point-at-eol) (point-max))
     (setq e (+ (point-at-eol) 1 )))
    ((= (point-at-eol) (point-max))
     (setq e (point-at-eol))))
  (setq pdb-end-user-region e)
  (goto-char b)
  (setq pdb-start-user-region (point-at-bol))
  (goto-char pdb-start-user-region))

(defun pdb-sub-markregion ()
  "PDB mode: Mark out region"
  (goto-char pdb-end-user-region)
  (set-mark pdb-start-user-region)
  (activate-region))

(defun pdb-sub-selectlocal (pdb-test-string)
  "PDB mode: Select current chain/residue"
  ;; elisp has no not (regexp) search, so this is complicated
  (beginning-of-line)
  ;; go back to closest non-matching residue
  (while (progn
       (re-search-backward "^." nil t)
       (cond ((= (point) (point-min))
          (goto-char (point-at-bol))
          (setq pdb-start-user-region (point-at-bol))
          nil)
         ((not (looking-at
            (concat "^\\(ATOM  \\|HETATM\\|ANISOU\\)"
                pdb-test-string)))
          (setq pdb-start-user-region (+ (point-at-eol) 1))
          nil)
         (t))))
  (goto-char pdb-start-user-region)
  ;; find next non-matching residue
  (while (progn
       (re-search-forward "^\\(ATOM  \\|HETATM\\|ANISOU\\)" (point-max) 1 nil)
       (cond ((not (looking-at pdb-test-string))
          (progn
            ;; roll back to previous matching residue
            (goto-char (- (point-at-bol) 1 ))
            (re-search-backward "^\\(ATOM  \\|HETATM\\|ANISOU\\)" nil (point) nil)
            (goto-char (+ 1 (point-at-eol))))
          nil)
         (t))))
  (setq pdb-end-user-region (point-at-bol))
  ;; mark out region
  (set-mark pdb-start-user-region)
  (goto-char pdb-end-user-region)
  (activate-region))

(defun pdb-sub-change ( pdb-test-string start length)
  "PDB mode: Change given string at given position"
  (while (< (point) pdb-end-user-region)
    (cond ((< start 30)
       (if (> start 15)
           (re-search-forward "^\\(ATOM\\|HETATM\\|ANISOU\\|TER   \\)" nil 1 nil)
       (re-search-forward "^\\(ATOM\\|HETATM\\|ANISOU\\)" nil 1 nil)))
      ((> start 29)
       (re-search-forward "^\\(ATOM\\|HETATM\\)" nil 1 nil)))
    (cond ((< (point) pdb-end-user-region)
       (pdb-sub-change2 pdb-test-string start length)))))

(defun pdb-sub-change2 (pdb-test-string start length)
  (pdb-sub-pad)
  (delete-region (+ (point-at-bol) start) (+ (point-at-bol) (+ start length)))
  (goto-char  (+ (point-at-bol) start))
  (insert pdb-test-string))

(defun pdb-sub-orth2frac ()
  "PDB mode: Store orth2frac matrix in pdb-orth2frac-local"
  (let* ((t11 (/ (asin 1) 90))
     (als (* t11 (elt pdb-cell-local 3)))
     (bes (* t11 (elt pdb-cell-local 4)))
     (gas (* t11 (elt pdb-cell-local 5)))
     (t11 (/ 1 (elt pdb-cell-local 0)))
     (t12 (/ (* -1 (cos gas)) (* (sin gas) (elt pdb-cell-local 0))))
     (t22 (/ 1 (* (elt pdb-cell-local 1) (sin gas) )))
     (cosalstar (/ (- (* (cos gas) (cos bes)) (cos als)) (* (sin bes) (sin gas))))
     (cosbestar (/ (- (* (cos gas) (cos als)) (cos bes)) (* (sin als) (sin gas))))
     (sinalstar (sqrt (- 1 (* cosalstar cosalstar))))
     (v (* (elt pdb-cell-local 0) (elt pdb-cell-local 1) (elt pdb-cell-local 2) sinalstar (sin bes) (sin gas)))
     (astar (/ (* (elt pdb-cell-local 1) (elt pdb-cell-local 2) (sin als)) v))
     (bstar (/ (* (elt pdb-cell-local 0) (elt pdb-cell-local 2) (sin bes)) v))
     (cstar (/ (* (elt pdb-cell-local 0) (elt pdb-cell-local 1) (sin gas)) v))
     (t13 (* astar cosbestar))
     (t23 (* bstar cosalstar))
     (t33 cstar))
    (setq pdb-orth2frac-local (list t11 t12 t13 0 t22 t23 0 0 t33))))

(defun pdb-sub-frac2orth ()
  "PDB mode: Store frac2orth matrix pdb-frac2orth-local"
(let* ((t11 (/ (asin 1) 90))
       (als (* t11 (elt pdb-cell-local 3)))
       (bes (* t11 (elt pdb-cell-local 4)))
       (gas (* t11 (elt pdb-cell-local 5)))
       (t22 (sin gas))
       (t12 (cos gas))
       (t13 (cos bes))
       (t33 (+ (* (sin als) (sin als)) (* (sin bes) (sin bes)) (* t22 t22) (* 2 (cos als) t12  t13 ) (* -1 2)))
       (t33 (/ (* (elt pdb-cell-local 2) (sqrt t33)) t22))
       (t23 (/ (* (elt pdb-cell-local 2) (- (cos als) (* t12 t13))) t22))
       (t13 (* t13 (elt pdb-cell-local 2)))
       (t12 (* t12 (elt pdb-cell-local 1)))
       (t22 (* t22 (elt pdb-cell-local 1)))
       (t11 (elt pdb-cell-local 0)))
  (setq pdb-frac2orth-local (list t11 t12 t13 0 t22 t23 0 0 t33))))

;;Maths
(defun pdb-sub-rot2mat (th v)
  "PDB mode: Convert angle + 1x3 vector to 3x3 rotation matrix"
  (let* (
     (mag (sqrt (+ (* (elt v 0) (elt v 0)) (* (elt v 1) (elt v 1)) (* (elt v 2) (elt v 2))))))
    (if (< mag 0.0001) (list 1 0 0 0 1 0 0 0 1)
      (let* (
         (x (/ (elt v 0) mag))
         (y (/ (elt v 1) mag))
         (z (/ (elt v 2) mag))
         (c (cos th))
         (s (sin th))
         (c2 (- 1 c)))
    (list
     (+ (* c2 x x) c)
     (+ (* c2 x y) (* s z))
     (- (* c2 x z) (* s y))
     (- (* c2 x y) (* s z))
     (+ (* c2 y y) c)
     (+ (* c2 y z) (* s x))
     (+ (* c2 x z) (* s y))
     (- (* c2 y z) (* s x))
     (+ (* c2 z z) c))))))

(defun pdb-sub-matxmat (m1 m2)
  "PDB mode: Multiply two 3x3 matrices"
  (let* (
     (m10 (elt m1 0))
     (m11 (elt m1 1))
     (m12 (elt m1 2))
     (m13 (elt m1 3))
     (m14 (elt m1 4))
     (m15 (elt m1 5))
     (m16 (elt m1 6))
     (m17 (elt m1 7))
     (m18 (elt m1 8))
     (m20 (elt m2 0))
     (m21 (elt m2 1))
     (m22 (elt m2 2))
     (m23 (elt m2 3))
     (m24 (elt m2 4))
     (m25 (elt m2 5))
     (m26 (elt m2 6))
     (m27 (elt m2 7))
     (m28 (elt m2 8)))
    (list (+ (* m10 m20) (* m11 m23) (* m12 m26))
      (+ (* m10 m21) (* m11 m24) (* m12 m27))
      (+ (* m10 m22) (* m11 m25) (* m12 m28))
      (+ (* m13 m20) (* m14 m23) (* m15 m26))
      (+ (* m13 m21) (* m14 m24) (* m15 m27))
      (+ (* m13 m22) (* m14 m25) (* m15 m28))
      (+ (* m16 m20) (* m17 m23) (* m18 m26))
      (+ (* m16 m21) (* m17 m24) (* m18 m27))
      (+ (* m16 m22) (* m17 m25) (* m18 m28)))))

(defun pdb-sub-vecxmat (v rm)
  "PDB mode: Multiply 1x3 vector by 3x3 matrix"
  (let* (
     (x (elt v 0))
     (y (elt v 1))
     (z (elt v 2))
     (r0 (elt rm 0))
     (r1 (elt rm 1))
     (r2 (elt rm 2))
     (r3 (elt rm 3))
     (r4 (elt rm 4))
     (r5 (elt rm 5))
     (r6 (elt rm 6))
     (r7 (elt rm 7))
     (r8 (elt rm 8)))
    (list
     (+ (* x r0) (* y r1) (* z r2))
     (+ (* x r3) (* y r4) (* z r5))
     (+ (* x r6) (* y r7) (* z r8)))))

(defun pdb-sub-dihedral (p1 p2 p3 p4)
  "PDB mode: Calculate angle between 2 vectors"
  (let* ((v1 (list (-(elt p2 0) (elt p1 0))(-(elt p2 1) (elt p1 1))(-(elt p2 2) (elt p1 2))))
     (v2 (list (-(elt p2 0) (elt p3 0))(-(elt p2 1) (elt p3 1))(-(elt p2 2) (elt p3 2))))
     (v3 (list (-(elt p4 0) (elt p3 0))(-(elt p4 1) (elt p3 1))(-(elt p4 2) (elt p3 2))))
     (p (pdb-sub-cross v1 v2))
     (q (pdb-sub-cross v2 v3))
     (theta (pdb-sub-angle p q))
     (r (pdb-sub-cross p q))
     (n (/(pdb-sub-dot v2 r) (abs (pdb-sub-dot v2 r)))))
    (* n theta)))


(defun pdb-sub-cross (v1 v2)
  "PDB mode: Calculate cross product between 2 vectors"
  (list (- (* (elt v1 1) (elt v2 2)) (* (elt v1 2) (elt v2 1)))
    (- (* (elt v1 2) (elt v2 0)) (* (elt v1 0) (elt v2 2)))
    (- (* (elt v1 0) (elt v2 1)) (* (elt v1 1) (elt v2 0)))))

(defun pdb-sub-dot (v1 v2)
  "PDB mode: Calculate dot product between 2 vectors"
  (+ (* (elt v1 0) (elt v2 0)) (* (elt v1 1) (elt v2 1)) (* (elt v1 2) (elt v2 2))))

(defun pdb-sub-len (v1)
  "PDB mode: Calculate magnitude of vector"
  (sqrt (+ (*(elt v1 0) (elt v1 0)) (* (elt v1 1) (elt v1 1)) (* (elt v1 2) (elt v1 2)))))

(defun pdb-sub-angle (v1 v2)
  "PDB mode: Calculate angle (degrees) between 2 vectors"
  (* (pdb-sub-anglerad v1 v2) 57.29578))

(defun pdb-sub-anglerad (v1 v2)
  "PDB mode; Calculate angle (radians) between 2 vectors"
  (acos (/ (pdb-sub-dot v1 v2) (* (pdb-sub-len v1) (pdb-sub-len v2)))))

;;Mouse bindings
(defun pdb-sub-mouse-cmouse2 (event)
  "PDB mode: Sets the point at the mouse location, then highlights current residue"
  (interactive "@e")
  (mouse-set-point event)
  (pdb-select-residue))

(defun pdb-sub-mouse-cmmouse2 (event)
  "PDB mode: Sets the point at the mouse location, then highlights current chain"
  (interactive "@e")
  (mouse-set-point event)
  (pdb-select-chain ""))

;;Web connection

(defun pdb-new-prodrg (b e)
  "PDB mode: Submit coordinates to PRODRG server"
  (interactive "r")
  (pdb-sub-defineregion b e)
  (pdb-sub-markregion)
  (let ((view-read-only nil)
    (word (buffer-substring b e)))
    (pop-to-buffer "*PRODRG*")
    (setq buffer-read-only nil)
    (erase-buffer)
    (if (< (length word) 150)
    (error "ERROR[PDB]: Fewer than 150 characters. Try again with a bigger region."))
    (if (not (string-match "\\(^ATOM\\|^HETATM\\)" word))
    (error "ERROR[PDB]: No ATOM or HETATM records. Try again with some atoms."))
    (pdb-sub-posturl word)))

(defun pdb-new-pdb (c)
  "PDB mode: New buffer with PDB file"
  (interactive "sPDB ID: ")
  (goto-char (point-at-bol))
  (let ((view-read-only nil))
    (kill-buffer (get-buffer-create (upcase c)))
    (message (concat "PDB mode: Obtaining coordinates for " c " from PDB ..."))
    (pdb-sub-geturl (get-buffer-create (upcase c))  "oca.ebi.ac.uk" 80 (concat "oca-bin/send-pdb?id=" c ))
    (setq buffer-file-name (concat c ".pdb"))))

(defun pdb-new-hicup (c)
  "PDB mode: Insert compound from HICUP"
  (interactive "sPDB residue name: ")
  (goto-char (point-at-bol))
  (let ((bufname buffer-file-name))
    (cond ((string= c "o2") (pdb-sub-geturl (get-buffer-create (concat "HICUP-" (buffer-name (current-buffer)))) "xray.bmc.uu.se" 80 (concat "hicup/" (upcase c) "_/" (downcase c) "_clean_pdb.txt")))
      ((= (length c) 3) (pdb-sub-geturl (get-buffer-create (concat "HICUP-" (buffer-name (current-buffer)))) "xray.bmc.uu.se" 80 (concat "hicup/" (upcase c) "/" (downcase c) "_clean_pdb.txt")))
      ((< (length c) 3) (pdb-sub-geturl (get-buffer-create (concat "HICUP-" (buffer-name (current-buffer)))) "xray.bmc.uu.se" 80 (concat "hicup/_" (upcase c) "/" (downcase c) "_clean_pdb.txt")))
      ((> (length c) 3) (error "ERROR[PDB]: Residue name too long (3 chars max.)"))
      )
    (setq buffer-file-name bufname)
    (message (concat "PDB mode: Coords for " (upcase c) " courtesy of HICUP - http://xray.bmc.uu.se/hicup/" ))))

(defun pdb-sub-posturl (data)
  "PDB mode: Attempt to download a POST request into a buffer."
  (let ((message-string (concat "coords=" data "&"))
    (tcp-connection)
    (big-string))
    (or
     (setq tcp-connection
       (open-network-stream "*PRODRG*" (get-buffer-create "*PRODRG*") "davapc1.bioch.dundee.ac.uk" 80))
     (error "ERROR[PDB]: Could not open connection to %s:%d" host port))
    (setq big-string (concat "POST /cgi-bin/prodrg/prodrg.cgi HTTP/1.0\r\nHost: davapc1.bioch.dundee.ac.uk\r\nContent-type: application/x-www-form-url-encoded\r\nContent-length: " (number-to-string (length message-string)) "\r\n\r\n" message-string "\r\n"))
    (process-send-string "*PRODRG*" big-string)
    (set-process-sentinel tcp-connection `pdb-prodrg-sentinel)))

(defun pdb-sub-geturl (buf host port file)
  "PDB mode: Attempt to download a URL into a buffer."
  (let ((tcp-connection)
        )
    (set-buffer buf)
    (or
     (setq tcp-connection
           (open-network-stream (buffer-name buf) buf host port))
     (error "ERROR[PDB]: Could not open connection to %s:%d" host port))
    (process-send-string tcp-connection (concat "GET /" file " HTTP/1.0\r\nHost:" host "\r\n\r\n"))
    (message (concat "PDB mode: Connecting to " host ))
    (cond ((string-match "HICUP" (buffer-name buf))
       (set-process-sentinel tcp-connection `pdb-hicup-sentinel))
      ((string-match "PRODRG" (buffer-name buf))
       (set-process-sentinel tcp-connection `pdb-prodrg-sentinel))
      (t
       (set-process-sentinel tcp-connection `pdb-ebi-sentinel)))
    (message (concat "PDB mode: Downloading " (buffer-name buf) " from " host " . Be patient ..."))))

(defun pdb-ebi-sentinel (process string)
  "PDB mode: Process the results from the EBI connection."
  (let ((buffer (get-buffer-create (process-name process))))
    (pop-to-buffer buffer)
    (setq inhibit-read-only t)
    (goto-char 0)
    (save-excursion   (while (re-search-forward "<.*?>" nil t)
            (replace-match "" nil nil)))
    (save-excursion   (while (re-search-forward "&gt" nil t)
            (replace-match ">" nil nil)))
    (save-excursion   (while (re-search-forward "&lt" nil t)
            (replace-match "<" nil nil)))
    (save-excursion (delete-matching-lines "\\(PDB Full entry for \\|^HTTP/1.1\\|^Date:\\|^Server:\\|^ETag:\\|^Accept-Ranges:\\|^Last-Modified:\\|^Connection:\\|^Content-Type:\\|^Content-Length:\\|^$\\|\\)"))
    (pdb-mode)
    (message (concat "PDB mode: Coords for " (process-name process) " courtesy of PDB - http://www.ebi.ac.uk/pdb" ))))

(defun pdb-prodrg-sentinel (process string)
  "Process the results from the PRODRG network connection."
  (let ((buffer (get-buffer-create (process-name process))))
    (pop-to-buffer buffer)
    (setq inhibit-read-only t)
    (goto-char 0)
    (save-excursion   (while (re-search-forward "\\([^@]\\)<.*?>" nil t)
            (replace-match (concat (match-string 1) "\n") nil nil)))
    (save-excursion   (while (re-search-forward "^<.*?>" nil t)
            (replace-match "\n" nil nil)))
    (save-excursion   (while (re-search-forward "<.*
.*?>" nil t)
            (replace-match "\n" nil nil)))
    (save-excursion   (while (re-search-forward "&gt" nil t)
            (replace-match ">" nil nil)))
    (save-excursion   (while (re-search-forward "&lt" nil t)
            (replace-match "<" nil nil)))
    (save-excursion (delete-matching-lines "\\(PDB Full entry for \\|^HTTP/1.1\\|^Date:\\|^Server:\\|^ETag:\\|^Accept-Ranges:\\|^Last-Modified:\\|^Connection:\\|^Content-Type:\\|^Content-Length:\\|^$\\|\\)"))
    (message (concat "PDB mode: Coords/geometry courtesy of PRODRG - http://davapc1.bioch.dundee.ac.uk/cgi-bin/prodrg/prodrg.cgi" ))))

(defun pdb-hicup-sentinel (process string)
  "PDB mode: Process the results from the HICUP network connection."
  (let ((buffer (get-buffer-create (process-name process)))
    (oldbuf (substring (process-name process) 6 )))
    (pop-to-buffer buffer)
    (setq inhibit-read-only t)
    (goto-char 0)
    (save-excursion (delete-matching-lines "\\(PDB Full entry for \\|^HTTP/1.1\\|^Date:\\|^Server:\\|^ETag:\\|^Accept-Ranges:\\|^Last-Modified:\\|^Connection:\\|^Content-Type:\\|^Content-Length:\\|^$\\|\\|^END\\)"))
    (save-excursion (delete-blank-lines))
    (pop-to-buffer oldbuf)
    (insert-buffer-substring buffer)
    (really-kill-buffer buffer)
    (pop-to-buffer oldbuf)))

(defun really-kill-buffer (buffer)
  "PDB mode: Function to kill buffer without confirmation even if altered."
  (switch-to-buffer buffer)
  (set-buffer-modified-p nil)
  (kill-buffer buffer))

(run-hooks 'pdb-menu-hook 'pdb-mode-hook))

(provide 'pdb-mode)

;;; pdb-mode.el ends here
