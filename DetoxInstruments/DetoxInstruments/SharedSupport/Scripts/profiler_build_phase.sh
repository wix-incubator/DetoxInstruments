#!/bin/bash

#if [ "${CONFIGURATION}" != "Debug" ]; then
#    echo "Profiler not included: current build configuration is not 'Debug'."
#    exit 0
#fi

PROFILER_LIB_DIR="iphoneos"
INSTRUMENTS_SCRIPTS_DIR="${0%/*}"
PROFILER_FRAMEWORK_NAME="DTXProfiler.framework"
PROFILER_FRAMEWORK_PATH="${INSTRUMENTS_SCRIPTS_DIR}/../${PROFILER_LIB_DIR}/${PROFILER_FRAMEWORK_NAME}"

if [ -e "${PROFILER_FRAMEWORK_PATH}" ]; then
    cp -Rf "$PROFILER_FRAMEWORK_PATH" "${CODESIGNING_FOLDER_PATH}/"
    if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" ]; then
      codesign -fs "${EXPANDED_CODE_SIGN_IDENTITY}" "${CODESIGNING_FOLDER_PATH}/${PROFILER_FRAMEWORK_NAME}"
    fi
	echo "Profiler has been included in ${CODESIGNING_FOLDER_PATH}."

    LLDB_INIT_FILE=~/.lldbinit
    LLDB_INIT_MAGIC_STRING="### Profiler LLDB commands support"

    if [ ! -e "${LLDB_INIT_FILE}" ] || ! grep -q "${LLDB_INIT_MAGIC_STRING}" "${LLDB_INIT_FILE}"; then
        echo "Note: it looks like the profiler debugger commands are not installed. Please refer to 'Loading the profiler via an Xcode Breakpoint' section of the INTEGRATION.md for information about loading DTXProfiler.framework included in this build."
    fi
else
echo "${PROFILER_FRAMEWORK_NAME} not loaded because it could not be found."
fi
