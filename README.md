# ImageStabilizationUsingFeatureIOS
Image stabilization using features detector in IOS

## Overview
Image stabilization is a essential technique when you take images using continuous shooting.
There are many approaches to solve this problem but this project use the feature extraction.

* At first, Extract features from image using Feature extractor like SIFT, SURF. In this project, I use BRISK and AKAZE, because it is fast and there is no patent issue.
* Find Matching features in two images. There are many matching technique but I just use Bruteforce Matcher because it is simple and result is not bad in this project.
* Last, Get geometric transformation matrix which is minimize error of transformed points. RANSAC is used for this process.

All this process are simply implemented using OpenCV


## Screenshot
![demo.gif](/docs/demo.gif)

Top images are original images and bottom images are stabilized image using ImageStabilizer.

## Requirement
1. OpenCV Framework

## Usage
Import ImageStabilizer
```objectiveC
  #import "ImageStabilizer.h"
  ImageStabilizer* stabilizer = [[ImageStailizer alloc] init];
```
  
Set first image to compare with others.
```objectiveC
  -(void) setStabilizeSourceImage:(UIImage*) sourceImage;
```

Get stabilized image
```objectiveC
  -(UIImage*) stabilizeImage:(UIImage*)targetImage;
```

## Limitation
This program use OpenCV library.
It is not use GPU in IOS. it is obviously more slower than library that it use GPU.
So I want to improve this code to use GPU like GPUImage.

## References
* http://stackoverflow.com/questions/13423884/how-to-use-brisk-in-opencv
* http://docs.opencv.org/master/db/d70/tutorial_akaze_matching.html#gsc.tab=0

## License
ImageStabilizationUsingFeatureIOS is licensed under the Apache License, Version 2.0.
See [LICENSE](/docs/LICENSE.txt) for full license text.

        Copyright (c) 2015 Naver Corp.
        @Author Eunchul Jeon

        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at

                http://www.apache.org/licenses/LICENSE-2.0

        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.

