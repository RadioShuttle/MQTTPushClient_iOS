![Title image](/docs/readme/title_image.png)

# RadioShuttle MQTT Push Client app for iOS

This app allows you to receive push notifications from MQTT environments. The app communicates with the public MQTT push server (radioshuttle.de), which in turn connects to an MQTT server and sends messages via the push services of Apple or Google. The app allows the configuration of push notifications for defined MQTT topics, which are automatically monitored by the MQTT push server. In the case of activity, these are immediately forwarded to the app, which outputs the message as a push notification. Push notifications are delivered automatically even if the app is not running.

In addition to receiving push notifications for registered topics, MQTT actions can also be defined to send an MQTT message that can trigger an action on the recipients.

The app offers the following application sections:

* Message view of all messages (push messages or simple messages)
* Actions for sending defined messages (menu with MQTT actions)
* Dashboard view (planned for a future version)

The messages view allows browsing all server collected MQTT messages for registered topics. These can be regular messages (without push notification) or push messages which have already been received via push. Messages can be deleted locally on the device. The main app window shows the server connections with the number of new/unread messages.

The dashboard view has a graphical user interface in which display and control elements (“dashes”) can be created. These dashes can be used to monitor and control any actions, such as switching lights, temperature display, weather, light color, heating control, home automation, to name just a few possibilities. Dash controls offer switches, sliders, text display, selection lists and web views, which are displayed as groupable interactive tiles.

## Prerequisites to test drive app
![App icon](/docs/readme/app_icon.png)

The app can be downloaded from the app store (Google Play Store or Apple App Store) which is the easiest way to test drive it. This app has been designed as an addition to an existing MQTT environment and provides an easy-to-use interface with the ability to receive MQTT messages as push notifications.


Required MQTT server:

* Access to an MQTT server that manages the messages you want to receive or send using the app, as well as the corresponding user name and password
* Devices or sensors for MQTT message exchange
* Information about the MQTT topics used and their message content (message structure)

If no own MQTT server is available, a public MQTT server, for example from Arduino Hannover, can be used. At mqtt.arduino-hannover.de an account for the MQTT server can be created.

The MQTT push server “push.radioshuttle.de” is already preset when setting up a new server connection and can be used with any MQTT server.


## Supported iOS devices
The MQTT Push Client app runs on iOS 10.3 and later.

## License and contributions
The software is provided under the [Apache 2.0 license](/docs/readme/LICENSE-apache-2.0.txt). Contributions to this project are accepted under the same license.

## Development prerequisites
* Xcode 9.4 or later
* [CocoaPods](https://cocoapods.org) version 1.5.3 or later 
* Objective-C programming language skills
* iOS development experience
* Apple Developer account (needed for running the app on a real device)

### Getting Started
* Check out (clone) this project
* On the command line, run “pod install” in the MQTTPushClient_iOS directory to install the required dependencies
* Open “MQTTPushClient.xcworkspace” in Xcode
* Build and run the project

You can test the MQTT Push Client app in the iOS Simulator

## Run the app on a real device, or publish an own app on the Apple App Store

 In order to run the app on a real device, or to publish it on the Apple App Store, the following changes are necessary:

* Add your Apple ID in the Xcode Accounts preferences.
* In the “Signing & Capabilities” settings of both targets “MQTTPushClient” and “MQTTPushClientServiceExtension” make the following changes:
   - In the “Team” popup, select your development team
   - Replace the bundle identifier and the app groups identifier by unique identifiers for your company
   - In the Shared/SharedConstants.m file, replace the value of `kSharedAppGroup` by your app groups identifier

## RadioShuttle MQTT push server
This app requires communication with the RadioShuttle MQTT push server. For non-commercial users, the use of the public push server (push.radioshuttle.de) is currently free of charge up to 3 mobile devices and 3 MQTT accounts.
RadioShuttle licensees, i.e. RadioShuttle board customers, can permanently benefit from this service free of charge.

Unlimited commercial use of the RadioShuttle MQTT push server software for operation on your own servers is available for an annual software rental with support included. An own deployment of the RadioShuttle MQTT push server (server written in Java) requires Apple or Google push certificates.

## MQTT push solution background
Apps that are permanently polling connections from mobile apps to MQTT servers do not work due to their high energy requirement and constant mobile network changes. Users wish to receive messages on their mobile devices, whether or not the app is running. Even when the mobile device is turned off, or there is no Internet connection, messages should arrive automatically once the device is online again.

The RadioShuttle MQTT push solution implements this via the RadioShuttle MQTT push server and its corresponding MQTT Push Client apps for Android and iOS. The app communicates via the MQTT push server only. The MQTT push server monitors the MQTT messages for the specified accounts and sends push messages via Google (Android) and Apple (iOS) to corresponding mobile devices connected to this account. In addition, the server keeps the last 100 MQTT push messages for each account.

The mobile device receives and displays push messages even if the app is not running. Once the app is started, it will display received messages in its messages view. At the same time it will update the latest messages from the MQTT push server to ensure that it is up to date.

The dashboard view will not connect to the MQTT server for the dash gallery view, instead it will communicate with the MQTT push server only. The MQTT push server remembers the latest message for each registered topic, therefore the display should represent the latest data (e.g. lights on or off, temperature, etc.).

The entire solution is highly optimized for great performance and reliable push messages without any polling. As push messages are being processed by Google and Apple, the amount of push messages per day should be limited to a reasonable number per account (e.g. 50 messages per day). The MQTT push server will limit the push messages per account to not more than one message within 20 seconds. In case of too many messages, it will delay push messages to avoid spamming.

## Security
The communication between the app and the MQTT push server is SSL encrypted. The MQTT server credentials (username and password) are locally stored in the app data, which are secured by the mobile operating system. The MQTT server credentials are also transferred to the MQTT push server to be used for communication with the MQTT server. The MQTT push server saves the credentials and its configuration encrypted to ensure that noone (even not admins) can access these.

After an account is removed within the app on all authorized devices, the account on the MQTT push server will be removed as well.

Received MQTT messages are stored encrypted on the MQTT push server.

The MQTT push server can be licensed (subscription based) to be deployed on own servers and used with an own version of the MQTT Push Client app. This would allow deploying it completely independent of RadioShuttle.de, however developer certificates from Google and Android are required for sending push messages.

The server operator of the MQTT push server can send direct messages to the app, to inform users about errors or other information.

## Credits
This app has initially been written by the RadioShuttle engineers (www.radioshuttle.de). Many thanks to everyone who helped to bring this project forward.

## Related links
* App online help project: https://github.com/RadioShuttle/MQTTPushClient_iOS
* App for Android project: https://github.com/RadioShuttle/MQTTPushClient_Android

## Acknowledgements
We used external resources, libraries and code, many thanks to:
* Google Material Icons: https://material.io/resources/icons/
* Firebase Cloud messaging: https://firebase.google.com/docs/cloudmessaging
