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
@end

@implementation GraphView

@synthesize graphScale = _graphScale;
@synthesize graphOrigin = _graphOrigin;
@synthesize userHasSelectedOrigin = _userHasSelectedOrigin;

#define DEFAULT_SCALE 5 // points per Unit CHECK THIS!

- (CGFloat)graphScale
{
    if (!_graphScale) {
        return DEFAULT_SCALE; // don't allow zero scale
    } else {
        return _graphScale;
    }
}

- (void)setGraphScale:(CGFloat)graphScale
{
    if (graphScale != _graphScale) {
        _graphScale = graphScale;
        [self setNeedsDisplay]; // any time our scale changes, call for redraw
    }
}

- (CGPoint)graphOrigin {
    if (!self.userHasSelectedOrigin){
        _graphOrigin.x = self.bounds.origin.x + self.bounds.size.width/2;
        _graphOrigin.y = self.bounds.origin.y + self.bounds.size.height/2;
    }
    return _graphOrigin;
}

- (void) setGraphOrigin:(CGPoint)graphOrigin
{
    if (_graphOrigin.x != graphOrigin.x || _graphOrigin.y != graphOrigin.y){
        _graphOrigin = graphOrigin;
        [self setNeedsDisplay];
    }
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        self.graphScale *= gesture.scale; // adjust our scale
        gesture.scale = 1;           // reset gestures scale to 1 (so future changes are incremental, not cumulative)
    }
}

- (void)tripleTapHandler: (UITapGestureRecognizer *) taps
{
    if (taps.state == UIGestureRecognizerStateEnded){
        CGPoint tapLocation;
        tapLocation = [taps locationInView:self];
        self.userHasSelectedOrigin = YES;
        self.graphOrigin = tapLocation;
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


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    NSLog(@"entered graphView drawRect");
    
    //CGRect graphBounds;
    CGPoint midPoint;
    CGFloat graphScale;
    
    /*graphBounds.origin.x = 10;
    graphBounds.origin.y = 10;
    graphBounds.size.width = 50;
    graphBounds.size.height = 100;*/
    
    midPoint = self.graphOrigin;
    graphScale = self.graphScale;
    
    [AxesDrawer drawAxesInRect: self.bounds originAtPoint:midPoint scale:graphScale];
    NSLog(@"Done with graphView drawRect");
}


@end