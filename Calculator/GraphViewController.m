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
@property (weak, nonatomic) IBOutlet UILabel *equationDisplay;
@end

@implementation GraphViewController
@synthesize equationDisplay = _formulaDisplay;

@synthesize graphView = _graphView;
@synthesize program = _program;

- (void)setProgram:(id)program
{
    _program = program;
    
    // Now print the formula we are plotting
    // If there is a comma, only show the text after the rightmost command
    NSArray *listPrograms = [[CalculatorBrain descriptionOfProgram:_program] componentsSeparatedByString:@","];
    
    self.equationDisplay.text = [NSString stringWithFormat:@"y = %@",[listPrograms lastObject]];
    
    [self.graphView setNeedsDisplay]; // redraw the graph if the program changes
}

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
    // If there is a comma, only show the text after the rightmost command
    NSArray *listPrograms = [[CalculatorBrain descriptionOfProgram:_program] componentsSeparatedByString:@","];
    
    self.equationDisplay.text = [NSString stringWithFormat:@"y = %@",[listPrograms lastObject]];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (id) getYInPixelsForX:(CGFloat)xVal forView:(GraphView *)sender
{
    NSDictionary *xvalDict;
    id calcResult;
    
    xvalDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:xVal] forKey:@"x"];
    
    calcResult = [CalculatorBrain runProgram:self.program usingVariableValues:xvalDict]; // fix this to allow for string value (i.e. error) return
    if ([calcResult isKindOfClass:[NSNumber class]]){
        return([NSNumber numberWithFloat: [calcResult floatValue]]);
    } else {
        return @"Error"; // When the caller receives a string, it will know there is an error in the value calculation
    }
}

- (void)viewDidUnload {
    [self setEquationDisplay:nil];
    [super viewDidUnload];
}
@end
