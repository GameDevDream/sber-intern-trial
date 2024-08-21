#!/bin/bash

echo "
===============================================================================
CMD: cmd-script.sh
Executing capi_test (ONNXRuntime Inference sample - Squeezenet)
"
cd squeezenet
if ./capi_test; then
    echo "
Execution success!
"
else
    echo "
Execution failed. Check Error message for clues. List of encountered and solved:
    1. Build time error #include \"*onnxruntime.h*\" no such file - onnxruntime
       installation was incorrect or unfinished. Check, if onnxruntime is installed
       locally (both in /usr/local/include/onnxruntime and /usr/local/lib). If
       installation was portable, rebuild application from root of 'samples' directory:
       cmake <path_to_samples> -DONNXRUNTIME_ROOTDIR=<path_to_ort_installation>
    2. Runtime error libcu*.so.* not found - application was looking for the version
       of CUDA Toolkit or cuDNN, that is different from installed in container. Either
       manually add symlinks (it is discouraged to do so) or rebuild image with
       other versions of libraries.
    3. Runtime error libnv*.so.* not found - same as "1." but for tensorrt-libs. It is
       possible that it was not installed at all.
    4. Runtime error *ModelProto* or *Protobuf*. squeezenet.onnx might have been
       downloaded incorrectly. Check if download was ever finished and if you've
       provided correct URL.
    5. Runtime error *Model not found* - capi_test was not able to find squeezenet.onnx
       in USER's current working directory. Make sure to cd <path_to_application> before
       execution. Make sure, current working directory contains squeezenet.onnx
    6. Runtime error *tensorrt unsupported SM 0x* - tensorrt does not support gpu that
       was passed to this container. Check that when using docker run you provide
       flag --gpus and then set it's value to tensorrt-compatible gpu (or --gpus all).
       Alternatively, rebuild image with proper version of tensorrt-libs. For example,
       all NVidia Pascal gpus (GTX 10xx) are unsupported by tensorrt since 8.6. Error
       code will be \"unsupported SM 0x601\"
"
fi
echo "
===============================================================================
Exiting...
"