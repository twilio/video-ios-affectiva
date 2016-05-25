//
//  I420Converter.h
//  VideoSampleCaptureRender
//
//  Created by Boisy Pitre on 5/21/16.
//  Copyright © 2016 Twilio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>
#import <TwilioConversationsClient/TWCI420Frame.h>

@interface I420Converter : NSObject

- (UIImage *)convertFrameVImageYUVToUIImage:(TWCI420Frame *)frame;

@end
