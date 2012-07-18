//
//  GraphViewController.h
//  Calculator
//
//  Created by Sanjaya Kumar on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RotatableViewController.h"

@interface GraphViewController : RotatableViewController
@property (nonatomic, strong) id program; // This program is a copy of the one created by CalculatorBrain
@property (nonatomic) BOOL drawUsingDots;
@end
