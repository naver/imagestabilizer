//
//  OpenCVUtils.h
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 9. 12..
//  Copyright (c) 2015년 EunchulJeon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVUtils : NSObject
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
+ (cv::Mat) mergeImage:(cv::Mat)image1 another:(cv::Mat)image2;
+ (void)saveImage:(UIImage *)imageToSave fileName:(NSString *)imageName;
@end
