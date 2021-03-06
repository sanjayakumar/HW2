//
//  CalculatorBrain.m
//  Calculator
//
//  Created by Sanjaya Kumar on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "CalculatorBrain.h"

@interface CalculatorBrain()
@property (nonatomic, strong) NSMutableArray *programStack;
@end

@implementation CalculatorBrain

@synthesize programStack = _programStack;

- (NSMutableArray *)programStack
{
    if (_programStack == nil) _programStack = [[NSMutableArray alloc] init];
    return _programStack;
}

- (id)program
{
    return [self.programStack copy];
}

+ (NSString *)descriptionOfProgram:(id)program
{
    NSMutableArray *stack;
    NSString * programDescription;
    
    if ([program isKindOfClass:[NSArray class]]) {
        stack = [program mutableCopy];
    }                   
    programDescription = [self descriptionOfTopOfStack:stack withParentOperation:@"null"];
    
    // If the stack is not empty, display the other programs as well, seperated by commas
    while([stack count] != 0){
        programDescription = [NSString stringWithFormat:@"%@, %@", [self descriptionOfTopOfStack:stack withParentOperation:@"null"], programDescription];
    }
    return(programDescription);
}


// This function returns priority values based on conventional arithmetic order of operations
+(int) operationPriority: (NSString *)operation
{
    if ([operation isEqualToString:@"/"] || [operation isEqualToString:@"*"]){
        return 2;
    }
    if ([operation isEqualToString:@"-"] || [operation isEqualToString:@"+"]){
        return 1;
    }
    return 0;
}

+(BOOL) operationIsNotCommutative: (NSString *) operation
{
    if ([operation isEqualToString:@"/"]){
        return YES;
    }
    if ([operation isEqualToString:@"-"]){
        return YES;
    }
    return NO;
}

+ (NSString *)descriptionOfTopOfStack:(id)stack withParentOperation: (NSString *) parentOp {
    NSString * descStr = @""; // description string
    NSString * secondOperand;
    
    int currentOperationPriority;
    int parentOperationPriority;
    
    // If the top of the stack is a number, just print that number
    id topOfStack = [stack lastObject];
    
    if (topOfStack) [stack removeLastObject];
    
    if([topOfStack isKindOfClass:[NSNumber class]]){
        descStr = [NSString stringWithFormat:@"%@",[NSString stringWithFormat:@"%g",[topOfStack doubleValue] ]];
    } else if ([topOfStack isKindOfClass:[NSString class]]){
        if (![self isOperation:topOfStack]){
            // if it is a string, but not an operation, then it must be a variable;
            descStr = [NSString stringWithFormat:@"%@",topOfStack];
        } else {
            switch ([self numOperands:topOfStack]) {
                case 0:
                    descStr = [NSString stringWithFormat:@"%@", topOfStack];
                    break;
                case 1:
                    descStr = [NSString stringWithFormat:@"%@(%@)", topOfStack, [self descriptionOfTopOfStack:stack withParentOperation:topOfStack]];
                    break;
                case 2:
                    currentOperationPriority = [self operationPriority:topOfStack];
                    parentOperationPriority = [self operationPriority:parentOp];
                    
                    secondOperand = [self descriptionOfTopOfStack:stack withParentOperation:topOfStack];
                    
                    // Here's the nifty part: if parent's priority is higher than ours, then we must enclose our operation in
                    // parenthesis, if it is the same, then we need parenthesis only if the parent is a non-commutative operation
                    // if our priority is higher than our parent, then we don't need any parenthesis
                    
                    if (currentOperationPriority < parentOperationPriority || 
                        (currentOperationPriority == parentOperationPriority && [self operationIsNotCommutative:parentOp])){                                    
                        
                        descStr = [NSString stringWithFormat:@"(%@ %@ %@)", [self descriptionOfTopOfStack:stack withParentOperation:topOfStack], topOfStack, secondOperand];
                    } else {
                        descStr = [NSString stringWithFormat:@"%@ %@ %@", [self descriptionOfTopOfStack:stack withParentOperation:topOfStack], topOfStack, secondOperand];                    
                    }
                    break;
                default:
                    break;
            } 
        }
    }
    return descStr;
}

