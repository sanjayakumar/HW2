//
//  CalculatorViewController.m
//  Calculator
//
//  Created by Sanjaya Kumar on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CalculatorViewController.h"
#import "CalculatorBrain.h"
#import "GraphViewController.h"

@interface CalculatorViewController()
@property (nonatomic) BOOL userIsInTheMiddleOfEnteringANumber;
@property (nonatomic, strong) CalculatorBrain *brain;
- (void) updateUserActionDisplay:(NSString *)dispString;
@end

#define MAX_USER_ACTION_DISPLAY_LENGTH 40 // max number of characters in the top strip of the calculator

@implementation CalculatorViewController


@synthesize display = _display;
@synthesize userActionDisplay = _userActionDisplay;
@synthesize userIsInTheMiddleOfEnteringANumber = _userIsInTheMiddleOfEnteringANumber;
@synthesize brain = _brain;


- (CalculatorBrain *)brain
{
    if (!_brain) _brain = [[CalculatorBrain alloc] init];
    return _brain;
}



- (void) updateUserActionDisplay: (NSString *)dispString {
    NSString *userDispText = dispString;
    NSUInteger userActionDisplayLength = [userDispText length];
    
    if (userActionDisplayLength >= MAX_USER_ACTION_DISPLAY_LENGTH){
        userDispText = [userDispText substringWithRange:NSMakeRange(userActionDisplayLength - MAX_USER_ACTION_DISPLAY_LENGTH, MAX_USER_ACTION_DISPLAY_LENGTH)];
    }
    self.userActionDisplay.text = userDispText;
}


- (IBAction)digitPressed:(UIButton *)sender {
    NSString *digit = sender.currentTitle;
    if (self.userIsInTheMiddleOfEnteringANumber) {
        if ([self.display.text isEqualToString:@"0"]){
            if ([digit isEqualToString:@"0"]){
                return;
            } else {
                self.display.text = digit;
                return;
            }
        }
        if ([digit isEqualToString:@"0"] && [self.display.text isEqualToString:@"0"]) return; //ignore leading zeros
        self.display.text = [self.display.text stringByAppendingString:digit];
    } else {
        self.display.text = digit;
        /* If the user presses 0 in the begining, we simply ignore it, i.e. act like the user hasn't started to type a number */
        //if ([digit isEqualToString:@"0"]){
        //    return;
        //}
        self.userIsInTheMiddleOfEnteringANumber = YES;
    }
}

- (IBAction)enterPressed {
    id resultPtr;
    [self.brain pushOperand:[self.display.text doubleValue]];
    self.userIsInTheMiddleOfEnteringANumber = NO;
    resultPtr = [[CalculatorBrain class] runProgram:self.brain.program usingVariableValues:nil]; // review later to see if nil is the right parameter
    
    if ([resultPtr isKindOfClass:[NSNumber class]]){
        self.display.text= [NSString stringWithFormat:@"%g",[resultPtr doubleValue]];
    }
    else {
        self.display.text = resultPtr;
    }
    
    [self updateUserActionDisplay: [CalculatorBrain descriptionOfProgram:self.brain.program]];
    
}

- (IBAction)operationPressed:(id)sender {
    NSString *operation = [sender currentTitle];
    id resultPtr;
    
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self enterPressed];
    }
    resultPtr = [self.brain performOperation:operation usingVariableValues:nil]; // revie wlater to see if nil is the right parameter
    if ([resultPtr isKindOfClass:[NSNumber class]]){
        self.display.text= [NSString stringWithFormat:@"%g",[resultPtr doubleValue] ];
    }
    else {
        self.display.text = resultPtr;
    }
    
    [self updateUserActionDisplay: [[CalculatorBrain class] descriptionOfProgram:self.brain.program]];
}

- (IBAction)decimalKeyPressed {
    if (!self.userIsInTheMiddleOfEnteringANumber){
        self.display.text = @"0.";
        self.userIsInTheMiddleOfEnteringANumber = YES;
    } else {
        NSRange isDecimalPresent = [self.display.text rangeOfString:@"."];
        if (isDecimalPresent.location == NSNotFound){
            self.display.text = [self.display.text stringByAppendingString:@"."];
        } // ignore the user-pressed decimal if it is already present
    }        
}

- (IBAction)clearPressed {
    self.display.text = @"0";
    self.userActionDisplay.text = @"";
    self.userIsInTheMiddleOfEnteringANumber = NO;
    [self.brain performClear];
}

- (IBAction)undoPressed:(UIButton *)sender {
    NSUInteger existingStringLength = [self.display.text length];
    // if number is being entered then effectively backspace over digit or decimal
    if (self.userIsInTheMiddleOfEnteringANumber){
        if (existingStringLength == 1) { 
            self.display.text = @"0";
            self.userIsInTheMiddleOfEnteringANumber = NO;
        } else {
            self.display.text = [self.display.text substringToIndex:existingStringLength-1];
        }
    } else {
        // ask brain to pop top of stack
        [self operationPressed:sender];
    }
}

- (void)viewDidUnload {
    [self setUserActionDisplay:nil];
    [super viewDidUnload];
}

- (IBAction)plusMinusPressed:(UIButton *)sender {
    if([self.display.text isEqualToString:@"0"]){
        // like the OS X calculator, ignore +/- if only zero is displayed.
        return;
    }
    if (self.userIsInTheMiddleOfEnteringANumber){
        if ([self.display.text hasPrefix:@"-"]){
            self.display.text = [self.display.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
        } else {
            self.display.text =  [NSString stringWithFormat:@"-%@", self.display.text];
        }
    } else {
        [self operationPressed:sender];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [segue.destinationViewController setProgram:self.brain.program];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (self.splitViewController)
        // on the iPad, we support all orientations
        return YES; 
    else
        // but no landscape on the iPhone, because I'm too lazy to fix the keypad
        return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}
- (IBAction)graphForIpad {
    // confirm ipad
    if (self.splitViewController){
        id detailViewController = [[self.splitViewController viewControllers] lastObject];
        [detailViewController  setProgram:self.brain.program];
    }
}

@end