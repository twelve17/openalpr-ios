//
//  Plate.m
//  AlprSample
//
//  Created by Alex on 04/11/15.
//  Copyright © 2015 alpr. All rights reserved.
//

#import "Plate.h"

@implementation Plate

- (id)initWithAlprPlate:(alpr::AlprPlate *)plate {
    if (self = [super init]) {
        self.number = [NSString stringWithCString:plate->characters.c_str()
                                         encoding:[NSString defaultCStringEncoding]];
        
        self.confidence = plate->overall_confidence;
    }
    return self;
}

@end
