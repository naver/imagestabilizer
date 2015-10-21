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
#import "ImageStabilizerWrapper.h"


typedef NS_ENUM(NSInteger, DataSet){
    DATASET_1 = 0,
    DATASET_2 = 1,
    DATASET_3 = 2,
    DATASET_4 = 3,
    DATASET_5 = 4,
    DATASET_6 = 5,
    DATASET_7 = 6,
    DATASET_8 = 7,
    DATASET_9 = 8,
    DATASET_10 = 9,
    DATASET_11 = 10,
    DATASET_12 = 11,
    DATASET_13 = 12,
    DATASET_14 = 13
};

#define DEFAULT_DATASET DATASET_14
#define REPRESENTING_FEATURE_PIXEL_SIZE 10
#define TIMER_INIT_INTERVAL 0.2
#define END_OF_DATASET DATASET_14

@interface ViewController ()
@property (nonatomic, strong) ImageStabilizerWrapper* stabilizerWrapper;
@property (nonatomic, strong) ImageStabilizer* stabilizer;
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
@property (nonatomic) NSInteger animationDirection;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _datasetIndex = DEFAULT_DATASET;
    _animationDirection = 1;
    
    self.stabilizer = [[ImageStabilizer alloc] init];
    self.stabilizerWrapper = [[ImageStabilizerWrapper alloc] init];
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

- (IBAction)featureMatchingClicked:(UIButton *)sender {
    NSLog(@"Feature Matching Clicked");
    _showResults = NO;
    [self.resultImages removeAllObjects];

//    [self.resultImages addObject:[UIImage imageNamed:[self.images objectAtIndex:0]]];
//    
//    for( int i =1 ; i < [self.images count] ; i++){
//        UIImage* result = [self.stabilizer matchedFeature:[UIImage imageNamed:[self.images objectAtIndex:i-1]] anotherImage:[UIImage imageNamed:[self.images objectAtIndex:i]] representingPixelSize:REPRESENTING_FEATURE_PIXEL_SIZE];
//        [_resultImages addObject:result];
//        NSLog(@"Extract Feature result index : %d", i);
//    }
    
    NSMutableArray* targetImages = [NSMutableArray array];
    
    for(int i = 0; i < [self.images count]; i++){
        [targetImages addObject:[UIImage imageNamed:self.images[i]]];
    }
    
    NSArray* result = [self.stabilizer matchedFeatureWithImageList:targetImages representingPixelSize:REPRESENTING_FEATURE_PIXEL_SIZE];
    
    for(int i  = 0; i < [result count]; i++){
        [self.resultImages addObject:[result objectAtIndex:i]];
    }
    
    _showResults = YES;

}

- (IBAction)stabilizeImageClicked:(UIButton *)sender {
    NSLog(@"Stabilize start");

    _showResults = NO;
    [self.resultImages removeAllObjects];
//    [self.resultImages addObject:[UIImage imageNamed:[self.images objectAtIndex:0]]];
//    [self.stabilizer setStabilizeSourceImage:[UIImage imageNamed:[self.images objectAtIndex:0]]];
//
//    for( int i =1; i < [self.images count] ; i++){
//        UIImage* result = [self.stabilizer stabilizeImage:[UIImage imageNamed:[self.images objectAtIndex:i]]];
//        [self.resultImages addObject:result];
//        NSLog(@"Stabilize Result Index : %d", i);
//    }
    NSMutableArray* targetImages = [NSMutableArray array];
    
    for(int i = 0; i < [self.images count]; i++){
        [targetImages addObject:[UIImage imageNamed:self.images[i]]];
    }
    
    NSArray* result = [self.stabilizerWrapper getStabilizedImages:targetImages];
    
    for(int i  = 0; i < [result count]; i++){
        [self.resultImages addObject:[result objectAtIndex:i]];
        NSLog(@"Image Size : %lf %lf", [self.resultImages[0] size].width, [self.resultImages[0] size].height);
    }
    
    _showResults = YES;
}
- (IBAction)compareExtractorClicked:(id)sender {
    NSLog(@"Compare Extractor started");
    NSMutableArray* targetImages = [NSMutableArray array];
    
    for(int i = 0; i < [self.images count]; i++){
        [targetImages addObject:[UIImage imageNamed:self.images[i]]];
    }

    [self.stabilizer compareExtractor:targetImages];
    
}

