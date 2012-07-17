//
//  GraphViewController.h
//  Calculator
//
//  Created by Sanjaya Kumar on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GraphViewController : UIViewController
@property (nonatomic, strong) id program; //During prepareForSegue, the CalculatorViewController puts the program to be graphed into this property
@end
