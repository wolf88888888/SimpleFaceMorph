//
//  MatRef.h
//  FaceMakeup
//
//  Created by Lang Jin on 4/28/16.
//  Copyright © 2016 LangJin. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

UIImage* UIImageFromCVMat(cv::Mat &cvMat);
cv::Mat cvMatFromUIImage(UIImage* image);
