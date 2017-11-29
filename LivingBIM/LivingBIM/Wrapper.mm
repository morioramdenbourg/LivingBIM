//
//  Wrapper.m
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 10/25/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

#import "Wrapper.h"
#import "ViewController.h"

//DepthFrame:(STDepthFrame *)depthFrame
//colorFrame:(STColorFrame*)colorFrame

@implementation ModelWrapper
{
    ViewController * vc;
    NSMutableOrderedSet * colors;
    NSMutableOrderedSet * depths;
    int test;
}

-(id)init
{
    colors = [[NSMutableOrderedSet alloc] init];
    depths = [[NSMutableOrderedSet alloc] init];
    vc = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    vc->wrapper = self;
    test = 5;
    return self;
}

-(int)getTest
{
    return test;
}

-(NSObject*)getVC
{
    return vc;
}

-(NSMutableOrderedSet*)getColors
{
    return colors;
}

-(NSMutableOrderedSet*)getDepths
{
    return depths;
}

-(void)addColor: (STColorFrame *) colorFrame
{
    [ colors addObject:colorFrame ];
}

-(void)addDepth: (STDepthFrame *) depthFrame
{
    [ depths addObject:depthFrame ];
}

@end

