//
//  NotificationViewController.m
//  NotificationServiceContentTitles
//
//  Created by 小飞鸟 on 2019/03/29.
//  Copyright © 2019 小飞鸟. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@interface NotificationViewController () <UNNotificationContentExtension>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveNotification:(UNNotification *)notification {
    
    NSURL * fileURL = [notification.request.content.attachments firstObject].URL;
    //当需要访问不在 App 自身的沙盒或者自身共享容器里的资源时，需要申请权限
    if (fileURL.startAccessingSecurityScopedResource) {
        //开始安全访问
        NSString * filePath = fileURL.path;

        UIImage * image = [[UIImage alloc]initWithContentsOfFile:filePath];
//        NSData * fileData = [[NSData alloc]initWithContentsOfFile:filePath];
//        UIImage * image = [[UIImage alloc]initWithData:fileData];
        CGSize imageSize = image.size;

        CGFloat width = self.view.frame.size.width;
        CGFloat imageHight = imageSize.width/width*imageSize.height;
        if (imageSize.width>width) {
           imageHight= width/imageSize.width*imageSize.height;
        }
        self.imageView.image = [self imageResize:image andResizeTo:CGSizeMake(width, imageHight)];
        
       NSLayoutConstraint * hightNSLayoutConstraint= [NSLayoutConstraint constraintWithItem:self.imageView attribute:(NSLayoutAttributeHeight) relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0  constant:imageHight];
        [hightNSLayoutConstraint setPriority:999];
        [self.imageView addConstraint:hightNSLayoutConstraint];
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view updateConstraints];
        [fileURL stopAccessingSecurityScopedResource];//停止安全访问
    }
}

-(UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize{
    CGFloat scale = [[UIScreen mainScreen]scale];
    
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

// Called when the user taps the play or pause button.
- (void)mediaPlay{
    NSLog(@"%s",__func__);
}
- (void)mediaPause{
      NSLog(@"%s",__func__);
}

//- (UNNotificationContentExtensionMediaPlayPauseButtonType)mediaPlayPauseButtonType
//{
//    return UNNotificationContentExtensionMediaPlayPauseButtonTypeDefault;
//}
//
//- (CGRect)mediaPlayPauseButtonFrame
//{
//    return CGRectMake(100, 100, 100, 100);
//}
//
//- (UIColor *)mediaPlayPauseButtonTintColor{
//    return [UIColor blueColor];
//}

//- (void)mediaPlayingStarted{
//    NSLog(@"主动调用开始的方法");
//}
//- (void)mediaPlayingPaused
//{
//    NSLog(@"主动调用暂停的方法");
//
//}

@end
