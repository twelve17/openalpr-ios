//
//  Plate.h
//  AlprSample
//
//  Created by Alex on 04/11/15.
//  Copyright © 2015 alpr. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <openalpr/alpr.h>

@interface Plate : NSObject

@property NSString *number;
@property float confidence;

- (id)initWithAlprPlate:(alpr::AlprPlate *)plate;

@end
