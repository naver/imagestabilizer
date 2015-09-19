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
    
    for(size_t i = 0; i < nn_matches.size(); i++) {
        DMatch first = nn_matches[i][0];
        float dist1 = nn_matches[i][0].distance;
        float dist2 = nn_matches[i][1].distance;
        if(dist1 < nn_match_ratio * dist2) {
            int new_i = matched1.size();
            matched1.push_back(keypointsA[first.queryIdx]);
            matched2.push_back(keypointsB[first.trainIdx]);
        }
    }
    
    NSLog(@"Matched : %ld", matched1.size());
    
    std::vector<float> diffX, diffY, diffR;
    float avgX=0, avgY=0, avgR=0;
    float varX = 0, varY = 0, varR =0;
    
//    NSMutableString* data = [[NSMutableString alloc] init];
    
    for(size_t i = 0; i < matched1.size(); i++){
        KeyPoint p1 = matched1[i];
        KeyPoint p2 = matched2[i];
        
        float dx = (p1.pt.x - p2.pt.x);
        float dy = (p1.pt.y - p2.pt.y);
        float dR = (p1.angle - p2.angle);

        avgX += dx;
        avgY += dy;
        avgR += dR;
        
        diffX.push_back(dx);
        diffY.push_back(dy);
        diffR.push_back(dR);
        
//        NSLog(@"%lf %lf %lf %lf %lf %lf", p1.pt.x, p1.pt.y, p1.angle, p2.pt.x, p2.pt.y, p2.angle);
//        [data appendFormat:@"%lf %lf %lf %lf %lf %lf\n", p1.pt.x, p1.pt.y, p1.angle, p2.pt.x, p2.pt.y, p2.angle];
    }
    
//    NSLog(@"data : \n%@", data);
    
    avgX = avgX / matched1.size();
    avgY = avgY / matched1.size();
    avgR = avgR / matched1.size();
    
    NSLog(@"Prev Avg : %lf %lf %lf", avgX, avgY, avgR);
    
    for(size_t i = 0; i < matched1.size(); i++){
        varX += ((diffX[i] - avgX)*(diffX[i] - avgX));
        varY += ((diffY[i] - avgY)*(diffY[i] - avgY));
        varR += ((diffR[i] - avgR)*(diffR[i] - avgR));
    }
    
    varX = varX / matched1.size();
    varY = varY / matched1.size();
    varR = varR / matched1.size();
    
    float stdX = sqrt(varX);
    float stdY = sqrt(varY);
    float stdR = sqrt(varR);
    
    for(size_t i = 0; i < matched1.size(); i++){
        KeyPoint p1 = matched1[i];
        KeyPoint p2 = matched2[i];
        
        float dx = (p1.pt.x - p2.pt.x);
        float dy = (p1.pt.y - p2.pt.y);
        float dR = (p1.angle - p2.angle);

        if(isInRange(dx,avgX, stdX) && isInRange(dy,avgY, stdY) && isInRange(dR, avgR, stdR)){
            inliers1.push_back(p1);
            inliers2.push_back(p2);
        }
    }
    
    NSLog(@"Inliner : %ld", inliers1.size());
    
    avgX = 0;
    avgY = 0;
    avgR = 0;
    for(size_t i = 0; i < inliers1.size(); i++){
        KeyPoint p1 = inliers1[i];
        KeyPoint p2 = inliers2[i];
        
        float dx = (p1.pt.x - p2.pt.x);
        float dy = (p1.pt.y - p2.pt.y);
        float dR = (p1.angle - p2.angle);
        
        avgX += dx;
        avgY += dy;
        avgR += dR;
    }
    
    avgX = avgX / inliers1.size();
    avgY = avgY / inliers1.size();
    avgR = avgR / inliers1.size();
    
    avgX = 10;
    avgY = 10;
    avgR = 10;

    NSLog(@"Avg : %lf %lf %lf", avgX, avgY, avgR);
    
    Mat originalImage = [OpenCVUtils cvMatFromUIImage:image2];
    int rows = originalImage.rows;
    int cols = originalImage.cols;
    
    Mat rotM = getRotationMatrix2D(Point2f(rows/2,cols/2), -avgR, 1.0);
    Mat transM = (Mat_<double>(2,3) << 1, 0, avgX, 0, 1, avgY);
    Mat trM = rotM;
    cv::Mat res(rows, cols, CV_8UC4);
    
    warpAffine(originalImage, res, rotM, cv::Size(rows,cols));
    warpAffine(res, res, transM, cv::Size(rows,cols));

    
    NSLog(@"TRM");

//    Mat res;
//    drawMatches(grayImageA, matched1, grayImageB, matched2, good_matches, res);
    UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:res];
    [self saveImage:resultImage fileName:@"test1"];
//    
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
