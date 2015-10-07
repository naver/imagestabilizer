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
    int Threshl=20;
    int Octaves=3; //(pyramid layer) from which the keypoint has been extracted
    float PatternScales=1.0f;
    
    cv::Ptr<cv::FeatureDetector> detactor = cv::BRISK::create(Threshl, Octaves, PatternScales);
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
    
    NSLog(@"Extracted %d points", keypoints.size());
    
    UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:resultImageMat];
    return resultImage;
}

-(UIImage*) matchedFeature:(UIImage*)image1 anotherImage:(UIImage*)image2 representingPixelSize:(NSInteger)pixel{
    Mat targetImageMat1 = [OpenCVUtils cvMatFromUIImage:image1];
    Mat targetImageMat2 = [OpenCVUtils cvMatFromUIImage:image2];
    Mat grayTargetImage1, grayTargetImage2;
    cvtColor(targetImageMat1, grayTargetImage1, CV_BGR2GRAY);
    cvtColor(targetImageMat2, grayTargetImage2, CV_BGR2GRAY);
    
    std::vector<cv::KeyPoint> keyPointsA, keyPointsB;
    cv::Mat descriptorsA, descriptorsB;
    extractFeatureUsingBRISK(grayTargetImage1, keyPointsA, descriptorsA);
    extractFeatureUsingBRISK(grayTargetImage2, keyPointsB, descriptorsB);
    
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
            matched1.push_back(keyPointsA[first.queryIdx]);
            matched2.push_back(keyPointsB[first.trainIdx]);
            
            p1.push_back(keyPointsA[first.queryIdx].pt);
            p2.push_back(keyPointsB[first.trainIdx].pt);
        }
    }
    
    NSLog(@"Points : %ld, Matched : %ld", keyPointsB.size() , matched2.size());
    
    Mat resultImageMat;
    cvtColor(grayTargetImage2, resultImageMat, CV_GRAY2BGRA);
    
    for(int i =0 ; i < p2.size(); i++){
        Point2f point = p2[i];
        [OpenCVUtils setPixelColor:resultImageMat posX:point.x posY:point.y size:pixel color:[UIColor redColor]];
    }
    
    UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:resultImageMat];
    return resultImage;
}

bool isInliner(std::vector< std::vector<DMatch> >& nn_matches, int queryIdx){
    const float nn_match_ratio = 0.9f;
    float dist1 = nn_matches[queryIdx][0].distance;
    float dist2 = nn_matches[queryIdx][1].distance;
    if(dist1 < nn_match_ratio * dist2) {
        return true;
    }else{
        return false;
    }
}

-(NSArray*) matchedFeatureWithImageList:(NSArray *)images representingPixelSize:(NSInteger)pixel{
    int numOfImages = [images count];

    vector<Mat> grayImages;
    vector< std::vector<cv::KeyPoint> > keyPointsVec;
    vector<Mat> descriptorsVec;
    
    for(int i =0 ; i < numOfImages; i++){
        Mat targetImageMat = [OpenCVUtils cvMatFromUIImage:images[i]];
        Mat grayImageMat;
        cvtColor(targetImageMat, grayImageMat, CV_BGR2GRAY);
        grayImages.push_back(grayImageMat);
        
        std::vector<cv::KeyPoint> keyPoints;
        Mat descriptors;
        
        extractFeatureUsingBRISK(grayImageMat, keyPoints, descriptors);
        keyPointsVec.push_back(keyPoints);
        descriptorsVec.push_back(descriptors);
        
        NSLog(@"Extract Feature : %d, extracted : %d", i, keyPoints.size());
    }
    
    NSLog(@"Start of matching");
    cv::BFMatcher matcher(cv::NORM_HAMMING);
    std::vector< std::vector< std::vector<DMatch> > > matchedList;
    
    for( int i =1; i < numOfImages; i++){
        std::vector< std::vector<DMatch> > nn_matches;
        matcher.knnMatch(descriptorsVec[i-1], descriptorsVec[i], nn_matches, 2);
        matchedList.push_back(nn_matches);
        
        NSLog(@"Index : %d", i);
        for( int j = 0; j < nn_matches.size(); j++){
            NSLog(@"QuaryIdx : %d, TrainIdx : %d",nn_matches[j][0].queryIdx, nn_matches[j][0].trainIdx);
        }
    }
    NSLog(@"Finished Matching");
    
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
                std::vector< std::vector<DMatch> > nn_matcher = matchedList[j];
                int nextTrainIdx = nn_matcher[trainIdx][0].trainIdx;
                
                if(isInliner(nn_matcher, trainIdx)){
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
    
    NSLog(@"Matched Num : %d", queryIndexes.size());
    
    
    vector<Mat> resultMats;
    
    for( int i = 0; i < grayImages.size(); i++){
        Mat resultImageMat;
        cvtColor(grayImages[i], resultImageMat, CV_GRAY2BGRA);
        resultMats.push_back(resultImageMat);
    }
    
//    NSMutableString* pointStr = [NSMutableString new];
//    
//    for( int i =0; i < queryIndexes.size(); i++){
//        std::vector<int> queries = queryIndexes[i];
//        
//        for(int j = 0; j < queries.size(); j++){
//            int index = queries[j];
//            Point2f point = keyPointsVec[j][index].pt;
//            [OpenCVUtils setPixelColor:resultMats[j] posX:point.x posY:point.y size:pixel color:[UIColor redColor]];
//            
//            if(j == 0){
//                [pointStr appendFormat:@"%lf\t%lf", point.x, point.y];
//            }else{
//                [pointStr appendFormat:@"\t%lf\t%lf", point.x, point.y];
//            }
//        }
//        
//        [pointStr appendString:@"\n"];
//    }
//    
//    NSLog(@"pointStr : %@", pointStr);
//    [OpenCVUtils writeFile:@"point_data" data:pointStr];
    
    NSMutableArray* results = [NSMutableArray array];
    for( int i = 0; i < numOfImages; i++){
        UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:resultMats[i]];
        [results addObject:resultImage];
    }
    
    return results;
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