- (void)pushOperand:(double)operand
{
    [self.programStack addObject:[NSNumber numberWithDouble:operand]];
}

- (id)performOperation:(NSString *)operation usingVariableValues:(NSDictionary *)variableValues
{
    if ([operation isEqualToString:@"Undo"]){
        // pop the top item on the stack and re-evaluate the program
        [self.programStack removeLastObject];
    } else {
        // other than Undo, do the normal thing: push operation on stack, run program
        [self.programStack addObject:operation];
    }
    return [[self class] runProgram:self.program usingVariableValues:nil];
}

+(NSString *) higherPriorityError: (id) secondOp comparedTo: (id) firstOp
{
    // Assumption: secondOp is definitely a String (i.e. Error). First Op may or may not be error.
    if ([firstOp isKindOfClass:[NSNumber class]]){
        return secondOp;
    }
    if ([firstOp isEqualToString:@"Error: Insufficient Operands!"] || [secondOp isEqualToString:@"Error: Insufficient Operands!"]) return @"Error: Insufficient Operands!";
    if ([firstOp isEqualToString:@"Error: Divide by Zero!"] || [secondOp isEqualToString:@"Error: Divide by Zero!"]) return @"Error: Divide by Zero!";
    if ([firstOp isEqualToString:@"Error: Square Root of -ve value!"] || [secondOp isEqualToString:@"Error: Square Root of -ve value!"]) return @"Error: Square Root of -ve value!";
    return secondOp;
}

+ (id)popOperandOffProgramStack:(NSMutableArray *)stack
{
    double result = 0;
    id secondOperandPtr;
    id firstOperandPtr;
    double secondOperandValue;
    double firstOperandValue;
    
    id topOfStack = [stack lastObject];
    
    if (topOfStack) {
        [stack removeLastObject];
    } else {
        return @"Error: Insufficient Operands!";
    }
    
    if ([topOfStack isKindOfClass:[NSNumber class]])
    {
        result = [topOfStack doubleValue];
        
    } else if ([topOfStack isKindOfClass:[NSString class]]) {
        
        int numOperands = [self numOperands:topOfStack];
        
        switch(numOperands){
            default:
            case 0:
                break;
            case 2:
                secondOperandPtr = [self popOperandOffProgramStack:stack];
                
                if ([secondOperandPtr isKindOfClass:[NSString class]]){
                    // if the operand is a string instead of a number, then it means it contains an error message
                    // if the error is "Variable in Use", it is more informative to the user to check for
                    // insufficient operands or other kind of errors based on the first operand
                    return [self higherPriorityError:secondOperandPtr comparedTo:[self popOperandOffProgramStack:stack]]; 
                } else {
                    secondOperandValue = [secondOperandPtr doubleValue];
                }
                // no break if two operands
            case 1:
                firstOperandPtr = [self popOperandOffProgramStack:stack];
                
                if ([firstOperandPtr isKindOfClass:[NSString class]]){
                    return firstOperandPtr; // if the operand is a string instead of a number, then it means it contains an error message
                } else {
                    firstOperandValue = [firstOperandPtr doubleValue];
                }
                break;
        }
        
        NSString *operation = topOfStack;
        if ([operation isEqualToString:@"+"]) {
            result = firstOperandValue + secondOperandValue;
        } else if ([operation isEqualToString:@"*"]) {
            result = firstOperandValue * secondOperandValue;
        } else if ([operation isEqualToString:@"-"]) {
            result = firstOperandValue - secondOperandValue;
        } else if ([operation isEqualToString:@"/"]) {
            if (secondOperandValue == 0){
                return @"Error: Divide by Zero!";
            }
            result = firstOperandValue / secondOperandValue;
        } else if ([operation isEqualToString:@"π"]){
            result = M_PI;
        } else if ([operation isEqualToString:@"sin"]){
            result = sin(firstOperandValue/*/180*M_PI*/); // Graph Plot of Radians looks much better!
        } else if ([operation isEqualToString:@"cos"]){
            result = cos(firstOperandValue/*/180*M_PI*/);
        } else if ([operation isEqualToString:@"sqrt"]){
            if (firstOperandValue < 0){
                return @"Error: Square Root of -ve value!";
            }
            result = pow(firstOperandValue, 0.5);
        } else if ([operation isEqualToString:@"ChSgn"]){
            result = firstOperandValue * -1;
        } else {
            // variable in stack but no value assigned
            return @"Variable in Use";
        }
    }
    return [[NSNumber class] numberWithDouble:result];
}

