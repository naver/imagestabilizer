//
//  GIFMaker.m
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 11. 18..
//  Copyright © 2015년 EunchulJeon. All rights reserved.
//

#import "GIFMaker.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>


@implementation GIFMaker

+ (NSString *)getGifOutputFilePath
{
    NSString *tempPath = NSTemporaryDirectory();
    NSString *dirPath = [NSString stringWithFormat:@"%@/GIF", tempPath];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSString *gifFileName = [NSString stringWithFormat:@"animatedGif.gif"];
    NSString *gifFilePath = [NSString stringWithFormat:@"%@/%@", dirPath, gifFileName];
    
    NSLog(@"GIF File Path : %@", gifFilePath);
    
    return gifFilePath;
}

+ (NSData *)saveGifWithImageList:(NSMutableArray *)imageList withDelay:(CGFloat)delay {
    
    NSString *path = [GIFMaker getGifOutputFilePath];
    unlink([path UTF8String]);
    
    NSDictionary *prep = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:delay] forKey:(NSString *) kCGImagePropertyGIFDelayTime] forKey:(NSString *) kCGImagePropertyGIFDictionary];
    
    
    // 루프 카운터 0이면 무한루프
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0,
                                             },
                                     (__bridge id)kCGImagePropertyGIFHasGlobalColorMap : [NSNumber numberWithBool:YES],
                                     };
    
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    
    CGImageDestinationRef dst = CGImageDestinationCreateWithURL(url, kUTTypeGIF, [imageList count], nil);
    CGImageDestinationSetProperties(dst, (__bridge CFDictionaryRef)fileProperties);
    
    NSInteger count = [imageList count];
    for (int i = 0; i < count; i++) {
        @autoreleasepool {
            UIImage *image = [imageList objectAtIndex:i];
            CGImageDestinationAddImage(dst, image.CGImage,(__bridge CFDictionaryRef)(prep));
        }
    }
    
    
    bool fileSave = NO;
    @autoreleasepool {
        fileSave = CGImageDestinationFinalize(dst);
        CFRelease(dst);
    }
    
    if(fileSave) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
        return data;
    }else{
        //        NSLog(@"error: no animated GIF file created at %@", path);
    }
    return nil;
}

@end
