//
// Created by Eunchul on 2015. 11. 7..
//

#include "com_naver_android_pholar_util_imagestabilizer_ImageStabilizer.h"

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <android/log.h>
#include <opencv2/video/tracking.hpp>

using namespace std;
using namespace cv;

#define  LOG_TAG    "JNI_LOG"
#define  ALOG(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)


JNIEXPORT jstring JNICALL Java_com_naver_android_pholar_util_imagestabilizer_ImageStabilizer_hello
        (JNIEnv *env, jobject obj){
    return env->NewStringUTF("Hello from JNI");
}

void setPixelColor(Mat& cvMat, int posX, int posY, int size){
    Vec4b c = {255,0,0,255};

    for( int dx = (posX-size/2); dx < (posX+size/2); dx++){
        for( int dy = (posY - size/2); dy < (posY+size/2); dy++){
            cvMat.at<cv::Vec4b>(dy, dx) = c;
        }
    }
}

void findCropAreaWithHMatrics(Mat &hMat, int width, int height, vector<int>& resultVec){
    Mat topLeftPoint = (Mat_<double>(3,1) << 0, 0, 1);
    Mat topRightPoint = (Mat_<double>(3,1) << width, 0, 1);
    Mat bottomLeftPoint = (Mat_<double>(3,1) << 0, height,1);
    Mat bottomRightPoint = (Mat_<double>(3,1) << width, height,1);

    topLeftPoint = hMat*topLeftPoint;
    topRightPoint = hMat*topRightPoint;
    bottomLeftPoint = hMat*bottomLeftPoint;
    bottomRightPoint = hMat*bottomRightPoint;

    int left = topLeftPoint.at<double>(0,0) > bottomLeftPoint.at<double>(0,0) ? ceil(topLeftPoint.at<double>(0,0)) : ceil(bottomLeftPoint.at<double>(0,0));
    int right = topRightPoint.at<double>(0,0) < bottomRightPoint.at<double>(0,0) ? floor(topRightPoint.at<double>(0,0)) : floor(bottomRightPoint.at<double>(0,0));
    int top = topLeftPoint.at<double>(1,0) > topRightPoint.at<double>(1,0) ? ceil(topLeftPoint.at<double>(1,0)) : ceil(topRightPoint.at<double>(1,0));
    int bottom = bottomLeftPoint.at<double>(1,0) < bottomRightPoint.at<double>(1,0) ? floor(bottomLeftPoint.at<double>(1,0)) : floor(bottomRightPoint.at<double>(1,0));

    if(left < 0){
        left = 0;
    }

    if(right > width){
        right = width;
    }
    if(top < 0){
        top = 0;
    }
    if(bottom > height){
        bottom = height;
    }

    resultVec.push_back(left);
    resultVec.push_back(right);
    resultVec.push_back(top);
    resultVec.push_back(bottom);
}

Mat cropImage(Mat& image,int left, int right, int top, int bottom){
    int width = right-left;
    int height = bottom-top;

    float ratio = (float)image.cols/(float)image.rows;

    if(width/ratio > height){
        width = height*ratio;
    }else{
        height = width/ratio;
    }

    cv::Mat result(height,width, CV_8UC4);
    result.setTo(0);

    for(int row =0 ;row < result.rows; row++){
        for(int col=0; col < result.cols; col++){
            result.at<cv::Vec4b>(row,col) = image.at<cv::Vec4b>(row+top, col+left);
        }
    }

    return result;
}

void extractFeatureUsingFAST(Mat& imageMat, vector<KeyPoint>& keyPoints, Mat& descriptor){
    Ptr<FastFeatureDetector> fast = FastFeatureDetector::create();
    fast->setThreshold(20);
    fast->detect(imageMat, keyPoints);
    Ptr<ORB> orb = ORB::create();
    orb->compute(imageMat, keyPoints, descriptor);
}

bool isInliner(std::vector< std::vector<DMatch> >& nn_matches, int queryIdx){
    const float nn_match_ratio = 0.6f;
    float dist1 = nn_matches[queryIdx][0].distance;
    float dist2 = nn_matches[queryIdx][1].distance;
    if(dist1 < nn_match_ratio * dist2) {
        return true;
    }else{
        return false;
    }
}


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

