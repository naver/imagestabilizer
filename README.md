# ImageStabilizationUsingFeatureIOS
Image stabilization using features detector in IOS

## Overview
GrabCut is an image segmentation method based on graph cuts. The algorithm was designed by Carsten Rother, Vladimir Kolmogorov & Andrew Blake from Microsoft Research Cambridge, UK. in their paper, "GrabCut": interactive foreground extraction using iterated graph cuts . An algorithm was needed for foreground extraction with minimal user interaction, and the result was GrabCut.

## Screenshot
![demo.gif](/docs/demo.gif)

## Requirement
1. OpenCV Framework

## Usage
      1. Import ImageStabilizer
 ```objectiveC
  #import "ImageStabilizer.h"
  ImageStabilizer* stabilizer = [[ImageStailizer alloc] init];
  ```
      2. Set first image to compare with others.
  ```objectiveC
  -(void) setStabilizeSourceImage:(UIImage*) sourceImage;
  ```
      3. Get stabilized image
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
See [LICENSE](/files/79302) for full license text.

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

