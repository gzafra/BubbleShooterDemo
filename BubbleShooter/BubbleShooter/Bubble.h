//
//  Bubble.h
//  BubbleShooter
//
//  Created by Guillermo Zafra on 16/07/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#define kNumColors 5
#define kTagBubble 100

enum EBubbleColor {
    GreyBall = 0,
    YellowBall = 1,
    RedBall = 2,
    BlueBall = 3,
    GreenBall = 4
    };

enum EBubbleType{
    EBubbleStatic,
    EBubbleMoving,
    EBubbleDisabled
};

@interface Bubble : CCSprite {
    enum EBubbleType bubbleType;
    enum EBubbleColor bubbleColor;
    CGPoint direction;
    float velocity;
    
    bool mustBeDestroyed;
    bool mustBeHeld;
    
}

@property (nonatomic) CGPoint direction;
@property (nonatomic) enum EBubbleType bubbleType;
@property (nonatomic) enum EBubbleColor bubbleColor;
@property (nonatomic) bool mustBeDestroyed;
@property (nonatomic) bool mustBeHeld;

- (id)initWithType:(enum EBubbleType)_type  andColor:(enum EBubbleColor)_color;
- (void)update:(ccTime)deltaTime;

@end
