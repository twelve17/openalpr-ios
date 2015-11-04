//
//  ViewController.m
//  AlprSample
//
//  Created by Alex on 04/11/15.
//  Copyright © 2015 alpr. All rights reserved.
//

#import "ViewController.h"
#import "PlateScanner.h"
#import "Plate.h"

@interface ViewController ()
@property PlateScanner *plateScanner;
@property (strong, nonatomic) NSMutableArray *plates;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *plateFilename = @"_change_me_to_something_else.jpg_";
    
    // Do any additional setup after loading the view, typically from a nib.
    self.plateImageView.image = [UIImage imageNamed:plateFilename];
    self.plateScanner = [[PlateScanner alloc] init];
    self.plates = [NSMutableArray arrayWithCapacity:0];
    
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:plateFilename ofType:nil];
    cv::Mat image = imread([imagePath UTF8String], CV_LOAD_IMAGE_COLOR);
    
    if (imagePath) {
        [self.plateScanner
         scanImage:image
         onSuccess:^(NSArray * results) {
             [self.plates addObjectsFromArray:results];
             [self.plateTableView reloadData];
         }
         onFailure:^(NSError * error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 NSLog(@"Error: %@", [error localizedDescription]);
                 [self showErrorDialogWithTitle:@"Error with scan."
                                        message:[NSString stringWithFormat:@"Unable to process license plate image: %@", [error localizedDescription]]];
             });
         }];
        
    }
    else {
        // Hackity Hack Hack
        Plate *placeHolder = [[Plate alloc] init];
        placeHolder.number = @"ERROR: plateFileName not found";
        [self.plates addObject:placeHolder];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.plates.count;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Scan Results";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    Plate *plate = self.plates[indexPath.row];
    cell.textLabel.text = [plate number];
    return cell;
}

#pragma mark error

- (void)showErrorDialogWithTitle:(NSString *)title
                         message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:title
                                    message:message
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [alert dismissViewControllerAnimated:YES completion:nil];
                                    }];
        
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
        
    });
}


@end
