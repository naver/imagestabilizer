LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

#opencv
OPENCVROOT:=/Users/eunchuljeon/Desktop/DEV_Libraries/OpenCV-android-sdk/
OPENCV_CAMERA_MODULES:=off
OPENCV_INSTALL_MODULES:=on
OPENCV_LIB_TYPE:=SHARED
include ${OPENCVROOT}/sdk/native/jni/OpenCV.mk
LOCAL_MODULE    := ImageStabilizer
LOCAL_SRC_FILES := main.cpp
LOCAL_LDLIBS := -llog
include $(BUILD_SHARED_LIBRARY)

