//
//  BaseSprite.h
//  pacman-objectivec
//
//  Created by hahasouliu on 10/14/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "BaseMapSprite.h"

@interface BaseSprite : NSObject

- (id)initWithEffect:(GLKBaseEffect *)baseEffect;
- (id)initWithFile:(NSString *)fileName effect:(GLKBaseEffect *)effect;
- (void)setMoveBoundary:(float)boundaryX boundaryY:(float)boundaryY;

@property (nonatomic, strong) GLKTextureInfo *textureInfo;
@property (nonatomic, weak) NSMutableArray *mapSpriteArray;
@property (assign) GLKVector2 position;
@property (assign) GLKVector2 moveVelocity;
@property (assign) CGSize contentSize;

// 0: right, 1: left, 2:up, 3:down
@property (assign) int currentMotion;
@property (assign) int nextMotion;

- (void)render;
- (void)update;

@end
