//
// Created by Eunchul on 2015. 11. 7..
//

#include "com_naver_android_pholar_util_imagestabilizer_MainActivity.h"

JNIEXPORT jstring JNICALL Java_com_naver_android_pholar_util_imagestabilizer_MainActivity_hello
        (JNIEnv *env, jobject obj){
    return env->NewStringUTF("Hello from JNI");
}