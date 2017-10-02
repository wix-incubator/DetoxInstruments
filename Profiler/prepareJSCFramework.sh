mv JavaScriptCore.framework/JavaScriptCore JavaScriptCore.framework/JSC
mv JavaScriptCore.framework JSC.framework
install_name_tool -id JSC JSC.framework/JSC
/usr/libexec/PlistBuddy -c "set CFBundleExecutable JSC" JSC.framework/Info.plist
/usr/bin/codesign --force --sign - --timestamp=none JSC.framework