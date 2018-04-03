//
//  RCTShareManager.m
//  RCTShareManager
//
//  Created by Steven on 2017/10/24.
//  Copyright © 2017年 mojie. All rights reserved.
//

#import "RCTShareManager.h"

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTLog.h>
#import <React/RCTUIManager.h>
#import <React/RCTUtils.h>
#import "ActivityItem.h"

@interface RCTShareManager () <UIActionSheetDelegate>
@end

@implementation RCTShareManager
{
    // Use NSMapTable, as UIAlertViews do not implement <NSCopying>
    // which is required for NSDictionary keys
    NSMapTable *_callbacks;
}

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

/*
 * The `anchor` option takes a view to set as the anchor for the share
 * popup to point to, on iPads running iOS 8. If it is not passed, it
 * defaults to centering the share popup on screen without any arrows.
 */
- (CGRect)sourceRectInView:(UIView *)sourceView
             anchorViewTag:(NSNumber *)anchorViewTag
{
    if (anchorViewTag) {
        UIView *anchorView = [self.bridge.uiManager viewForReactTag:anchorViewTag];
        return [anchorView convertRect:anchorView.bounds toView:sourceView];
    } else {
        return (CGRect){sourceView.center, {1, 1}};
    }
}


RCT_EXPORT_METHOD(showShareWithOptions:(NSDictionary *)options
                  failureCallback:(RCTResponseErrorBlock)failureCallback
                  successCallback:(RCTResponseSenderBlock)successCallback)
{
    if (RCTRunningInAppExtension()) {
        RCTLogError(@"Unable to show action sheet from app extension");
        return;
    }
    
    NSMutableArray<id> *items = [NSMutableArray array];
    NSString *message = [RCTConvert NSString:options[@"message"]];
    if (message) {
        [items addObject:message];
    }
    NSArray *URLS = [RCTConvert NSArray:options[@"url"]];
    for (int i = 0; i < URLS.count; i++) {
      NSURL *URL = [RCTConvert NSURL:URLS[i]];
      if (URL) {
          if ([URL.scheme.lowercaseString isEqualToString:@"data"]) {
              NSError *error;
              NSData *data = [NSData dataWithContentsOfURL:URL
                                                   options:(NSDataReadingOptions)0
                                                     error:&error];
              if (!data) {
                  failureCallback(error);
                  return;
              }
              [items addObject:data];
          } else if ([URL.scheme.lowercaseString isEqualToString:@"file"]) {
              NSError *error;
              NSData *data = [NSData dataWithContentsOfURL:URL
                                                   options:(NSDataReadingOptions)0
                                                     error:&error];
              if (!data) {
                  failureCallback(error);
                  return;
              }

              UIImage *imageData = [UIImage imageWithData:UIImagePNGRepresentation(data)];

              ActivityItem *item = [ActivityItem new];
              item.image = imageData;
              item.imagePath = URL;

              [items addObject:item];
          } else {
              [items addObject:URL];
          }
      }
    }
    if (items.count == 0) {
        RCTLogError(@"No `url` or `message` to share");
        return;
    }
    
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    NSString *subject = [RCTConvert NSString:options[@"subject"]];
    if (subject) {
        [shareController setValue:subject forKey:@"subject"];
    }
    
    NSArray *excludedActivityTypes = [RCTConvert NSStringArray:options[@"excludedActivityTypes"]];
    if (excludedActivityTypes) {
        shareController.excludedActivityTypes = excludedActivityTypes;
    }
    
    UIViewController *controller = RCTPresentedViewController();
    shareController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, __unused NSArray *returnedItems, NSError *activityError) {
        if (activityError) {
            failureCallback(activityError);
        } else {
            successCallback(@[@(completed), RCTNullIfNil(activityType)]);
        }
    };
    
    shareController.modalPresentationStyle = UIModalPresentationPopover;
    NSNumber *anchorViewTag = [RCTConvert NSNumber:options[@"anchor"]];
    if (!anchorViewTag) {
        shareController.popoverPresentationController.permittedArrowDirections = 0;
    }
    shareController.popoverPresentationController.sourceView = controller.view;
    shareController.popoverPresentationController.sourceRect = [self sourceRectInView:controller.view anchorViewTag:anchorViewTag];
    
    [controller presentViewController:shareController animated:YES completion:nil];
    
    shareController.view.tintColor = [RCTConvert UIColor:options[@"tintColor"]];
}

#pragma mark UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    RCTResponseSenderBlock callback = [_callbacks objectForKey:actionSheet];
    if (callback) {
        callback(@[@(buttonIndex)]);
        [_callbacks removeObjectForKey:actionSheet];
    } else {
        RCTLogWarn(@"No callback registered for action sheet: %@", actionSheet.title);
    }
}

@end
