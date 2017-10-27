//
//  Wrapper.m
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 10/25/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

#import "Wrapper.h"
#import "ViewController.h"

@implementation SwiftWrapper
{
    ViewController * vc;
}

-(id)init
{
    vc = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    return self;
}

-(NSObject*)getVC
{
    return vc;
}

@end

