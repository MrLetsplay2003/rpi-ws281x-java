#!/bin/bash

# ---------------------------------------------------------------------------------------------------------------------
# Compiles shared libraries required for interfacing with Raspberry Pi GPIO hardware from Java, using JNI.
# ---------------------------------------------------------------------------------------------------------------------
# Author(s):    limpygnome <limpygnome@gmail.com>, mbelling <matthew.bellinger@gmail.com>
# ---------------------------------------------------------------------------------------------------------------------

# *********************************************************************************************************************
# Configuration
# *********************************************************************************************************************

#This is needed since somehow the swig command isn't being found on my RasPi 0 otherwise
PATH=$PATH:/usr/local/bin/
# This defines the JDK to use for JNI header files; automatically picks first dir using ls
JDK_PATH="/usr/lib/jvm"
JDK_DIR=$(ls "${JDK_PATH}" | head -n 1)
JDK_FULL_PATH="${JDK_PATH}/${JDK_DIR}"

# The libs to include when building C files using GCC
GCC_INCLUDES="-I${JDK_FULL_PATH}/include -I${JDK_FULL_PATH}/include/linux"

# Relative dir names for input/output
BASE_DIR="$(realpath "$(dirname "$0")/../..")"
OUTPUT="${BASE_DIR}/build"
SWIG_SRC="${BASE_DIR}/src/swig"
SWIG_OUT_JAVA="${OUTPUT}/generatedSource/java/com/github/mbelling/ws281x/jni"
SWIG_PACKAGE_NAME="com.github.mbelling.ws281x.jni"
NATIVE_SRC="${BASE_DIR}/src/native/rpi_ws281x"
NATIVE_LIB_NAME="ws281x.so"
LIB_BASE_NAME="libws281x"
WRAPPER_LIB_NAME="${LIB_BASE_NAME}.so"


# *********************************************************************************************************************
# Functions
# *********************************************************************************************************************

function programInstalled
(
    CMD="${1}"
    EXPECTED="${2}"
    ERROR="${3}"
    SUCCESS="${4}"

    OUTPUT=$(eval ${CMD} || echo "fail")
    if [[ "${OUTPUT}" != *"${EXPECTED}"* ]]; then
        echo "${ERROR}"
        exit 1
    else
        echo "${SUCCESS}"
    fi
)

# *********************************************************************************************************************
# Main
# *********************************************************************************************************************
echo "**********************[createNativeLibLocal.sh]*************************"
echo "*                                                                      *"
echo "*               NeoPixel ws281x Library Compiler                       *"
echo "*                                                                      *"
echo "************************************************************************"

# Check dependencies installed
set -e
programInstalled "swig -version" "SWIG Version" "Error - SWIG is not installed, cannot continue! Check out the tutorial in this repo's README!" "✅ - SWIG installed..."
programInstalled "java --version" "Runtime Environment" "Error  -  Java is not installed, cannot continue! (SWIG won't work either w/out java btw... Check out the tutorial in the README!)"
programInstalled "gcc --version" "free software" "Error - GCC is not installed, cannot continue!" "✅ - GCC installed..."
programInstalled "ar --version" "free software" "Error - AR is not installed, cannot continue!" "✅ - AR installed..."
programInstalled "ranlib -v" "free software" "Error - ranlib is not installed, cannot continue!" "✅ - ranlib installed..."
programInstalled "git --version" "git version" "Error - git is not installed, cannot continue!" "✅ - git installed..."
set +e

# Create all the required dirs
echo "Creating required dirs..."
mkdir -p "${SWIG_OUT_JAVA}"

# Building swig wrapper
echo "Building JNI interface using SWIG..."
swig -v -java -outdir "${SWIG_OUT_JAVA}" -package "${SWIG_PACKAGE_NAME}" -o "${NATIVE_SRC}/extra/rpi_ws281x_wrap.c" "${SWIG_SRC}/rpi_ws281x.i"

echo "Compiling library..."
CMAKE_EXTRA="-DCMAKE_C_FLAGS='-I/usr/lib/jvm/java-17-openjdk-amd64/include -I/usr/lib/jvm/java-17-openjdk-amd64/include/linux'" sh "${NATIVE_SRC}/docker_build.sh" "apt install -y openjdk-17-jdk"
cp "${NATIVE_SRC}/build.aarch64/libws2811.aarch64.so" build/nativeLib/libws281x.so
