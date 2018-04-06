# Profiler Framework Integration Guide with Xcode

The following steps explain how to link the Profiler framework into your iOS application, providing a quick and easy way to enable profiling of your application.

> **WARNING:** Never submit a product which has been linked with the Profiler framework to the App Store. The instructions below outline a way to use build configurations to isolate linking the framework to Debug builds only. You can customize this to allow profiling of other configurations, but be careful.

You'll need to perform the following steps for each target that you wish to integrate:

1. Before starting the integration process, ensure that Detox Instruments has been installed using Homebrew Cask, as explained in the README document.
2. Open your project in Xcode, then select the project's icon in Xcode's Project Navigator.
3. Select the target you want to profile from the **TARGETS** list.
4. Select the **Build Settings** tab and add the following to the **Debug** configuration of the **Other Linker Flags** (`OTHER_LDFLAGS`) setting:
 
  ```bash
  -ObjC -F"${CODESIGNING_FOLDER_PATH}"/Frameworks -framework DTXProfiler
  ```
  
  > Add this build setting to additional configurations if you wish to profile them.
  
  ![Other Linker Flags](Resources/Integration_OtherLinkerFlags.png "Add the Other Linker Flags build setting")
 
5. Select the **Build Phases** tab and add a new **Run Script** phase—name it “Profiler Framework Integration”. Paste in the following shell script:

  ```bash
  # Only integrate the framework for Debug configuration by default. Edit this section to integrate with additional configurations.
  if [ "${CONFIGURATION}" != "Debug" ]; then
    echo "Profiler not included: current build configuration is not 'Debug'."
    exit 0
  fi
 
  # Find where the Detox Instruments app is installed
  INSTRUMENTS_APP_PATH=$(mdfind kMDItemCFBundleIdentifier="com.wix.DetoxInstruments" | head -n 1)
  PROFILER_BUILD_SCRIPT_PATH="${INSTRUMENTS_APP_PATH}/Contents/SharedSupport/Scripts/profiler_build_phase.sh"
  if [ "${INSTRUMENTS_APP_PATH}" -a -e "${PROFILER_BUILD_SCRIPT_PATH}" ]; then
    echo Found integration script at "${PROFILER_BUILD_SCRIPT_PATH}"
	# Run the Profiler framework integration script
    "${PROFILER_BUILD_SCRIPT_PATH}"
  else
    echo "Profiler not included: Cannot find an installed Detox Instruments app."
  fi
  ```
  
  ![New Run Script](Resources/Integration_NewBuildPhase.png "Add new run script and paste the script")
  
6. Drag the newly added script to the top of the phase list.
  
  ![Drag to Top](Resources/Integration_DragToTop.png "Drag the new script to the top of the list")
 
7. In Xcode, build and run your application using a scheme that is set to use the **Debug** configuration. If you are running your application on a device, ensure that it is on the same Wi-Fi network as the Mac running Detox Instruments.

 If everything worked correctly, you should be able to see your application listed in Detox Instruments. Select your app to start profiling.

  ![Discovered](Resources/Integration_Discovered.png "Detox Instruments lists your app")
 
8. Run your application again, this time using a scheme set to use the **Release** configuration. Verify that Detox Instruments cannot connect to your application. If you can still connect, make sure the Release configuration is not present in the **integration script** and/or the **Other Linker Flags** build setting.
