# ``dwi_preproc``  

Preprocesses (neonatal) dMRI data using key steps from the dHCP neonatal dMRI preprocessing pipeline. 
This pipeline requires FSL, Python 3, and MRtrix3 (more speficially MRtrix3 ``SS3T_beta``).

NOTE: Currently still a work in progress.


# Installation

## External Dependencies

* **NOTE: Table is work in progress.**

| Dependency  | Environmental variable (if applicable)  |
|---|---|
| [`FSL`](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/)  | `FSLDIR`  |

## Python Dependencies
NumPy.

## Package/Script Installation

```bash
# Clone repository
git clone https://github.com/AdebayoBraimah/dwi_preproc.git

# Change branch to the neonate branch
cd dwi_preproc
git checkout neonate

# Download tractography wrapper CLI
git submodule update --init -- pkgs
```



