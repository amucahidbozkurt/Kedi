//
//  NotificationService.swift
//  OneSignalNotificationServiceExtension
//
//  Created by Saffet Emin Reisoğlu on 3/22/24.
//

import UserNotifications
import OneSignalExtension

final class NotificationService: UNNotificationServiceExtension {
    
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var receivedRequest: UNNotificationRequest!
    private var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent {
            /* DEBUGGING: Uncomment the 2 lines below to check this extension is executing
             Note, this extension only runs when mutable-content is set
             Setting an attachment or action buttons automatically adds this */
            // print("Running NotificationServiceExtension")
            // bestAttemptContent.body = "[Modified] " + bestAttemptContent.body
            
            OneSignalExtension.didReceiveNotificationExtensionRequest(
                receivedRequest,
                with: bestAttemptContent,
                withContentHandler: contentHandler
            )
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler,
           let bestAttemptContent {
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(
                receivedRequest,
                with: bestAttemptContent
            )
            contentHandler(bestAttemptContent)
        }
    }
}
