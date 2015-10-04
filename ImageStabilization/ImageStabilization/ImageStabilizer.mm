//
//  ImageStabilizer.m
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 9. 23..
//  Copyright (c) 2015년 EunchulJeon. All rights reserved.
//

#import "ImageStabilizer.h"
#import "OpenCVUtils.h"

using namespace std;
using namespace cv;

@interface ImageStabilizer()
@property(nonatomic) Mat graySourceImage;
@property(nonatomic) Mat sourceImageMat;
@property(nonatomic) NSInteger saveImageIndex;
@end

@implementation ImageStabilizer
-(void) setStabilizeSourceImage:(UIImage*) sourceImage{
    self.sourceImageMat = [OpenCVUtils cvMatFromUIImage:sourceImage];
//    self.graySourceImage = [OpenCVUtils cvMatFromUIImage:sourceImage];
    cvtColor(_sourceImageMat, _graySourceImage, CV_BGR2GRAY);
    
    _saveImageIndex = 0;
}

void extractFeatureUsingBRISK(Mat& imageMat, vector<KeyPoint>& keyPoints, Mat& descriptor){
    // Set brisk parameters
//    int Threshl=80;
//    int Octaves=4; //(pyramid layer) from which the keypoint has been extracted
//    float PatternScales=1.0f;
    
    cv::Ptr<cv::FeatureDetector> detactor = cv::BRISK::create();
    detactor->detect(imageMat, keyPoints);
    detactor->compute(imageMat, keyPoints, descriptor);
}

void extractFeatureUsingAkaze(Mat& imageMat, vector<KeyPoint>& keyPoints, Mat& descriptor){
    Ptr<AKAZE> akaze = AKAZE::create();
    akaze->detectAndCompute(imageMat, noArray(), keyPoints, descriptor);
}

void extractFeatureUsingORB(Mat& imageMat, vector<KeyPoint>& keyPoints, Mat& descriptor){

    Ptr<ORB> orb = ORB::create();
    orb->detectAndCompute(imageMat, noArray(), keyPoints, descriptor);
}

void extractFEatureUsingMSER(Mat& imageMat, vector<KeyPoint>& keyPoints, Mat& descriptor){
    Ptr<MSER> mser = MSER::create();
    mser->detectAndCompute(imageMat, noArray(), keyPoints, descriptor);
}

-(UIImage*) extractFeature:(UIImage *)targetImage representingPixelSize:(NSInteger)pixel{
    Mat targetImageMat = [OpenCVUtils cvMatFromUIImage:targetImage];
    Mat grayTargetImage;
    cvtColor(targetImageMat, grayTargetImage, CV_BGR2GRAY);
    
    std::vector<cv::KeyPoint> keypoints;
    cv::Mat descriptors;
    extractFeatureUsingBRISK(grayTargetImage, keypoints, descriptors);
    
    Mat resultImageMat;
    cvtColor(grayTargetImage, resultImageMat, CV_GRAY2BGRA);
    
    for(int i =0 ; i < keypoints.size(); i++){
        KeyPoint point = keypoints[i];
        [OpenCVUtils setPixelColor:resultImageMat posX:point.pt.x posY:point.pt.y size:pixel color:[UIColor redColor]];
    }
    
    UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:resultImageMat];
    return resultImage;
}

-(UIImage*) stabilizeImage:(UIImage*)targetImage{
    Mat targetImageMat = [OpenCVUtils cvMatFromUIImage:targetImage];
//    Mat grayTargetImage = [OpenCVUtils cvMatFromUIImage:targetImage];;
    Mat grayTargetImage;
    cvtColor(targetImageMat, grayTargetImage, CV_BGR2GRAY);
    
    std::vector<cv::KeyPoint> keypointsA, keypointsB;
    cv::Mat descriptorsA, descriptorsB;

    NSLog(@"Start of Detection");
//    extractFeatureUsingBRISK(_graySourceImage, keypointsA, descriptorsA);
//    extractFeatureUsingBRISK(grayTargetImage, keypointsB, descriptorsB);
    
    extractFeatureUsingORB(_sourceImageMat, keypointsA, descriptorsA);
    extractFeatureUsingORB(targetImageMat, keypointsB, descriptorsB);
    
//    extractFEatureUsingMSER(_graySourceImage, keypointsA, descriptorsA);
//    extractFEatureUsingMSER(grayTargetImage, keypointsB, descriptorsB);

    
    NSLog(@"End of Detection : extracted from A : %ld, B : %ld", keypointsA.size(), keypointsB.size());
    
    if(keypointsA.size() ==0 || keypointsB.size()== 0){
        NSLog(@"ERROR : Feature Extraction Failed....");
        return targetImage;
    }
    
    NSLog(@"Start of matching");
    cv::BFMatcher matcher(cv::NORM_HAMMING);
    std::vector< std::vector<DMatch> > nn_matches;
    matcher.knnMatch(descriptorsA, descriptorsB, nn_matches, 2);
    
    vector<KeyPoint> matched1, matched2, inliers1, inliers2;
    const float nn_match_ratio = 0.8f;
    
    vector<cv::Point2f> p1, p2;
    
    for(size_t i = 0; i < nn_matches.size(); i++) {
        DMatch first = nn_matches[i][0];
        float dist1 = nn_matches[i][0].distance;
        float dist2 = nn_matches[i][1].distance;
        if(dist1 < nn_match_ratio * dist2) {
            matched1.push_back(keypointsA[first.queryIdx]);
            matched2.push_back(keypointsB[first.trainIdx]);
            
            p1.push_back(keypointsA[first.queryIdx].pt);
            p2.push_back(keypointsB[first.trainIdx].pt);
        }
    }
    
    NSLog(@"Matched : %ld", matched1.size());

    Mat R = estimateRigidTransform(p2, p1, true);
    
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
    
    int rows = targetImageMat.rows;
    int cols = targetImageMat.cols;
    
    cv::Mat res(rows, cols, CV_8UC4);
    warpPerspective(targetImageMat, res, H, cv::Size(rows, cols));
    res = [OpenCVUtils mergeImage:self.sourceImageMat another:res];
    
    UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:res];
//    [OpenCVUtils saveImage:resultImage fileName:[NSString stringWithFormat:@"result_%ld",_saveImageIndex++]];

    return resultImage;
}

@end
