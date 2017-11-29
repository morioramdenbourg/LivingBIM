//
//  Wrapper.h
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 10/25/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

#ifndef Wrapper_h
#define Wrapper_h

#import <Foundation/Foundation.h>
#import <Structure/Structure.h>
#import <Structure/StructureSLAM.h>

@interface ModelWrapper: NSObject

-(id)init;
-(NSObject*)getVC;
-(NSMutableOrderedSet*)getColors;
-(NSMutableOrderedSet*)getDepths;
-(void)addColor: (STColorFrame *) colorFrame;
-(void)addDepth: (STDepthFrame *) depthFrame;
-(int)getTest;

@end

#endif /* Wrapper_h */
