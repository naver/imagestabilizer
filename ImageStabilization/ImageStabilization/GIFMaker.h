//
//  GIFMaker.h
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 11. 18..
//  Copyright © 2015년 EunchulJeon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GIFMaker : NSObject
+ (NSData *)saveGifWithImageList:(NSMutableArray *)imageList withDelay:(CGFloat)delay;
@end
