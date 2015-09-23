//
//  ViewController.m
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 9. 12..
//  Copyright (c) 2015년 EunchulJeon. All rights reserved.
//

#import "ViewController.h"
#import "FeatureExtractor.h"
#import "ImageStabilizer.h"

@interface ViewController ()
@property(nonatomic, strong) ImageStabilizer* stabilizer;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewer1;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewer2;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) NSArray* images;
@property (nonatomic, strong) NSMutableArray* resultImages;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) BOOL showResults;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.stabilizer = [[ImageStabilizer alloc] init];
    [self setDefaultImages];
    self.currentIndex = 0;
    self.showResults = NO;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
    [self.imageViewer2 setImage:[UIImage imageNamed:@"data_1_1.jpg"]];
    
    _resultImages = [NSMutableArray array];
}

- (void) dealloc{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)stabilizeImageClicked:(UIButton *)sender {
    NSLog(@"Stabilize start");

    _showResults = NO;
    [self.resultImages removeAllObjects];
    [self.resultImages addObject:[UIImage imageNamed:[self.images objectAtIndex:0]]];
    [self.stabilizer setStabilizeSourceImage:[UIImage imageNamed:[self.images objectAtIndex:0]]];

    for( int i =1; i < [self.images count] ; i++){
        UIImage* result = [self.stabilizer stabilizeImage:[UIImage imageNamed:[self.images objectAtIndex:i]]];
        [self.resultImages addObject:result];
        NSLog(@"Stabilize Result Index : %d", i);
    }
    _showResults = YES;
}

-(void) timerTick{
    
    [_imageViewer1 setImage:[UIImage imageNamed:[self.images objectAtIndex:_currentIndex]]];
    
    if(_showResults){
        [_imageViewer2 setImage:[_resultImages objectAtIndex:_currentIndex]];
    }
    
    _currentIndex++;
    if(_currentIndex >= [_images count]){
        _currentIndex = 0;
    }
    
}

-(void) setDefaultImages{
    self.images = @[@"data_1_1.jpg",@"data_1_2.jpg",@"data_1_3.jpg",@"data_1_4.jpg",@"data_1_5.jpg",@"data_1_6.jpg"];
}

@end
