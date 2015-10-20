//
//  ImageStabilizerWrapper.m
//  Pholar
//
//  Created by EunchulJeon on 2015. 10. 17..
//  Copyright © 2015년 NAVERCORP. All rights reserved.
//

#import "ImageStabilizerWrapper.h"
#import "ImageStabilizer.h"

@interface ImageStabilizerWrapper()
@property(nonatomic, strong) ImageStabilizer* stabilizer;
@end

@implementation ImageStabilizerWrapper

-(id) init{
    
    self = [super init];
    
    if(self){
        _stabilizer = [[ImageStabilizer alloc] init];
    }
    
    return self;
}

-(NSArray*) getStabilizedImages:(NSArray*)originalImages{
    if([_stabilizer hasPrevResult]){
        return [_stabilizer stabilizedWithPrevResult:originalImages];
    }else{
        return [_stabilizer stabilizedWithImageList:originalImages];
    }
}

-(BOOL) isStabilizerEnabled{
    return [_stabilizer isEnabled];
}

-(void) resetStabilizer{
    [_stabilizer resetStabilizer];
}
@end
