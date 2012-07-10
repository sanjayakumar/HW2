//
//  CalculatorViewController.m
//  Calculator
//
//  Created by Sanjaya Kumar on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CalculatorViewController.h"
#import "CalculatorBrain.h"

@interface CalculatorViewController()
@property (nonatomic) BOOL userIsInTheMiddleOfEnteringANumber;
@property (nonatomic, strong) CalculatorBrain *brain;
@property (nonatomic, strong) NSDictionary *testVariableValues;
@property (nonatomic, strong) NSDictionary *testDict1;
@property (nonatomic, strong) NSDictionary *testDict2;
- (void) updateUserActionDisplay:(NSString *)dispString;
@end

#define MAX_USER_ACTION_DISPLAY_LENGTH 40 // max number of characters in the top strip of the calculator

@implementation CalculatorViewController


@synthesize display = _display;
@synthesize userActionDisplay = _userActionDisplay;
@synthesize testVarValuesDisplay = _testVarValuesDisplay;
@synthesize userIsInTheMiddleOfEnteringANumber = _userIsInTheMiddleOfEnteringANumber;
@synthesize brain = _brain;
@synthesize testVariableValues = _testVariableValues;
@synthesize testDict1 = _testDict1;
@synthesize testDict2 = _testDict2;

- (CalculatorBrain *)brain
{
    if (!_brain) _brain = [[CalculatorBrain alloc] init];
    return _brain;
}

- (NSDictionary *)testDict1
{
    if (!_testDict1) _testDict1 = [NSDictionary dictionaryWithObjectsAndKeys: 
                                   [NSNumber numberWithDouble:5],   @"x", 
                                   [NSNumber numberWithDouble:4.8], @"a", 
                                   [NSNumber numberWithDouble:0],   @"b", 
                                   nil];
    return _testDict1;
}

- (NSDictionary *)testDict2
{
    if (!_testDict2) _testDict2 = [NSDictionary dictionaryWithObjectsAndKeys: 
                                   [NSNumber numberWithDouble:-10],   @"x", 
                                   [NSNumber numberWithDouble:15.8],  @"a", 
                                   [NSNumber numberWithDouble:0],     @"b", 
                                   nil];
    return _testDict2;
}


- (void) updateUserActionDisplay: (NSString *)dispString {
    NSString *userDispText = dispString;
    NSUInteger userActionDisplayLength = [userDispText length];
    
    if (userActionDisplayLength >= MAX_USER_ACTION_DISPLAY_LENGTH){
        userDispText = [userDispText substringWithRange:NSMakeRange(userActionDisplayLength - MAX_USER_ACTION_DISPLAY_LENGTH, MAX_USER_ACTION_DISPLAY_LENGTH)];
    }
    self.userActionDisplay.text = userDispText;
}

- (void) updateTestVarValuesDisplay {
    NSEnumerator *enumerator = [self.testVariableValues keyEnumerator];
    id key;
    NSNumber *varValue;
    NSString *varValsStr = @"";
    
    while ((key = [enumerator nextObject])) {
        /* code that uses the returned key */
        varValue = [self.testVariableValues objectForKey:key];
        varValsStr = [NSString stringWithFormat:@"%@ %@ = %@,", varValsStr, key, [varValue stringValue]];
    }
    // Remove the last comma
    if ([varValsStr length] > 0){
        varValsStr = [varValsStr substringWithRange:NSMakeRange(0, [varValsStr length]-1)];
    }
    self.testVarValuesDisplay.text = varValsStr;
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
    resultPtr = [[CalculatorBrain class] runProgram:self.brain.program usingVariableValues:self.testVariableValues];
    
    if ([resultPtr isKindOfClass:[NSNumber class]]){
        self.display.text= [resultPtr stringValue];
    }
    else {
        self.display.text = resultPtr;
    }
    
    [self updateUserActionDisplay: [[CalculatorBrain class] descriptionOfProgram:self.brain.program]];
    
}

- (IBAction)operationPressed:(id)sender {
    NSString *operation = [sender currentTitle];
    id resultPtr;
    
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self enterPressed];
    }
    resultPtr = [self.brain performOperation:operation usingVariableValues:self.testVariableValues];
    if ([resultPtr isKindOfClass:[NSNumber class]]){
        self.display.text= [resultPtr stringValue];
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
    [self setTestVarValuesDisplay:nil];
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

- (IBAction)testButtonPressed:(UIButton *)sender {
    id resultPtr;
    NSString *testKeyName = [sender currentTitle];
    if ([testKeyName isEqualToString: @"Test1"]){
        self.testVariableValues = self.testDict1;
    } else if ([testKeyName isEqualToString: @"Test2"]){
        self.testVariableValues = self.testDict2;
    } else if ([testKeyName isEqualToString: @"Test3"]){
        self.testVariableValues = nil;
    }
    [self updateTestVarValuesDisplay];
    
    resultPtr = [[CalculatorBrain class] runProgram:self.brain.program usingVariableValues:self.testVariableValues];
    if ([resultPtr isKindOfClass:[NSNumber class]]){
        self.display.text= [resultPtr stringValue];
    }
    else {
        self.display.text = resultPtr;
    }
    
    // note: no need to update descriptionOfProgram since the program itself hasn't changed
}
@end