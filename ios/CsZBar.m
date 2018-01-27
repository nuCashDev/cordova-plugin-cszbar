#import "CsZBar.h"
#import <AVFoundation/AVFoundation.h>
#import "AlmaZBarReaderViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark - State

@interface CsZBar ()
@property bool scanInProgress;
@property NSString *scanCallbackId;
@property AlmaZBarReaderViewController *scanReader;

@end

#pragma mark - Synthesize

@implementation CsZBar

@synthesize scanInProgress;
@synthesize scanCallbackId;
@synthesize scanReader;

#pragma mark - Cordova Plugin

- (void)pluginInitialize {
    self.scanInProgress = NO;
}

#pragma mark - Plugin API

- (void)scan: (CDVInvokedUrlCommand*)command;
{
    if (self.scanInProgress) {
        [self.commandDelegate
         sendPluginResult: [CDVPluginResult
                            resultWithStatus: CDVCommandStatus_ERROR
                            messageAsString:@"A scan is already in progress."]
         callbackId: [command callbackId]];
    } else {
        self.scanInProgress = YES;
        self.scanCallbackId = [command callbackId];
        self.scanReader = [AlmaZBarReaderViewController new];
        
        self.scanReader.readerDelegate = self;
        self.scanReader.videoQuality = UIImagePickerControllerQualityTypeHigh;
        
        // Get user parameters
        NSDictionary *params = (NSDictionary*) [command argumentAtIndex:0];
        NSString *camera = [params objectForKey:@"camera"];
        if([camera isEqualToString:@"front"]) {
            // We do not set any specific device for the default "back" setting,
            // as not all devices will have a rear-facing camera.
            self.scanReader.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        
        NSString *flash = [params objectForKey:@"flash"];
        
        if ([flash isEqualToString:@"on"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        } else if ([flash isEqualToString:@"off"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        }else if ([flash isEqualToString:@"auto"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        }
        
        //UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; [button setTitle:@"Press Me" forState:UIControlStateNormal]; [button sizeToFit]; [self.view addSubview:button];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        
        BOOL drawSight = [params objectForKey:@"drawSight"] ? [[params objectForKey:@"drawSight"] boolValue] : true;
        UIToolbar *toolbarViewFlash = [[UIToolbar alloc] init];
        
        BOOL drawQRCode = [params objectForKey:@"drawQRCode"] ? [[params objectForKey:@"drawQRCode"] boolValue] : true;
        
        NSString *layout_type = [params objectForKey:@"layout_type"];
        
        UIImage *image = [[UIImage alloc] init];
        UIImage *imageGuia = [[UIImage alloc] init];
        
        if(layout_type)
        {
            //Client
            image = [UIImage imageNamed:@"logo"];
            imageGuia = [UIImage imageNamed:@"guia-qrcode"];
        }
        else if([layout_type isEqual: @"pos"])
        {
            //POS
            image = [UIImage imageNamed:@"logo-azul"];
            imageGuia = [UIImage imageNamed:@"corner-azul"];
            NSLog(@"ENTROU NO POS");
        }
        else if([layout_type isEqual: @"saque"])
        {
            //Saque
            image = [UIImage imageNamed:@"logo-roxo"];
            imageGuia = [UIImage imageNamed:@"corner-roxo"];
        }
        
        if(drawQRCode)
        {
            NSLog(@"%s", "LAYOUT_TYPE: ");
            NSLog(@"%@", layout_type);
            self.scanReader.supportedOrientationsMask = (UIInterfaceOrientationPortrait);
            [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
            NSLog(@"Portrait");
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.frame = CGRectMake(self.viewController.view.bounds.size.width/2-image.size.width/4, image.size.height/2, image.size.width/2, image.size.height/2);
            //        self.scanReader.cameraOverlayView = imageView;
            [scanReader.view insertSubview:imageView aboveSubview:scanReader.view];
            [scanReader.view bringSubviewToFront:imageView];
            
            
            UIImageView *imageViewGuia = [[UIImageView alloc] initWithImage:imageGuia];
            imageViewGuia.frame = CGRectMake(self.viewController.view.bounds.size.width/2-imageGuia.size.width/4, imageGuia.size.height/2, imageGuia.size.height/1.4, imageGuia.size.width/1.4);
            imageViewGuia.center = self.viewController.view.center;
            [scanReader.view insertSubview:imageViewGuia aboveSubview:scanReader.view];
            [scanReader.view bringSubviewToFront:imageViewGuia];
        }
        else
        {
            NSLog(@"Deitado");
            [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
            self.scanReader.supportedOrientationsMask = (UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight);
            //            [self drawLine];
        }
        //The bar length it depends on the orientation
        toolbarViewFlash.frame = CGRectMake(0.0, 0, (screenWidth > screenHeight ?screenWidth:screenHeight), 44.0);
        toolbarViewFlash.barStyle = UIBarStyleBlackOpaque;
        UIBarButtonItem *buttonFlash = [[UIBarButtonItem alloc] initWithTitle:@"Flash" style:UIBarButtonItemStyleDone target:self action:@selector(toggleflash)];
        
        NSArray *buttons = [NSArray arrayWithObjects: buttonFlash, nil];
        [toolbarViewFlash setItems:buttons animated:NO];
        [self.scanReader.view addSubview:toolbarViewFlash];
        
        [self.viewController presentViewController:self.scanReader animated:YES completion:nil];
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        
        //        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"mp3"];
        //        SystemSoundID soundID;
        //        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
        //        AudioServicesPlaySystemSound(soundID);
    }
}

- (void)toggleflash {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    if (device.torchAvailable == 1) {
        if (device.torchMode == 0) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
        }
    }
    
    [device unlockForConfiguration];
}

-(void)viewTampaBotao {
    
    CGPoint point;
    point.x = self.viewController.view.bounds.size.width-10;
    point.y = self.viewController.view.bounds.size.height-10;
    
    unsigned char pixel[4] = {0};
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    
    CGContextTranslateCTM(context, -point.x, -point.y);
    
    [self.viewController.view.layer renderInContext:context];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    //NSLog(@"pixel: %d %d %d %d", pixel[0], pixel[1], pixel[2], pixel[3]);
    
    UIColor *color = [UIColor colorWithRed:pixel[0]/255.0 green:pixel[1]/255.0 blue:pixel[2]/255.0 alpha:pixel[3]/255.0];
    
    UIView *viewTampa = [[UIView alloc] initWithFrame:CGRectMake(self.viewController.view.bounds.size.width-150, self.viewController.view.bounds.size.height-65, 65, 65)];
    viewTampa.backgroundColor = color;  //[UIColor colorWithRed:97/255.0 green:97/255.0 blue:97/255.0 alpha:1];
    viewTampa.layer.zPosition = MAXFLOAT;
    viewTampa.userInteractionEnabled = NO;
    [self.scanReader.view addSubview:viewTampa];
    //    [scanReader.view bringSubviewToFront:viewTampa];
    
    //        UITextField *txtNumero = [[UITextField alloc] initWithFrame:CGRectMake(35, 75, 200, 40)];
    //        txtNumero.textColor = [UIColor colorWithRed:0/256.0 green:84/256.0 blue:129/256.0 alpha:1.0];
    //        txtNumero.font = [UIFont fontWithName:@"Helvetica-Bold" size:25];
    //        txtNumero.backgroundColor=[UIColor lightGrayColor];
    //        txtNumero.text=@"";
    //
    //        [viewNumero addSubview:txtNumero];
    [viewTampa bringSubviewToFront:viewTampa];
}

-(void)drawLine {
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(50,screenHeight/2, screenWidth-50, 1)];
    lineView.backgroundColor = [UIColor redColor];
    
    //    self.scanReader.cameraOverlayView = polygonView;
    [self.scanReader.view addSubview:lineView];
}

#pragma mark - Helpers

- (void)sendScanResult: (CDVPluginResult*)result {
    [self.commandDelegate sendPluginResult: result callbackId: self.scanCallbackId];
}

#pragma mark - ZBarReaderDelegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    return;
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
    
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    
    ZBarSymbol *symbol = nil;
    for (symbol in results) break; // get the first result
    
    if(true)
    {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"double_beep" ofType:@"mp3"];
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
        AudioServicesPlaySystemSound(soundID);
        
        [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
            self.scanInProgress = NO;
            [self sendScanResult: [CDVPluginResult
                                   resultWithStatus: CDVCommandStatus_OK
                                   messageAsString: symbol.data]];
            NSLog(@"%@", symbol.data);
        }];
        
        if ([self.scanReader isBeingDismissed]) {
            return;
        }
        
        
    }
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController*)picker {
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_ERROR
                               messageAsString: @"cancelled"]];
        
        self.scanReader.supportedOrientationsMask = UIInterfaceOrientationPortrait;
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
        
    }];
}

- (void) readerControllerDidFailToRead:(ZBarReaderController*)reader withRetry:(BOOL)retry {
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_ERROR
                               messageAsString: @"Failed"]];
        
        self.scanReader.supportedOrientationsMask = UIInterfaceOrientationPortrait;
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
        
    }];
}

@end



