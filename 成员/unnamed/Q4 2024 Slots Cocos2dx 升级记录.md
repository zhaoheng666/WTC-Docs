**1 、spidermonkey库编译报错:**  
\[arm64-v8a\] StaticLibrary  : libccandroid.a  
\[arm64-v8a\] StaticLibrary  : libcpufeatures.a  
\[armeabi-v7a\] SharedLibrary  : libgame.so  
\[arm64-v8a\] SharedLibrary  : libgame.so  
/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/external/spidermonkey/prebuilt/android/armeabi-v7a/libjs\_static.a(jscntxt.o):function JSContext::updateJITEnabled(): error: undefined reference to 'std::\_\_ndk1::ios\_base::init(void\*)'  
/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/external/spidermonkey/prebuilt/android/armeabi-v7a/libjs\_static.a(jscntxt.o):function JSContext::updateJITEnabled(): error: undefined reference to 'std::\_\_ndk1::ios\_base::clear(unsigned int)'  
/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/external/spidermonkey/prebuilt/android/armeabi-v7a/libjs\_static.a(jscntxt.o):function JSContext::updateJITEnabled(): error: undefined reference to 'std::\_\_ndk1::ios\_base::getloc() const'  
/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/external/spidermonkey/prebuilt/android/armeabi-v7a/libjs\_static.a(jscntxt.o):function JSContext::updateJITEnabled(): error: undefined reference to 'std::\_\_ndk1::locale::use\_facet(std::\_\_ndk1::locale::id&) const'  
/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/external/spidermonkey/prebuilt/android/armeabi-v7a/libjs\_static.a(jscntxt.o):function JSContext::updateJITEnabled(): error: undefined reference to 'std::\_\_ndk1::locale::\~locale()'  
/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/external/spidermonkey/prebuilt/android/armeabi-v7a/libjs\_static.a(jscntxt.o):function JSContext::updateJITEnabled(): error: undefined reference to 'std::\_\_ndk1::locale::\~locale()'  
/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/external/spidermonkey/prebuilt/android/armeabi-v7a/libjs\_static.a(jscntxt.o):function JSContext::updateJITEnabled(): error: undefined reference to 'std::\_\_ndk1::ios\_base::\~ios\_base()'  
/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/external/spidermonkey/prebuilt/android/armeabi-v7a/libjs\_static.a(jscntxt.o):function JSContext::updateJITEnabled(): error: undefined reference to 'std::\_\_ndk1::ios\_base::init(void\*)'  
**注意报错log：std::\_\_ndk1::ios\_base::init(void\*)**  
**项目application.mk的c++编译相关配置**  
**APP\_STL := gnustl\_static**  
**gnustl\_static的报错日志应该是std::ios\_base::init(void\*)**  
**而报错log中含有\_\_ndk1则说明这个库的编译方式为c++标准库，修改如下**  
**APP\_STL := c++\_static**

**2、编译报错**

   ![0][image1]

**编译方式改为APP\_STL := c++\_static之后出现的编译错误,所以由此可以推断cocos2dx库内有相当一部分文件不支持gcc c++\_static编译，暂且搁置**

**3、修改编译方式为clang**  
询问鑫爷得知，tp的编译方式已经修改为clang，所以修改applicatoin.mk文件  
NDK\_TOOLCHAIN\_VERSION := clang  
重新编译还是报错，说明配置未生效  
经过一顿查找，发现打包的命令行里强制制定了ndk编译版本为ndk 4.9

    ![0][image2]

所以修改脚本如下

    ![0][image3]

**4、编译报错**  
**warning:** unknown warning option '-Wno-psabi' \[-Wunknown-warning-option\]  
**error:** invalid argument '-std=gnu++11' not allowed with 'C/ObjC'  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/zensdk\_static/\_\_/\_\_/core/crypto/base64/libb64.o\] Error 1  
make: \*\*\* Waiting for unfinished jobs....  
\[armeabi-v7a\] Compile arm    : zensdk\_static \<= md5.c  
1 warning generated.  
1 warning generated.  
**warning:** unknown warning option '-Wno-psabi' \[-Wunknown-warning-option\]  
**error:** invalid argument '-std=gnu++11' not allowed with 'C/ObjC'  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/zensdk\_static/\_\_/\_\_/core/crypto/md5/md5.o\] Error 1  
1 warning generated.  
经查得知需修改android.mk中编译配置

    ![0][image4]

* LOCAL\_CPPFLAGS 用于C++相关的编译标志。典型的标志包括C++标准选择、特定于C++的宏定义等等。  
* LOCAL\_CFLAGS 用于C语言相关的编译标志以及通用的编译标志，适用于C和C++。  
* 

**5、编译报错**  
/Users/gaoyachuang/Desktop/native/android-ndk-r16b/ndk-build \-j8 \-C /Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app NDK\_DEBUG=1 NDK\_MODULE\_PATH=/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/..:/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x:/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/external:/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app/../../../cocos2d-x/cocos NDK\_TOOLCHAIN\_VERSION=clang

Android NDK: WARNING: Unsupported source file extensions in jni/../../../../..//libZenSDK/platform/android/Android.mk for module zensdk\_static

Android NDK:   FILE\_LIST \+= FILE\_LIST \+= FILE\_LIST \+= FILE\_LIST \+= FILE\_LIST \+= FILE\_LIST \+=

Android NDK: WARNING: Unsupported source file extensions in jni/../../../../..//libZenSDK/platform/android/Android.mk for module zensdk\_static

