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

-(void)reset;
-(id)init;
-(NSObject*)getVC;
-(void)setCaptureTime: (NSDate *) newTime;
-(void)save: (NSData *)zipData description: (NSString *) description;
-(void)addFrame: (NSDate*) time depthFrame: (STDepthFrame *) depthFrame colorFrame: (STColorFrame *) colorFrame;
-(void)setMatrix: (GLKMatrix4) cameraGLProjection cameraViewPoint: (GLKMatrix4) cameraViewPoint;
-(void)explicitDealloc;

@end

#endif /* Wrapper_h */
