'use strict';

import { NativeModules, processColor, Share as ShareRN } from 'react-native';
//const processColor = require('react-native/Libraries/StyleSheet/processColor');
//console.log(Object.keys(NativeModules).sort().toString())
const { ShareManager } = NativeModules

const invariant = require('fbjs/lib/invariant');


type Content = { title?: string, message: string } | { title?: string, url: string };
type Options = { dialogTitle?: string, excludeActivityTypes?: Array<string>, tintColor?: string };

class Share {
  // Allow content.url to be an Array of url
  static share(content: Content, options: Options = {}): Promise<Object> {
    invariant(
      typeof content === 'object' && content !== null,
      'Content to share must be a valid object'
    );
    invariant(
      typeof content.url === 'string' || typeof content.message === 'string',
      'At least one of URL and message is required'
    );
    invariant(
      typeof options === 'object' && options !== null,
      'Options must be a valid object'
    );

    if (ShareManager) {
      let content_new = { ...content }
      if (!content_new.url){
        content_new.url = []
      }
      else if (content_new.url && !Array.isArray(content_new.url)){
        content_new.url = [content_new.url]
      }
      return new Promise((resolve, reject) => {
        ShareManager.showShareWithOptions(
          {...content_new, ...options, tintColor: processColor(options.tintColor)},
          (error) => reject(error),
          (success, activityType) => {
            if (success) {
              resolve({
                'action': 'sharedAction',
                'activityType': activityType
              });
            } else {
              resolve({
                'action': 'dismissedAction'
              });
            }
          }
        );
      });
    } else {
      let content_new = { ...content }
      if (content_new.url && Array.isArray(content_new.url)){
        content_new.url = content_new.url[0]
      }
      return ShareRN.share(content_new, options);
    }
  }

  /**
   * The content was successfully shared.
   */
  static get sharedAction() { return 'sharedAction'; }

  /**
   * The dialog has been dismissed.
   * @platform ios
   */
  static get dismissedAction() { return 'dismissedAction'; }

}

module.exports = Share
