//
//  Wrapper.m
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 10/25/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

#import "Wrapper.h"
#import "ViewController.h"
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "LivingBIM-Swift.h"

@implementation ModelWrapper
{
    ViewController * vc;
    NSManagedObjectContext * managedContext;
    NSManagedObject * capture;
//    NSMutableSet * frames;
    NSDate * captureTime;
    GLKMatrix4 projection;
    GLKMatrix4 viewpoint;
}

-(id)init
{
    vc = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    vc->wrapper = self;
    
    // Core data
    managedContext = AppDelegate.delegate.persistentContainer.viewContext;
    capture = [NSEntityDescription insertNewObjectForEntityForName: @"Capture" inManagedObjectContext: managedContext];
//    frames = [capture mutableSetValueForKey:@"Frames"];
    
    return self;
}

-(void)setCaptureTime: (NSDate *) newTime
{
    captureTime = newTime;
}

-(void)save: (NSData *)zipData description: (NSString *) description
{
    NSLog(@"saving");
    [ModelWrapper addCaptureDataWithManagedObject:capture captureTime:captureTime zipData:zipData description:description];
    [capture.managedObjectContext save: nil];
}

-(NSObject*)getVC
{
    return vc;
}

-(void)dealloc
{
    NSLog(@"in dealloc");
}

-(void)explicitDealloc
{
    [ managedContext reset ];
    NSLog(@"in explicit dealloc");
}

-(void)setMatrix: (GLKMatrix4) cameraGLProjection cameraViewPoint: (GLKMatrix4) cameraViewPoint
{
    projection = cameraGLProjection;
    viewpoint = cameraViewPoint;
}

-(void)reset
{
//    [ AppDelegate resetToHome ];
}

-(void)addFrame: (NSDate*) time depthFrame: (STDepthFrame *) depthFrame colorFrame: (STColorFrame *) colorFrame
{
    NSManagedObject * frame = [NSEntityDescription insertNewObjectForEntityForName: @"Frame" inManagedObjectContext: managedContext];
    
    // Downsize the frames
    STColorFrame * downsizedColor = colorFrame;
    STDepthFrame * downsizedDepth = depthFrame;
    
    // Add frame information
    [ ModelWrapper addFrameDataWithManagedObject:frame captureTime:time depthFrame:downsizedDepth colorFrame:downsizedColor cameraGLProjection:projection.m cameraViewPoint: viewpoint.m];
    NSMutableSet * test = [capture mutableSetValueForKey:@"Frames"];
    [ test addObject: frame ];
//    [ frames addObject:frame ];
}
@end

