//
//  ViewController.m
//  pacman-objectivec
//
//  Created by hahasouliu on 10/14/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//

#import "ViewController.h"
#import "MapSprite.h"
#import "BaseSprite.h"

@interface ViewController ()
@property (assign) float screenWidth;
@property (assign) float screenHeight;
@property (assign) float timeSinceLastSpawn;
@property (assign) bool isTouchStart;
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, strong) GLKBaseEffect * mapEffect;
@property (nonatomic, strong) BaseSprite *pacmanSprite;
@property (nonatomic, strong) MapSprite * mapSprite;
@property (strong) NSMutableArray * children;
@property (assign) CGPoint touchStartPoint;
@property (assign) CGPoint touchEndPoint;
@end

@implementation ViewController {
    GLuint _vertextBufferId;
}

@synthesize context = _context;
@synthesize children = _children;
@synthesize timeSinceLastSpawn = _timeSinceLastSpawn;
@synthesize isTouchStart = _isTouchStart;
@synthesize touchStartPoint = _touchStartPoint;
@synthesize touchEndPoint = _touchEndPoint;

- (void)viewDidLoad {
    // Do any additional setup after loading the view, typically from a nib.
    
    [super viewDidLoad];
    
    self.screenWidth = [[UIScreen mainScreen] bounds].size.width;
    self.screenHeight = [[UIScreen mainScreen] bounds].size.height;
    NSLog(@"Screen size [%f, %f]", self.screenWidth, self.screenHeight);
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    // init effect
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, self.screenWidth, 0, self.screenHeight, -1024, 1024);
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.transform.projectionMatrix = projectionMatrix;
    
    // init children array
    self.children = [NSMutableArray array];
    
    // setup pacman
    self.pacmanSprite = [[BaseSprite alloc] initWithFile:@"pacman-2.png" effect:self.baseEffect];
    [self.pacmanSprite setMoveBoundary:self.screenWidth boundaryY:self.screenHeight];


    // setup map
    GLKMatrix4 projectionMatrixForMap = GLKMatrix4MakeOrtho(0, 320, 0, 568, -1024, 1024);
    self.mapEffect = [[GLKBaseEffect alloc] init];
    self.mapEffect.transform.projectionMatrix = projectionMatrixForMap;
    self.mapSprite = [[MapSprite alloc] initWithFile:@"map-1.png" effect:self.mapEffect];
    
    // gesture recognize
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    // init touch
    self.isTouchStart = false;
    
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.touchStartPoint = [[touches anyObject] locationInView:self.view];
    NSLog(@"touchesBegan [%f, %f]", self.touchStartPoint.x, self.touchStartPoint.y);
    self.isTouchStart = true;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //CGPoint touchMovingPoint = [[touches anyObject] locationInView:self.view];
    //NSLog(@"touchesMoved [%f, %f]", touchMovingPoint.x, touchMovingPoint.y);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.touchEndPoint = [[touches anyObject] locationInView:self.view];
    NSLog(@"touchesEnded [%f, %f]", self.touchEndPoint.x, self.touchEndPoint.y);
    
    if (self.isTouchStart) {
        self.isTouchStart = false;
        [self calculateMotion];
    }
}

- (void) calculateMotion {
    int motionX = self.touchEndPoint.x - self.touchStartPoint.x;
    int motionY = self.touchStartPoint.y - self.touchEndPoint.y; // reverse Y axis
    
    if ((abs(motionX) * 3) < abs(motionY)) {
        NSLog(@"Y motion");
        if (motionY > 0) {
            self.pacmanSprite.moveVelocity = GLKVector2Make(0, 10);
        } else {
            self.pacmanSprite.moveVelocity = GLKVector2Make(0 ,-10);
        }
    } else if ((abs(motionY) * 3) < abs(motionX)) {
        NSLog(@"X motion");
        if (motionX > 0) {
            self.pacmanSprite.moveVelocity = GLKVector2Make(10, 0);
        } else {
            self.pacmanSprite.moveVelocity = GLKVector2Make(-10, 0);
        }
    }
}


/*
 - (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
 CGPoint touchPoint = [[touches anyObject] locationView:self.view];
 }*/

- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer {
    
    // 1
    CGPoint touchLocation = [recognizer locationInView:recognizer.view];
    touchLocation = CGPointMake(touchLocation.x, self.screenHeight - touchLocation.y);
    NSLog(@"handleTapFrom [%f, %f]", touchLocation.x, touchLocation.y);
}

- (void)addGhost {
    BaseSprite * ghost = [[BaseSprite alloc] initWithFile:@"red-ghost-1.png" effect:self.baseEffect];
    [self.children addObject:ghost];
    
    int minY = 0;
    int maxY = self.screenHeight - ghost.contentSize.height/4;
    //NSLog(@"ghost x %f", ghost.contentSize.width/4);
    //NSLog(@"ghost y [%d, %d]", minY, maxY);
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    
    ghost.position = GLKVector2Make(320, actualY);
    
    int minVelocity = self.screenWidth/20;
    int maxVelocity = self.screenWidth/10;
    int rangeVelocity = maxVelocity - minVelocity;
    int actualVelocity = (arc4random() % rangeVelocity) + minVelocity;
    
    ghost.moveVelocity = GLKVector2Make(-actualVelocity, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //NSLog(@"drawInRect %@", view);
    glClearColor(0, 0.9, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    [self.mapSprite render];
    [self.pacmanSprite render];
    for (BaseSprite * sprite in self.children) {
        [sprite render];
    }
}

- (void)update {
    //NSLog(@"TimeSinceLastUpdate %f", self.timeSinceLastUpdate);
    [self.pacmanSprite update];
    
    self.timeSinceLastSpawn += self.timeSinceLastUpdate;
    if (self.timeSinceLastSpawn > 1.0) {
        self.timeSinceLastSpawn = 0;
        [self addGhost];
    }
    
    for (BaseSprite * sprite in self.children) {
        [sprite update];
    }
}

@end
