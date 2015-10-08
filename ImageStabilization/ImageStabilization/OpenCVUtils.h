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
+ (cv::Mat) mergeImage:(cv::Mat)image1 another:(cv::Mat)image2 mask:(cv::Mat)mask;
+ (cv::Mat) removeEdge:(cv::Mat)image edge:(NSInteger)edgeSize;
+ (void)saveImage:(UIImage *)imageToSave fileName:(NSString *)imageName;
+ (void)setPixelColor:(cv::Mat)cvMat posX:(NSInteger)posX posY:(NSInteger)posY size:(NSInteger)size color:(UIColor *)color;
+ (cv::Vec4b) convertUIColorToVect:(UIColor*)color;

+(void)writeFile:(NSString*)fileName data:(NSString*) data;
@end
