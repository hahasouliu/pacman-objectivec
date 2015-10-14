//
//  MapSprite.h
//  pacman-objectivec
//
//  Created by hahasouliu on 10/14/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface MapSprite : NSObject

@property (nonatomic, strong) GLKTextureInfo *textureInfo;
@property (assign) CGSize contentSize;
//@property (assign) GLKVector2 position;

- (id)initWithFile:(NSString *)fileName effect:(GLKBaseEffect *)effect;
- (void)render;

@end