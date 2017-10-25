#!/bin/bash
set -e
PROFILER_LIB_DIR="ProfilerFramework"
INSTRUMENTS_SCRIPTS_DIR="${0%/*}"
PROFILER_FRAMEWORK_NAME="DTXProfiler.framework"
PROFILER_FRAMEWORK_PATH="${INSTRUMENTS_SCRIPTS_DIR}/../${PROFILER_LIB_DIR}/${PROFILER_FRAMEWORK_NAME}"

echo "${PROFILER_FRAMEWORK_PATH}"

if [ -e "${PROFILER_FRAMEWORK_PATH}" ]; then
	mkdir -p "${CODESIGNING_FOLDER_PATH}"/Frameworks
    cp -rf "$PROFILER_FRAMEWORK_PATH" "${CODESIGNING_FOLDER_PATH}"/Frameworks
    if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" ]; then
      codesign -fs "${EXPANDED_CODE_SIGN_IDENTITY}" "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"
    fi
	echo "Profiler framework has been included in ${CODESIGNING_FOLDER_PATH}."
else
	echo "Profiler framework not loaded because it could not be found."
	exit -1
fi
