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
        descStr = [NSString stringWithFormat:@"%@",[topOfStack stringValue]];
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
    return [[self class] runProgram:self.program usingVariableValues:variableValues];
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
                    return secondOperandPtr; // if the operand is a string instead of a number, then it means it contains an error message
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
            result = sin(firstOperandValue/180*M_PI);
        } else if ([operation isEqualToString:@"cos"]){
            result = cos(firstOperandValue/180*M_PI);
        } else if ([operation isEqualToString:@"sqrt"]){
            if (firstOperandValue < 0){
                return @"Error: Square Root of -ve value!";
            }
            result = pow(firstOperandValue, 0.5);
        } else if ([operation isEqualToString:@"ChSgn"]){
            result = firstOperandValue * -1;
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
                if (!varValue || ![varValue isKindOfClass:[NSNumber class]]){
                    varValue = [NSNumber numberWithDouble:0];
                }
                [stack replaceObjectAtIndex:i withObject:varValue];
                // NSLog(@"Replacing %@ with %g", var, [varValue doubleValue]);
            }
        }
    }
    // now that all variables have been replaced with their values, we can do the operation
    return [self popOperandOffProgramStack:stack];
}

+ (BOOL)isOperation:(NSString *)operation{
    
    // instantiate a set which contains known operations
    NSSet *setOfOperations = [NSSet setWithObjects: @"+", @"-", @"/", @"*", @"sqrt", @"π", @"sin", @"cos", @"ChSgn", nil];
    
    if ([setOfOperations containsObject: operation]){
        return YES;
    } else {
        return NO;
    }
}

+ (int) numOperands:(NSString *)operation{ // given an operation, this method returns the number of operands
    // NSSet *zeroOperandOperations = [NSSet setWithObjects: @"π", nil]; // Not used since default value
    NSSet *oneOperandOperations = [NSSet setWithObjects: @"sqrt", @"sin", @"cos", @"ChSgn", nil];
    NSSet *twoOperandOperations = [NSSet setWithObjects: @"+", @"-", @"/", @"*", nil];
    
    if ([twoOperandOperations containsObject:operation]){
        return 2;
    } else if ([oneOperandOperations containsObject:operation]){
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
