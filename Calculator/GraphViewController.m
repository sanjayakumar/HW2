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
#import "CalculatorProgramsTableViewController.h"

@interface GraphViewController () <GraphViewDataSource, SplitViewBarButtonItemPresenter, CalculatorProgramsTableViewControllerDelegate>
@property (nonatomic, weak) IBOutlet GraphView *graphView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationbar;
@property (weak, nonatomic) IBOutlet UILabel *toolbarTitle;
@property (strong, nonatomic) NSMutableDictionary *yValueCache;
@property BOOL cacheEnabled;
@property (nonatomic, strong) UIPopoverController *popoverController;
@end

@implementation GraphViewController

@synthesize graphView = _graphView;
@synthesize program = _program;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize toolbar = _toolbar;
@synthesize navigationbar = _navigationbar;
@synthesize toolbarTitle = _toolbarTitle;
@synthesize drawUsingDots = _drawUsingDots;
@synthesize yValueCache = _yValueCache;
@synthesize cacheEnabled = _cacheEnabled;
@synthesize popoverController;

#define MAX_DICT_ENTRIES 2000  // since dictionary is a cache, we limit the size. Move to zero size if it reaches MAX. 
                               // we don't have the keys, so it goes directly from 50,000 to zero!

- (NSMutableDictionary *) yValueCache
{
    if (!_yValueCache)_yValueCache = [[NSMutableDictionary alloc]init];
    return(_yValueCache);
}

- (void) setDrawUsingDots:(BOOL)drawUsingDots
{
    _drawUsingDots = drawUsingDots;
    self.graphView.drawUsingDots = drawUsingDots;
    //NSLog(@"total: %i hits:%i DictSize: %i", num_requests, num_hits, [self.yValueCache count]);
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
        // What is this below? A way to dynamically adjust font size to fit (from StackOverflow)!
        UILabel* tlabel=[[UILabel alloc]initWithFrame:CGRectMake(0,0, 400, 40)];
        tlabel.textAlignment = UITextAlignmentRight;
        tlabel.text=self.navigationItem.title;
        tlabel.textColor=[UIColor whiteColor];
        tlabel.backgroundColor =[UIColor clearColor];
        tlabel.adjustsFontSizeToFitWidth=YES;
        self.navigationItem.titleView=tlabel;
    }
}

- (void)setProgram:(id)program
{
    _program = program;
    
    self.yValueCache = nil; // Of course, if the equation changes, we must invalidate the cache!
    self.cacheEnabled = YES;
    
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
static int num_requests = 0;
static int num_hits = 0;

- (id) getYInPixelsForX:(CGFloat)xVal forView:(GraphView *)sender
{
    NSDictionary *xvalDict;
    id calcResult;
    
    num_requests++;
    
    NSNumber *xptr = [NSNumber numberWithFloat:xVal];
    if (self.cacheEnabled && (calcResult = [self.yValueCache objectForKey:xptr])){ // cache enabled and hit
        num_hits++;
    } else {
        // since runProgram takes up lot of CPU, only run it if there is a cache miss
        xvalDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:xVal] forKey:@"x"];
        calcResult = [CalculatorBrain runProgram:self.program usingVariableValues:xvalDict];
        
        if (self.cacheEnabled){
            [self.yValueCache setObject:calcResult forKey:xptr];
            // We can't let the cache grow for ever! so delete it if it reaches a limit
            if ([self.yValueCache count] > MAX_DICT_ENTRIES)self.yValueCache = nil;
        }
    }
    return calcResult;
}

- (void) enableCache:(GraphView *)sender
{
    self.cacheEnabled = YES;
}

- (void) disableCache:(GraphView *)sender
{
    self.cacheEnabled = NO;
    self.yValueCache = nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // default value of slider is on
    self.drawUsingDots = YES;
  }
- (IBAction)drawGraphUsingDots:(UISwitch *)sender {
    self.drawUsingDots = sender.on;
}

- (void)viewDidUnload {
    [self setNavigationbar:nil];
    [self setToolbarTitle:nil];
    [super viewDidUnload];
}
#define FAVORITES_KEY @"CalculatorGraphViewController.Favorites"

- (IBAction)addToFavorites:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *favorites = [[defaults objectForKey:FAVORITES_KEY] mutableCopy];
    if (!favorites) favorites = [NSMutableArray array];
    [favorites addObject:self.program];
    [defaults setObject:favorites forKey:FAVORITES_KEY];
    [defaults synchronize];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Favorite Graphs"]) {
        // this if statement added after lecture to prevent multiple popovers
        // appearing if the user keeps touching the Favorites button over and over
        // simply remove the last one we put up each time we segue to a new one
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            [self.popoverController dismissPopoverAnimated:YES];
            self.popoverController = popoverSegue.popoverController; // might want to be popover's delegate and self.popoverController = nil on dismiss?
        }
        NSArray *programs = [[NSUserDefaults standardUserDefaults] objectForKey:FAVORITES_KEY];
        [segue.destinationViewController setPrograms:programs];
        [segue.destinationViewController setDelegate:self];
    }
}

- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender
                                 choseProgram:(id)program
{
    self.program = program;
    // if you wanted to close the popover when a graph was selected
    // you could uncomment the following line
    // you'd probably want to set self.popoverController = nil after doing so
    // [self.popoverController dismissPopoverAnimated:YES];
    [self.navigationController popViewControllerAnimated:YES]; // added after lecture to support iPhone
}

// added after lecture to support deletion from the table
// deletes the given program from NSUserDefaults (including duplicates)
// then resets the Model of the sender

- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender
                               deletedProgram:(id)program
{
    NSString *deletedProgramDescription = [CalculatorBrain descriptionOfProgram:program];
    NSMutableArray *favorites = [NSMutableArray array];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (id program in [defaults objectForKey:FAVORITES_KEY]) {
        if (![[CalculatorBrain descriptionOfProgram:program] isEqualToString:deletedProgramDescription]) {
            [favorites addObject:program];
        }
    }
    [defaults setObject:favorites forKey:FAVORITES_KEY];
    [defaults synchronize];
    sender.programs = favorites;
}

@end
