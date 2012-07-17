//
//  GraphView.h
//  Calculator
//
//  Created by Sanjaya Kumar on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GraphView;

@protocol GraphViewDataSource
- (CGFloat) getYInPixelsForX:(CGFloat)xVal forView:(GraphView *)sender;
@end



@interface GraphView : UIView
@property (nonatomic)CGFloat graphScale;
@property (nonatomic)CGPoint graphOrigin;

- (void)pinch:(UIPinchGestureRecognizer *)gesture;  // resizes the graph
- (void)tripleTapHandler: (UITapGestureRecognizer *)taps; // defines origin of graph
- (void)panHandler: (UIPanGestureRecognizer *)pan; // Yes, I know the variable name is punny!

@property (nonatomic, weak) IBOutlet id <GraphViewDataSource> dataSource;

@end