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

@implementation FeatureExtractor

double pow(double p){
    return p*p;
}

bool isInRange(float checkValue, float avg, float st){
    if(checkValue > avg-st){
        if(checkValue < avg + st){
            return true;
        }
    }
    return false;
}

Mat getGeometricTransformMat(std::vector<KeyPoint>& aList, std::vector<KeyPoint>& bList){
    
// Geometric Transformation Matrix
// T = t11 t12 0
//     t21 t22 0
//     t31 t32 1
//
// M1 * T = M2
// M1 = SumOfAxSquare   SumOfAxAy       SumOfAx     0               0               0
//      SumOfAxAy       SumofAySqaure   SumOfAy     0               0               0
//      SumOfAx         SumOfAy         SumOf 1     0               0               0
//      0               0               0           SumOfAxSquare   SumOfAxAy       SumOfAx
//      0               0               0           SumOfAxAy       SumofAySqaure   SumOfAy
//      0               0               0           SumOfAx         SumOfAy         SumOf 1
//
// M2 = SumOfAxBx
//      SumOfAyBx
//      SumOfBx
//      SumOfAxBy
//      SumOfAyBy
//      SumOfBy
    
 
    double sumOfAxSquare = 0;
    double sumOfAxAy = 0;
    double sumOfAx = 0;
    double sumOfAySquare = 0;
    double sumOfAy = 0;
    double sumOfAxBx = 0;
    double sumOfAyBx = 0;
    double sumOfBx = 0;
    double sumOfAxBy = 0;
    double sumOfAyBy = 0;
    double sumOfBy = 0;
    
    for( int i = 0; i < aList.size(); i++){
        KeyPoint a = aList[i];
        KeyPoint b = bList[i];
        
        sumOfAxSquare += (a.pt.x * a.pt.x);
        sumOfAxAy += (a.pt.x * a.pt.y);
        sumOfAx += a.pt.x;
        sumOfAySquare += (a.pt.y * a.pt.y);
        sumOfAy += a.pt.y;
        
        sumOfAxBx += (a.pt.x * b.pt.x);
        sumOfAyBx += (a.pt.y * b.pt.x);
        sumOfBx += b.pt.x;
        sumOfAxBy += (a.pt.x * b.pt.y);
        sumOfAyBy += (a.pt.y * b.pt.y);
        sumOfBy += b.pt.y;
    }
    
    double sizeOfA = (double)aList.size();

    double m1[6][6] = {{sumOfAxSquare, sumOfAxAy,sumOfAx,0,0,0},
        {sumOfAxAy, sumOfAySquare, sumOfAy, 0,0,0},
        {sumOfAx, sumOfAy, sizeOfA,0,0,0},
        {0,0,0,sumOfAxSquare, sumOfAxAy,sumOfAx},
        {0,0,0,sumOfAxAy, sumOfAySquare, sumOfAy},
        {0,0,0,sumOfAx, sumOfAy, sizeOfA}};
    
    Mat M1Inv = Mat(6,6,CV_64F, m1).inv();
    
    double m2[6] = {sumOfAxBx, sumOfAyBx, sumOfBx, sumOfAxBy, sumOfAyBy, sumOfBy};
    
    Mat M2 = Mat(6,1,CV_64F, m2);
    
    Mat result = M1Inv * M2;
    
    double t[3][3] = {result.at<double>(0,0), result.at<double>(3,0), 0,
        result.at<double>(1,0), result.at<double>(4,0),0,
        result.at<double>(2,0), result.at<double>(5,0),1};
    
    
    NSLog(@"Print result");
    for( int i = 0 ; i < 6; i++){
        for( int j = 0; j < 1; j++){
            double val = result.at<double>(i,j);
            NSLog(@"%lf",val);
        }
    }
    
    return Mat(3,3,CV_64F, t);
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
    
    Mat t1 = getGeometricTransformMat(matched1, matched2);
    for( int i =0 ; i < 3; i++){
        for( int j= 0; j < 3; j++){
            double v = t1.at<double>(i,j);
            NSLog(@"t1 : %lf", v);
        }
    }
    
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
    
    Mat originalImage = [OpenCVUtils cvMatFromUIImage:image2];
    int rows = originalImage.rows;
    int cols = originalImage.cols;
    
    cv::Mat res(rows, cols, CV_8UC4);
    warpPerspective(originalImage, res, H, cv::Size(rows, cols));
    res = [OpenCVUtils mergeImage:[OpenCVUtils cvMatFromUIImage:image1] another:res];
    
    UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:res];
    [self saveImage:resultImage fileName:@"test1"];

    return resultImage;
}

- (void)saveImage:(UIImage *)imageToSave fileName:(NSString *)imageName;
{
    NSData *dataForPNGFile = UIImagePNGRepresentation(imageToSave);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSError *error = nil;
    if (![dataForPNGFile writeToFile:[documentsDirectory stringByAppendingPathComponent:imageName] options:NSAtomicWrite error:&error])
    {
        return;
    }
    
    NSString*p  = [documentsDirectory stringByAppendingPathComponent:imageName];
    NSLog(@"p : %@", p);
}



@end
