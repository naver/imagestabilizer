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

const int HORIZONTAL_BORDER_CROP = 20;
struct Trajectory
{
    Trajectory() {}
    Trajectory(double _x, double _y, double _a) {
        x = _x;
        y = _y;
        a = _a;
    }
    // "+"
    friend Trajectory operator+(const Trajectory &c1,const Trajectory  &c2){
        return Trajectory(c1.x+c2.x,c1.y+c2.y,c1.a+c2.a);
    }
    //"-"
    friend Trajectory operator-(const Trajectory &c1,const Trajectory  &c2){
        return Trajectory(c1.x-c2.x,c1.y-c2.y,c1.a-c2.a);
    }
    //"*"
    friend Trajectory operator*(const Trajectory &c1,const Trajectory  &c2){
        return Trajectory(c1.x*c2.x,c1.y*c2.y,c1.a*c2.a);
    }
    //"/"
    friend Trajectory operator/(const Trajectory &c1,const Trajectory  &c2){
        return Trajectory(c1.x/c2.x,c1.y/c2.y,c1.a/c2.a);
    }
    //"="
    Trajectory operator =(const Trajectory &rx){
        x = rx.x;
        y = rx.y;
        a = rx.a;
        return Trajectory(x,y,a);
    }
    
    double x;
    double y;
    double a; // angle
};

@interface ImageStabilizer()
@property(nonatomic) Mat graySourceImage;
@property(nonatomic) Mat sourceImageMat;
@property(nonatomic) NSInteger saveImageIndex;
@property(nonatomic) vector<Mat*> estimatedResults;

@end

@implementation ImageStabilizer

-(id) init{
    self = [super init];
    if(self){
        _hasPrevResult = NO;
        _isEnabled = NO;
    }
    
    return self;
}

-(void) dealloc{
    [self resetStabilizer];
}

-(void) resetStabilizer{
    if(_estimatedResults.size() > 0){
        for(int i=0; i < _estimatedResults.size(); i++){
            delete _estimatedResults[i];
        }
        _estimatedResults.clear();
    }

    _hasPrevResult = NO;
    _isEnabled = NO;
}

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
    detactor->detectAndCompute(imageMat, noArray(), keyPoints, descriptor);
}

void extractFeatureUsingAkaze(Mat& imageMat, vector<KeyPoint>& keyPoints, Mat& descriptor){
    Ptr<AKAZE> akaze = AKAZE::create();
    akaze->detectAndCompute(imageMat, noArray(), keyPoints, descriptor);
}

void extractFeatureUsingORB(Mat& imageMat, vector<KeyPoint>& keyPoints, Mat& descriptor){
    
    Ptr<ORB> orb = ORB::create();
    orb->detectAndCompute(imageMat, noArray(), keyPoints, descriptor);
}

void extractFeatureUsingFAST(Mat& imageMat, vector<KeyPoint>& keyPoints, Mat& descriptor){
    Ptr<FastFeatureDetector> fast = FastFeatureDetector::create();
    fast->setThreshold(20);
    fast->detect(imageMat, keyPoints);
    Ptr<ORB> orb = ORB::create();
    orb->compute(imageMat, keyPoints, descriptor);
}

