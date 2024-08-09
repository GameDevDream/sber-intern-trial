# PREAMBLE
This document's intention is to help user to setup everything needed for 
building and running the container. Since my machine uses Windows 10 as an
OS, I do not have the proper knowledge nor experience to include instructions
for Linux or Mac native machines. It is supposed that the setup steps
would be the same for Windows 11, some of setup steps can be omitted for
Linux or done diferrently for Mac. In any case, it is HIGHLY RECOMMENDED that
if user's machine is not Windows 10 native, they should use official setup
guidelines and keep this document only as a reference.

# COMPLETE SETUP MANUAL
## Install Docker
Docker's one and only intended platform is Linux. There is no Docker
for Windows ~yet~. But there is an official work-around. Docker can be
installed on a VM, that emulates Linux kernel. Initialy, Docker would
run on Hyper-VM and this option is still available, but considered
deprecated. As of today, Windows 10 and Windows 11 come with an optional
feature "Windows Subsystem for Linux" (WSL2). In essence, it's a
containerized Linux kernel managed by Windows (hence SUBsystem), that is
fine-tuned by Microsoft themselves in order to achieve maximum performance.
Since WSL2 is a container it provides better performance than any VM by
definition (in a sence that container does not emulate hardware). Docker
acknowleges this and WSL2 is highly recommended to use for Docker Engine
(and is MANDATORY for deep learning)

So in order to be able to build image described in `Dockerfile`:
1. Enable WSL2
2. Install Linux distro on top of WSL2. Ubuntu is recommended by oficial
guidelines.
3. Install Docker Desktop from an official website. Make sure that Docker
engine will use WSL2 as Host, either by checking an option in installer
or in Docker Desktop settings.

## Install dependencies
The image described in `Dockerfile` will require dependencies set beforehand
BOTH in image's build-time and runtime.

Run time dependencies are set automatically during build and do not require
active involvement of user. Those are:
1. NVidia CUDA
2. NVidia cuDNN
3. ONNX runtime (dependant on CUDA and cuDNN in order to execute sample)

Build time dependencies have to be set manually before starting build
process. Those are:
1. NVidia CUDA Toolkit

NVidia CUDA should be able to access host GPU, regardless of it's run
environment. Since we don't invoke it in hosts environment, we are not
required to install it directly on host. However, there is a need for a
"bridge" between a container and host GPU. Hence why we manually
install NVidia CUDA Toolkit.

In order to install NVidia CUDA Toolkit for WSL2:
1. Host machine must have NVidia GPU.
2. Enable WSL2 and install distro if not already.
3. Update NVidia GPU's driver using an official web-site. According to official
guidelines, this also installs the driver directly inside WSL2's subsystem.
Reupdating them inside WSL2 can ruin the installation process so proceed with
caution.
4. Remove old Nvidia GPG key for package manager. This ensures that package
manager gets up-to-date packages of all NVidia's software. Make sure to install
up-to-date GPG key beforehand. 
5. Install NVidia CUDA Toolkit for WSL2 from WSL2's terminal using offical
tool. Pay attention to the 'Distribution' option: it should be "WSL-Ubuntu",
since it does not include GPU driver installation.

## Build an image
After successful installation of Toolkit, build image described in Dockerfile.

### Build-time
Build script will automatically:
1. Mount directories [DIR1 DIR2...] into container
2. Clone ONNXRuntime repository inside
3. Build ONNXRuntime image based on ubuntu:22.04 with NVidia CUDA and cuDNN
installed
4. Mounts named volume `TAS-git-repoes`

### Runtime
When starting the container:
1. Echoes some text and verifies installation of `git`, `cmake` and `g++`
2. Clones ONNXRuntime inference example inside `repo` volume if this wasn't
done in previos image runs.
3. Compiles and Builds squeezenet sample executable.
4. Executes the result

Steps 2-4 are executed as `CMD`. They can be overwriten by providing
a command as an argument when running an image. 

Step 1 is executed as `ENTRYPOINT`. It can be overwritten by using
`--entrypoint` flag when running image. This might force user to also
explicitly provide a command.