JNIEXPORT jint JNICALL Java_com_naver_android_pholar_util_imagestabilizer_ImageStabilizer_getFeatrueExtractedImages
        (JNIEnv *env, jobject obj, jlongArray originalImagesAddrs, jlongArray resultImagesAddrs, jint size){

    vector<jlong> originalVec;
    vector<jlong> resultVec;

    JavaLongArrayToLongVector(env, originalImagesAddrs, &originalVec);
    JavaLongArrayToLongVector(env, resultImagesAddrs, &resultVec);

    for(int i =0; i < size; i++){
        Mat& mRgb = *(Mat*)(originalVec[i]);
        Mat& mGray = *(Mat*)(resultVec[i]);
        Mat grayMat;

        cvtColor(mRgb, grayMat, CV_RGBA2GRAY);
        cvtColor(grayMat, mGray, CV_GRAY2RGBA);

        std::vector<cv::KeyPoint> keypoints;
        cv::Mat descriptors;
        extractFeatureUsingFAST(grayMat, keypoints, descriptors);

        ALOG("Num of points %d", keypoints.size());

        for(int j =0 ; j < keypoints.size(); j++){
            KeyPoint point = keypoints[j];
            setPixelColor(mGray, point.pt.x, point.pt.y, 5);
        }
    }

    return 1;
}

JNIEXPORT jint JNICALL Java_com_naver_android_pholar_util_imagestabilizer_ImageStabilizer_getMatchedFeatureImages
        (JNIEnv *env, jobject obj, jlongArray originalImagesAddrs, jlongArray resultImagesAddrs, jint size){

    int numOfImages = size;
    vector<jlong> originalVec;
    vector<jlong> resultVec;

    JavaLongArrayToLongVector(env, originalImagesAddrs, &originalVec);
    JavaLongArrayToLongVector(env, resultImagesAddrs, &resultVec);

    vector< std::vector<cv::KeyPoint> > keyPointsVec;
    vector<Mat> descriptorsVec;

    for(int i =0; i < size; i++){
        Mat& mRgb = *(Mat*)(originalVec[i]);
        Mat grayMat;
        Mat& mGray = *(Mat*)(resultVec[i]);

        cvtColor(mRgb, grayMat, CV_RGBA2GRAY);
        cvtColor(grayMat, mGray, CV_GRAY2RGBA);

        std::vector<cv::KeyPoint> keypoints;
        cv::Mat descriptors;
        extractFeatureUsingFAST(grayMat, keypoints, descriptors);

        keyPointsVec.push_back(keypoints);
        descriptorsVec.push_back(descriptors);

        ALOG("Num of Features %d", keypoints.size());
    }

    ALOG("Start of matching");
    cv::BFMatcher matcher(cv::NORM_HAMMING);
    std::vector< std::vector< std::vector<DMatch> > > matchedList;

    for( int i =1; i < numOfImages; i++){
        std::vector< std::vector<DMatch> > nn_matches;
        matcher.knnMatch(descriptorsVec[i-1], descriptorsVec[i], nn_matches, 2);
        matchedList.push_back(nn_matches);
    }
    ALOG("Finished Matching");

    std::vector< std::vector<int> > queryIndexes;
    std::vector< std::vector<DMatch> > first_nn_matches = matchedList[0];

    for( int i =0 ;i < first_nn_matches.size(); i++){
        std::vector<int> queries;
        int queryIdx = first_nn_matches[i][0].queryIdx;
        int trainIdx = first_nn_matches[i][0].trainIdx;
        queries.push_back( queryIdx );
        queries.push_back( trainIdx );

        if(isInliner(first_nn_matches, queryIdx)){
            bool inliner = false;

            for(int j = 1; j < matchedList.size(); j++){
                int nextTrainIdx = matchedList[j][trainIdx][0].trainIdx;
                if(isInliner(matchedList[j], trainIdx)){
                    queries.push_back(nextTrainIdx);
                    trainIdx = nextTrainIdx;
                    inliner = true;
                }else{
                    inliner = false;
                    break;
                }
            }

            if(inliner){
                queryIndexes.push_back(queries);
            }
        }
    }

    ALOG("Matched Num : %d", queryIndexes.size());

    for( int i =0; i < queryIndexes.size(); i++){
        std::vector<int> queries = queryIndexes[i];

        for(int j = 0; j < queries.size(); j++){
            int index = queries[j];
            Mat& mGray = *(Mat*)(resultVec[j]);
            Point2f point = keyPointsVec[j][index].pt;
            setPixelColor(mGray, point.x, point.y, 5);
        }
    }

    return 1;
}

