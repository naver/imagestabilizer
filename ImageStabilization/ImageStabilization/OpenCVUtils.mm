//
//  OpenCVUtils.m
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 9. 12..
//  Copyright (c) 2015년 EunchulJeon. All rights reserved.
//

#import "OpenCVUtils.h"
using namespace cv;
@implementation OpenCVUtils


+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

+(cv::Mat) mergeImage:(cv::Mat)image1 another:(cv::Mat)image2{
    cv::Mat result(image1.rows, image1.cols, CV_8UC4);
    image1.copyTo(result);
    
    for(int row = 0; row < image1.rows; row++){
        for( int col = 0; col < image1.cols; col++){
            cv::Vec4b c = image2.at<cv::Vec4b>(cv::Point(row,col));
            
            if(c[0] == 0 && c[1] == 0 && c[2] ==0){
                // skip;
            }else{
                result.at<cv::Vec4b>(col,row) = c;
            }
        }
    }
    return  result;
}

+(cv::Mat) mergeImage:(cv::Mat)image1 another:(cv::Mat)image2 mask:(cv::Mat)mask{
    cv::Mat result(image1.rows, image1.cols, CV_8UC4);
    image1.copyTo(result);
    image2.copyTo(result, mask);
    return result;
}

+(cv::Mat) mergeImage:(cv::Mat)image1 another:(cv::Mat)image2 rect:(CGRect)r{
    cv::Mat result(image1.rows, image1.cols, CV_8UC4);
    image1.copyTo(result);
    
    for(int row = r.origin.y; row < (r.origin.y+r.size.height); row++){
        for( int col = r.origin.x; col < (r.origin.x+r.size.width); col++){
            cv::Vec4b c = image2.at<cv::Vec4b>(col,row);
//            c[0] = 255;
//            c[1] = 0;
//            c[2] = 0;
//            c[3] = 255;
            result.at<cv::Vec4b>(col,row) = c;
        }
    }

    return result;
}

+(cv::Mat) removeEdge:(cv::Mat)image edge:(NSInteger)edgeSize{
    int rows = image.rows;
    int cols = image.cols;
    
    for( int row = 0 ; row < edgeSize; row++){
        for( int col = 0; col < cols; col++){
            image.at<cv::Vec4b>(col, row) = 0;
        }
    }
    
    for( int row = rows-edgeSize-1 ; row < rows; row++){
        for( int col = 0; col < cols; col++){
            image.at<cv::Vec4b>(col, row) = 0;
        }
    }
    
    for( int row = 0; row < rows; row++){
        for( int col = 0; col < edgeSize; col++){
            image.at<cv::Vec4b>(col, row) = 0;
        }
    }
    
    for( int row = 0; row < rows; row++){
        for( int col = cols-edgeSize-1; col < cols; col++){
            image.at<cv::Vec4b>(col, row) = 0;
        }
    }
    
    return image;
}

+ (NSArray*) findCropAreaWithHMatrics:(cv::Mat)hMat imageWidth:(int)width imageHeight:(int)height{
    Mat topLeftPoint = (Mat_<double>(3,1) << 0, 0, 1);
    Mat topRightPoint = (Mat_<double>(3,1) << width, 0, 1);
    Mat bottomLeftPoint = (Mat_<double>(3,1) << 0, height,1);
    Mat bottomRightPoint = (Mat_<double>(3,1) << width, height,1);
    
    topLeftPoint = hMat*topLeftPoint;
    topRightPoint = hMat*topRightPoint;
    bottomLeftPoint = hMat*bottomLeftPoint;
    bottomRightPoint = hMat*bottomRightPoint;
    
    print(topLeftPoint);
    NSLog(@"next");
    print(topRightPoint);
    NSLog(@"next");
    print(bottomLeftPoint);
    NSLog(@"next");
    print(bottomRightPoint);
    NSLog(@"next");
    int left = topLeftPoint.at<double>(0,0) > bottomLeftPoint.at<double>(0,0) ? ceil(topLeftPoint.at<double>(0,0)) : ceil(bottomLeftPoint.at<double>(0,0));
    int right = topRightPoint.at<double>(0,0) < bottomRightPoint.at<double>(0,0) ? floor(topRightPoint.at<double>(0,0)) : floor(bottomRightPoint.at<double>(0,0));
    int top = topLeftPoint.at<double>(1,0) > topRightPoint.at<double>(1,0) ? ceil(topLeftPoint.at<double>(1,0)) : ceil(topRightPoint.at<double>(1,0));
    int bottom = bottomLeftPoint.at<double>(1,0) < bottomRightPoint.at<double>(1,0) ? floor(bottomLeftPoint.at<double>(1,0)) : floor(bottomRightPoint.at<double>(1,0));
    
    if(left < 0){
        left = 0;
    }
    if(right > width){
        right = width;
    }
    if(top < 0){
        top = 0;
    }
    if(bottom > height){
        bottom = height;
    }
    
    return @[[NSNumber numberWithInt:left],[NSNumber numberWithInt:right],[NSNumber numberWithInt:top],[NSNumber numberWithInt:bottom]];
}

+ (Mat) cropImage:(Mat) image left:(int)left right:(int)right top:(int)top bottom:(int)bottom{
    int width = right-left;
    int height = bottom-top;
    
    float ratio = (float)image.cols/(float)image.rows;
    
    if(width/ratio > height){
        width = height*ratio;
    }else{
        height = width/ratio;
    }

    
    cv::Mat result(height,width, CV_8UC4);
    result.setTo(0);

    for(int row =0 ;row < result.rows; row++){
        for(int col=0; col < result.cols; col++){
            result.at<cv::Vec4b>(row,col) = image.at<cv::Vec4b>(row+top, col+left);
        }
    }

    return result;
}

+ (void)saveImage:(UIImage *)imageToSave fileName:(NSString *)imageName
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

+ (cv::Vec4b) convertUIColorToVect:(UIColor*)color{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    cv::Vec4b c = {static_cast<unsigned char>(r*255), static_cast<unsigned char>(g*255), static_cast<unsigned char>(b*255), static_cast<unsigned char>(a*255)};
    return c;
}

+ (void)setPixelColor:(cv::Mat)cvMat posX:(NSInteger)posX posY:(NSInteger)posY size:(NSInteger)size color:(UIColor *)color{
    //    cv::Vec4b c = cvMat.at<cv::Vec4b>(cv::Point(posY, posX));
    
    cv::Vec4b c = [OpenCVUtils convertUIColorToVect:color];
    
    for( NSInteger dx = (posX-size/2); dx < (posX+size/2); dx++){
        for( NSInteger dy = (posY - size/2); dy < (posY+size/2); dy++){
            cvMat.at<cv::Vec4b>(dy, dx) = c;
        }
    }
}

+(void)writeFile:(NSString*)fileName data:(NSString*) data{
    // Destination for file that is writeable
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSURL *documentsURL = [NSURL URLWithString:documentsDirectory];
    
    NSURL *destinationURL = [documentsURL URLByAppendingPathComponent:fileName];
    
    
    
    // Now you can write to the file....
    
    NSError *writeError = nil;
    [data writeToFile:[destinationURL absoluteString] atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    NSLog(@"File : %@", [destinationURL absoluteString]);
}

@end
