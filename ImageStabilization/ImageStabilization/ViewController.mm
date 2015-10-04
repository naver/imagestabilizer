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


typedef NS_ENUM(NSInteger, DataSet){
    DATASET_1 = 0,
    DATASET_2 = 1,
    DATASET_3 = 2,
};

#define DEFAULT_DATASET DATASET_3
#define REPRESENTING_FEATURE_PIXEL_SIZE 10
#define TIMER_INIT_INTERVAL 0.2

@interface ViewController ()
@property(nonatomic, strong) ImageStabilizer* stabilizer;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewer1;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewer2;
@property (weak, nonatomic) IBOutlet UISlider *timerSlider;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) NSArray* images;
@property (nonatomic, strong) NSMutableArray* resultImages;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) CGFloat animatinonInterval;
@property (nonatomic) BOOL showResults;
@property (nonatomic) DataSet datasetIndex;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _datasetIndex = DEFAULT_DATASET;
    
    self.stabilizer = [[ImageStabilizer alloc] init];
    [self setDefaultImages];
    self.currentIndex = 0;
    self.showResults = NO;
    
    _animatinonInterval = TIMER_INIT_INTERVAL;
    [self.timerSlider setValue:_animatinonInterval];
     
     self.timer = [NSTimer scheduledTimerWithTimeInterval:_animatinonInterval target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
    [self.imageViewer1 setImage:[UIImage imageNamed:[self.images objectAtIndex:0]]];
    [self.imageViewer2 setImage:[UIImage imageNamed:[self.images objectAtIndex:0]]];
    
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

- (IBAction)featureExtractionClicked:(UIButton *) sender{
    NSLog(@"Feature Extraction Clicked");
    _showResults = NO;
    [self.resultImages removeAllObjects];
    for( int i =0 ; i < [self.images count] ; i++){
        UIImage* result = [self.stabilizer extractFeature:[UIImage imageNamed:[self.images objectAtIndex:i]] representingPixelSize:REPRESENTING_FEATURE_PIXEL_SIZE];
        [_resultImages addObject:result];
        NSLog(@"Extract Feature result index : %d", i);
    }
    _showResults = YES;
}
- (IBAction)featureMatingClicked:(UIButton *)sender {
    NSLog(@"Feature Matching Clicked");
    _showResults = NO;
    [self.resultImages removeAllObjects];

    [self.resultImages addObject:[UIImage imageNamed:[self.images objectAtIndex:0]]];
    
    for( int i =1 ; i < [self.images count] ; i++){
        UIImage* result = [self.stabilizer matchedFeature:[UIImage imageNamed:[self.images objectAtIndex:0]] anotherImage:[UIImage imageNamed:[self.images objectAtIndex:i]] representingPixelSize:REPRESENTING_FEATURE_PIXEL_SIZE];
        [_resultImages addObject:result];
        NSLog(@"Extract Feature result index : %d", i);
    }
    _showResults = YES;

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
    if( _datasetIndex == DATASET_1){
        self.images = @[@"data_1_1.jpg",@"data_1_2.jpg",@"data_1_3.jpg",@"data_1_4.jpg",@"data_1_5.jpg",@"data_1_6.jpg"];
    }else if( _datasetIndex == DATASET_2){
        self.images = @[@"data_2_1.jpg",@"data_2_2.jpg",@"data_2_3.jpg",@"data_2_4.jpg",@"data_2_5.jpg",@"data_2_6.jpg"];
    }
    else if( _datasetIndex == DATASET_3){
        self.images = @[@"data_3_1.jpg",@"data_3_2.jpg",@"data_3_3.jpg",@"data_3_4.jpg",@"data_3_5.jpg"];
    }
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    NSLog(@"Slider Value : %lf",sender.value);        
    _animatinonInterval = sender.value;
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:_animatinonInterval target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
}


@end
