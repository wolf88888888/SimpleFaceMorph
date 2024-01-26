//
//  FaceMorph.m
//  FaceMorph
//
//  Created by Admin on 12/24/17.
//  Copyright © 2017 wolf. All rights reserved.
//

#import "FaceMorph.h"

#include <dlib/image_processing.h>
//#include <dlib/image_io.h>
#include <dlib/opencv/cv_image.h>

#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#import "UIImage+OpenCV.h"
#include <vector>

/*
 //perform Delaunay Triangulation on the keypoints of the morph image.
 */
struct correspondens{
    std::vector<int> index;
};

@interface FaceMorph ()

@property (assign) BOOL prepared;

@end
@implementation FaceMorph{
    dlib::shape_predictor _sp;
    cv::CascadeClassifier _faceCascade;
    cv::Mat _matFirst;
    std::vector<cv::Point2f> _landmarks1;
    BOOL _isDetection1;
    cv::Mat _matSecond;
    std::vector<cv::Point2f> _landmarks2;
    BOOL _isDetection2;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
        _isDetection1 = NO;
        _isDetection2 = NO;
        [self prepare];
    }
    return self;
}

- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];

    dlib::deserialize(modelFileNameCString) >> _sp;
//opencv face detection
    
    NSString *cascadPath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default30" ofType:@"xml"];
    
    std::string cascadeFilePath([cascadPath UTF8String]);
    bool isCascade = _faceCascade.load(cascadeFilePath);

    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
}

// ----------------------------------------------------------------------------------------

/* detect 68 face landmarks on the input image by using the face landmark detector in dlib.

 */
- (BOOL)faceLandmarkDetection:(cv::Mat&)matSrc :(std::vector<cv::Point2f>&)landmark {
//    dlib::frontal_face_detector detector = dlib::get_frontal_face_detector();
    //dlib::pyramid_up(img);

//    std::vector<dlib::rectangle> dets = detector(img);
    //cout << "Number of faces detected: " << dets.size() << endl;
    
    std::vector<cv::Rect> allFaces;
    _faceCascade.detectMultiScale(matSrc, allFaces, 1.2, 3, 0,
                                   cv::Size(matSrc.rows / 4, matSrc.rows / 4));

    if (allFaces.size() == 0)
        return false;
    dlib::rectangle rtROI(allFaces[0].x, allFaces[0].y,
                        allFaces[0].x + allFaces[0].width - 1, allFaces[0].y + allFaces[0].height - 1);
    
    dlib::cv_image<dlib::bgr_pixel> img(matSrc);
    dlib::full_object_detection shape = _sp(img, rtROI);
//    //image_window win;
//    //win.clear_overlay();
//    //win.set_image(img);
//    //win.add_overlay(render_face_detections(shape));
    for (int i = 0; i < shape.num_parts(); ++i)
    {
        float x=shape.part(i).x();
        float y=shape.part(i).y();
        landmark.push_back(cv::Point2f(x,y));
    }
    return true;
}

/*
 //add eight keypoints to the keypoints set of the input image.
 //the added eight keypoints are the four corners points of the image, plus four median points of the four edges of the image.
 */

- (void)addKeypoints:(std::vector<cv::Point2f>&)points :(cv::Size)imgSize {
    points.push_back(cv::Point2f(1,1));
    points.push_back(cv::Point2f(1,imgSize.height-1));
    points.push_back(cv::Point2f(imgSize.width-1,imgSize.height-1));
    points.push_back(cv::Point2f(imgSize.width-1,1));
    points.push_back(cv::Point2f(1,imgSize.height/2));
    points.push_back(cv::Point2f(imgSize.width/2,imgSize.height-1));
    points.push_back(cv::Point2f(imgSize.width-1,imgSize.height/2));
    points.push_back(cv::Point2f(imgSize.width/2,1));
}

/*
 // calculate the keypoints on the morph image.
 */

- (void)morpKeypoints:(const std::vector<cv::Point2f>&)points1 :(const std::vector<cv::Point2f>&)points2 :(std::vector<cv::Point2f>&)pointsMorph :(double)alpha {
    for (int i = 0; i < points1.size(); i++)
    {
        float x, y;
        x = (1 - alpha) * points1[i].x + alpha * points2[i].x;
        y = (1 - alpha) * points1[i].y + alpha * points2[i].y;

        pointsMorph.push_back(cv::Point2f(x, y));

    }
}

