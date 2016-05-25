//
//  I420Converter.m
//  VideoSampleCaptureRender
//
//  Created by Boisy Pitre on 5/21/16.
//  Copyright © 2016 Twilio. All rights reserved.
//

#import "I420Converter.h"

@interface I420Converter()

@property (nonatomic, assign) vImage_YpCbCrToARGB *conversionInfo;

@end

@implementation I420Converter

- (vImage_Error)prepareForAccelerateConversion
{
    // Setup the YpCbCr to ARGB conversion.
    
    if (_conversionInfo != NULL) {
        return kvImageNoError;
    }
    
    vImage_YpCbCrPixelRange pixelRange = { 0, 128, 255, 255, 255, 1, 255, 0 };
    //    vImage_YpCbCrPixelRange pixelRange = { 16, 128, 235, 240, 255, 0, 255, 0 };
    vImage_YpCbCrToARGB *outInfo = malloc(sizeof(vImage_YpCbCrToARGB));
    vImageYpCbCrType inType = kvImage420Yp8_Cb8_Cr8;
    vImageARGBType outType = kvImageARGB8888;
    
    vImage_Error error = vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_601_4, &pixelRange, outInfo, inType, outType, kvImagePrintDiagnosticsToConsole);
    
    _conversionInfo = outInfo;
    
    return error;
}

- (void)unprepareForAccelerateConversion
{
    if (_conversionInfo != NULL) {
        free(_conversionInfo);
        _conversionInfo = NULL;
    }
}

- (UIImage *)convertFrameVImageYUVToUIImage:(TWCI420Frame *)frame
{
    UIImage *result = nil;
    
    [self prepareForAccelerateConversion];
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferCreate(nil, frame.width, frame.height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer);
    
    [self convertFrameVImageYUV:frame toBuffer:pixelBuffer];

    [self unprepareForAccelerateConversion];

    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef uiImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(pixelBuffer),
                                                 CVPixelBufferGetHeight(pixelBuffer))];
    
    result = [UIImage imageWithCGImage:uiImage];
    CGImageRelease(uiImage);
    
    return result;
}

- (vImage_Error)convertFrameVImageYUV:(TWCI420Frame *)frame toBuffer:(CVPixelBufferRef)pixelBufferRef
{
    if (pixelBufferRef == NULL) {
        return kvImageInvalidParameter;
    }
    
    // Compute info for interleaved YUV420 source.
    
    vImagePixelCount width = frame.width;
    vImagePixelCount height = frame.height;
    vImagePixelCount subsampledWidth = frame.chromaWidth;
    vImagePixelCount subsampledHeight = frame.chromaHeight;
    
    const uint8_t *yPlane = frame.yPlane;
    const uint8_t *uPlane = frame.uPlane;
    const uint8_t *vPlane = frame.vPlane;
    size_t yStride = (size_t)frame.yPitch;
    size_t uStride = (size_t)frame.uPitch;
    size_t vStride = (size_t)frame.vPitch;
    
    // Create vImage buffers to represent each of the Y, U, and V planes
    
    vImage_Buffer yPlaneBuffer = {.data = (void *)yPlane, .height = height, .width = width, .rowBytes = yStride};
    vImage_Buffer uPlaneBuffer = {.data = (void *)uPlane, .height = subsampledHeight, .width = subsampledWidth, .rowBytes = uStride};
    vImage_Buffer vPlaneBuffer = {.data = (void *)vPlane, .height = subsampledHeight, .width = subsampledWidth, .rowBytes = vStride};
    
    // Create a vImage buffer for the destination pixel buffer.
    
    CVPixelBufferLockBaseAddress(pixelBufferRef, 0);
    
    void *pixelBufferData = CVPixelBufferGetBaseAddress(pixelBufferRef);
    size_t rowBytes = CVPixelBufferGetBytesPerRow(pixelBufferRef);
    vImage_Buffer destinationImageBuffer = {.data = pixelBufferData, .height = height, .width = width, .rowBytes = rowBytes};
    
    // Do the conversion.
    
    uint8_t permuteMap[4] = {3, 2, 1, 0}; // BGRA
    vImage_Error convertError = vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(&yPlaneBuffer, &vPlaneBuffer, &uPlaneBuffer, &destinationImageBuffer, self.conversionInfo, permuteMap, 255, 0);
    
    CVPixelBufferUnlockBaseAddress(pixelBufferRef, 0);
    
    return convertError;
}

@end
