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
#import "SplitViewBarButtonItemPresenter.h"

@interface GraphViewController () <GraphViewDataSource, SplitViewBarButtonItemPresenter>
@property (nonatomic, weak) IBOutlet GraphView *graphView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationbar;
@property (weak, nonatomic) IBOutlet UILabel *toolbarTitle;
@end

@implementation GraphViewController

@synthesize graphView = _graphView;
@synthesize program = _program;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize toolbar = _toolbar;
@synthesize navigationbar = _navigationbar;
@synthesize toolbarTitle = _toolbarTitle;
@synthesize drawUsingDots = _drawUsingDots;

- (void) setDrawUsingDots:(BOOL)drawUsingDots
{
    _drawUsingDots = drawUsingDots;
    self.graphView.drawUsingDots = drawUsingDots;
}

- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem
{
    if (_splitViewBarButtonItem != splitViewBarButtonItem){
        NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
        if (_splitViewBarButtonItem) [toolbarItems removeObject:_splitViewBarButtonItem];
        if (splitViewBarButtonItem) [toolbarItems insertObject:splitViewBarButtonItem atIndex:0];
        self.toolbar.items = toolbarItems;
        _splitViewBarButtonItem = splitViewBarButtonItem;
    }
}

- (void) printEquationInGraph
{
    NSString * equation;
    // Now print the formula we are plotting
    // If there is a comma, only show the text after the rightmost command
    NSArray *listPrograms = [[CalculatorBrain descriptionOfProgram:_program] componentsSeparatedByString:@","];
    
    if (![[listPrograms lastObject] isEqualToString:@""]){
        equation = [NSString stringWithFormat:@"y = %@",[listPrograms lastObject]];
    } else {
        equation = nil;
    }
    
    if (self.toolbar) {
        self.toolbarTitle.text = equation;
    } else {
        self.navigationbar.title = equation;
    }
}

- (void)setProgram:(id)program
{
    _program = program;
    
    [self printEquationInGraph];
    
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
    self.graphView.drawUsingDots = self.drawUsingDots;
    
    [self printEquationInGraph];
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

- (void)awakeFromNib {
    [super awakeFromNib];
    // default value of slider is on
    self.drawUsingDots = YES;
  }
- (IBAction)drawGraphUsingDots:(UISwitch *)sender {
    self.drawUsingDots = sender.on;
    NSLog(@"switch");
}

- (void)viewDidUnload {
    [self setNavigationbar:nil];
    [self setToolbarTitle:nil];
    [super viewDidUnload];
}
@end