- (void)delaunayTriangulation:(const std::vector<cv::Point2f>&)points1 :(const std::vector<cv::Point2f>&)points2 :(std::vector<cv::Point2f>&)pointsMorph :(double)alpha :(std::vector<correspondens>&)delaunayTri :(cv::Size)imgSize
{
    //cout<<"begin delaunayTriangulation......"<<endl;
    [self morpKeypoints:points1 :points2 :pointsMorph :alpha];
    //cout<<"done morpKeypoints, pointsMorph has points "<<pointsMorph.size()<<endl;
    cv::Rect rect(0, 0, imgSize.width, imgSize.height);

//    for(int i=0;i<pointsMorph.size();++i)
//    {
//        cout<<pointsMorph[i].x<<" "<<pointsMorph[i].y<<endl;
//    }
//

    cv::Subdiv2D subdiv(rect);
    for (std::vector<cv::Point2f>::iterator it = pointsMorph.begin(); it != pointsMorph.end(); it++)
        subdiv.insert(*it);
    //cout<<"done subdiv add......"<<endl;
    std::vector<cv::Vec6f> triangleList;
    subdiv.getTriangleList(triangleList);
    //cout<<"traingleList number is "<<triangleList.size()<<endl;


    //std::vector<Point2f> pt;
    //correspondens ind;
    for (size_t i = 0; i < triangleList.size(); ++i)
    {

        std::vector<cv::Point2f> pt;
        correspondens ind;
        cv::Vec6f t = triangleList[i];
        pt.push_back( cv::Point2f(t[0], t[1]) );
        pt.push_back( cv::Point2f(t[2], t[3]) );
        pt.push_back( cv::Point2f(t[4], t[5]) );
        //cout<<"pt.size() is "<<pt.size()<<endl;

        if (rect.contains(pt[0]) && rect.contains(pt[1]) && rect.contains(pt[2]))
        {
            //cout<<t[0]<<" "<<t[1]<<" "<<t[2]<<" "<<t[3]<<" "<<t[4]<<" "<<t[5]<<endl;
            int count = 0;
            for (int j = 0; j < 3; ++j)
                for (size_t k = 0; k < pointsMorph.size(); k++)
                    if (abs(pt[j].x - pointsMorph[k].x) < 1.0   &&  abs(pt[j].y - pointsMorph[k].y) < 1.0)
                    {
                        ind.index.push_back(k);
                        count++;
                    }
            if (count == 3)
                //cout<<"index is "<<ind.index[0]<<" "<<ind.index[1]<<" "<<ind.index[2]<<endl;

                delaunayTri.push_back(ind);
        }
        //pt.resize(0);
        //cout<<"delaunayTri.size is "<<delaunayTri.size()<<endl;
    }
}


/*
 // apply affine transform on one triangle.
 */
- (void)applyAffineTransform:(cv::Mat&)warpImage :(cv::Mat&)src :(std::vector<cv::Point2f>&)srcTri :(std::vector<cv::Point2f>&)dstTri {
    cv::Mat warpMat = getAffineTransform(srcTri, dstTri);

    warpAffine(src, warpImage, warpMat, warpImage.size(), cv::INTER_LINEAR, cv::BORDER_REFLECT_101);
}

/*
 //the core function of face morph.
 //morph the two input image to the morph image by transacting the set of triangles in the two input image to the morph image.
 */
