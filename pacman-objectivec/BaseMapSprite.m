//
//  BaseMapSprite.m
//  pacman-objectivec
//
//  Created by hahasouliu on 10/21/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//


#import "BaseMapSprite.h"

#define SQUARE_WIDTH 10.0f
#define SQUARE_HEIGHT 50.0f

typedef struct {
    GLKVector3 positionCoordinates;
    GLKVector2 textureCoordinates;
} VertexData;

@interface BaseMapSprite()

@property (nonatomic, weak) GLKBaseEffect *baseEffect;
@property (assign) float width;
@property (assign) float height;

@end



@implementation BaseMapSprite {
    GLuint _vertextBufferId;
    VertexData *_baseMapVertices;
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
        
    }
    return self;
}

- (void) setSize:(float)width height:(float)height {
    _baseMapVertices = malloc(sizeof(VertexData) * 6);
    _baseMapVertices[0].positionCoordinates = GLKVector3Make((-1)*width/2, (-1)*height/2, 0.0f);
    _baseMapVertices[0].textureCoordinates = GLKVector2Make(0.0f, 0.0f);
    _baseMapVertices[1].positionCoordinates = GLKVector3Make(width/2, (-1)*height/2, 0.0f);
    _baseMapVertices[1].textureCoordinates = GLKVector2Make(1.0f, 0.0f);
    _baseMapVertices[2].positionCoordinates = GLKVector3Make((-1)*width/2, height/2, 0.0f);
    _baseMapVertices[2].textureCoordinates = GLKVector2Make(0.0f, 1.0f);
    _baseMapVertices[3].positionCoordinates = GLKVector3Make((-1)*width/2, height/2, 0.0f);
    _baseMapVertices[3].textureCoordinates = GLKVector2Make(0.0f, 1.0f);
    _baseMapVertices[4].positionCoordinates = GLKVector3Make(width/2, (-1)*height/2, 0.0f);
    _baseMapVertices[4].textureCoordinates = GLKVector2Make(1.0f, 0.0f);
    _baseMapVertices[5].positionCoordinates = GLKVector3Make(width/2, height/2, 0.0f);
    _baseMapVertices[5].textureCoordinates = GLKVector2Make(1.0f, 1.0f);
    self.width = width;
    self.height = height;
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
    glBufferData(GL_ARRAY_BUFFER, sizeof(VertexData) * 6, _baseMapVertices, GL_STATIC_DRAW);
    
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
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.width/2, self.height/2, 0);
    return modelMatrix;
}

- (float) getWidth {
    return self.width;
}

- (float) getHeight {
    return self.height;
}


@end

