#!/bin/bash
set -e -x

INSTRUMENTS_SCRIPTS_DIR="${0%/*}"

PROFILER_LIB_DIR="ProfilerFramework"
PROFILER_FRAMEWORK_NAME="DTXProfiler.framework"
PROFILER_FRAMEWORK_PATH="${INSTRUMENTS_SCRIPTS_DIR}/../${PROFILER_LIB_DIR}/${PROFILER_FRAMEWORK_NAME}"

SHIM_LIB_DIR="ShimFramework"
SHIM_FRAMEWORK_NAME="DTXProfilerShim.framework"
SHIM_FRAMEWORK_PATH="${INSTRUMENTS_SCRIPTS_DIR}/../${SHIM_LIB_DIR}/${SHIM_FRAMEWORK_NAME}"

CONFIGURATION=$1
# Clean any leading or trailing whitespace from list of allowed configurations
ALLOWED_CONFIGURATIONS=`echo "$2" | perl -e "s/\s*\,\s*/\ /g" -p`

thin_framework() {
	EXTRACTED_ARCHS=()
	
	FRAMEWORK_PATH="$1"
	FRAMEWORK_BIN_NAME="$2"
	
	echo "Processing architectures of $FRAMEWORK_BIN_NAME"

	for ARCH in $ARCHS
	do
		echo "Extracting $ARCH"
		lipo -extract "${ARCH}" "${FRAMEWORK_PATH}"/"${FRAMEWORK_BIN_NAME}" -o "${FRAMEWORK_PATH}"/"${FRAMEWORK_BIN_NAME}-${ARCH}"
		EXTRACTED_ARCHS+=("${FRAMEWORK_PATH}"/"${FRAMEWORK_BIN_NAME}-${ARCH}")
	done

	echo "Merging extracted architectures: ${ARCHS}"
	lipo -o "${FRAMEWORK_PATH}"/"${FRAMEWORK_BIN_NAME}-merged" -create "${EXTRACTED_ARCHS[@]}"
	rm "${EXTRACTED_ARCHS[@]}"

	echo "Replacing original executable with thinned version"
	rm "${FRAMEWORK_PATH}"/"${FRAMEWORK_BIN_NAME}"
	mv "${FRAMEWORK_PATH}"/"${FRAMEWORK_BIN_NAME}-merged" "${FRAMEWORK_PATH}"/"${FRAMEWORK_BIN_NAME}"
}

if [ -e "${PROFILER_FRAMEWORK_PATH}" ]; then
	mkdir -p "${CODESIGNING_FOLDER_PATH}"/Frameworks

	if [ -d "${CODESIGNING_FOLDER_PATH}"/Frameworks/DTXProfiler.framework ]; then
		rm -fr "${CODESIGNING_FOLDER_PATH}"/Frameworks/DTXProfiler.framework
	fi

	rm -f "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"
	if [[ " ${ALLOWED_CONFIGURATIONS[@]} " =~ " ${CONFIGURATION} " ]]; then
		cp -Rf "${PROFILER_FRAMEWORK_PATH}" "${CODESIGNING_FOLDER_PATH}"/Frameworks/
		## 🤦‍♂️ rdar://45972646 "Notarization service fails for an app with an iOS framework embedded in it"
		openssl enc -aes-256-cbc -d -K 0 -iv 0 -nosalt -in "${PROFILER_FRAMEWORK_PATH}"/DTXProfiler -out "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
		openssl enc -aes-256-cbc -d -K 0 -iv 0 -nosalt -in "${PROFILER_FRAMEWORK_PATH}"/Frameworks/DetoxSync.framework/DetoxSync -out "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"/Frameworks/DetoxSync.framework/DetoxSync
		
		echo "Profiler framework has been integrated in ${CODESIGNING_FOLDER_PATH}."
	else
		cp -Rf "${SHIM_FRAMEWORK_PATH}" "${CODESIGNING_FOLDER_PATH}"/Frameworks/
		cp -f "${PROFILER_FRAMEWORK_PATH}"/Info.plist "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${SHIM_FRAMEWORK_NAME}"
		mv "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${SHIM_FRAMEWORK_NAME}" "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"
		mv "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"/DTXProfilerShim "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
		## 🤦‍♂️ rdar://45972646 "Notarization service fails for an app with an iOS framework embedded in it"
		openssl enc -aes-256-cbc -d -K 0 -iv 0 -nosalt -in "${SHIM_FRAMEWORK_PATH}"/DTXProfilerShim -out "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
		# install_name_tool -id "DTXProfiler" "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
		echo "Profiler framework not integrated: current build configuration “${CONFIGURATION}” is not included in the ALLOWED_CONFIGURATIONS list."
	fi
	
	if [ "${ENABLE_BITCODE}" = "NO" ]; then
		echo "Stripping bitcode"
		xcrun bitcode_strip -r "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"/DTXProfiler -o "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
	fi
	
	thin_framework "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}" "DTXProfiler"
	if [ -d "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}/Frameworks/DetoxSync.framework" ]; then
		thin_framework "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}/Frameworks/DetoxSync.framework" "DetoxSync"
	fi

	if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" ]; then
		codesign -fs "${EXPANDED_CODE_SIGN_IDENTITY}" "${CODESIGNING_FOLDER_PATH}"/Frameworks/"${PROFILER_FRAMEWORK_NAME}"
	fi

	if [ -d "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}" ]; then
		rm -fr "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}"
	fi

	cp -rf "${PROFILER_FRAMEWORK_PATH}" "${BUILT_PRODUCTS_DIR}/"
	rm -f "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
	rm -fr "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}"/*.momd
	rm -fr "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}"/Frameworks

	echo "Profiler framework headers have been copied to ${BUILT_PRODUCTS_DIR}"
else
	echo "Profiler framework could not be found. Make sure Detox Instruments is properly installed."
	exit 255
fi
