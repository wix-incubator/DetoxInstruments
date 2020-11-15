#!/bin/bash
set -e -x

INSTRUMENTS_SCRIPTS_DIR="${0%/*}"

PROFILER_LIB_DIR="ProfilerFramework"
PROFILER_FRAMEWORK_NAME="DTXProfiler.framework"
PROFILER_FRAMEWORK_CONTAINER="${INSTRUMENTS_SCRIPTS_DIR}/../${PROFILER_LIB_DIR}"

CONFIGURATION=$1
# Clean any leading or trailing whitespace from list of allowed configurations
ALLOWED_CONFIGURATIONS=`echo "$2" | perl -e "s/\s*\,\s*/\ /g" -p`

addNSLocalNetworkUsageDescriptionIfNeeded()
{
	/usr/libexec/PlistBuddy -c 'print :NSLocalNetworkUsageDescription' "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}" || /usr/libexec/PlistBuddy -c 'add :NSLocalNetworkUsageDescription string "The service will allow discovery and connection by Detox Instruments."' "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
}

addNSBonjourServices()
{
	/usr/libexec/PlistBuddy -c 'Add :NSBonjourServices array' "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
	
	appendNSBonjourServices
}

appendNSBonjourServices()
{
	/usr/libexec/PlistBuddy -c 'Add NSBonjourServices:0 string "_detoxprofiling_launchprofiling._tcp"' "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
	/usr/libexec/PlistBuddy -c 'Add NSBonjourServices:0 string "_detoxprofiling._tcp"' "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
}

addOrAppendNSBonjourServicesIfNeeded()
{
	/usr/libexec/PlistBuddy -c 'print :NSBonjourServices' "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}" && appendNSBonjourServices || addNSBonjourServices
}

if [ -e "${PROFILER_FRAMEWORK_CONTAINER}" ]; then
	if [[ " ${ALLOWED_CONFIGURATIONS[@]} " =~ " ${CONFIGURATION} " ]]; then
		addNSLocalNetworkUsageDescriptionIfNeeded
		addOrAppendNSBonjourServicesIfNeeded
		
		echo "Profiler framework has been integrated in ${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}."
	else
		echo "Profiler framework not integrated: current build configuration “${CONFIGURATION}” is not included in the ALLOWED_CONFIGURATIONS list."
	fi
else
	echo "Profiler framework could not be found. Make sure Detox Instruments is properly installed."
	exit 255
fi
