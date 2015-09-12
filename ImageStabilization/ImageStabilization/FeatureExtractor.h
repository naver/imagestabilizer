//
//  FeatureExtractor.h
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 9. 12..
//  Copyright (c) 2015년 EunchulJeon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>

@interface FeatureExtractor : NSObject
-(void) extractFeatureFromUIImage:(UIImage *)image;
@end