JNIEXPORT jint JNICALL Java_com_naver_android_pholar_util_imagestabilizer_ImageStabilizer_getStabilizedImages
        (JNIEnv *env, jobject obj, jlongArray originalImagesAddrs, jlongArray resultImagesAddrs, jint size){

    try {
        int numOfImages =size;

        vector<jlong> originalVec;
        vector<jlong> resultVec;

        JavaLongArrayToLongVector(env, originalImagesAddrs, &originalVec);
        JavaLongArrayToLongVector(env, resultImagesAddrs, &resultVec);

        vector< std::vector<cv::KeyPoint> > keyPointsVec;
        vector<Mat> descriptorsVec;

        for(int i =0; i < numOfImages; i++){
            Mat& mRgb = *(Mat*)(originalVec[i]);
            Mat grayMat;

            cvtColor(mRgb, grayMat, CV_RGBA2GRAY);

            std::vector<cv::KeyPoint> keypoints;
            cv::Mat descriptors;
            extractFeatureUsingFAST(grayMat, keypoints, descriptors);

            keyPointsVec.push_back(keypoints);
            descriptorsVec.push_back(descriptors);

            ALOG("Num of Features %d", keypoints.size());

            if(keypoints.size() < 3){
                return 0;
            }
        }

        ALOG("Start of matching");
        cv::BFMatcher matcher(cv::NORM_HAMMING);
        std::vector< std::vector< std::vector<DMatch> > > matchedList;

        for( int i =1; i < numOfImages; i++){
            std::vector< std::vector<DMatch> > nn_matches;
            matcher.knnMatch(descriptorsVec[i-1], descriptorsVec[i], nn_matches, 2);
            matchedList.push_back(nn_matches);
        }
        ALOG("Finished Matching");

        std::vector< std::vector<int> > queryIndexes;
        std::vector< std::vector<DMatch> > first_nn_matches = matchedList[0];

        for( int i =0 ;i < first_nn_matches.size(); i++){
            std::vector<int> queries;
            int queryIdx = first_nn_matches[i][0].queryIdx;
            int trainIdx = first_nn_matches[i][0].trainIdx;
            queries.push_back( queryIdx );
            queries.push_back( trainIdx );

            if(isInliner(first_nn_matches, queryIdx)){
                bool inliner = false;

                for(int j = 1; j < matchedList.size(); j++){
                    //                std::vector< std::vector<DMatch> > nn_matcher = matchedList[j];
                    int nextTrainIdx = matchedList[j][trainIdx][0].trainIdx;

                    if(isInliner(matchedList[j], trainIdx)){
                        queries.push_back(nextTrainIdx);
                        trainIdx = nextTrainIdx;
                        inliner = true;
                    }else{
                        inliner = false;
                        break;
                    }
                }

                if(inliner){
                    queryIndexes.push_back(queries);
                }
            }
        }

        ALOG("Find Inliner Matched Num : %d", queryIndexes.size());

        if(queryIndexes.size() <= 3){
            // 점이 충분하지않으므로 기존 이미지를 넘겨줌
            return 0;
        }

        vector< vector<cv::Point2f> > resultFeature;
        for( int i = 0; i < numOfImages; i++){
            vector<cv::Point2f> feature;
            resultFeature.push_back(feature);
        }

        for( int i =0; i < queryIndexes.size(); i++){
            std::vector<int> queries = queryIndexes[i];

            for(int j = 0; j < queries.size(); j++){
                int index = queries[j];
                Point2f point = keyPointsVec[j][index].pt;
                resultFeature[j].push_back(point);
            }
        }

        Mat& firstTargetImageMat = *(Mat*)(originalVec[0]);
        Mat firstResultImageMat(firstTargetImageMat.rows, firstTargetImageMat.cols, CV_8UC4);
        firstTargetImageMat.copyTo(firstResultImageMat);
        vector<Mat> resultMats;
        resultMats.push_back(firstResultImageMat);

        Mat prevH;
        vector< vector<int> > cropAreas;

        for( int i = 1; i < numOfImages; i++){
            Mat R = estimateRigidTransform(resultFeature[i], resultFeature[i-1], true);

            if(R.cols ==0 && R.rows ==0){
                // Estimate 가 잘 안된경우
                return 0;
            }

            cv::Mat H = cv::Mat(3,3,R.type());
            H.at<double>(0,0) = R.at<double>(0,0);
            H.at<double>(0,1) = R.at<double>(0,1);
            H.at<double>(0,2) = R.at<double>(0,2);

            H.at<double>(1,0) = R.at<double>(1,0);
            H.at<double>(1,1) = R.at<double>(1,1);
            H.at<double>(1,2) = R.at<double>(1,2);

            H.at<double>(2,0) = 0.0;
            H.at<double>(2,1) = 0.0;
            H.at<double>(2,2) = 1.0;


            Mat& targetImageMat = *(Mat*)(originalVec[i]);
            int rows = targetImageMat.rows;
            int cols = targetImageMat.cols;

            Mat res(rows, cols, CV_8UC4);
            resultMats.push_back(res);

            if(i==1){
                prevH = H;
            }else{
                prevH = prevH*H;
            }

            Mat* pMat = new Mat(3,3,CV_64F);
            pMat->at<double>(0,0) = prevH.at<double>(0,0);
            pMat->at<double>(0,1) = prevH.at<double>(0,1);
            pMat->at<double>(0,2) = prevH.at<double>(0,2);

            pMat->at<double>(1,0) = prevH.at<double>(1,0);
            pMat->at<double>(1,1) = prevH.at<double>(1,1);
            pMat->at<double>(1,2) = prevH.at<double>(1,2);

            pMat->at<double>(2,0) = 0.0;
            pMat->at<double>(2,1) = 0.0;
            pMat->at<double>(2,2) = 1.0;

            warpPerspective(targetImageMat, res, prevH, cv::Size(cols, rows));
            vector<int> cropArea;
            findCropAreaWithHMatrics(prevH, cols, rows, cropArea);

            cropAreas.push_back(cropArea);
        }

        ALOG("end ot estimate");

        ALOG("find crop area");
        int left = 0; int top = 0; int right = firstTargetImageMat.cols; int bottom = firstTargetImageMat.rows;

        for(int i = 0; i < cropAreas.size(); i++){
            vector<int> cropArea = cropAreas[i];

            int targetLeft = cropArea[0];
            int targetRight = cropArea[1];
            int targetTop = cropArea[2];
            int targetBottom = cropArea[3];

            if(left < targetLeft){
                left = targetLeft;
            }
            if(right > targetRight){
                right = targetRight;
            }
            if(top<targetTop){
                top = targetTop;
            }
            if(bottom>targetBottom){
                bottom = targetBottom;
            }
        }

        float imageWidth = firstTargetImageMat.cols;
        float imageHeight = firstTargetImageMat.rows;
        float maxDiff = 0.0;
        maxDiff = maxDiff < (float)left/imageWidth ? (float)left/imageWidth : maxDiff;
        maxDiff = maxDiff < abs(imageWidth - right)/imageWidth ? abs(imageWidth - right)/imageWidth : maxDiff;
        maxDiff = maxDiff < (float)top/imageHeight ? (float)top/imageHeight : maxDiff;
        maxDiff = maxDiff < abs(imageHeight - bottom)/imageHeight ? abs(imageHeight - bottom)/imageHeight : maxDiff;

        ALOG("Max Diff : %lf", maxDiff);

        if(maxDiff > 0.1){
            return 0;
        }

        for(int i = 0; i < numOfImages; i++){
            Mat mat = resultMats[i];
            Mat cropedMat = cropImage(mat, left, right, top, bottom);

            Mat& finalMat = *(Mat*)(resultVec[i]);
            resize(cropedMat, finalMat, finalMat.size());
        }

        return 1;
    }catch(cv::Exception &e){
        return 0;
    }
}