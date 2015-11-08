//
// Created by Eunchul on 2015. 11. 7..
//

#include "com_naver_android_pholar_util_imagestabilizer_MainActivity.h"
#include "com_naver_android_pholar_util_imagestabilizer_ImageStabilizer.h"

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

using namespace std;
using namespace cv;

JNIEXPORT jstring JNICALL Java_com_naver_android_pholar_util_imagestabilizer_MainActivity_hello
        (JNIEnv *env, jobject obj){
    return env->NewStringUTF("Hello from JNI");
}


//int toGray(Mat img, Mat& gray)
//{
//    cvtColor(img, gray, CV_RGBA2GRAY); // Assuming RGBA input
//
//    if (gray.rows == img.rows && gray.cols == img.cols)
//    {
//        return (1);
//    }
//    return(0);
//}

template <typename JavaArrayType>
size_t SafeGetArrayLength(JNIEnv* env, JavaArrayType jarray) {
    jsize length = env->GetArrayLength(jarray);
    return static_cast<size_t>(std::max(0, length));
}

void JavaLongArrayToLongVector(JNIEnv* env,
                               jlongArray long_array,
                               std::vector<jlong>* out) {
    size_t len = SafeGetArrayLength(env, long_array);
    out->resize(len);
    if (!len)
        return;
    env->GetLongArrayRegion(long_array, 0, len, &(*out)[0]);
}


JNIEXPORT jint JNICALL Java_com_naver_android_pholar_util_imagestabilizer_ImageStabilizer_getGrayImages
        (JNIEnv *env, jobject obj, jlongArray originalImagesAddrs, jlongArray resultImagesAddrs, jint size){

    vector<jlong> originalVec;
    vector<jlong> resultVec;

    JavaLongArrayToLongVector(env, originalImagesAddrs, &originalVec);
    JavaLongArrayToLongVector(env, resultImagesAddrs, &resultVec);

    for(int i =0; i < size; i++){
        Mat& mRgb = *(Mat*)(originalVec[i]);
        Mat& mGray = *(Mat*)(resultVec[i]);

        cvtColor(mRgb, mGray, CV_RGBA2GRAY);
    }

    return 1;
}