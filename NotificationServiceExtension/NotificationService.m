//
//  NotificationService.m
//  NotificationServiceExtension
//
//  Created by 小飞鸟 on 2019/03/26.
//  Copyright © 2019 小飞鸟. All rights reserved.
//

#import "NotificationService.h"

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService


/*
 文字aps
 {
 "aps":{
 "alert":{
 "body":"test: 我不知道你在想什么，还是那个地点那条街",
 "title":"外滩十八号"
 },
 "badge":1,
 "category":"myMessageNotificationCategory",
 "sound":"default"
 },
 "id":"test",
 "type":"chat"
 }
 图片aps
 {
 "aps":{
 "alert":{
 "body":"test: 图片",
 "title":"外滩十八号",
 "subtitle":"测试"
 },
 "badge":1,
 "category":"myMessageNotificationCategory",
 "sound":"default",
 "mutable-content":"1"
 },
 "id":"test18",
 "type":"chat",
 "media":{
 "type":"image",
 "url":"https://www.fotor.com/images2/features/photo_effects/e_bw.jpg"
 }
 }
 视频aps
 {
 "aps":{
 "alert":{
 "body":"test: 视频",
 "title":"外滩十八号"
 },
 "badge":1,
 "category":"myMessageNotificationCategory",
 "sound":"default",
 "mutable-content":"1"
 },
 "id":"test18",
 "type":"chat",
 "media":{
 "type":"video",
 "url":"http://www.yidiankeji.online/flvTest.mp4"
 }
 }
 */
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    self.bestAttemptContent.subtitle = self.bestAttemptContent.subtitle;
    self.bestAttemptContent.body = self.bestAttemptContent.body;
    
    NSDictionary *dict =  self.bestAttemptContent.userInfo;

    self.bestAttemptContent.categoryIdentifier = [dict[@"aps"] objectForKey:@"categoryIdentifier"];
    // 附件
    NSDictionary * fileJson = [dict objectForKey:@"media"] ;
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [self jsonStringEncoded:dict];//粘贴板处理
    
    if (!fileJson) {
        //不存在 富文本
        self.contentHandler(self.bestAttemptContent);
        return;
    }
    NSString *imgUrl = [NSString stringWithFormat:@"%@",fileJson[@"url"]];//资源路径
    NSString * fileType =[self fileExtensionForMediaType:fileJson[@"type"]];//文件类型
    [self loadAttachmentForUrlString:imgUrl withType:fileType completionHandle:^(UNNotificationAttachment *attach) {
            if (attach) {
                self.bestAttemptContent.attachments = @[attach];
            }
        self.contentHandler(self.bestAttemptContent);
    }];
}


-(void)saveLocalData:(NSString*)imgUrl FileType:(NSString*)fileType{
        NSData* imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]];
        if (imageData) {
            NSString* imageFilePath = [self saveImageDataToSandBox:imageData Type:fileType];
            if (imageFilePath && imageFilePath.length != 0) {
                UNNotificationAttachment* attachment = [UNNotificationAttachment attachmentWithIdentifier:@"photo" URL:[NSURL URLWithString:[@"file://" stringByAppendingString:imageFilePath]] options:nil error:nil];
                if (attachment) {
                    self.bestAttemptContent.attachments = @[attachment];
                }
            }
        }
}

#pragma mark - SaveImageDataToSandBox
- (NSString *)saveImageDataToSandBox:(NSData *)imageData Type:(NSString*)type {
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString * fileName = [NSString stringWithFormat:@"notification_image.%@",type];//文件名字
    NSString* imageDataFilePath = [NSString stringWithFormat:@"%@/%@", documentPath,fileName];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:imageDataFilePath]) {
        [fileManager removeItemAtPath:imageDataFilePath
                                error:nil];
    }
    NSError* error = nil;
    [imageData writeToFile:imageDataFilePath options:NSAtomicWrite error:&error];
    if (!error) {
        return imageDataFilePath;
    }
    return nil;
}

-(NSString *)jsonStringEncoded:(NSDictionary*)jsonDic{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:0 error:&error];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return json;
}

-(NSString *)fileExtensionForMediaType:(NSString *)type {
    NSString *ext = type;
    if ([type isEqualToString:@"image"]) {
        ext = @"jpg";
    }
    if ([type isEqualToString:@"video"]) {
        ext = @"mp4";
    }
    if ([type isEqualToString:@"audio"]) {
        ext = @"mp3";
    }
    return ext;
}

- (void)loadAttachmentForUrlString:(NSString *)urlStr
                          withType:(NSString *)type
                  completionHandle:(void(^)(UNNotificationAttachment *attach))completionHandler{
    
    __block UNNotificationAttachment *attachment = nil;
    NSURL *attachmentURL = [NSURL URLWithString:urlStr];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                    
                    if (error != nil) {
                        NSLog(@"%@", error.localizedDescription);
                    } else {
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        
                        NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                        NSString * fileName = [NSString stringWithFormat:@"notification_image.%@",type];//文件名字
                        NSString* imageDataFilePath = [documentPath stringByAppendingPathComponent:fileName];
                        //移除已存在的
                        if ([fileManager fileExistsAtPath:imageDataFilePath]) {
                            [fileManager removeItemAtPath:imageDataFilePath
                                                    error:nil];
                        }
                        
                        [fileManager moveItemAtPath:temporaryFileLocation.path toPath:imageDataFilePath error:NULL];
                        NSError *attachmentError = nil;
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:[NSURL URLWithString:[@"file://" stringByAppendingString:imageDataFilePath]] options:nil error:&attachmentError];
                        if (attachmentError) {
                            NSLog(@"%@", attachmentError.localizedDescription);
                        }
                    }
                    completionHandler(attachment);
                }] resume];
}

//  如果处理时间太长，等不及处理了，就会把收到的apns直接展示出来
- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    
    self.bestAttemptContent.title = @"下载资源超时";
    self.contentHandler(self.bestAttemptContent);
}

@end
