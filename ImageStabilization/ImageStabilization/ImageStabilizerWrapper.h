//
//  ImageStabilizerWrapper.h
//  Pholar
//
//  Created by EunchulJeon on 2015. 10. 17..
//  Copyright © 2015년 NAVERCORP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageStabilizerWrapper : NSObject
-(NSArray*) getStabilizedImages:(NSArray*)originalImages;
-(BOOL) isStabilizerEnabled;
-(void) resetStabilizer;
@end
