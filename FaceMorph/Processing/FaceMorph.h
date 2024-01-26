//
//  FaceMorph.h
//  FaceMorph
//
//  Created by Admin on 12/24/17.
//  Copyright © 2017 wolf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface FaceMorph : NSObject

- (instancetype)init;

- (BOOL)setFirstImage:(UIImage*)img;

- (BOOL)setSecondImage:(UIImage*)img;

- (UIImage*)faceMorph :(float)alpha;

@end
