//
//  ImageStabilizer.h
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 9. 23..
//  Copyright (c) 2015년 EunchulJeon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

// Reference
// 1. http://stackoverflow.com/questions/13423884/how-to-use-brisk-in-opencv
// 2. http://docs.opencv.org/master/db/d70/tutorial_akaze_matching.html#gsc.tab=0

@interface ImageStabilizer : NSObject
-(void) setStabilizeSourceImage:(UIImage*) sourceImage;
-(UIImage*) stabilizeImage:(UIImage*)targetImage;
@end
