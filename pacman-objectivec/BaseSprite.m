//
//  BaseSprite.m
//  pacman-objectivec
//
//  Created by hahasouliu on 10/14/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//


#import "BaseSprite.h"

#define SQUARE_SIZE 30.0f

typedef struct {
    GLKVector3 positionCoordinates;
    GLKVector2 textureCoordinates;
} VertexData;

VertexData SpriteVertices[] = {
    {{-SQUARE_SIZE/2, -SQUARE_SIZE/2, 0.0f}, {0.0f, 0.0f}},
    {{SQUARE_SIZE/2, -SQUARE_SIZE/2, 0.0f}, {1.0f, 0.0f}},
    {{-SQUARE_SIZE/2, SQUARE_SIZE/2, 0.0f}, {0.0f, 1.0f}},
    {{-SQUARE_SIZE/2, SQUARE_SIZE/2, 0.0f}, {0.0f, 1.0f}},
    {{SQUARE_SIZE/2, -SQUARE_SIZE/2, 0.0f}, {1.0f, 0.0f}},
    {{SQUARE_SIZE/2, SQUARE_SIZE/2, 0.0f}, {1.0f, 1.0f}}
};

@interface BaseSprite()

@property (nonatomic, weak) GLKBaseEffect *baseEffect;
@property (assign) float boundayX;
@property (assign) float boundayY;

@end



@implementation BaseSprite {
    GLuint _vertextBufferId;
}

- (id)initWithFile:(NSString *)fileName effect:(GLKBaseEffect *)effect {
    if ((self = [super init])) {
        self.baseEffect = effect;
        NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES],
                                  GLKTextureLoaderOriginBottomLeft,
                                  nil];
        NSError * error;
        NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
        //NSLog(@"path is %@", path);
        
        self.textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
        if (self.textureInfo == nil) {
            NSLog(@"Error loading file: %@", [error localizedDescription]);
            return nil;
        }
        
        self.contentSize = CGSizeMake(self.textureInfo.width, self.textureInfo.height);
        //NSLog(@"initWithFile [%u, %u]", self.textureInfo.width, self.textureInfo.height);
    }
    return self;
}


- (id)initWithEffect:(GLKBaseEffect *)baseEffect {
    if ((self = [super init])) {
        self.baseEffect = baseEffect;
    }
    return self;
}

- (void)render {
    glGenBuffers(1, &_vertextBufferId);
    glBindBuffer(GL_ARRAY_BUFFER, _vertextBufferId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SpriteVertices), SpriteVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(VertexData),
                          (GLvoid *)offsetof(VertexData, positionCoordinates));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(VertexData),
                          (GLvoid *)offsetof(VertexData, textureCoordinates));
    
    self.baseEffect.texture2d0.name = self.textureInfo.name;
    self.baseEffect.texture2d0.target = self.textureInfo.target;
    self.baseEffect.transform.modelviewMatrix = [self caculateModelMatrix];
    
    [self.baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

- (GLKMatrix4) caculateModelMatrix {
    
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.position.x, self.position.y, 0);
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.contentSize.width/2, self.contentSize.height/2, 0);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, GLKMathDegreesToRadians(90.0f), 0, 0, 1);
    //modelMatrix = GLKMatrix4Translate(modelMatrix, -self.contentSize.width/2, -self.contentSize.height/2, 0);
    
    //modelMatrix = GLKMatrix4Scale(modelMatrix, 0.25, 0.25, 0);
    return modelMatrix;
}

- (void)update {
    GLKVector2 curMove = GLKVector2MultiplyScalar(self.moveVelocity, 1);
    
    GLKVector2 updatedPosition = GLKVector2Add(self.position, curMove);
 /*
    NSLog(@"update curMove[%f, %f]", curMove.x, curMove.y);
    NSLog(@"update bounday[%f, %f]", self.boundayX, self.boundayY);
    NSLog(@"update bounday cal [%f, %f]", self.boundayX-(self.contentSize.width), self.boundayY-(self.contentSize.height));
    NSLog(@"update updatedPosition[%f, %f]", updatedPosition.x, updatedPosition.y);
    
    NSLog(@"updatedPosition.x %f", updatedPosition.x);
    NSLog(@"self.contentSize.width %f", self.contentSize.width);
   */
    if (self.boundayX > 0 && self.boundayY > 0) {
        if (updatedPosition.x >= 0 &&
            updatedPosition.x <= self.boundayX-(self.contentSize.width) &&
            updatedPosition.y >= 0 &&
            updatedPosition.y <= self.boundayY-(self.contentSize.height) ) {
            //NSLog(@"update updatePosition");
            self.position = updatedPosition;
        } else {
            //NSLog(@"update remain Position[%f, %f]", self.position.x, self.position.y);
        }
    } else {
        self.position = updatedPosition;
    }
}

- (void)setMoveBoundary:(float)boundaryX boundaryY:(float)boundaryY {
    self.boundayX = boundaryX;
    self.boundayY = boundaryY;
}

@end