-(void) timerTick{
    
    [_imageViewer1 setImage:[UIImage imageNamed:[self.images objectAtIndex:_currentIndex]]];
    
    if(_showResults){
        [_imageViewer2 setImage:[_resultImages objectAtIndex:_currentIndex]];
    }
    
    _currentIndex = _currentIndex + _animationDirection;
    if(_currentIndex >= [_images count]){
        _currentIndex = [_images count] -1;
        _animationDirection = -1;
    }else if (_currentIndex < 0){
        _currentIndex = 0;
        _animationDirection = 1;
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
    }else if( _datasetIndex == DATASET_4){
        self.images = @[@"data_4_1.jpg",@"data_4_2.jpg",@"data_4_3.jpg",@"data_4_4.jpg",@"data_4_5.jpg"];
    }else if( _datasetIndex == DATASET_5){
        self.images = @[@"data_5_1.jpg",@"data_5_2.jpg",@"data_5_3.jpg",@"data_5_4.jpg",@"data_5_5.jpg"];
    }else if( _datasetIndex == DATASET_6){
        self.images = @[@"data_6_1.jpg",@"data_6_2.jpg",@"data_6_3.jpg",@"data_6_4.jpg",@"data_6_5.jpg", @"data_6_6.jpg"];
    }else if( _datasetIndex == DATASET_7){
        self.images = @[@"data_7_1.jpg",@"data_7_2.jpg",@"data_7_3.jpg",@"data_7_4.jpg",@"data_7_5.jpg", @"data_7_6.jpg"];
    }else if( _datasetIndex == DATASET_8){
        self.images = @[@"data_8_1.jpg",@"data_8_2.jpg",@"data_8_3.jpg",@"data_8_4.jpg",@"data_8_5.jpg", @"data_8_6.jpg", @"data_8_7.jpg", @"data_8_8.jpg"];
    }else if( _datasetIndex == DATASET_9){
        self.images = @[@"data_9_1.jpg",@"data_9_2.jpg",@"data_9_3.jpg",@"data_9_4.jpg",@"data_9_5.jpg"];
    }else if( _datasetIndex == DATASET_10){
        self.images = @[@"data_10_1.jpg",@"data_10_2.jpg",@"data_10_3.jpg",@"data_10_4.jpg",@"data_10_5.jpg"];
    }else if( _datasetIndex == DATASET_11){
        self.images = @[@"data_11_1.jpg",@"data_11_2.jpg",@"data_11_3.jpg",@"data_11_4.jpg",@"data_11_5.jpg"];
    }else if( _datasetIndex == DATASET_12){
        self.images = @[@"data_12_1.jpg",@"data_12_2.jpg",@"data_12_3.jpg",@"data_12_4.jpg",@"data_12_5.jpg"];
    }else if( _datasetIndex == DATASET_13){
        self.images = @[@"data_13_1.jpg",@"data_13_2.jpg",@"data_13_3.jpg",@"data_13_4.jpg",@"data_13_5.jpg"];
    }else if( _datasetIndex == DATASET_14){
        self.images = @[@"data_14_1.jpg",@"data_14_2.jpg",@"data_14_3.jpg",@"data_14_4.jpg",@"data_14_5.jpg"];
    }
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    NSLog(@"Slider Value : %lf",sender.value);        
    _animatinonInterval = sender.value;
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:_animatinonInterval target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
}

- (IBAction)nextImageSetClicked:(id)sender {
    int nextIndex = _datasetIndex +1;
    
    if(nextIndex > END_OF_DATASET){
        nextIndex = 0;
    }
    
    _datasetIndex = (DataSet)nextIndex;
    _showResults = false;
    _currentIndex = 0;
    _animationDirection = 1;
    [self setDefaultImages];
    [_stabilizerWrapper resetStabilizer];
}

@end
