//
//  FilterViewController.h
//  OpenGL_ES_Filter
//
//  Created by trs on 2020/8/11.
//  Copyright © 2020 Ctair. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    FilterTypeSplitScreen = 0,
    FilterTypeGrayAndMosic,
} FilterType;

@interface FilterViewController : UIViewController
@property (nonatomic, assign) FilterType fiterType;

@end

NS_ASSUME_NONNULL_END
