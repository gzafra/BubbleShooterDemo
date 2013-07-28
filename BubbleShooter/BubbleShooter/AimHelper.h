//
//  AimHelper.h
//  BubbleShooter
//
//  Created by Guillermo Zafra on 16/07/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface AimHelper : CCNode {
    CGPoint origin;
    CGPoint direction;
    float length;
}

@property (nonatomic) CGPoint direction;
@property (readwrite, assign) float length;

-(id)initWithOrigin:(CGPoint)_origin;

@end
