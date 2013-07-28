//
//  WorldLayer.h
//  BubbleShooter
//
//  Created by Guillermo Zafra on 16/07/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Bubble.h"
#import "AimHelper.h"

// Sizes and positions
#define kVerticalOffset -24
#define kHorizontalOffset 16
#define kBubbleSize 24

#define kScreenHeight ([[CCDirector sharedDirector] winSize].height)
#define kScreenWidth ([[CCDirector sharedDirector] winSize].width)

// Other values
#define kMaxRows 16
#define kNumOfMatchesRequired 3
#define kTimeToPushRow 2

// Tags
#define kTagGameOverLabel 10

enum EGameState {
    EGamePlaying = 0,
    EGameStopped = 1,
    EGamePaused = 2
    };

@interface WorldLayer : CCLayer
{
    CCSpriteBatchNode *batchNode;
    NSMutableArray *bubblesGrid;
    int filledRows;
    int pushedRows;
    bool even;
    bool shooting;
    
    CGPoint lastLocation;
    CGPoint cannonPoint;
    
    Bubble *bubbleToShoot;
    
    AimHelper *aimHelper;
    
    float elapsedTime;
    
    enum EGameState gameState;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
