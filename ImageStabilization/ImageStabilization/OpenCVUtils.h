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
+ (cv::Mat)cvMatFromUIImage:(UIImage *)imaage;
+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
+ (cv::Mat) mergeImage:(cv::Mat)image1 another:(cv::Mat)image2;
+ (cv::Mat) mergeImage:(cv::Mat)image1 another:(cv::Mat)image2 mask:(cv::Mat)mask;
+ (cv::Mat) mergeImage:(cv::Mat)image1 another:(cv::Mat)image2 rect:(CGRect)r;
+ (cv::Mat) removeEdge:(cv::Mat)image edge:(NSInteger)edgeSize;
+ (void)saveImage:(UIImage *)imageToSave fileName:(NSString *)imageName;
+ (void)setPixelColor:(cv::Mat)cvMat posX:(NSInteger)posX posY:(NSInteger)posY size:(NSInteger)size color:(UIColor *)color;
+ (cv::Vec4b) convertUIColorToVect:(UIColor*)color;
+ (NSArray*) findCropAreaWithHMatrics:(cv::Mat)hMat imageWidth:(int)width imageHeight:(int)height;
+(void)writeFile:(NSString*)fileName data:(NSString*) data;
+ (cv::Mat) cropImage:(cv::Mat) image left:(int)left right:(int)right top:(int)top bottom:(int)bottom;
@end
