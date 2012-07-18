//
//  CalculatorViewController.h
//  Calculator
//
//  Created by Sanjaya Kumar on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RotatableViewController.h"
#import "SplitViewBarButtonItemPresenter.h"

@interface CalculatorViewController : RotatableViewController
@property (weak, nonatomic) IBOutlet UILabel *display;
@property (weak, nonatomic) IBOutlet UILabel *userActionDisplay;
@end