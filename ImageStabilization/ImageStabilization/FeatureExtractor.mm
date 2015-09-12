//
//  FeatureExtractor.m
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 9. 12..
//  Copyright (c) 2015년 EunchulJeon. All rights reserved.
//

#import "FeatureExtractor.h"
#import "OpenCVUtils.h"

using namespace std;
using namespace cv;

static string homographyStr = "7.6285898e-01  -2.9922929e-01   2.2567123e+02\n2 3.3443473e-01   1.0143901e+00  -7.6999973e+01\n3 3.4663091e-04  -1.4364524e-05   1.0000000e+00";


@implementation FeatureExtractor

double pow(double p){
    return p*p;
}

-(UIImage*) extractFeatureFromUIImage:(id)image1 anotherImage:(UIImage *)image2{
    cv::Mat grayImageA = [OpenCVUtils cvMatFromUIImage:image1];
    cv::Mat grayImageB = [OpenCVUtils cvMatFromUIImage:image2];

    std::vector<cv::KeyPoint> keypointsA, keypointsB;
    cv::Mat descriptorsA, descriptorsB;

    // Set brisk parameters
    int Threshl=60;
    int Octaves=4; //(pyramid layer) from which the keypoint has been extracted
    float PatternScales=1.0f;
    
//    //declare a variable BRISKD of the type cv::BRISK
//    cv::BRISK brisk = cv::BRISK::create(<#const std::vector<float> &radiusList#>, <#const std::vector<int> &numberList#>)
////    cv::BRISK  BRISKD(Threshl,Octaves,PatternScales);//initialize algoritm
////    BRISKD.create("Feature2D.BRISK");
////    
////    BRISKD.detect(GrayA, keypointsA);
////    BRISKD.compute(GrayA, keypointsA,descriptorsA);
////    
////    BRISKD.detect(GrayB, keypointsB);
////    BRISKD.compute(GrayB, keypointsB,descriptorsB);
    
//    cv::Ptr<cv::FeatureDetector> detector = creat<cv::FeatureDetector>("Feature2D.BRISK");
//    
//    detector->detect(GrayA, keypointsA);
//    detector->detect(GrayB, keypointsB);
    
    cv::Ptr<cv::FeatureDetector> detactor = cv::BRISK::create(Threshl, Octaves, PatternScales);
    
    NSLog(@"Start of Detection");
    detactor->detect(grayImageA, keypointsA);
    detactor->detect(grayImageB, keypointsB);
    NSLog(@"End of Detection : extracted from A : %ld, B : %ld", keypointsA.size(), keypointsB.size());

    NSLog(@"Start of Compute");
    detactor->compute(grayImageA, keypointsA, descriptorsA);
    detactor->compute(grayImageB, keypointsB, descriptorsB);
    NSLog(@"End of Compute");

    NSLog(@"Start of matching");
    cv::BFMatcher matcher(cv::NORM_HAMMING);
    std::vector< std::vector<DMatch> > nn_matches;
    matcher.knnMatch(descriptorsA, descriptorsB, nn_matches, 2);

    vector<KeyPoint> matched1, matched2, inliers1, inliers2;
    vector<DMatch> good_matches;
    const float nn_match_ratio = 0.8f;
    
    
    for(size_t i = 0; i < nn_matches.size(); i++) {
        DMatch first = nn_matches[i][0];
        float dist1 = nn_matches[i][0].distance;
        float dist2 = nn_matches[i][1].distance;
        if(dist1 < nn_match_ratio * dist2) {
            int new_i = matched1.size();
            matched1.push_back(keypointsA[first.queryIdx]);
            matched2.push_back(keypointsB[first.trainIdx]);
            good_matches.push_back(DMatch(new_i, new_i, 0));
        }
    }
    
//    for(size_t i = 0; i < matched1.size(); i++){
//        KeyPoint p1 = matched1[i];
//        KeyPoint p2 = matched2[i];
//        
//        NSLog(@"(%d %d, %lf), (%d %d %lf), dist : %lf angle : %lf", (int)p1.pt.x, (int)p1.pt.y, p1.angle, (int)p2.pt.x, (int)p2.pt.y, p2.angle, sqrt(pow(p1.pt.x - p2.pt.x)+pow(p1.pt.y - p2.pt.y)), fabs(p2.angle - p1.angle));
//
//
//    }
//
    Mat res;
    drawMatches(grayImageA, matched1, grayImageB, matched2, good_matches, res);
    UIImage* matchedImage = [OpenCVUtils UIImageFromCVMat:res];
    
    return matchedImage;
    
//    Mat homography = Mat(3, 3, CV_64FC1);
//    (7.6285898e-01,-2.9922929e-01,2.2567123e+02,3.3443473e-01,1.0143901e+00,-7.6999973e+01,3.4663091e-04,-1.4364524e-05,1.0000000e+00);
//    Mat homography(0.762, -0.2992);
//    homography.setTo(0);
//    homography.at<double>(0,0) = 7.6285898e-01;
//    homography.at<double>(0,1) = -2.9922929e-01;
//    homography.at<double>(0,2) = 2.2567123e+02;
//    homography.at<double>(1,0) = 3.3443473e-01;
//    homography.at<double>(1,1) = 1.0143901e+00;
//    homography.at<double>(1,2) = -7.6999973e+01;
//    homography.at<double>(2,0) = 3.4663091e-04;
//    homography.at<double>(2,1) = -1.4364524e-05;
//    homography.at<double>(2,2) = 1.0000000e+00;
    
//    homography.at<float>(0) = 7.6285898e-01;
//    homography.at<float>(1) = -2.9922929e-01;
//    homography.at<float>(2) = 2.2567123e+02;
//    homography.at<float>(3) = 3.3443473e-01;
//    homography.at<float>(4) = 1.0143901e+00;
//    homography.at<float>(5) = -7.6999973e+01;
//    homography.at<float>(6) = 3.4663091e-04;
//    homography.at<float>(7) = -1.4364524e-05;
//    homography.at<float>(8) = 1.0000000e+00;
//
//    
//    const float inlier_threshold = 2.5f;
////    Mat homography;
////    homographyStr >> homography;
//
//    NSLog(@"Start of removing outlier");
//    for(unsigned i = 0; i < matched1.size(); i++) {
//        Mat col = Mat::ones(3, 1, CV_64F);
//        col.at<double>(0) = matched1[i].pt.x;
//        col.at<double>(1) = matched1[i].pt.y;
//        col = homography * col;
//        col /= col.at<double>(2);
//        double dist = sqrt( pow(col.at<double>(0) - matched2[i].pt.x, 2) +
//                           pow(col.at<double>(1) - matched2[i].pt.y, 2));
//        if(dist < inlier_threshold) {
//            int new_i = static_cast<int>(inliers1.size());
//            inliers1.push_back(matched1[i]);
//            inliers2.push_back(matched2[i]);
//            good_matches.push_back(DMatch(new_i, new_i, 0));
//        }
//    }
//    NSLog(@"End of removing outlier, remain : %ld", good_matches.size());
//    
//
//    FileStorage fs("../data/H1to3p.xml", FileStorage::READ);
//    fs.getFirstTopLevelNode() >> homography;
}

@end