- (void)morphTriangle:(cv::Mat&)img1 :(cv::Mat&)img2 :(cv::Mat&)img :(std::vector<cv::Point2f>&)t1 :(std::vector<cv::Point2f>&)t2 :(std::vector<cv::Point2f>&)t :(double)alpha
{
    cv::Rect r = cv::boundingRect(t);
    cv::Rect r1 = cv::boundingRect(t1);
    cv::Rect r2 = cv::boundingRect(t2);

    std::vector<cv::Point2f> t1Rect, t2Rect, tRect;
    std::vector<cv::Point> tRectInt;
    for (int i = 0; i < 3; ++i)
    {
        tRect.push_back(cv::Point2f(t[i].x - r.x, t[i].y - r.y));
        tRectInt.push_back(cv::Point(t[i].x - r.x, t[i].y - r.y));

        t1Rect.push_back(cv::Point2f(t1[i].x - r1.x, t1[i].y - r1.y));
        t2Rect.push_back(cv::Point2f(t2[i].x - r2.x, t2[i].y - r2.y));
    }

    cv::Mat mask = cv::Mat::zeros(r.height, r.width, CV_32FC3);
    fillConvexPoly(mask, tRectInt, cv::Scalar(1.0, 1.0, 1.0), 16, 0);

    cv::Mat img1Rect, img2Rect;
    img1(r1).copyTo(img1Rect);
    img2(r2).copyTo(img2Rect);

    cv::Mat warpImage1 = cv::Mat::zeros(r.height, r.width, img1Rect.type());
    cv::Mat warpImage2 = cv::Mat::zeros(r.height, r.width, img2Rect.type());

    [self applyAffineTransform:warpImage1 :img1Rect :t1Rect :tRect];
    [self applyAffineTransform:warpImage2 :img2Rect :t2Rect :tRect];

    cv::Mat imgRect = (1.0 - alpha)*warpImage1 + alpha*warpImage2;

    multiply(imgRect, mask, imgRect);
    multiply(img(r), cv::Scalar(1.0, 1.0, 1.0) - mask, img(r));
    img(r) = img(r) + imgRect;
}

/*
 //morp the two input images into the morph image.
 //first get the keypoints correspondents of the set of  triangles, then call the core function.
 */
- (void)morp:(cv::Mat&)img1 :(cv::Mat&)img2 :(cv::Mat&)imgMorph :(double)alpha :(const std::vector<cv::Point2f>&)points1 :(const std::vector<cv::Point2f>&)points2 :(const std::vector<correspondens>&)triangle {
    cv::Mat matImg1_32f, matImg2_32f;;
    
    img1.convertTo(matImg1_32f, CV_32F);
    img2.convertTo(matImg2_32f, CV_32F);


    std::vector<cv::Point2f> points;
    [self morpKeypoints:points1 :points2 :points :alpha];

    int x, y, z;
    for (int i=0;i<triangle.size();++i)
    {
        correspondens corpd=triangle[i];
        x = corpd.index[0];
        y = corpd.index[1];
        z = corpd.index[2];
        std::vector<cv::Point2f> t1, t2, t;
        t1.push_back(points1[x]);
        t1.push_back(points1[y]);
        t1.push_back(points1[z]);

        t2.push_back(points2[x]);
        t2.push_back(points2[y]);
        t2.push_back(points2[z]);

        t.push_back(points[x]);
        t.push_back(points[y]);
        t.push_back(points[z]);
        [self morphTriangle:matImg1_32f :matImg2_32f :imgMorph :t1 :t2 :t :alpha];
    }
}

