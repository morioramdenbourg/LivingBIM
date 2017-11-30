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
    NSEntityDescription * entity;
    NSEntityDescription * frameEntity;
    NSManagedObject * capture;
    NSMutableSet * frames;
    NSDate * captureTime;
    STDepthToRgba * toRGBA;
}

-(id)init
{
    vc = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    vc->wrapper = self;
    
    // Core data
    managedContext = AppDelegate.delegate.persistentContainer.viewContext;
    entity = [NSEntityDescription entityForName: @"Capture" inManagedObjectContext: managedContext];
    frameEntity = [NSEntityDescription entityForName: @"Frame" inManagedObjectContext: managedContext];
    
    capture = [NSEntityDescription insertNewObjectForEntityForName: @"Capture" inManagedObjectContext: managedContext];
    frames = [capture mutableSetValueForKey:@"Frames"];
    
    NSNumber * value = [NSNumber numberWithInt: STDepthToRgbaStrategyRedToBlueGradient];
    NSDictionary *options = [NSDictionary dictionaryWithObject:value forKey: kSTDepthToRgbaStrategyKey];
    toRGBA = [[ STDepthToRgba alloc ] initWithOptions:options];
    
    return self;
}

-(void)setCaptureTime: (NSDate *) newTime
{
    captureTime = newTime;
}

-(void)save: (NSData *) zipData
{
    // Set values
    [capture setValue:captureTime forKey:@"captureTime"];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [capture setValue: [defaults valueForKey:@"usernameUD"] forKey:@"username"];
    [capture setValue: zipData forKey:@"mesh"];
    
    [capture.managedObjectContext save: nil];
}

-(NSObject*)getVC
{
    return vc;
}

-(void)addFrame: (NSDate*) time colorFrame: (STColorFrame *) colorFrame depthFrame: (STDepthFrame *) depthFrame
{
    NSManagedObject * frame = [NSEntityDescription insertNewObjectForEntityForName: @"Frame" inManagedObjectContext: managedContext];
    
    NSData *colorData = [ self convertToData: [colorFrame sampleBuffer]];
    NSData *frameData = [ self convertDepthToData: depthFrame ];
    
    [ frame setValue: colorData forKey:@"color" ];
    [ frame setValue: frameData forKey:@"depth" ];
    [ frame setValue: time forKey:@"time" ];
    
    [ frames addObject:frame ];
}
    
-(NSData *)convertDepthToData: (STDepthFrame *) depthFrame
{
    uint8_t * pixels = [toRGBA convertDepthFrameToRgba: depthFrame];
    UIImage *depthImage = [UIImage imageFromPixels:pixels width: toRGBA.width height: toRGBA.height];
    NSData * data = UIImagePNGRepresentation(depthImage);
    return data;
}

-(NSData *)convertToData: (CMSampleBufferRef) buffer
{
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(buffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *context = [CIContext contextWithOptions: nil];
    CGImageRef myImage = [context createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
    UIImage *uiImage = [UIImage imageWithCGImage:myImage];
    NSData * data = UIImagePNGRepresentation(uiImage);
    return data;
}
@end

