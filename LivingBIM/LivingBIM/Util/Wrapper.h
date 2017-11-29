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
- (void)showMeshViewerMessage:(UILabel*)label msg:(NSString *)msg;


-(id)init;
-(NSObject*)getVC;
-(void)save: (NSDate* )captureTime :(NSData *)zipData;
-(void)addFrame: (STColorFrame *) colorFrame;

@end

#endif /* Wrapper_h */