- (cv::Mat)cropImage:(cv::Mat)matSrc :(std::vector<cv::Point2f>&)landmarks {
    int left = matSrc.cols - 1;
    int right = 0;
    int top = matSrc.rows - 1;
    int bottom = 0;
    for (int i = 0; i < landmarks.size(); i ++) {
        if (left > landmarks[i].x)
            left = landmarks[i].x;
        if (right < landmarks[i].x)
            right = landmarks[i].x;
        if (top > landmarks[i].y)
            top = landmarks[i].y;
        if (bottom < landmarks[i].y)
            bottom = landmarks[i].y;
    }
    left -= 10;        left = left < 0 ? 0 : left;
    right += 10;    right = right > matSrc.cols - 1 ? matSrc.cols - 1 : right;
    top -= 10;        top  = top < 0 ? 0 : top;
    bottom += 10;    bottom = bottom > matSrc.rows - 1? matSrc.rows - 1 : bottom;

    int width = right - left + 1;
    int height = bottom - top + 1;

    cv::Mat matDst(300, 300, CV_8UC3, cv::Scalar(0));

    int WIDTH_DST = 150;
    float scale = WIDTH_DST / (float)width;
    float scaleH = matDst.rows / (float)height;

    if (scale > scaleH)
        scale = scaleH;

    cv::Mat matCrop = matSrc(cv::Rect(left, top, width, height)).clone();
    cv::Mat matMask = cv::Mat::zeros(height, width, CV_8UC1);
    for (int i = 0; i < landmarks.size(); i ++) {
        landmarks[i].x -= left;
        landmarks[i].y -= top;
        if (landmarks[i].x < 0)
            landmarks[i].x = 0;
        if (landmarks[i].y < 0)
            landmarks[i].y = 0;
    }

    cv::Point ptOutlines[27];
    for (int i = 0; i < 17; i ++) {
        ptOutlines[i] = landmarks[i];
    }
    ptOutlines[17] = landmarks[26];
    ptOutlines[18] = landmarks[22];
    ptOutlines[19] = landmarks[21];
    ptOutlines[20] = landmarks[17];

    cv::fillConvexPoly(matMask,
                       ptOutlines,
                       21,
                       cv::Scalar(255));
    
    cv::Point ptLeft[5];
    for (int i = 0; i < 5; i ++) {
        ptLeft[i] = landmarks[i + 17];
    }
    cv::fillConvexPoly(matMask,
                       ptLeft,
                       5,
                       cv::Scalar(255));
    
    cv::Point ptRight[5];
    for (int i = 0; i < 5; i ++) {
        ptRight[i] = landmarks[i + 22];
    }
    cv::fillConvexPoly(matMask,
                       ptRight,
                       5,
                       cv::Scalar(255));
    //     imshow("mask", matMask);
    //     waitKey(0);
    cv::Mat matCropDst = cv::Mat::zeros(matCrop.rows, matCrop.cols, CV_8UC3);
    matCrop.copyTo(matCropDst, matMask);

    cv::resize(matCropDst, matCropDst, cv::Size(matCropDst.cols * scale, matCropDst.rows * scale));

    matCropDst.copyTo(matDst(cv::Rect((matDst.cols - matCropDst.cols)/2, (matDst.rows - matCropDst.rows)/2, matCropDst.cols, matCropDst.rows)));

    for (int i = 0; i < landmarks.size(); i ++) {
        landmarks[i].x = landmarks[i].x * scale + (matDst.cols - matCropDst.cols)/2;
        landmarks[i].y = landmarks[i].y * scale + (matDst.rows - matCropDst.rows)/2;
    }

    return matDst;
}

- (BOOL)setFirstImage:(UIImage*)img{
    _matFirst = cvMatFromUIImage(img);

    _isDetection1 = [self faceLandmarkDetection:_matFirst :_landmarks1];
    if (_isDetection1)
        _matFirst = [self cropImage:_matFirst :_landmarks1];
    return _isDetection1;
}

- (BOOL)setSecondImage:(UIImage*)img {
    _matSecond = cvMatFromUIImage(img);

    _isDetection2 = [self faceLandmarkDetection:_matSecond :_landmarks2];
    if (_isDetection2)
        _matSecond = [self cropImage:_matSecond :_landmarks2];
    return _isDetection2;
}

- (UIImage*)faceMorph :(float)alpha{
    if (!_isDetection1 || !_isDetection2)
        return NULL;

    [self addKeypoints:_landmarks1 :_matFirst.size()];
    [self addKeypoints:_landmarks2 :_matSecond.size()];

    cv::Mat imgMorph = cv::Mat::zeros(_matFirst.size(), CV_32FC3);
    std::vector<cv::Point2f> pointsMorph;

    std::vector<correspondens> delaunayTri;
    [self delaunayTriangulation:_landmarks1 :_landmarks2 :pointsMorph :alpha :delaunayTri :_matFirst.size()];
    
    [self morp:_matFirst :_matSecond :imgMorph :alpha :_landmarks1 :_landmarks2 :delaunayTri];

    cv::Mat matResult;
    imgMorph.convertTo(matResult, CV_8UC3);

    imgMorph.release();

    UIImage *imgResult = UIImageFromCVMat(matResult);

    return imgResult;
}

@end
