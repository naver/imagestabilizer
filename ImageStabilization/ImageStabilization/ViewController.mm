//
//  ViewController.m
//  ImageStabilization
//
//  Created by EunchulJeon on 2015. 9. 12..
//  Copyright (c) 2015년 EunchulJeon. All rights reserved.
//

#import "ViewController.h"
#import "FeatureExtractor.h"

@interface ViewController ()
@property(nonatomic, strong) FeatureExtractor* extractor;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewer1;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewer2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.extractor = [[FeatureExtractor alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)extractFeatureClicked:(UIButton *)sender {
    NSLog(@"Extract Feature Clicked");
    UIImage* resultImage = [self.extractor extractFeatureFromUIImage:self.imageViewer1.image anotherImage:self.imageViewer2.image];
    
    [self.imageViewer1 setImage:resultImage];
}

@end