Android NDK:   FILE\_LIST \+= FILE\_LIST \+= FILE\_LIST \+= FILE\_LIST \+= FILE\_LIST \+= FILE\_LIST \+=

make: Entering directory \`/Users/gaoyachuang/Desktop/project/WorldTourCasino/frameworks/runtime-src/proj.android-studio/app'  
\[armeabi-v7a\] Compile++ arm  : ccs \<= WidgetReader.cpp  
\[armeabi-v7a\] Compile++ arm  : ccs \<= FlatBuffersSerialize.cpp  
\[armeabi-v7a\] Compile++ arm  : ccs \<= WidgetCallBackHandlerProtocol.cpp  
\[armeabi-v7a\] Compile++ arm  : ccs \<= CCComExtensionData.cpp  
\[armeabi-v7a\] Compile++ arm  : ccs \<= CocoStudio.cpp  
\[armeabi-v7a\] Compile++ thumb: audio \<= mp3reader.cpp  
\[armeabi-v7a\] Compile++ thumb: audio \<= tinysndfile.cpp  
\[armeabi-v7a\] Compile++ arm  : cc\_core \<= atitc.cpp  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/cc\_core/base/atitc.o\] Killed: 9  
make: \*\*\* Waiting for unfinished jobs....  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/audio/tinysndfile.o\] Killed: 9  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/audio/mp3reader.o\] Killed: 9  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/ccs/CocoStudio.o\] Killed: 9  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/ccs/CCComExtensionData.o\] Killed: 9  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/ccs/WidgetCallBackHandlerProtocol.o\] Killed: 9  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/ccs/FlatBuffersSerialize.o\] Killed: 9  
make: \*\*\* \[obj/local/armeabi-v7a/objs-debug/ccs/WidgetReader/WidgetReader.o\] Killed: 9  
切换了编译方式，清理一下编译缓存重新编译即可

**6、运行报错**  
2024-10-28 15:32:03.023612+0800 OldVegasCasino\[79002:15650860\] Execution of the command buffer was aborted due to an error during execution. Caused GPU Address Fault Error (0000000b:kIOGPUCommandBufferCallbackErrorPageFault)  
2024-10-28 15:32:03.023749+0800 OldVegasCasino\[79002:15650860\] Execution of the command buffer was aborted due to an error during execution. Caused GPU Address Fault Error (0000000b:kIOGPUCommandBufferCallbackErrorPageFault)  
2024-10-28 15:32:03.024047+0800 OldVegasCasino\[79002:15649770\] nothing\_to\_trace  
nothing\_to\_trace  
2024-10-28 15:32:03.024093+0800 OldVegasCasino\[79002:15649770\] Error converting value to object  
Error converting value to object  
2024-10-28 15:32:03.024143+0800 OldVegasCasino\[79002:15649770\] JS: /var/mobile/Containers/Data/Application/0058CFE5-0959-4C02-B0E2-5B677596CA01/Documents/game.js:24148:Error: Error converting value to object  
2024-10-28 15:32:03.024156+0800 OldVegasCasino\[79002:15650860\] GLDRendererMetal command buffer completion error: Error Domain=MTLCommandBufferErrorDomain Code=3 "Caused GPU Address Fault Error (0000000b:kIOGPUCommandBufferCallbackErrorPageFault)" UserInfo={NSLocalizedDescription=Caused GPU Address Fault Error (0000000b:kIOGPUCommandBufferCallbackErrorPageFault)}  
JS: /var/mobile/Containers/Data/Application/0058CFE5-0959-4C02-B0E2-5B677596CA01/Documents/game.js:24148:Error: Error converting value to object  
2024-10-28 15:32:03.026797+0800 OldVegasCasino\[79002:15650860\] Execution of the command buffer was aborted due to an error during execution. Caused GPU Address Fault Error (0000000b:kIOGPUCommandBufferCallbackErrorPageFault)  
2024-10-28 15:32:03.026845+0800 OldVegasCasino\[79002:15650860\] Execution of the command buffer was aborted due to an error during execution. Caused GPU Address Fault Error (0000000b:kIOGPUCommandBufferCallbackErrorPageFault)  
2024-10-28 15:32:03.026895+0800 OldVegasCasino\[79002:15650860\] GLDRendererMetal command buffer completion error: Error Domain=MTLCommandBufferErrorDomain Code=3 "Caused GPU Address Fault Error (0000000b:kIOGPUCommandBufferCallbackErrorPageFault)" UserInfo={NSLocalizedDescription=Caused GPU Address Fault Error (0000000b:kIOGPUCommandBufferCallbackErrorPageFault)}  
2024-10-28 15:32:03.047972+0800 OldVegasCasino\[79002:15649770\] nothing\_to\_trace  
nothing\_to\_trace  
2024-10-28 15:32:03.048017+0800 OldVegasCasino\[79002:15649770\] Error converting value to object  
Error converting value to object  
2024-10-28 15:32:03.048064+0800 OldVegasCasino\[79002:15649770\] JS: /var/mobile/Containers/Data/Application/0058CFE5-0959-4C02-B0E2-5B677596CA01/Documents/game.js:24148:Error: Error converting value to object  
JS: /var/mobile/Containers/Data/Application/0058CFE5-0959-4C02-B0E2-5B677596CA01/Documents/game.js:24148:Error: Error converting value to object

    ![0][image5]

经查，项目的cocos2dx库之前升级过，在升级的基础上有在底层做了一些修改，本次升级又给覆盖回去了，还原相关代码即可

**7、关于clang和gcc 4.9编译方式的区别**

    ![0][image6]











