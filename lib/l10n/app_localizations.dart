import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI-Based Breast Cancer Detection App'**
  String get appTitle;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission:'**
  String get ourMission;

  /// No description provided for @ourMissionDesc.
  ///
  /// In en, this message translates to:
  /// **'We are committed to empowering women through early breast cancer awareness and diagnosis using artificial intelligence.'**
  String get ourMissionDesc;

  /// No description provided for @whatWeDo.
  ///
  /// In en, this message translates to:
  /// **'What We Do:'**
  String get whatWeDo;

  /// No description provided for @whatWeDoDesc.
  ///
  /// In en, this message translates to:
  /// **'BreaScan AI is an intelligent mobile app that analyzes microscopic breast tissue images using advanced DL models.'**
  String get whatWeDoDesc;

  /// No description provided for @failedToLoadUserData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user data:'**
  String get failedToLoadUserData;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcement;

  /// No description provided for @failedToLoadAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Failed to load announcements.'**
  String get failedToLoadAnnouncements;

  /// No description provided for @showingLatestLoadedAnnouncementsTempIssue.
  ///
  /// In en, this message translates to:
  /// **'Showing latest loaded announcements (temporary issue).'**
  String get showingLatestLoadedAnnouncementsTempIssue;

  /// No description provided for @showingCachedAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Showing latest loaded announcements (temporary issue).'**
  String get showingCachedAnnouncements;

  /// No description provided for @noAnnouncementYet.
  ///
  /// In en, this message translates to:
  /// **'No announcement yet!'**
  String get noAnnouncementYet;

  /// No description provided for @newAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'You have received a new announcement.'**
  String get newAnnouncement;

  /// No description provided for @forAudiencePrefix.
  ///
  /// In en, this message translates to:
  /// **'For:'**
  String get forAudiencePrefix;

  /// No description provided for @forAudience.
  ///
  /// In en, this message translates to:
  /// **'For: {audience}'**
  String forAudience(String audience);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotificationYet.
  ///
  /// In en, this message translates to:
  /// **'No notification yet!'**
  String get noNotificationYet;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @unreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unreadLabel;

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read All'**
  String get readAll;

  /// No description provided for @noUnreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications found.'**
  String get noUnreadNotifications;

  /// No description provided for @allNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read.'**
  String get allNotificationsRead;

  /// No description provided for @allNotificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read.'**
  String get allNotificationsMarkedRead;

  /// No description provided for @defaultNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'You have received a new notification.'**
  String get defaultNotificationMessage;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in.'**
  String get userNotLoggedIn;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get notLoggedIn;

  /// No description provided for @pleaseLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Please login again.'**
  String get pleaseLoginAgain;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please login first.'**
  String get pleaseLoginFirst;

  /// No description provided for @incompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get incompleteProfileTitle;

  /// No description provided for @incompleteProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Your profile is incomplete. Please add Age, Marital Status, Medication and Cancer in family.'**
  String get incompleteProfileDesc;

  /// No description provided for @completeNow.
  ///
  /// In en, this message translates to:
  /// **'Complete Now'**
  String get completeNow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @openProfileFromBottomNav.
  ///
  /// In en, this message translates to:
  /// **'Open Patient Profile tab from bottom nav'**
  String get openProfileFromBottomNav;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectedMessage.
  ///
  /// In en, this message translates to:
  /// **'You are now connected with each other.'**
  String get connectedMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type Message'**
  String get typeMessage;

  /// No description provided for @chatNow.
  ///
  /// In en, this message translates to:
  /// **'Chat Now'**
  String get chatNow;

  /// No description provided for @chatRoom.
  ///
  /// In en, this message translates to:
  /// **'Chat Room'**
  String get chatRoom;

  /// No description provided for @chatRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Room'**
  String get chatRoomTitle;

  /// No description provided for @chatRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Requests'**
  String get chatRequestsTitle;

  /// No description provided for @chatARequest.
  ///
  /// In en, this message translates to:
  /// **'Chat Request'**
  String get chatARequest;

  /// No description provided for @viewChatRequest.
  ///
  /// In en, this message translates to:
  /// **'View Chat Request'**
  String get viewChatRequest;

  /// No description provided for @requestChat.
  ///
  /// In en, this message translates to:
  /// **'Request a Chat'**
  String get requestChat;

  /// No description provided for @noApprovedDoctorFound.
  ///
  /// In en, this message translates to:
  /// **'No approved doctor found yet.'**
  String get noApprovedDoctorFound;

  /// No description provided for @noDoctorsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No doctors available right now! We’ll notify you as soon as a doctor is available.'**
  String get noDoctorsAvailable;

  /// No description provided for @noChatAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No chat available yet.'**
  String get noChatAvailableYet;

  /// No description provided for @noChatYet.
  ///
  /// In en, this message translates to:
  /// **'No chat yet!'**
  String get noChatYet;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet!'**
  String get noMessagesYet;

  /// No description provided for @chatErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat error:'**
  String get chatErrorLabel;

  /// No description provided for @chatErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Chat error'**
  String get chatErrorPrefix;

  /// No description provided for @chatTipLongPressImage.
  ///
  /// In en, this message translates to:
  /// **'Tip: Long-press an image bubble to see HTTP error details.'**
  String get chatTipLongPressImage;

  /// No description provided for @lastMessageImage.
  ///
  /// In en, this message translates to:
  /// **'📷 Image'**
  String get lastMessageImage;

  /// No description provided for @lastMessagePdf.
  ///
  /// In en, this message translates to:
  /// **'📄 PDF'**
  String get lastMessagePdf;

  /// No description provided for @patientFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientFallbackName;

  /// No description provided for @doctorFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorFallbackName;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @viewMedia.
  ///
  /// In en, this message translates to:
  /// **'View Media'**
  String get viewMedia;

  /// No description provided for @viewMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'View Media'**
  String get viewMediaTitle;

  /// No description provided for @imageGallery.
  ///
  /// In en, this message translates to:
  /// **'Image (Gallery)'**
  String get imageGallery;

  /// No description provided for @imageCamera.
  ///
  /// In en, this message translates to:
  /// **'Image (Camera)'**
  String get imageCamera;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @pdfDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get pdfDocument;

  /// No description provided for @sendFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get sendFailedTitle;

  /// No description provided for @uploadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Failed'**
  String get uploadFailedTitle;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @pdfErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF Error'**
  String get pdfErrorTitle;

  /// No description provided for @unableToReadPdfBytes.
  ///
  /// In en, this message translates to:
  /// **'Unable to read PDF bytes.'**
  String get unableToReadPdfBytes;

  /// No description provided for @invalidFileUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid file URL'**
  String get invalidFileUrl;

  /// No description provided for @couldNotOpenFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not open file'**
  String get couldNotOpenFileTitle;

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file.'**
  String get couldNotOpenFile;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image.'**
  String get failedToLoadImage;

  /// No description provided for @failedToLoadImageNoPeriod.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImageNoPeriod;

  /// No description provided for @failedToLoadImageShort.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImageShort;

  /// No description provided for @tapBelowToSeeWhy.
  ///
  /// In en, this message translates to:
  /// **'Tap below to see why (HTTP details).'**
  String get tapBelowToSeeWhy;

  /// No description provided for @showErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Error Details'**
  String get showErrorDetails;

  /// No description provided for @holdToDebug.
  ///
  /// In en, this message translates to:
  /// **'Hold to debug'**
  String get holdToDebug;

  /// No description provided for @stackLabel.
  ///
  /// In en, this message translates to:
  /// **'Stack'**
  String get stackLabel;

  /// No description provided for @invalidUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrlTitle;

  /// No description provided for @invalidUrlDesc.
  ///
  /// In en, this message translates to:
  /// **'The stored URL is empty or malformed.'**
  String get invalidUrlDesc;

  /// No description provided for @fileLoadDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'File Load Debug'**
  String get fileLoadDebugTitle;

  /// No description provided for @requestFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Failed'**
  String get requestFailedTitle;

  /// No description provided for @httpStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'HTTP Status:'**
  String get httpStatusLabel;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL:'**
  String get urlLabel;

  /// No description provided for @headersLabel.
  ///
  /// In en, this message translates to:
  /// **'Headers:'**
  String get headersLabel;

  /// No description provided for @bodyPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Body Preview:'**
  String get bodyPreviewLabel;

  /// No description provided for @rawLabel.
  ///
  /// In en, this message translates to:
  /// **'raw:'**
  String get rawLabel;

  /// No description provided for @fixedLabel.
  ///
  /// In en, this message translates to:
  /// **'fixed:'**
  String get fixedLabel;

  /// No description provided for @imageFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Failed'**
  String get imageFailedTitle;

  /// No description provided for @requestErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Request error:'**
  String get requestErrorLabel;

  /// No description provided for @flutterErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Flutter error:'**
  String get flutterErrorLabel;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @yourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Your Feedback'**
  String get yourFeedback;

  /// No description provided for @adminResponse.
  ///
  /// In en, this message translates to:
  /// **'Admin Response:'**
  String get adminResponse;

  /// No description provided for @noResponseYet.
  ///
  /// In en, this message translates to:
  /// **'No response yet.'**
  String get noResponseYet;

  /// No description provided for @noFeedbackYet.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet!'**
  String get noFeedbackYet;

  /// No description provided for @addFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Feedback'**
  String get addFeedbackTitle;

  /// No description provided for @addFeedback.
  ///
  /// In en, this message translates to:
  /// **'Add Feedback'**
  String get addFeedback;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Message:'**
  String get yourMessage;

  /// No description provided for @pleaseWriteFeedbackFirst.
  ///
  /// In en, this message translates to:
  /// **'Please write feedback first.'**
  String get pleaseWriteFeedbackFirst;

  /// No description provided for @feedbackSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent successfully!'**
  String get feedbackSentSuccessfully;

  /// No description provided for @feedbackUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Feedback updated successfully!'**
  String get feedbackUpdatedSuccessfully;

  /// No description provided for @feedbackDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Feedback deleted successfully!'**
  String get feedbackDeletedSuccessfully;

  /// No description provided for @failedToSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Failed to send feedback'**
  String get failedToSendFeedback;

  /// No description provided for @errorUpdatingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Error updating feedback'**
  String get errorUpdatingFeedback;

  /// No description provided for @failedToDeleteFeedback.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete feedback'**
  String get failedToDeleteFeedback;

  /// No description provided for @cantEditAdminResponded.
  ///
  /// In en, this message translates to:
  /// **'You can’t edit because admin already responded.'**
  String get cantEditAdminResponded;

  /// No description provided for @cantDeleteAdminResponded.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete because admin already responded.'**
  String get cantDeleteAdminResponded;

  /// No description provided for @editFeedback.
  ///
  /// In en, this message translates to:
  /// **'Edit Feedback'**
  String get editFeedback;

  /// No description provided for @updateYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Update your message...'**
  String get updateYourMessage;

  /// No description provided for @messageCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Message cannot be empty.'**
  String get messageCannotBeEmpty;

  /// No description provided for @deleteFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Feedback'**
  String get deleteFeedbackTitle;

  /// No description provided for @deleteFeedbackConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this feedback?'**
  String get deleteFeedbackConfirm;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Write your feedback here...'**
  String get feedbackHint;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @cancelUpper.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelUpper;

  /// No description provided for @updateUpper.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get updateUpper;

  /// No description provided for @fbLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get fbLoginTitle;

  /// No description provided for @fbEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get fbEmptyTitle;

  /// No description provided for @fbEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Please write feedback first.'**
  String get fbEmptyDesc;

  /// No description provided for @fbSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get fbSuccessTitle;

  /// No description provided for @fbSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent successfully!'**
  String get fbSuccessDesc;

  /// No description provided for @fbFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get fbFailedTitle;

  /// No description provided for @fbFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Failed to send feedback.'**
  String get fbFailedDesc;

  /// No description provided for @fbUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get fbUpdatedTitle;

  /// No description provided for @fbUpdatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Feedback updated.'**
  String get fbUpdatedDesc;

  /// No description provided for @fbDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get fbDeletedTitle;

  /// No description provided for @fbDeletedDesc.
  ///
  /// In en, this message translates to:
  /// **'Feedback deleted.'**
  String get fbDeletedDesc;

  /// No description provided for @fbLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get fbLockedTitle;

  /// No description provided for @fbLockedEditDesc.
  ///
  /// In en, this message translates to:
  /// **'You can’t edit because admin already responded.'**
  String get fbLockedEditDesc;

  /// No description provided for @fbLockedDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete because admin already responded.'**
  String get fbLockedDeleteDesc;

  /// No description provided for @fbEditDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Feedback'**
  String get fbEditDialogTitle;

  /// No description provided for @fbDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get fbDeleteTitle;

  /// No description provided for @fbDeleteConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this feedback?'**
  String get fbDeleteConfirmDesc;

  /// No description provided for @fbNotifyAdminsNewFeedback.
  ///
  /// In en, this message translates to:
  /// **'New patient feedback received.'**
  String get fbNotifyAdminsNewFeedback;

  /// No description provided for @fbNotifyAdminsUpdated.
  ///
  /// In en, this message translates to:
  /// **'A patient updated their feedback.'**
  String get fbNotifyAdminsUpdated;

  /// No description provided for @fbNotifyAdminsDeleted.
  ///
  /// In en, this message translates to:
  /// **'A patient deleted their feedback.'**
  String get fbNotifyAdminsDeleted;

  /// No description provided for @fbNotifyUserSent.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been sent to admin.'**
  String get fbNotifyUserSent;

  /// No description provided for @fbNotifyUserUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been updated.'**
  String get fbNotifyUserUpdated;

  /// No description provided for @fbNotifyUserDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been deleted.'**
  String get fbNotifyUserDeleted;

  /// No description provided for @patientProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient Profile'**
  String get patientProfileTitle;

  /// No description provided for @patientProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Patient profile not found.'**
  String get patientProfileNotFound;

  /// No description provided for @patientDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Patient data not found.'**
  String get patientDataNotFound;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @enterAge.
  ///
  /// In en, this message translates to:
  /// **'Enter age'**
  String get enterAge;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @maritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital Status'**
  String get maritalStatus;

  /// No description provided for @anyMedication.
  ///
  /// In en, this message translates to:
  /// **'Any Medication'**
  String get anyMedication;

  /// No description provided for @cancerInFamily.
  ///
  /// In en, this message translates to:
  /// **'Cancer in family?'**
  String get cancerInFamily;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get single;

  /// No description provided for @married.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get married;

  /// No description provided for @validation.
  ///
  /// In en, this message translates to:
  /// **'Validation'**
  String get validation;

  /// No description provided for @profileIncompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Your profile is incomplete.'**
  String get profileIncompleteDesc;

  /// No description provided for @profileFixHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields.'**
  String get profileFixHighlighted;

  /// No description provided for @fixHighlightedFields.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields.'**
  String get fixHighlightedFields;

  /// No description provided for @profileLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Please login again.'**
  String get profileLoginAgain;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save Failed'**
  String get saveFailed;

  /// No description provided for @failedToSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile.'**
  String get failedToSaveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile Saved ✅'**
  String get profileSaved;

  /// No description provided for @profileSavedIncompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Profile saved, but some fields are still incomplete.'**
  String get profileSavedIncompleteDesc;

  /// No description provided for @profileCompleted.
  ///
  /// In en, this message translates to:
  /// **'Profile Completed ✅'**
  String get profileCompleted;

  /// No description provided for @profileCompletedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your profile is completed successfully.'**
  String get profileCompletedDesc;

  /// No description provided for @profileCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Completed ✅'**
  String get profileCompletedTitle;

  /// No description provided for @profileSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Saved ✅'**
  String get profileSavedTitle;

  /// No description provided for @profileSavedDesc.
  ///
  /// In en, this message translates to:
  /// **'Saved, but still incomplete.'**
  String get profileSavedDesc;

  /// No description provided for @profileSaveFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile.'**
  String get profileSaveFailedDesc;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get profileNameRequired;

  /// No description provided for @profileNameMin2.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get profileNameMin2;

  /// No description provided for @profileNameLettersOnly.
  ///
  /// In en, this message translates to:
  /// **'Name must contain only letters and spaces'**
  String get profileNameLettersOnly;

  /// No description provided for @profileEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get profileEmailRequired;

  /// No description provided for @profileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get profileEmailInvalid;

  /// No description provided for @profileAgeRequired.
  ///
  /// In en, this message translates to:
  /// **'Age is required'**
  String get profileAgeRequired;

  /// No description provided for @profileAgeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid age'**
  String get profileAgeInvalid;

  /// No description provided for @profileAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Age must be between 10 and 120'**
  String get profileAgeRange;

  /// No description provided for @profileFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String profileFieldRequired(Object fieldName);

  /// No description provided for @doctorNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Doctor not logged in!'**
  String get doctorNotLoggedIn;

  /// No description provided for @doctorNotLoggedInBang.
  ///
  /// In en, this message translates to:
  /// **'Doctor not logged in!'**
  String get doctorNotLoggedInBang;

  /// No description provided for @approvedPatients.
  ///
  /// In en, this message translates to:
  /// **'Approved Patients'**
  String get approvedPatients;

  /// No description provided for @noApprovedPatientsYet.
  ///
  /// In en, this message translates to:
  /// **'No approved patients yet!'**
  String get noApprovedPatientsYet;

  /// No description provided for @pleaseSelectPatientFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a patient first.'**
  String get pleaseSelectPatientFirst;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message.'**
  String get failedToSendMessage;

  /// No description provided for @approvedDoctors.
  ///
  /// In en, this message translates to:
  /// **'Approved Doctors'**
  String get approvedDoctors;

  /// No description provided for @sendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Sending request...'**
  String get sendingRequest;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successTitle;

  /// No description provided for @requestSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully!'**
  String get requestSentSuccessfully;

  /// No description provided for @pleaseSelectDoctorFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a doctor first.'**
  String get pleaseSelectDoctorFirst;

  /// No description provided for @alreadyRequestedDoctor.
  ///
  /// In en, this message translates to:
  /// **'You already requested this doctor.'**
  String get alreadyRequestedDoctor;

  /// No description provided for @failedToSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request.'**
  String get failedToSendRequest;

  /// No description provided for @queryErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Query error:'**
  String get queryErrorPrefix;

  /// No description provided for @noRequestYet.
  ///
  /// In en, this message translates to:
  /// **'No request yet!'**
  String get noRequestYet;

  /// No description provided for @approveRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Request'**
  String get approveRequestTitle;

  /// No description provided for @approveRequestDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve {name}?'**
  String approveRequestDesc(String name);

  /// No description provided for @rejectRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get rejectRequestTitle;

  /// No description provided for @rejectRequestDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject {name}?'**
  String rejectRequestDesc(String name);

  /// No description provided for @requestApprovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request approved successfully!'**
  String get requestApprovedSuccessfully;

  /// No description provided for @requestRejectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request rejected successfully!'**
  String get requestRejectedSuccessfully;

  /// No description provided for @failedToUpdateRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to update request. Try again.'**
  String get failedToUpdateRequest;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploadExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Exercise'**
  String get uploadExerciseTitle;

  /// No description provided for @uploadExercise.
  ///
  /// In en, this message translates to:
  /// **'Upload Exercise'**
  String get uploadExercise;

  /// No description provided for @selectMediaLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Media (Image / Video)'**
  String get selectMediaLabel;

  /// No description provided for @tapToPickMedia.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick image/video'**
  String get tapToPickMedia;

  /// No description provided for @couldNotReadFilePath.
  ///
  /// In en, this message translates to:
  /// **'Could not read file path. Try again.'**
  String get couldNotReadFilePath;

  /// No description provided for @onlyImagesAndVideosAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only images and videos are allowed.'**
  String get onlyImagesAndVideosAllowed;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large'**
  String get fileTooLarge;

  /// No description provided for @maxAllowed.
  ///
  /// In en, this message translates to:
  /// **'Max allowed'**
  String get maxAllowed;

  /// No description provided for @pickFailed.
  ///
  /// In en, this message translates to:
  /// **'Pick failed'**
  String get pickFailed;

  /// No description provided for @selectedFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Selected file is empty.'**
  String get selectedFileEmpty;

  /// No description provided for @fileTooLargeBytes.
  ///
  /// In en, this message translates to:
  /// **'File too large'**
  String get fileTooLargeBytes;

  /// No description provided for @maxAllowedBytes.
  ///
  /// In en, this message translates to:
  /// **'Max allowed'**
  String get maxAllowedBytes;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter title.'**
  String get pleaseEnterTitle;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter description.'**
  String get pleaseEnterDescription;

  /// No description provided for @pleaseSelectMediaFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select an image or video first.'**
  String get pleaseSelectMediaFirst;

  /// No description provided for @pleaseRepickFile.
  ///
  /// In en, this message translates to:
  /// **'Please re-pick the file.'**
  String get pleaseRepickFile;

  /// No description provided for @uploadReturnedEmptyUrl.
  ///
  /// In en, this message translates to:
  /// **'Upload succeeded but server returned empty url/path.'**
  String get uploadReturnedEmptyUrl;

  /// No description provided for @exerciseUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Exercise uploaded successfully!'**
  String get exerciseUploadedSuccessfully;

  /// No description provided for @videoFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Video failed to load'**
  String get videoFailedToLoad;

  /// No description provided for @manageUploads.
  ///
  /// In en, this message translates to:
  /// **'Manage Uploads'**
  String get manageUploads;

  /// No description provided for @noUploadsYet.
  ///
  /// In en, this message translates to:
  /// **'No uploads yet!'**
  String get noUploadsYet;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @editUpload.
  ///
  /// In en, this message translates to:
  /// **'Edit Upload'**
  String get editUpload;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @deletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedTitle;

  /// No description provided for @uploadDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Upload deleted successfully.'**
  String get uploadDeletedSuccessfully;

  /// No description provided for @updatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Updated ✅'**
  String get updatedTitle;

  /// No description provided for @uploadUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Upload updated successfully.'**
  String get uploadUpdatedSuccessfully;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @manageOwnUploadsOnly.
  ///
  /// In en, this message translates to:
  /// **'You can only manage your own uploads.'**
  String get manageOwnUploadsOnly;

  /// No description provided for @missingFilePathReupload.
  ///
  /// In en, this message translates to:
  /// **'Missing filePath in Firestore. Please re-upload this media.'**
  String get missingFilePathReupload;

  /// No description provided for @mediaTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'VIDEO'**
  String get mediaTypeVideo;

  /// No description provided for @mediaTypeImage.
  ///
  /// In en, this message translates to:
  /// **'IMAGE'**
  String get mediaTypeImage;

  /// No description provided for @noDescriptionDash.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get noDescriptionDash;

  /// No description provided for @titleLabelPlain.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabelPlain;

  /// No description provided for @descriptionLabelPlain.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabelPlain;

  /// No description provided for @invalidMediaUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid media URL'**
  String get invalidMediaUrl;

  /// No description provided for @doctorNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor Notifications'**
  String get doctorNotificationsTitle;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @completeProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Add experience, specialization, qualification and description to complete your doctor profile.'**
  String get completeProfileDesc;

  /// No description provided for @yourProfileIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Your profile is incomplete.'**
  String get yourProfileIncomplete;

  /// No description provided for @manageDoctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Manage Doctor Profile'**
  String get manageDoctorProfile;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get enterFirstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @enterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get enterLastName;

  /// No description provided for @emailReadonly.
  ///
  /// In en, this message translates to:
  /// **'Email (Read-only)'**
  String get emailReadonly;

  /// No description provided for @experienceYears.
  ///
  /// In en, this message translates to:
  /// **'Experience (Years)'**
  String get experienceYears;

  /// No description provided for @enterExperience.
  ///
  /// In en, this message translates to:
  /// **'Enter years of experience'**
  String get enterExperience;

  /// No description provided for @specialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specialization;

  /// No description provided for @enterSpecialization.
  ///
  /// In en, this message translates to:
  /// **'e.g. Physiotherapist'**
  String get enterSpecialization;

  /// No description provided for @qualification.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get qualification;

  /// No description provided for @enterQualification.
  ///
  /// In en, this message translates to:
  /// **'e.g. MBBS FCPS'**
  String get enterQualification;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @enterDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write about yourself (min 20 chars)'**
  String get enterDescriptionHint;

  /// No description provided for @imageError.
  ///
  /// In en, this message translates to:
  /// **'Image Error'**
  String get imageError;

  /// No description provided for @couldNotPickImage.
  ///
  /// In en, this message translates to:
  /// **'Could not pick image.'**
  String get couldNotPickImage;

  /// No description provided for @profileImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile image upload failed.'**
  String get profileImageUploadFailed;

  /// No description provided for @doctorProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctorProfileTitle;

  /// No description provided for @doctorLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorLabel;

  /// No description provided for @doctorBio.
  ///
  /// In en, this message translates to:
  /// **'I am a board-certified oncologist specializing in breast cancer diagnosis and treatment. I focus on patient-centered care and early detection.'**
  String get doctorBio;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @qualifications.
  ///
  /// In en, this message translates to:
  /// **'Qualifications'**
  String get qualifications;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @logoutConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmDesc;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout Failed'**
  String get logoutFailed;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @manageProfile.
  ///
  /// In en, this message translates to:
  /// **'Manage Profile'**
  String get manageProfile;

  /// No description provided for @resetPasswordOptional.
  ///
  /// In en, this message translates to:
  /// **'Reset Password (Optional)'**
  String get resetPasswordOptional;

  /// No description provided for @emailMissingAt.
  ///
  /// In en, this message translates to:
  /// **'Your email does not contain @. Please include @.'**
  String get emailMissingAt;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password can\'t be less than 8 characters'**
  String get passwordTooShort;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @languageUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Updated 🎉'**
  String get languageUpdatedTitle;

  /// No description provided for @languageUpdatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your app language has been changed to {lang} successfully!'**
  String languageUpdatedDesc(String lang);

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @selectYourImages.
  ///
  /// In en, this message translates to:
  /// **'Select your images'**
  String get selectYourImages;

  /// No description provided for @selectImages.
  ///
  /// In en, this message translates to:
  /// **'Select images'**
  String get selectImages;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note:'**
  String get note;

  /// No description provided for @uploadNoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Simply upload your breast tissue microscope images at any magnification (40×, 100×, 200×, or 400×) and let our AI help identify the cancer type.'**
  String get uploadNoteDesc;

  /// No description provided for @startDiagnoses.
  ///
  /// In en, this message translates to:
  /// **'Start Diagnoses'**
  String get startDiagnoses;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLabel;

  /// No description provided for @selectAtLeastOneImage.
  ///
  /// In en, this message translates to:
  /// **'Please select at least 1 image.'**
  String get selectAtLeastOneImage;

  /// No description provided for @startingDiagnoses.
  ///
  /// In en, this message translates to:
  /// **'Starting diagnoses...'**
  String get startingDiagnoses;

  /// No description provided for @invalidImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid Image'**
  String get invalidImageTitle;

  /// No description provided for @invalidImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Only breast tissue microscope images are allowed.\nRandom photos (watch, guitar, glass, etc.) are rejected.'**
  String get invalidImageDesc;

  /// No description provided for @limitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get limitReachedTitle;

  /// No description provided for @limitReachedDesc.
  ///
  /// In en, this message translates to:
  /// **'You can select maximum 4 images.'**
  String get limitReachedDesc;

  /// No description provided for @scanFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan image:'**
  String get scanFailedDesc;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @modelLoadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Model loading failed:'**
  String get modelLoadingFailed;

  /// No description provided for @modelsNotReadyYet.
  ///
  /// In en, this message translates to:
  /// **'Models are not ready yet...'**
  String get modelsNotReadyYet;

  /// No description provided for @loadingModel.
  ///
  /// In en, this message translates to:
  /// **'Loading model...'**
  String get loadingModel;

  /// No description provided for @resultCancerous.
  ///
  /// In en, this message translates to:
  /// **'Cancerous'**
  String get resultCancerous;

  /// No description provided for @resultNotCancerous.
  ///
  /// In en, this message translates to:
  /// **'Not Cancerous'**
  String get resultNotCancerous;

  /// No description provided for @predictionLabel.
  ///
  /// In en, this message translates to:
  /// **'Prediction'**
  String get predictionLabel;

  /// No description provided for @confidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidenceLabel;

  /// No description provided for @myReport.
  ///
  /// In en, this message translates to:
  /// **'My Report'**
  String get myReport;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet!'**
  String get noReportsYet;

  /// No description provided for @pleaseLoginToViewReports.
  ///
  /// In en, this message translates to:
  /// **'Please login to view reports.'**
  String get pleaseLoginToViewReports;

  /// No description provided for @failedToLoadReports.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reports:'**
  String get failedToLoadReports;

  /// No description provided for @imageReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Reports'**
  String get imageReportsTitle;

  /// No description provided for @symptomReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptom Reports'**
  String get symptomReportsTitle;

  /// No description provided for @noSymptomReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No symptom assessment reports yet.'**
  String get noSymptomReportsYet;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get viewReport;

  /// No description provided for @statusMalignant.
  ///
  /// In en, this message translates to:
  /// **'Malignant'**
  String get statusMalignant;

  /// No description provided for @statusBenign.
  ///
  /// In en, this message translates to:
  /// **'Benign'**
  String get statusBenign;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @riskLevel.
  ///
  /// In en, this message translates to:
  /// **'Risk level'**
  String get riskLevel;

  /// No description provided for @likelihoodMeter.
  ///
  /// In en, this message translates to:
  /// **'Likelihood meter'**
  String get likelihoodMeter;

  /// No description provided for @riskLowConcern.
  ///
  /// In en, this message translates to:
  /// **'Low concern'**
  String get riskLowConcern;

  /// No description provided for @riskMildConcern.
  ///
  /// In en, this message translates to:
  /// **'Mild concern'**
  String get riskMildConcern;

  /// No description provided for @riskReviewRecommended.
  ///
  /// In en, this message translates to:
  /// **'Review recommended'**
  String get riskReviewRecommended;

  /// No description provided for @riskModerateConcern.
  ///
  /// In en, this message translates to:
  /// **'Moderate concern'**
  String get riskModerateConcern;

  /// No description provided for @riskHighConcern.
  ///
  /// In en, this message translates to:
  /// **'High concern'**
  String get riskHighConcern;

  /// No description provided for @riskReviewUrgently.
  ///
  /// In en, this message translates to:
  /// **'Review urgently'**
  String get riskReviewUrgently;

  /// No description provided for @refreshImages.
  ///
  /// In en, this message translates to:
  /// **'Refresh Images'**
  String get refreshImages;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @failedToLoadImages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load images.'**
  String get failedToLoadImages;

  /// No description provided for @noImagesForReport.
  ///
  /// In en, this message translates to:
  /// **'No images available for this report.'**
  String get noImagesForReport;

  /// No description provided for @reportImages.
  ///
  /// In en, this message translates to:
  /// **'Report Images'**
  String get reportImages;

  /// No description provided for @breastHealthReport.
  ///
  /// In en, this message translates to:
  /// **'Breast Health Report'**
  String get breastHealthReport;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis:'**
  String get diagnosis;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type:'**
  String get typeLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get dateLabel;

  /// No description provided for @whatThisMeansTitle.
  ///
  /// In en, this message translates to:
  /// **'What this means'**
  String get whatThisMeansTitle;

  /// No description provided for @commonSymptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Common symptoms'**
  String get commonSymptomsTitle;

  /// No description provided for @riskFactorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible causes / risk factors'**
  String get riskFactorsTitle;

  /// No description provided for @nextStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended next steps'**
  String get nextStepsTitle;

  /// No description provided for @resultTypeMalignant.
  ///
  /// In en, this message translates to:
  /// **'Result Type: Malignant (cancerous pattern)'**
  String get resultTypeMalignant;

  /// No description provided for @resultTypeBenign.
  ///
  /// In en, this message translates to:
  /// **'Result Type: Benign (non-cancerous pattern)'**
  String get resultTypeBenign;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer: This AI report is an assistive tool and does not replace clinical diagnosis.'**
  String get disclaimer;

  /// No description provided for @pdfReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF Ready'**
  String get pdfReadyTitle;

  /// No description provided for @pdfReadyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your report PDF has been generated.'**
  String get pdfReadyDesc;

  /// No description provided for @symptomDiagnosisTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptom Diagnosis'**
  String get symptomDiagnosisTitle;

  /// No description provided for @symptomAssessmentReportPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptom Assessment Report'**
  String get symptomAssessmentReportPdfTitle;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @riskLabel.
  ///
  /// In en, this message translates to:
  /// **'Risk'**
  String get riskLabel;

  /// No description provided for @urgencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgencyLabel;

  /// No description provided for @keyFindingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Findings'**
  String get keyFindingsTitle;

  /// No description provided for @recommendedTestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended Tests'**
  String get recommendedTestsTitle;

  /// No description provided for @diagnoseSymptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnose Symptoms'**
  String get diagnoseSymptomsTitle;

  /// No description provided for @pageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pageLabel;

  /// No description provided for @pleaseAnswerAllQuestions.
  ///
  /// In en, this message translates to:
  /// **'Please answer all questions on this page to continue.'**
  String get pleaseAnswerAllQuestions;

  /// No description provided for @symptomsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Symptoms saved successfully.'**
  String get symptomsSavedSuccessfully;

  /// No description provided for @failedToSaveSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Failed to save symptoms:'**
  String get failedToSaveSymptoms;

  /// No description provided for @symptomQ1.
  ///
  /// In en, this message translates to:
  /// **'Do you feel a new lump or thickening in the breast?'**
  String get symptomQ1;

  /// No description provided for @symptomQ2.
  ///
  /// In en, this message translates to:
  /// **'Do you feel a lump or swelling in the underarm area?'**
  String get symptomQ2;

  /// No description provided for @symptomQ3.
  ///
  /// In en, this message translates to:
  /// **'Have you noticed a change in the size of one breast?'**
  String get symptomQ3;

  /// No description provided for @symptomQ4.
  ///
  /// In en, this message translates to:
  /// **'Have you noticed a change in the shape of one breast?'**
  String get symptomQ4;

  /// No description provided for @symptomQ5.
  ///
  /// In en, this message translates to:
  /// **'Is one breast suddenly looking different from the other?'**
  String get symptomQ5;

  /// No description provided for @symptomQ6.
  ///
  /// In en, this message translates to:
  /// **'Do you feel heaviness in one breast?'**
  String get symptomQ6;

  /// No description provided for @symptomQ7.
  ///
  /// In en, this message translates to:
  /// **'Do you have persistent breast pain that does not go away?'**
  String get symptomQ7;

  /// No description provided for @symptomQ8.
  ///
  /// In en, this message translates to:
  /// **'Does the pain increase over time?'**
  String get symptomQ8;

  /// No description provided for @symptomQ9.
  ///
  /// In en, this message translates to:
  /// **'Have you noticed swelling in part of the breast?'**
  String get symptomQ9;

  /// No description provided for @symptomQ10.
  ///
  /// In en, this message translates to:
  /// **'Have you observed unusual firmness in the breast tissue?'**
  String get symptomQ10;

  /// No description provided for @symptomQ11.
  ///
  /// In en, this message translates to:
  /// **'Have you noticed nipple discharge without squeezing?'**
  String get symptomQ11;

  /// No description provided for @symptomQ12.
  ///
  /// In en, this message translates to:
  /// **'Is the nipple discharge bloody or clear?'**
  String get symptomQ12;

  /// No description provided for @symptomQ13.
  ///
  /// In en, this message translates to:
  /// **'Has your nipple recently turned inward (inversion)?'**
  String get symptomQ13;

  /// No description provided for @symptomQ14.
  ///
  /// In en, this message translates to:
  /// **'Have you noticed nipple itching or burning?'**
  String get symptomQ14;

  /// No description provided for @symptomQ15.
  ///
  /// In en, this message translates to:
  /// **'Do you see crusting or scaling on the nipple?'**
  String get symptomQ15;

  /// No description provided for @symptomQ16.
  ///
  /// In en, this message translates to:
  /// **'Is there redness around the nipple or breast skin?'**
  String get symptomQ16;

  /// No description provided for @symptomQ17.
  ///
  /// In en, this message translates to:
  /// **'Do you notice dimpling or puckering of the breast skin?'**
  String get symptomQ17;

  /// No description provided for @symptomQ18.
  ///
  /// In en, this message translates to:
  /// **'Does the skin look like an orange peel texture?'**
  String get symptomQ18;

  /// No description provided for @symptomQ19.
  ///
  /// In en, this message translates to:
  /// **'Is there a sore or wound on the breast that does not heal?'**
  String get symptomQ19;

  /// No description provided for @symptomQ20.
  ///
  /// In en, this message translates to:
  /// **'Have you noticed visible veins or skin thickening on the breast?'**
  String get symptomQ20;

  /// No description provided for @symptomQ21.
  ///
  /// In en, this message translates to:
  /// **'Has the lump increased in size over the last few weeks?'**
  String get symptomQ21;

  /// No description provided for @symptomQ22.
  ///
  /// In en, this message translates to:
  /// **'Does the lump feel hard or irregular in shape?'**
  String get symptomQ22;

  /// No description provided for @symptomQ23.
  ///
  /// In en, this message translates to:
  /// **'Is the lump painless most of the time?'**
  String get symptomQ23;

  /// No description provided for @symptomQ24.
  ///
  /// In en, this message translates to:
  /// **'Have you noticed swelling near the collarbone?'**
  String get symptomQ24;

  /// No description provided for @symptomQ25.
  ///
  /// In en, this message translates to:
  /// **'Do you feel enlarged lymph nodes in the neck or armpit?'**
  String get symptomQ25;

  /// No description provided for @symptomQ26.
  ///
  /// In en, this message translates to:
  /// **'Have symptoms worsened over time instead of improving?'**
  String get symptomQ26;

  /// No description provided for @symptomQ27.
  ///
  /// In en, this message translates to:
  /// **'Do you feel breast discomfort even without touching?'**
  String get symptomQ27;

  /// No description provided for @symptomQ28.
  ///
  /// In en, this message translates to:
  /// **'Have you experienced breast tightness or pulling sensation?'**
  String get symptomQ28;

  /// No description provided for @symptomQ29.
  ///
  /// In en, this message translates to:
  /// **'Do you notice unusual breast asymmetry developing recently?'**
  String get symptomQ29;

  /// No description provided for @symptomQ30.
  ///
  /// In en, this message translates to:
  /// **'Have you observed a lump that does not move easily?'**
  String get symptomQ30;

  /// No description provided for @symptomQ31.
  ///
  /// In en, this message translates to:
  /// **'Do you have a family history of breast cancer (mother/sister/daughter)?'**
  String get symptomQ31;

  /// No description provided for @symptomQ32.
  ///
  /// In en, this message translates to:
  /// **'Do you have a family history of ovarian cancer?'**
  String get symptomQ32;

  /// No description provided for @symptomQ33.
  ///
  /// In en, this message translates to:
  /// **'Have you ever had a breast biopsy before?'**
  String get symptomQ33;

  /// No description provided for @symptomQ34.
  ///
  /// In en, this message translates to:
  /// **'Have you been diagnosed with benign breast disease previously?'**
  String get symptomQ34;

  /// No description provided for @symptomQ35.
  ///
  /// In en, this message translates to:
  /// **'Have you ever had radiation therapy to the chest area?'**
  String get symptomQ35;

  /// No description provided for @symptomQ36.
  ///
  /// In en, this message translates to:
  /// **'Did you start menstruation before age 12?'**
  String get symptomQ36;

  /// No description provided for @symptomQ37.
  ///
  /// In en, this message translates to:
  /// **'Did you reach menopause after age 55?'**
  String get symptomQ37;

  /// No description provided for @symptomQ38.
  ///
  /// In en, this message translates to:
  /// **'Have you ever used hormone replacement therapy?'**
  String get symptomQ38;

  /// No description provided for @symptomQ39.
  ///
  /// In en, this message translates to:
  /// **'Have you ever been diagnosed with a BRCA gene mutation?'**
  String get symptomQ39;

  /// No description provided for @symptomQ40.
  ///
  /// In en, this message translates to:
  /// **'Have you had your first pregnancy after age 30 or never been pregnant?'**
  String get symptomQ40;

  /// No description provided for @symptomQ41.
  ///
  /// In en, this message translates to:
  /// **'Have you experienced unexplained weight loss recently?'**
  String get symptomQ41;

  /// No description provided for @symptomQ42.
  ///
  /// In en, this message translates to:
  /// **'Do you feel unusual tiredness or fatigue daily?'**
  String get symptomQ42;

  /// No description provided for @symptomQ43.
  ///
  /// In en, this message translates to:
  /// **'Do you have frequent unexplained fever or weakness?'**
  String get symptomQ43;

  /// No description provided for @symptomQ44.
  ///
  /// In en, this message translates to:
  /// **'Do you smoke regularly?'**
  String get symptomQ44;

  /// No description provided for @symptomQ45.
  ///
  /// In en, this message translates to:
  /// **'Do you consume alcohol frequently?'**
  String get symptomQ45;

  /// No description provided for @symptomQ46.
  ///
  /// In en, this message translates to:
  /// **'Do you have a sedentary lifestyle with little physical activity?'**
  String get symptomQ46;

  /// No description provided for @symptomQ47.
  ///
  /// In en, this message translates to:
  /// **'Are you overweight or obese?'**
  String get symptomQ47;

  /// No description provided for @symptomQ48.
  ///
  /// In en, this message translates to:
  /// **'Do you experience stress or anxiety about breast symptoms?'**
  String get symptomQ48;

  /// No description provided for @symptomQ49.
  ///
  /// In en, this message translates to:
  /// **'Have you delayed seeing a doctor despite symptoms?'**
  String get symptomQ49;

  /// No description provided for @symptomQ50.
  ///
  /// In en, this message translates to:
  /// **'Do you feel symptoms are affecting your daily life?'**
  String get symptomQ50;

  /// No description provided for @chatWithDoctors.
  ///
  /// In en, this message translates to:
  /// **'Chat with Doctors'**
  String get chatWithDoctors;

  /// No description provided for @diagnoseSymptom.
  ///
  /// In en, this message translates to:
  /// **'Diagnose Symptom'**
  String get diagnoseSymptom;

  /// No description provided for @doctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctors;

  /// No description provided for @selectDoctor.
  ///
  /// In en, this message translates to:
  /// **'Select Doctor'**
  String get selectDoctor;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile.'**
  String get failedToLoadProfile;

  /// No description provided for @completeYourProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfileTitle;

  /// No description provided for @addDoctorTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Doctor'**
  String get addDoctorTitle;

  /// No description provided for @doctorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor Name'**
  String get doctorNameLabel;

  /// No description provided for @enterDoctorName.
  ///
  /// In en, this message translates to:
  /// **'Enter doctor name'**
  String get enterDoctorName;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @emailCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be empty'**
  String get emailCannotBeEmpty;

  /// No description provided for @passwordCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get passwordCannotBeEmpty;

  /// No description provided for @infoTitle.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get infoTitle;

  /// No description provided for @announcementAddedSuccessfullyFor.
  ///
  /// In en, this message translates to:
  /// **'Announcement added successfully for {audience}!'**
  String announcementAddedSuccessfullyFor(String audience);

  /// No description provided for @adminFeedbackResponsesTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Responses'**
  String get adminFeedbackResponsesTitle;

  /// No description provided for @failedToLoadFeedbacks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feedbacks'**
  String get failedToLoadFeedbacks;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @responded.
  ///
  /// In en, this message translates to:
  /// **'Responded'**
  String get responded;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @viewResponse.
  ///
  /// In en, this message translates to:
  /// **'View Response'**
  String get viewResponse;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get response;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @feedbackResponsesTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Responses'**
  String get feedbackResponsesTitle;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @monitorChats.
  ///
  /// In en, this message translates to:
  /// **'Monitor Chats'**
  String get monitorChats;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @manageResponse.
  ///
  /// In en, this message translates to:
  /// **'Manage Response'**
  String get manageResponse;

  /// No description provided for @manageAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Manage Announcements'**
  String get manageAnnouncements;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @viewDoctorsTitle.
  ///
  /// In en, this message translates to:
  /// **'View Doctors'**
  String get viewDoctorsTitle;

  /// No description provided for @noApprovedDoctorsYet.
  ///
  /// In en, this message translates to:
  /// **'No approved doctors yet!'**
  String get noApprovedDoctorsYet;

  /// No description provided for @qualificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get qualificationLabel;

  /// No description provided for @specializationLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specializationLabel;

  /// No description provided for @experienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceLabel;

  /// No description provided for @doctorFallback.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorFallback;

  /// No description provided for @yearsSuffix.
  ///
  /// In en, this message translates to:
  /// **'y'**
  String get yearsSuffix;

  /// No description provided for @feedbackResponses.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Responses'**
  String get feedbackResponses;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @monitorChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor Chats'**
  String get monitorChatsTitle;

  /// No description provided for @monitorChatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All active chats between doctors and patients will appear below.'**
  String get monitorChatsSubtitle;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @monitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get monitor;

  /// No description provided for @patientFallback.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientFallback;

  /// No description provided for @couldNotOpenFileDesc.
  ///
  /// In en, this message translates to:
  /// **'The system could not open this URL:'**
  String get couldNotOpenFileDesc;

  /// No description provided for @urlEmptyOrMalformedDesc.
  ///
  /// In en, this message translates to:
  /// **'URL is empty or malformed:'**
  String get urlEmptyOrMalformedDesc;

  /// No description provided for @httpStatusCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'HTTP request statusCode:'**
  String get httpStatusCodeLabel;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'(present)'**
  String get present;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'(none)'**
  String get none;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'status:'**
  String get statusLabel;

  /// No description provided for @redirectsLabel.
  ///
  /// In en, this message translates to:
  /// **'redirects:'**
  String get redirectsLabel;

  /// No description provided for @first700CharsLabel.
  ///
  /// In en, this message translates to:
  /// **'first 700 chars'**
  String get first700CharsLabel;

  /// No description provided for @requestErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Request error:'**
  String get requestErrorDesc;

  /// No description provided for @failedToLoadImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image.'**
  String get failedToLoadImageDesc;

  /// No description provided for @monitoringModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitoring Mode'**
  String get monitoringModeTitle;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get readOnly;

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientLabel;

  /// No description provided for @monitorTipLongPress.
  ///
  /// In en, this message translates to:
  /// **'Tip: Long-press an image bubble to see HTTP error details.'**
  String get monitorTipLongPress;

  /// No description provided for @manageExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Exercise'**
  String get manageExerciseTitle;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noMediaYet.
  ///
  /// In en, this message translates to:
  /// **'No media yet!'**
  String get noMediaYet;

  /// No description provided for @manageAnnouncementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Announcements'**
  String get manageAnnouncementsTitle;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @noAnnouncementsYet.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet!'**
  String get noAnnouncementsYet;

  /// No description provided for @editAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Announcement'**
  String get editAnnouncementTitle;

  /// No description provided for @sendToLabel.
  ///
  /// In en, this message translates to:
  /// **'Send To'**
  String get sendToLabel;

  /// No description provided for @announcementHint.
  ///
  /// In en, this message translates to:
  /// **'Write your announcement here...'**
  String get announcementHint;

  /// No description provided for @audiencePatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get audiencePatient;

  /// No description provided for @audienceDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get audienceDoctor;

  /// No description provided for @audienceBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get audienceBoth;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTitle;

  /// No description provided for @deleteAnnouncementConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this announcement?'**
  String get deleteAnnouncementConfirmDesc;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @adminNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Admin not logged in!'**
  String get adminNotLoggedIn;

  /// No description provided for @announcementDeletedSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Announcement deleted successfully.'**
  String get announcementDeletedSuccessDesc;

  /// No description provided for @announcementUpdatedSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Announcement updated successfully.'**
  String get announcementUpdatedSuccessDesc;

  /// No description provided for @failedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedTitle;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get emptyTitle;

  /// No description provided for @writeAnnouncementFirstDesc.
  ///
  /// In en, this message translates to:
  /// **'Please write an announcement first.'**
  String get writeAnnouncementFirstDesc;

  /// No description provided for @announcementDeletedFor.
  ///
  /// In en, this message translates to:
  /// **'Announcement deleted for'**
  String get announcementDeletedFor;

  /// No description provided for @announcementEditedFor.
  ///
  /// In en, this message translates to:
  /// **'Announcement edited for'**
  String get announcementEditedFor;

  /// No description provided for @adminAnnouncementDeletedNotif.
  ///
  /// In en, this message translates to:
  /// **'An announcement was deleted.'**
  String get adminAnnouncementDeletedNotif;

  /// No description provided for @adminAnnouncementEditedNotif.
  ///
  /// In en, this message translates to:
  /// **'An announcement was edited.'**
  String get adminAnnouncementEditedNotif;

  /// No description provided for @userAnnouncementRemovedNotif.
  ///
  /// In en, this message translates to:
  /// **'An announcement was removed.'**
  String get userAnnouncementRemovedNotif;

  /// No description provided for @userAnnouncementUpdatedNotif.
  ///
  /// In en, this message translates to:
  /// **'An announcement was updated.'**
  String get userAnnouncementUpdatedNotif;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get firstNameHint;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get lastNameHint;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @ageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter age'**
  String get ageHint;

  /// No description provided for @emailReadOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (Read only)'**
  String get emailReadOnlyLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @loadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Load Failed'**
  String get loadFailedTitle;

  /// No description provided for @couldNotLoadProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile.'**
  String get couldNotLoadProfileDesc;

  /// No description provided for @imageErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Error'**
  String get imageErrorTitle;

  /// No description provided for @couldNotPickImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Could not pick image.'**
  String get couldNotPickImageDesc;

  /// No description provided for @imageUploadFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed.'**
  String get imageUploadFailedDesc;

  /// No description provided for @validationTitle.
  ///
  /// In en, this message translates to:
  /// **'Validation'**
  String get validationTitle;

  /// No description provided for @fixHighlightedFieldsDesc.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields.'**
  String get fixHighlightedFieldsDesc;

  /// No description provided for @notLoggedInTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get notLoggedInTitle;

  /// No description provided for @pleaseLoginAgainDesc.
  ///
  /// In en, this message translates to:
  /// **'Please login again.'**
  String get pleaseLoginAgainDesc;

  /// No description provided for @profileUpdatedSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdatedSuccessDesc;

  /// No description provided for @saveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Failed'**
  String get saveFailedTitle;

  /// No description provided for @failedUpdateProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile.'**
  String get failedUpdateProfileDesc;

  /// No description provided for @profileUpdatedNotificationMsg.
  ///
  /// In en, this message translates to:
  /// **'Your profile was updated successfully.'**
  String get profileUpdatedNotificationMsg;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @firstNameMin2.
  ///
  /// In en, this message translates to:
  /// **'First name must be at least 2 characters'**
  String get firstNameMin2;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @lastNameMin2.
  ///
  /// In en, this message translates to:
  /// **'Last name must be at least 2 characters'**
  String get lastNameMin2;

  /// No description provided for @ageRequired.
  ///
  /// In en, this message translates to:
  /// **'Age is required'**
  String get ageRequired;

  /// No description provided for @enterValidAge.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid age'**
  String get enterValidAge;

  /// No description provided for @ageRange10to120.
  ///
  /// In en, this message translates to:
  /// **'Age must be between 10 and 120'**
  String get ageRange10to120;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @allReadTitle.
  ///
  /// In en, this message translates to:
  /// **'All Read!'**
  String get allReadTitle;

  /// No description provided for @allReadDesc.
  ///
  /// In en, this message translates to:
  /// **'All notifications have been marked as read.'**
  String get allReadDesc;

  /// No description provided for @nothingNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing New'**
  String get nothingNewTitle;

  /// No description provided for @nothingNewDesc.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications found.'**
  String get nothingNewDesc;

  /// No description provided for @markReadFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark all as read.'**
  String get markReadFailedDesc;

  /// No description provided for @failedLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedLoadNotifications;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notification yet!'**
  String get noNotificationsYet;

  /// No description provided for @notificationFallback.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationFallback;

  /// No description provided for @feedbackDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback Detail'**
  String get feedbackDetailTitle;

  /// No description provided for @failedToLoadFeedback.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feedback'**
  String get failedToLoadFeedback;

  /// No description provided for @feedbackUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'Feedback user not found.'**
  String get feedbackUserNotFound;

  /// No description provided for @pleaseWriteResponseFirst.
  ///
  /// In en, this message translates to:
  /// **'Please write a response first.'**
  String get pleaseWriteResponseFirst;

  /// No description provided for @adminUpdatedResponseToYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Admin updated the response to your feedback.'**
  String get adminUpdatedResponseToYourFeedback;

  /// No description provided for @adminRespondedToYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Admin responded to your feedback.'**
  String get adminRespondedToYourFeedback;

  /// No description provided for @feedbackResponseEdited.
  ///
  /// In en, this message translates to:
  /// **'A feedback response was edited.'**
  String get feedbackResponseEdited;

  /// No description provided for @feedbackResponseSent.
  ///
  /// In en, this message translates to:
  /// **'A feedback response was sent.'**
  String get feedbackResponseSent;

  /// No description provided for @editResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Response'**
  String get editResponseTitle;

  /// No description provided for @writeResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Write Response'**
  String get writeResponseTitle;

  /// No description provided for @responseHint.
  ///
  /// In en, this message translates to:
  /// **'Write your response here...'**
  String get responseHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @sendResponse.
  ///
  /// In en, this message translates to:
  /// **'Send Response'**
  String get sendResponse;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @responseUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Response updated successfully.'**
  String get responseUpdatedSuccessfully;

  /// No description provided for @responseSentToUser.
  ///
  /// In en, this message translates to:
  /// **'Response sent to the user.'**
  String get responseSentToUser;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @emptyAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty Announcement'**
  String get emptyAnnouncementTitle;

  /// No description provided for @emptyAnnouncementDesc.
  ///
  /// In en, this message translates to:
  /// **'Please write an announcement first.'**
  String get emptyAnnouncementDesc;

  /// No description provided for @addAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Announcement'**
  String get addAnnouncementTitle;

  /// No description provided for @sendTo.
  ///
  /// In en, this message translates to:
  /// **'Send To'**
  String get sendTo;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get both;

  /// No description provided for @announcementAddedFor.
  ///
  /// In en, this message translates to:
  /// **'Announcement added for'**
  String get announcementAddedFor;

  /// No description provided for @failedToAddAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Failed to add announcement.'**
  String get failedToAddAnnouncement;

  /// Welcome text on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}!'**
  String welcome(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
