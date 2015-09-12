//
//  FeatureExtractor.h
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 9. 12..
//  Copyright (c) 2015년 EunchulJeon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

// Reference
// 1. http://stackoverflow.com/questions/13423884/how-to-use-brisk-in-opencv
// 2. http://docs.opencv.org/master/db/d70/tutorial_akaze_matching.html#gsc.tab=0

@interface FeatureExtractor : NSObject
-(UIImage*) extractFeatureFromUIImage:(UIImage *)image1 anotherImage:(UIImage*)image2;
@end