+ (id)runProgram:(id)program usingVariableValues:(NSDictionary *)variableValues
{
    NSMutableArray *stack;
    if ([program isKindOfClass:[NSArray class]]) {
        if ([program count] == 0){
            // no program exists, but the test button has been pressed. Just return the zero string
            return @"0";
        }
        stack = [program mutableCopy];
    }
    
    // find out which variables are used in the program
    NSSet * setOfVariables = [[self class] variablesUsedInProgram:stack];
    
    if (setOfVariables){ // set is not nil, i.e. the program  uses variables
        
        // iterate through the program array using index
        NSUInteger numElementsInProgram = [stack count];
        unsigned int i;
        for (i = 0; i < numElementsInProgram; i++){
            id var = [program objectAtIndex:i];
            if ([setOfVariables containsObject:var]){
                // then replace the variable with its value in program using the provided dictionary
                // if the value is not in the dictonary, then use 0 i.e. nil returned value from dictionary is OK
                NSNumber * varValue = [variableValues objectForKey:var];
                if (varValue && [varValue isKindOfClass:[NSNumber class]]){
                    // If the dictionary has a value corresponding to the variable, substitute the value for the variable in programStack 
                    [stack replaceObjectAtIndex:i withObject:varValue];
                }
            }
        }
    }
    // now that all variables have been replaced with their values, we can do the operation
    return [self popOperandOffProgramStack:stack];
}

static NSSet * _listOfOperations;
static NSSet * _oneOperandOperations;
static NSSet * _twoOperandOperations;

// instantiate a set which contains known operations
+ (NSSet *) listOfOperations
{
    if (!_listOfOperations) _listOfOperations = [NSSet setWithObjects: @"+", @"-", @"/", @"*", @"sqrt", @"π", @"sin", @"cos", @"ChSgn", nil];
    return _listOfOperations;
}

// NSSet *zeroOperandOperations = [NSSet setWithObjects: @"π", nil]; // Not used since default value
+ (NSSet *) oneOperandOperations
{
    if (!_oneOperandOperations) _oneOperandOperations = [NSSet setWithObjects: @"sqrt", @"sin", @"cos", @"ChSgn", nil];
    return _oneOperandOperations;
}

+ (NSSet *) twoOperandOperations
{
    if (!_twoOperandOperations) _twoOperandOperations = [NSSet setWithObjects: @"+", @"-", @"/", @"*", nil];
    return _twoOperandOperations;
}


+ (BOOL)isOperation:(NSString *)operation{
    
    // instantiate a set which contains known operations
    [NSSet setWithObjects: @"+", @"-", @"/", @"*", @"sqrt", @"π", @"sin", @"cos", @"ChSgn", nil];
    
    if ([[self listOfOperations] containsObject: operation]){
        return YES;
    } else {
        return NO;
    }
}

+ (int) numOperands:(NSString *)operation{ // given an operation, this method returns the number of operands
    
    if ([[self twoOperandOperations] containsObject:operation]){
        return 2;
    } else if ([[self oneOperandOperations] containsObject:operation]){
        return 1;
    } else {
        return 0; // no need to check the set
    }
}

+ (NSSet *)variablesUsedInProgram:(id)program
{
    // This function assumes that if an ojbect in the stack is a string and it is not one of the known
    // operations such as +, -, sqrt etc or known operand such as π, then it is a variable name
    
    NSMutableSet *setOfVariables = [NSMutableSet set]; // Empty set
    
    for (id object in program){
        // if object is a string
        if ([object isKindOfClass:[NSString class]]){
            // and it is not one of the known operations then add it to list of variables to be returned
            if (![self isOperation:object]){
                [setOfVariables addObject: object];              
            }
        }
    }
    // The Assignment 2 instructions say that if the set is empty, then return nil, not an empty set
    if ([setOfVariables count] == 0){
        return nil;
    } else {
        return setOfVariables;
    }
}

- (void)performClear
{        
    [self.programStack removeAllObjects];
}


@end
