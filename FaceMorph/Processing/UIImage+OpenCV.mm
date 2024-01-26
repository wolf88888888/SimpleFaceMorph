//
//  MatRef.h
//  FaceMakeup
//
//  Created by Lang Jin on 4/28/16.
//  Copyright © 2016 LangJin. All rights reserved.
//
#import "UIImage+OpenCV.h"
#import "UIImage+FixOrientation.h"

UIImage* UIImageFromCVMat(cv::Mat &cvMat)
//-(UIImage*) UIImageFromCVMat:(cv::Mat&) cvMat
{
    if (cvMat.empty()) {
        return nil;
    }
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    cv::Mat mat1 = cvMat.clone();
    if (cvMat.elemSize() == 3) {
        cv::cvtColor(mat1, mat1, CV_BGR2RGBA);
    }
    
    if (cvMat.elemSize() == 4) {
        cv::cvtColor(mat1, mat1, CV_BGRA2RGBA);
    }
    NSData *data = [NSData dataWithBytes:mat1.data length:mat1.elemSize() * mat1.total()];
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(mat1.cols,                                     // Width
                                        mat1.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * mat1.elemSize(),                           // Bits per pixel
                                        mat1.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    mat1.release();
    return image;
}

cv::Mat cvMatFromUIImage(UIImage* image)
//-(cv::Mat) cvMatFromUIImage:(UIImage*) image
{
    if (image == nil) {
        return cv::Mat::zeros(10, 10, CV_8UC4);
    }
    image = [image fixOrientation];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    cv::Mat matBGR ;
    cv::cvtColor(cvMat, matBGR, CV_RGBA2BGR);
    cvMat.release();
    return matBGR;
}

