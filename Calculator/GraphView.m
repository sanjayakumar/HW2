//
//  GraphView.m
//  Calculator
//
//  Created by Sanjaya Kumar on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GraphView.h"
#import "AxesDrawer.h"

@interface GraphView()
@property BOOL userHasSelectedOrigin; // triple tap or panning
- (void) drawGraphFromMinX: (CGFloat) xmin toMaxX: (CGFloat) xmax inContext: (CGContextRef) context;
@end

@implementation GraphView

@synthesize dataSource = _dataSource;

@synthesize graphScale = _graphScale;
@synthesize graphOrigin = _graphOrigin;
@synthesize userHasSelectedOrigin = _userHasSelectedOrigin;
@synthesize drawUsingDots = _drawUsingDots;

#define DEFAULT_SCALE 5 // points per Unit CHECK THIS!

/* Saving and getting User Preferences */

// Performace issues: It turns out pinch and pan become slow if we set the user preferences
// in the setter. On the other hand, accessing the values in the getter is not too bad since
// it is only accessed if the run time value has not been initialized.
// So to summarize: It's ok to READ NSUserDefaults in getter, but DO NOT WRITE to NSUserDefaults
// in the setter.

- (CGFloat) graphScale
{
    // if the runtime value is 0, then it means it hasn't been set; get it from User Defaults
    if (!_graphScale){
        _graphScale = [[NSUserDefaults standardUserDefaults] floatForKey:@"graphScale"];
        if (!_graphScale){ // If it is STILL zero, meaning user has never set it, return default value
            _graphScale = DEFAULT_SCALE;
        }
    } 
    return _graphScale;
}

- (void)setGraphScale:(CGFloat)graphScale
{
    if (graphScale != _graphScale) {
        _graphScale = graphScale;
        [self setNeedsDisplay]; // any time our scale changes, call for redraw
    }
}

- (void)writeScaleToUserDefaults
{
    [[NSUserDefaults standardUserDefaults] setFloat:self.graphScale forKey:@"graphScale"];
}

- (CGPoint) graphOrigin
{
    if (self.userHasSelectedOrigin){
        return _graphOrigin;
    }
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    if ([userDef boolForKey:@"userHasSetOrigin"]){ // cannot rely on 0 return of x and y to mean it hasn't been set
        _graphOrigin.x = [userDef floatForKey:@"graphOriginX"];
        _graphOrigin.y = [userDef floatForKey:@"graphOriginY"];
    } else {
        _graphOrigin.x = self.bounds.origin.x + self.bounds.size.width/2;
        _graphOrigin.y = self.bounds.origin.y + self.bounds.size.height/2;
    }
    self.userHasSelectedOrigin = YES;
    return _graphOrigin;
}

- (void) setGraphOrigin:(CGPoint)graphOrigin
{
    if (_graphOrigin.x != graphOrigin.x || _graphOrigin.y != graphOrigin.y){
        _graphOrigin = graphOrigin;
        self.userHasSelectedOrigin = YES;
        [self setNeedsDisplay];
    }
}

- (void)writeOriginToUserDefaults
{
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setFloat:self.graphOrigin.x forKey:@"graphOriginX"];
    [userDef setFloat:self.graphOrigin.y forKey:@"graphOriginY"];
    [userDef setBool:TRUE forKey:@"userHasSetOrigin"];
}

- (void) setDrawUsingDots:(BOOL)drawUsingDots
{
    if (_drawUsingDots != drawUsingDots){
        _drawUsingDots = drawUsingDots;
        [self setNeedsDisplay];
    }
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        self.graphScale *= gesture.scale; // adjust our scale
        gesture.scale = 1;           // reset gestures scale to 1 (so future changes are incremental, not cumulative)
        
        if (gesture.state == UIGestureRecognizerStateEnded){
            [self writeScaleToUserDefaults];
        }
    }
}

- (void)tripleTapHandler: (UITapGestureRecognizer *) taps
{
    if (taps.state == UIGestureRecognizerStateEnded){
        CGPoint tapLocation;
        tapLocation = [taps locationInView:self];
        self.userHasSelectedOrigin = YES;
        self.graphOrigin = tapLocation;
        [self writeOriginToUserDefaults];
    }
}

- (void)panHandler:(UIPanGestureRecognizer *)pan
{
    if ((pan.state == UIGestureRecognizerStateChanged) ||
         (pan.state == UIGestureRecognizerStateEnded)){
        CGPoint translationAmount = [pan translationInView:self];
        self.userHasSelectedOrigin = YES; // both panning and triple tapping change the origin
        CGPoint newOrigin;
        CGPoint zeroTrans;
        zeroTrans.x = 0;
        zeroTrans.y = 0;
        newOrigin.x = self.graphOrigin.x + translationAmount.x;
        newOrigin.y = self.graphOrigin.y + translationAmount.y;
        
        [pan setTranslation:zeroTrans inView:self];
        
        self.graphOrigin = newOrigin;
        
        if (pan.state == UIGestureRecognizerStateEnded){
            [self writeOriginToUserDefaults];
        }
    }
}

- (void)setup
{
    self.contentMode = UIViewContentModeRedraw;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) awakeFromNib
{
    [self setup]; // get initialized when we come out of a storyboard
}

- (void) drawGraphFromMinX: (CGFloat) xmin toMaxX: (CGFloat) xmax inContext: (CGContextRef) context;
{
    CGFloat x, y;
    id yObjPtr;
    BOOL previousPointValid = NO;
    
    UIGraphicsPushContext(context);
    CGContextBeginPath(context);
    [[UIColor blueColor] setStroke];
    [[UIColor blueColor] setFill];
    
    if (!self.drawUsingDots){
        x = xmin;
        yObjPtr = [self.dataSource getYInPixelsForX:(x - self.graphOrigin.x)/self.graphScale forView:self];
        if ([yObjPtr isKindOfClass:[NSNumber class]]){
            y = self.graphOrigin.y - ([yObjPtr floatValue]*self.graphScale);
            previousPointValid = YES;
            CGContextMoveToPoint(context, x, y);
        }
    }
    
    for (x = xmin; x <= xmax; x += 1.0/self.contentScaleFactor){
        yObjPtr = [self.dataSource getYInPixelsForX:(x - self.graphOrigin.x)/self.graphScale forView:self];
        if ([yObjPtr isKindOfClass:[NSNumber class]]){
            y = self.graphOrigin.y - ([yObjPtr floatValue]*self.graphScale);
            if (self.drawUsingDots) {
                CGRect rect = CGRectMake(x, y, 1.0/self.contentScaleFactor, 1.0/self.contentScaleFactor);
                CGContextFillRect(context, rect);   
            } else {
                if (previousPointValid){
                    CGContextAddLineToPoint(context, x, y);
                } else {
                    CGContextMoveToPoint(context, x, y);
                    previousPointValid = YES;
                }
            }
        } else {
            previousPointValid = NO;
        }
    }
    CGContextStrokePath(context);
    UIGraphicsPopContext();
}


- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint midPoint;
    CGFloat graphScale;
    
    midPoint = self.graphOrigin;
    graphScale = self.graphScale;
    
    [AxesDrawer drawAxesInRect: self.bounds originAtPoint:midPoint scale:graphScale];
    
    [self drawGraphFromMinX:0 toMaxX:self.bounds.size.width inContext:context];
}


@end
