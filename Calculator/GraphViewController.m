//
//  GraphViewController.m
//  Calculator
//
//  Created by Sanjaya Kumar on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GraphViewController.h"
#import "GraphView.h"
#import "CalculatorBrain.h"
#import "AxesDrawer.h"

@interface GraphViewController () <GraphViewDataSource>
@property (nonatomic, weak) IBOutlet GraphView *graphView;
@property (weak, nonatomic) IBOutlet UILabel *formulaDisplay;
@end

@implementation GraphViewController
@synthesize formulaDisplay = _formulaDisplay;

@synthesize graphView = _graphView;
@synthesize program = _program;

- (void)setGraphView:(GraphView *)graphView
{
    _graphView = graphView;
    
    // enable pinch gestures in the FaceView using its pinch: handler
    [self.graphView addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self.graphView action:@selector(pinch:)]];
    
    // enable triple taps to allow the user to specify origin
    UITapGestureRecognizer *tripleTap = [UITapGestureRecognizer alloc];
    [self.graphView addGestureRecognizer:[tripleTap initWithTarget:self.graphView action:@selector(tripleTapHandler:)]];
    tripleTap.numberOfTapsRequired = 3;
    
    // enable panning
    [self.graphView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self.graphView action:@selector(panHandler:)]];
    
    self.graphView.dataSource = self;
    // Now print the formula we are plotting
    self.formulaDisplay.text = [CalculatorBrain descriptionOfProgram:self.program];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (CGFloat) getYInPixelsForX:(CGFloat)xVal forView:(GraphView *)sender
{
    NSDictionary *xvalDict;
    CGFloat trueX, trueY;
    id calcResult;
    CGPoint formulaLocation;
    
    formulaLocation.x = 10;
    formulaLocation.y = 10;
    
    trueX = (xVal - sender.graphOrigin.x)/sender.graphScale;
    
    xvalDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:trueX] forKey:@"x"];
    
    
    calcResult = [CalculatorBrain runProgram:self.program usingVariableValues:xvalDict]; // fix this to allow for string value (i.e. error) return
    if ([calcResult isKindOfClass:[NSNumber class]]){
        trueY = [calcResult floatValue];
        return(sender.graphOrigin.y - (trueY*sender.graphScale));
    } else {
        return 0; // revisit this later
    }
}

- (void)viewDidUnload {
    [self setFormulaDisplay:nil];
    [super viewDidUnload];
}
@end
