# PREREQUISITES
1. **WSL2** if on **Windows 10** or **Windows 11**.
2. **Docker** (or **Docker Desktop** for **Windows**)
3. Up-to-date **NVidia Driver**
3. **NVidia Container Toolkit**

# MANUAL
## TO CREATE THE IMAGE
From `shell`:
1. Change current directory to where the repository is located, using the command `cd`
2. Build the image using the command `docker build .`. You can provide a tag to an image
using flag `-t <name>:<tag>`
```
docker build <path_to_Dockerfile> -t <name>:<tag>
```

## TO RUN THE IMAGE IN A CONTAINER
From `shell`:
1. Use the command `docker run <name>:<tag>`. Recommended flags: `--rm` to remove the
container upon stopping, `-it` to allow transfer into container context mode in a terminal.
`--gpus all` in order for container to be able to use host's gpu (without that, sample
does not run successfully)

```
docker run --rm -it --gpus all <name>:<tag>
```

# IMAGE COMPOSITION
The image is based on `nvcr.io/nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04` from
nvcr.io (NVidia Container Repository a.k.a NGC Catalog)

When building an image, builder walks through the next steps/stages:
1. Download necessery files
2. Install necessery libs and their dependencies
3. Build sample

Upon starting, the container executes NVidia's built in script as `entrypoint`. Then it
executes `cmd-script.sh` located inside the `scripts` directory. To disable this behavior,
check Docker reference for the `docker run` flag `--entrypoint` and the parameter
`command`.

## USED LIBRARIES
1. NVidia CUDA Toolkit 11.8
2. NVidia cuDNN 8.9.7
3. TensorRT 8.5.3
4. ONNXRuntime 1.14.0

## DEFAULT WORKDIR
`/usr/local/src`. It contains:
1. Directory `samples` which is a copy of `samples-commented` in repository
2. Directory `squeezenet` which contains:
    1. `capi_test` - result of building the target sample. This file may be reffered to
    as "the application" in this document.
    2. `squeezenet.onnx` - model that is used by the application.

# SCRIPTS
All scripts are located inside the `scripts` directory of repository and
`/usr/local/src` containerside.

## CMD-SCRIPT
Wraps the application to ease debugging runtime errors, if they occur.

This is the only script, that is actually used by container. It is automatically
invoked when running an image (starting a container), unless `command` argument
was provided to `docker run <flags> <image> <command>`. 

## GSC-SCRIPT
Uses Git Sparse-Checkout to download only the needed files from sample repository

Not used by the image, left as to give reference, how exactly container could be
using git clone when running/building. Since most of commented code will already
be present in repository, it is much more efficient to just copy it inside the image
instead of redownloading it.

This script was used once, to populate `samples-commented` directory

## ENTRYPOINT-SCRIPT
Verifies installation of some tools and always invoked when running (starting)
container.

Not used by the image, left as an artefact

# TO DO LIST
* comment on required cpp's code
* comment on cmake code
* finish README.md
* fine-polish everything
* add english localization release-tag
* add russian localization as fork and release-tag
