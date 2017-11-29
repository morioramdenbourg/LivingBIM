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
    
    return self;
}

-(void)save: (NSDate *)captureTime :(NSData *)zipData
{
    // Set values
    [capture setValue:captureTime forKey:@"captureTime"];
    
    
    [capture.managedObjectContext save: nil];
}

-(NSObject*)getVC
{
    return vc;
}

-(void)addFrame: (STColorFrame *) colorFrame
{
    NSLog(@"ADDING COLOR: %@", colorFrame);
    
    NSManagedObject * frame = [NSEntityDescription insertNewObjectForEntityForName: @"Frame" inManagedObjectContext: managedContext];
    
//    CMSampleBufferRef buffer = colorFrame.sampleBuffer;
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buffer);
//    CVPixelBufferLockBaseAddress(imageBuffer,0);
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//    void *src_buff = CVPixelBufferGetBaseAddress(imageBuffer);
//    NSData *data = [NSData dataWithBytes:src_buff length:bytesPerRow * height];
//    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CMSampleBufferRef buffer = colorFrame.sampleBuffer;
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(buffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *context = [CIContext contextWithOptions: nil];
    CGImageRef myImage = [context createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
    UIImage *uiImage = [UIImage imageWithCGImage:myImage];
    NSData * data = UIImagePNGRepresentation(uiImage);
    
    
    [ frame setValue: data forKey:@"color" ];
    
    [ frames addObject:frame ];
}
@end

