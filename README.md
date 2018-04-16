# niifti_normalise
A script to normalise niifti (.nii .nii.gz) images using two PcTs and clamp to 0-100.
Uses fslmaths and fslstats.
You must have FSL on your path (https://fsl.fmrib.ox.ac.uk/fsl/).

Usage:
```bash 
niifti_normalise.sh -i INPUT.nii.gz -o OUTPUT.nii.gz 
```

Compulsory arguments:
-i: InputImage: in nii/nii.gz format (USE FULL PATH)
-o: OutputFile: in nii/nii.gz format (USE FULL PATH)

Optional arguments:
-b: keep all intermediate files for debug 0 = off 1 = on (default = 0)
-h: print this help screen

Send issues and comments to thomasbasilshaw@gmail.com