-(UIImage*) extractFeature:(UIImage *)targetImage representingPixelSize:(NSInteger)pixel{
    Mat targetImageMat = [OpenCVUtils cvMatFromUIImage:targetImage];
    Mat grayTargetImage;
    cvtColor(targetImageMat, grayTargetImage, CV_BGR2GRAY);
    
    std::vector<cv::KeyPoint> keypoints;
    cv::Mat descriptors;
    extractFeatureUsingFAST(grayTargetImage, keypoints, descriptors);
    
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
    extractFeatureUsingFAST(grayTargetImage1, keyPointsA, descriptorsA);
    extractFeatureUsingFAST(grayTargetImage2, keyPointsB, descriptorsB);
    
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
    const float nn_match_ratio = 0.6f;
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
        
        extractFeatureUsingFAST(grayImageMat, keyPoints, descriptors);
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
        
        //        NSLog(@"Index : %d", i);
        //        for( int j = 0; j < nn_matches.size(); j++){
        //            NSLog(@"QuaryIdx : %d, TrainIdx : %d",nn_matches[j][0].queryIdx, nn_matches[j][0].trainIdx);
        //        }
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
    
    NSLog(@"Matched Num : %d", queryIndexes.size());
    
    
    vector<Mat> resultMats;
    
    for( int i = 0; i < grayImages.size(); i++){
        Mat resultImageMat;
        cvtColor(grayImages[i], resultImageMat, CV_GRAY2BGRA);
        resultMats.push_back(resultImageMat);
    }
    
    NSMutableString* pointStr = [NSMutableString new];
    
    for( int i =0; i < queryIndexes.size(); i++){
        std::vector<int> queries = queryIndexes[i];
        
        for(int j = 0; j < queries.size(); j++){
            int index = queries[j];
            Point2f point = keyPointsVec[j][index].pt;
            [OpenCVUtils setPixelColor:resultMats[j] posX:point.x posY:point.y size:pixel color:[UIColor redColor]];
            
            if(j == 0){
                [pointStr appendFormat:@"%lf\t%lf", point.x, point.y];
            }else{
                [pointStr appendFormat:@"\t%lf\t%lf", point.x, point.y];
            }
        }
        
        [pointStr appendString:@"\n"];
    }
    
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
    
    extractFeatureUsingFAST(_sourceImageMat, keypointsA, descriptorsA);
    extractFeatureUsingFAST(targetImageMat, keypointsB, descriptorsB);
    
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

-(NSArray*) stabilizedWithImageList:(NSArray *)images{
    
    try{
        int numOfImages = [images count] ;
        
        vector<Mat> grayImages;
        vector<Mat> targetImageMats;
        vector< std::vector<cv::KeyPoint> > keyPointsVec;
        vector<Mat> descriptorsVec;
        
        for(int i =0 ; i < numOfImages; i++){
            Mat targetImageMat = [OpenCVUtils cvMatFromUIImage:images[i]];
            Mat grayImageMat;
            cvtColor(targetImageMat, grayImageMat, CV_BGR2GRAY);
            grayImages.push_back(grayImageMat);
            targetImageMats.push_back(targetImageMat);
            
            std::vector<cv::KeyPoint> keyPoints;
            Mat descriptors;
            
            NSLog(@"Extract Started");
            extractFeatureUsingFAST(grayImageMat, keyPoints, descriptors);
            keyPointsVec.push_back(keyPoints);
            descriptorsVec.push_back(descriptors);
            
            NSLog(@"Extract Feature : %d, extracted : %d", i, keyPoints.size());
            if(keyPoints.size() < 3){
                _isEnabled = NO;
                return images;
            }
        }
        
        NSLog(@"Start of matching");
        cv::BFMatcher matcher(cv::NORM_HAMMING);
        std::vector< std::vector< std::vector<DMatch> > > matchedList;
        
        for( int i =1; i < numOfImages; i++){
            std::vector< std::vector<DMatch> > nn_matches;
            matcher.knnMatch(descriptorsVec[i-1], descriptorsVec[i], nn_matches, 2);
            matchedList.push_back(nn_matches);
            
            //        NSLog(@"Index : %d", i);
            //        for( int j = 0; j < nn_matches.size(); j++){
            //            NSLog(@"QuaryIdx : %d, TrainIdx : %d",nn_matches[j][0].queryIdx, nn_matches[j][0].trainIdx);
            //        }
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
        
        NSLog(@"Find Inliner Matched Num : %d", queryIndexes.size());
        
        if(queryIndexes.size() <= 3){
            // 점이 충분하지않으므로 기존 이미지를 넘겨줌
            _isEnabled = NO;
            return images;
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
        
        
        vector<Mat> resultMats;
        resultMats.push_back(targetImageMats[0]);
        
        _hasPrevResult = YES;
        
        Mat prevH;
        if(_estimatedResults.size() > 0){
            for(int i=0; i < _estimatedResults.size(); i++){
                delete _estimatedResults[i];
            }
            _estimatedResults.clear();
        }
        
        
        NSLog(@"estimate homograpy start");
        NSMutableArray* cropAreas = [[NSMutableArray alloc] init];
        
        for( int i = 1; i < numOfImages; i++){
            Mat R = estimateRigidTransform(resultFeature[i], resultFeature[i-1], true);
            //        Mat R = findHomography(resultFeature[i], resultFeature[i-1]);
//            Mat R = findHomography(resultFeature[i], resultFeature[i-1]);
            
            if(R.cols ==0 && R.rows ==0){
                // Estimate 가 잘 안된경우
                _isEnabled = NO;
                return images;
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
            
            int rows = targetImageMats[i].rows;
            int cols = targetImageMats[i].cols;
            
            cv::Mat res(rows, cols, CV_8UC4);
//            cv::Mat mask(rows, cols, CV_8UC4);
//            mask.setTo(1);
//            [OpenCVUtils removeEdge:mask edge:1];
            
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
            _estimatedResults.push_back(pMat);
            
            NSLog(@"index : %i %p", i, pMat);
            //            print(*pMat);
            NSLog(@"");
            
            warpPerspective(targetImageMats[i], res, prevH, cv::Size(cols, rows));
//            warpPerspective(mask, mask, prevH, cv::Size(cols,rows));

            NSArray* arr = [OpenCVUtils findCropAreaWithHMatrics:prevH imageWidth:cols imageHeight:rows];
            [cropAreas addObject:arr];
            
            //        res = [OpenCVUtils mergeImage:targetImageMats[0] another:res];
//            res = [OpenCVUtils mergeImage:resultMats[0] another:res mask:mask];
            
            resultMats.push_back(res);
        }
        
        NSLog(@"end ot estimate");
        
        NSLog(@"Find crop area");
        int left = 0; int top = 0; int right = targetImageMats[0].cols; int bottom = targetImageMats[0].rows;
        
        for (NSArray* arr in cropAreas) {
            int targetLeft = [arr[0] integerValue];
            int targetRight = [arr[1] integerValue];
            int targetTop = [arr[2] integerValue];
            int targetBottom = [arr[3] integerValue];
            
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

        float imageWidth = targetImageMats[0].cols;
        float imageHeight = targetImageMats[0].rows;
        float maxDiff = 0.0;
        maxDiff = maxDiff < (float)left/imageWidth ? (float)left/imageWidth : maxDiff;
        maxDiff = maxDiff < abs(imageWidth - right)/imageWidth ? abs(imageWidth - right)/imageWidth : maxDiff;
        maxDiff = maxDiff < (float)top/imageHeight ? (float)top/imageHeight : maxDiff;
        maxDiff = maxDiff < abs(imageHeight - bottom)/imageHeight ? abs(imageHeight - bottom)/imageHeight : maxDiff;
        
        NSLog(@"Max Diff : %lf", maxDiff);
        
        if(maxDiff > 0.1){
            _isEnabled = NO;
            return images;
        }
        
        NSMutableArray* results = [NSMutableArray array];
        Mat om;
        for( int i = 0; i < numOfImages; i++){
            Mat mat = resultMats[i];
//            UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:mat];
            
            UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:[OpenCVUtils cropImage:mat left:left right:right top:top bottom:bottom]];
            
//            Mat m2 = [OpenCVUtils cropImage:mat left:left right:right top:top bottom:bottom];
//
//            if( i > 0){
//                m2 = [OpenCVUtils mergeImage:om another:m2 rect:CGRectMake(150, 190, 420, 130)];
//            }else{
//                om = m2;
//            }
//
//            UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:m2];
            
            [results addObject:resultImage];
        }
        
        _isEnabled = YES;
        
        return results;
    }catch(cv::Exception & e){
        _isEnabled = NO;
        
        return images;
    }
}

-(NSArray*) stabilizedWithPrevResult:(NSArray *)images{
    try{
        int numOfImages = [images count];
        
        NSMutableArray* results = [NSMutableArray array];
        
        Mat firstImageMat = [OpenCVUtils cvMatFromUIImage:images[0]];
        NSMutableArray* cropAreas = [[NSMutableArray alloc] init];
        
        vector<Mat> resultMats;
        resultMats.push_back(firstImageMat);
        
        for( int i = 1; i < numOfImages; i++){
            Mat targetImageMat = [OpenCVUtils cvMatFromUIImage:images[i]];
            int rows = targetImageMat.rows;
            int cols = targetImageMat.cols;
            
            cv::Mat res(rows, cols, CV_8UC4);
//            cv::Mat mask(rows, cols, CV_8UC4);
//            mask.setTo(1);
//            [OpenCVUtils removeEdge:mask edge:1];
            
            NSLog(@"after index : %i %p", i, _estimatedResults[i-1]);
            //            print(*_estimatedResults[i-1]);
            NSLog(@"");
            
            warpPerspective(targetImageMat, res, *_estimatedResults[i-1], cv::Size(cols, rows));
//            warpPerspective(mask, mask, *_estimatedResults[i-1], cv::Size(cols, rows));
            
            NSArray* arr = [OpenCVUtils findCropAreaWithHMatrics:*_estimatedResults[i-1] imageWidth:cols imageHeight:rows];
            [cropAreas addObject:arr];
            
            resultMats.push_back(res);
            
            //        res = [OpenCVUtils mergeImage:targetImageMats[0] another:res];
//            res = [OpenCVUtils mergeImage:firstImageMat another:res mask:mask];
//            UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:res];
//            [results addObject:resultImage];
        }
        
        NSLog(@"Find crop area");
        int left = 0; int top = 0; int right = firstImageMat.cols; int bottom = firstImageMat.rows;
        
        for (NSArray* arr in cropAreas) {
            int targetLeft = [arr[0] integerValue];
            int targetRight = [arr[1] integerValue];
            int targetTop = [arr[2] integerValue];
            int targetBottom = [arr[3] integerValue];
            
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
        
        float imageWidth = firstImageMat.cols;
        float imageHeight = firstImageMat.rows;
        float maxDiff = 0.0;
        maxDiff = maxDiff < (float)left/imageWidth ? (float)left/imageWidth : maxDiff;
        maxDiff = maxDiff < abs(imageWidth - right)/imageWidth ? abs(imageWidth - right)/imageWidth : maxDiff;
        maxDiff = maxDiff < (float)top/imageHeight ? (float)top/imageHeight : maxDiff;
        maxDiff = maxDiff < abs(imageHeight - bottom)/imageHeight ? abs(imageHeight - bottom)/imageHeight : maxDiff;
        
        NSLog(@"Max Diff : %lf", maxDiff);
        
        if(maxDiff > 0.1){
            _isEnabled = NO;
            return images;
        }
        
        for( int i = 0; i < numOfImages; i++){
            Mat mat = resultMats[i];
            //            UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:mat];
            UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:[OpenCVUtils cropImage:mat left:left right:right top:top bottom:bottom]];
            [results addObject:resultImage];
        }
        
        _isEnabled = YES;
        
        return results;
        
    }catch(cv::Exception &e){
        _isEnabled = NO;
        return images;
    }
}


-(void) compareExtractor:(NSArray*)images{
    int numOfImages = [images count] ;
    
    vector<Mat> grayImages;
    vector<Mat> targetImageMats;
    vector< std::vector<cv::KeyPoint> > keyPointsVec;
    vector<Mat> descriptorsVec;
    
    for(int i =0 ; i < numOfImages; i++){
        Mat targetImageMat = [OpenCVUtils cvMatFromUIImage:images[i]];
        Mat grayImageMat;
        cvtColor(targetImageMat, grayImageMat, CV_BGR2GRAY);
        grayImages.push_back(grayImageMat);
        targetImageMats.push_back(targetImageMat);
    }
    
    NSLog(@"BRISK Algorithm start");
    for(int i =0; i < numOfImages; i++){
        
        std::vector<cv::KeyPoint> keyPoints;
        Mat descriptors;
        extractFeatureUsingBRISK(grayImages[i], keyPoints, descriptors);
        keyPointsVec.push_back(keyPoints);
        descriptorsVec.push_back(descriptors);
        NSLog(@"Extract Feature : %d, extracted : %d", i, keyPoints.size());
    }
    NSLog(@"BRISK END");
    
    NSLog(@"AKAZE Algorithm start");
    for(int i =0; i < numOfImages; i++){
        extractFeatureUsingAkaze(targetImageMats[i], keyPointsVec[i], descriptorsVec[i]);
        NSLog(@"Extract Feature : %d, extracted : %d", i, keyPointsVec[i].size());
    }
    NSLog(@"AKAZE END");
    
    NSLog(@"ORB Algorithm start");
    for(int i =0; i < numOfImages; i++){
        extractFeatureUsingORB(grayImages[i], keyPointsVec[i], descriptorsVec[i]);
        NSLog(@"Extract Feature : %d, extracted : %d", i, keyPointsVec[i].size());
    }
    NSLog(@"ORB END");
    
    NSLog(@"FAST Algorithm start");
    for(int i =0; i < numOfImages; i++){
        extractFeatureUsingFAST(grayImages[i], keyPointsVec[i], descriptorsVec[i]);
        NSLog(@"Extract Feature : %d, extracted : %d", i, keyPointsVec[i].size());
    }
    NSLog(@"FAST END");
}

// http://nghiaho.com/?p=2093
-(NSArray *) opticalFlowImageList:(NSArray *)images{
    int numOfImages = [images count] ;
    
    vector<Mat> resultMats;
    Mat cur, cur_grey;
    Mat prev_grey;
    Mat prev;
    vector <Point2f> prev_corner;
    vector <Point2f> cur_corner;
    Mat last_T;
    
    // Accumulated frame to frame transform
    double a = 0;
    double x = 0;
    double y = 0;

    Trajectory X;//posteriori state estimate
    Trajectory	X_;//priori estimate
    Trajectory P;// posteriori estimate error covariance
    Trajectory P_;// priori estimate error covariance
    Trajectory K;//gain
    Trajectory	z;//actual measurement
    double pstd = 4e-3;//can be changed
    double cstd = 0.25;//can be changed
    Trajectory Q(pstd,pstd,pstd);// process noise covariance
    Trajectory R(cstd,cstd,cstd);// measurement noise covariance
    
    for(int i =0 ; i < numOfImages; i++){
        cur = [OpenCVUtils cvMatFromUIImage:images[i]];
        
        cvtColor(cur, cur_grey, COLOR_BGR2GRAY);
        
        // vector from prev to cur
        vector <Point2f> prev_corner, cur_corner;
        vector <Point2f> prev_corner2, cur_corner2;
        vector <uchar> status;
        vector <float> err;
        
        if(i==0){
            prev_grey = cur_grey;
            prev = cur;
        }
        
        goodFeaturesToTrack(prev_grey, prev_corner, 200, 0.01, 30);
        calcOpticalFlowPyrLK(prev_grey, cur_grey, prev_corner, cur_corner, status, err);
        
        // weed out bad matches
        for(size_t i=0; i < status.size(); i++) {
            if(status[i]) {
                prev_corner2.push_back(prev_corner[i]);
                cur_corner2.push_back(cur_corner[i]);
            }
        }
        
        // translation + rotation only
        Mat T = estimateRigidTransform(prev_corner2, cur_corner2, false); // false = rigid transform, no scaling/shearing
        
        // in rare cases no transform is found. We'll just use the last known good transform.
        if(T.data == NULL) {
            last_T.copyTo(T);
        }
        
        T.copyTo(last_T);
        
        // decompose T
        double dx = T.at<double>(0,2);
        double dy = T.at<double>(1,2);
        double da = atan2(T.at<double>(1,0), T.at<double>(0,0));
        //
        //prev_to_cur_transform.push_back(TransformParam(dx, dy, da));
        
        //
        // Accumulated frame to frame transform
        x += dx;
        y += dy;
        a += da;
        //trajectory.push_back(Trajectory(x,y,a));
        //
        //
        z = Trajectory(x,y,a);
        //
        if(i==0){
            // intial guesses
            X = Trajectory(0,0,0); //Initial estimate,  set 0
            P =Trajectory(1,1,1); //set error variance,set 1
        }
        else
        {
            //time update（prediction）
            X_ = X; //X_(k) = X(k-1);
            P_ = P+Q; //P_(k) = P(k-1)+Q;
            // measurement update（correction）
            K = P_/( P_+R ); //gain;K(k) = P_(k)/( P_(k)+R );
            X = X_+K*(z-X_); //z-X_ is residual,X(k) = X_(k)+K(k)*(z(k)-X_(k));
            P = (Trajectory(1,1,1)-K)*P_; //P(k) = (1-K(k))*P_(k);
        }
        //smoothed_trajectory.push_back(X);

        //-
        // target - current
        double diff_x = X.x - x;//
        double diff_y = X.y - y;
        double diff_a = X.a - a;
        
        dx = dx + diff_x;
        dy = dy + diff_y;
        da = da + diff_a;
        
        //new_prev_to_cur_transform.push_back(TransformParam(dx, dy, da));
        //

        //
        T.at<double>(0,0) = cos(da);
        T.at<double>(0,1) = -sin(da);
        T.at<double>(1,0) = sin(da);
        T.at<double>(1,1) = cos(da);
        
        T.at<double>(0,2) = dx;
        T.at<double>(1,2) = dy;
        
        Mat cur2;
        
        warpAffine(prev, cur2, T, cur.size());
        
        int vert_border = HORIZONTAL_BORDER_CROP * prev.rows / prev.cols;
        cur2 = cur2(Range(vert_border, cur2.rows-vert_border), Range(HORIZONTAL_BORDER_CROP, cur2.cols-HORIZONTAL_BORDER_CROP));
        
        // Resize cur2 back to cur size, for better side by side comparison
        resize(cur2, cur2, cur.size());
        
        resultMats.push_back(cur2);
        
        //
        prev = cur.clone();//cur.copyTo(prev);
        cur_grey.copyTo(prev_grey);
    }

    NSMutableArray* results = [NSMutableArray array];
    for( int i = 0; i < numOfImages; i++){
        UIImage* resultImage = [OpenCVUtils UIImageFromCVMat:resultMats[i]];
        [results addObject:resultImage];
    }
    
    return results;
}

@end
