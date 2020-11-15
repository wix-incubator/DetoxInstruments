#!/bin/bash
set -e -x

PLATFORM_NAME=${EFFECTIVE_PLATFORM_NAME:1}

INSTRUMENTS_SCRIPTS_DIR="${0%/*}"

PROFILER_LIB_DIR="ProfilerFramework"
PROFILER_FRAMEWORK_NAME="DTXProfiler.framework"
PROFILER_FRAMEWORK_CONTAINER="${INSTRUMENTS_SCRIPTS_DIR}/../${PROFILER_LIB_DIR}"

SHIM_LIB_DIR="ShimFramework"
SHIM_FRAMEWORK_NAME="DTXProfilerShim.framework"
SHIM_FRAMEWORK_CONTAINER="${INSTRUMENTS_SCRIPTS_DIR}/../${SHIM_LIB_DIR}"

CONFIGURATION=$1
# Clean any leading or trailing whitespace from list of allowed configurations
ALLOWED_CONFIGURATIONS=`echo "$2" | perl -e "s/\s*\,\s*/\ /g" -p`

TARGET_FRAMEWORKS="${CODESIGNING_FOLDER_PATH}/${BUNDLE_FRAMEWORKS_FOLDER_PATH}"

if [ -e "${PROFILER_FRAMEWORK_CONTAINER}" ]; then
	mkdir -p "${TARGET_FRAMEWORKS}"

	if [ -d "${TARGET_FRAMEWORKS}"/DTXProfiler.framework ]; then
		rm -fr "${TARGET_FRAMEWORKS}"/DTXProfiler.framework
	fi

	rm -f "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"
	if [[ " ${ALLOWED_CONFIGURATIONS[@]} " =~ " ${CONFIGURATION} " ]]; then
		cp -Rf "${PROFILER_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${PROFILER_FRAMEWORK_NAME}" "${TARGET_FRAMEWORKS}"

		## 🤦‍♂️ rdar://45972646 "Notarization service fails for an app with an iOS framework embedded in it"
		if [ "${PLATFORM_NAME}" == "maccatalyst" ] || [ "${PLATFORM_NAME}" == "macosx" ]; then
			openssl enc -aes-256-cbc -d -K 0 -iv 0 -nosalt -in "${PROFILER_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${PROFILER_FRAMEWORK_NAME}"/Versions/A/DTXProfiler -out "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/Versions/A/DTXProfiler
			openssl enc -aes-256-cbc -d -K 0 -iv 0 -nosalt -in "${PROFILER_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${PROFILER_FRAMEWORK_NAME}"/Versions/A/Frameworks/DetoxSync.framework/Versions/A/DetoxSync -out "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/Versions/A/Frameworks/DetoxSync.framework/Versions/A/DetoxSync
		else
			openssl enc -aes-256-cbc -d -K 0 -iv 0 -nosalt -in "${PROFILER_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${PROFILER_FRAMEWORK_NAME}"/DTXProfiler -out "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
			openssl enc -aes-256-cbc -d -K 0 -iv 0 -nosalt -in "${PROFILER_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${PROFILER_FRAMEWORK_NAME}"/Frameworks/DetoxSync.framework/DetoxSync -out "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/Frameworks/DetoxSync.framework/DetoxSync
		fi
		
		echo "Profiler framework has been integrated in ${CODESIGNING_FOLDER_PATH}."
	else
		cp -Rf "${SHIM_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${SHIM_FRAMEWORK_NAME}" "${TARGET_FRAMEWORKS}"
		mv "${TARGET_FRAMEWORKS}/${SHIM_FRAMEWORK_NAME}" "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"
		
		if [ "${PLATFORM_NAME}" == "maccatalyst" ] || [ "${PLATFORM_NAME}" == "macosx" ]; then
			cp -f "${PROFILER_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${PROFILER_FRAMEWORK_NAME}"/Versions/A/Resources/Info.plist "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/Versions/A/Resources
			mv "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/Versions/A/DTXProfilerShim "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/Versions/A/DTXProfiler
			rm -f "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/DTXProfilerShim
			pushd .
			cd "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"
			ln -s Versions/Current/DTXProfiler DTXProfiler
			popd
			
			## 🤦‍♂️ rdar://45972646 "Notarization service fails for an app with an iOS framework embedded in it"
			openssl enc -aes-256-cbc -d -K 0 -iv 0 -nosalt -in "${SHIM_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${SHIM_FRAMEWORK_NAME}"/Versions/A/DTXProfilerShim -out "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/Versions/A/DTXProfiler
		else
			cp -f "${PROFILER_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${PROFILER_FRAMEWORK_NAME}"/Info.plist "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"
			mv "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/DTXProfilerShim "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
			
			## 🤦‍♂️ rdar://45972646 "Notarization service fails for an app with an iOS framework embedded in it"
			openssl enc -aes-256-cbc -d -K 0 -iv 0 -nosalt -in "${SHIM_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${SHIM_FRAMEWORK_NAME}"/DTXProfilerShim -out "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
		fi
		
		# install_name_tool -id "DTXProfiler" "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
		echo "Profiler framework not integrated: current build configuration “${CONFIGURATION}” is not included in the ALLOWED_CONFIGURATIONS list."
	fi
	
	if [ "${ENABLE_BITCODE}" = "NO" ]; then
		echo "Stripping bitcode"
		xcrun bitcode_strip -r "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/DTXProfiler -o "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
	fi
	
	if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" ]; then
		codesign -fs "${EXPANDED_CODE_SIGN_IDENTITY}" --deep "${TARGET_FRAMEWORKS}/${PROFILER_FRAMEWORK_NAME}"
	fi

	if [ -d "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}" ]; then
		rm -fr "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}"
	fi

	cp -rf "${PROFILER_FRAMEWORK_CONTAINER}/${PLATFORM_NAME}/${PROFILER_FRAMEWORK_NAME}" "${BUILT_PRODUCTS_DIR}/"
	rm -f "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}"/DTXProfiler
	rm -fr "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}"/*.momd
	rm -fr "${BUILT_PRODUCTS_DIR}/${PROFILER_FRAMEWORK_NAME}"/Frameworks

	echo "Profiler framework headers have been copied to ${BUILT_PRODUCTS_DIR}"
else
	echo "Profiler framework could not be found. Make sure Detox Instruments is properly installed."
	exit 255
fi
