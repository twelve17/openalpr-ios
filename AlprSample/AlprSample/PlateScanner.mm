//
//  PlateScanner.m
//  AlprSample
//
//  Created by Alex on 04/11/15.
//  Copyright © 2015 alpr. All rights reserved.
//

#import "PlateScanner.h"
#import "Plate.h"

#import <openalpr/alpr.h>

@implementation PlateScanner {
    alpr::Alpr* delegate;
}

- (id) init {
    if (self = [super init]) {
        
        delegate = new alpr::Alpr(
                                  [@"us" UTF8String],
                                  [[[NSBundle mainBundle] pathForResource:@"openalpr.conf" ofType:nil] UTF8String],
                                  [[[NSBundle mainBundle] pathForResource:@"runtime_data" ofType:nil] UTF8String]
                                  );
        delegate->setTopN(3);
        
        if (delegate->isLoaded() == false) {
            NSLog(@"Error initializing OpenALPR library");
            delegate = nil;
        }
        if (!delegate) self = nil;
    }
    return self;
    
}

- (void)scanImage:(cv::Mat &)colorImage
        onSuccess:(onPlateScanSuccess)success
        onFailure:(onPlateScanFailure)failure {
    
    if (delegate->isLoaded() == false) {
        NSError *error = [NSError errorWithDomain:@"alpr" code:-100
                                         userInfo:[NSDictionary dictionaryWithObject:@"Error loading OpenALPR" forKey:NSLocalizedDescriptionKey]];
        failure(error);
    }
    
    std::vector<alpr::AlprRegionOfInterest> regionsOfInterest;
    alpr::AlprResults results = delegate->recognize(colorImage.data, (int)colorImage.elemSize(), colorImage.cols, colorImage.rows, regionsOfInterest);
    
    NSMutableArray *bestPlates = [[NSMutableArray alloc]initWithCapacity:results.plates.size()];
    
    for (int i = 0; i < results.plates.size(); i++) {
        alpr::AlprPlateResult plateResult = results.plates[i];
        [bestPlates addObject:[[Plate alloc]initWithAlprPlate:&plateResult.bestPlate]];
    }
    
    success(bestPlates);
}

@end
