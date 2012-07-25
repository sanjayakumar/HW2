//
//  CalculatorProgramsTableViewController.m
//  Calculator
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "CalculatorProgramsTableViewController.h"
#import "CalculatorBrain.h"

@implementation CalculatorProgramsTableViewController

@synthesize programs = _programs;
@synthesize delegate = _delegate;

// added after lecture to be sure table gets reloaded if Model changes
// you should always do this (i.e. reload table when Model changes)
// the Model getting out of synch with the contents of the table is bad

- (void)setPrograms:(NSArray *)programs
{
    _programs = programs;
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.programs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Calculator Program Description";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    id program = [self.programs objectAtIndex:indexPath.row];
    cell.textLabel.text = [@"y = " stringByAppendingString:[CalculatorBrain descriptionOfProgram:program]];
    
    return cell;
}

// this method added after lecture to support deletion
// simply delegates deletion

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id program = [self.programs objectAtIndex:indexPath.row];
        [self.delegate calculatorProgramsTableViewController:self deletedProgram:program];
    }
}

// added after lecture
// don't allow deletion if the delegate does not support it too!

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.delegate respondsToSelector:@selector(calculatorProgramsTableViewController:deletedProgram:)];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id program = [self.programs objectAtIndex:indexPath.row];
    [self.delegate calculatorProgramsTableViewController:self choseProgram:program];
}

@end






