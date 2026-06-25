// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI-Based Breast Cancer Detection App';

  @override
  String get aboutUs => 'About Us';

  @override
  String get ourMission => 'Our Mission:';

  @override
  String get ourMissionDesc =>
      'We are committed to empowering women through early breast cancer awareness and diagnosis using artificial intelligence.';

  @override
  String get whatWeDo => 'What We Do:';

  @override
  String get whatWeDoDesc =>
      'BreaScan AI is an intelligent mobile app that analyzes microscopic breast tissue images using advanced DL models.';

  @override
  String get failedToLoadUserData => 'Failed to load user data:';

  @override
  String get announcements => 'Announcements';

  @override
  String get announcement => 'Announcement';

  @override
  String get failedToLoadAnnouncements => 'Failed to load announcements.';

  @override
  String get showingLatestLoadedAnnouncementsTempIssue =>
      'Showing latest loaded announcements (temporary issue).';

  @override
  String get showingCachedAnnouncements =>
      'Showing latest loaded announcements (temporary issue).';

  @override
  String get noAnnouncementYet => 'No announcement yet!';

  @override
  String get newAnnouncement => 'You have received a new announcement.';

  @override
  String get forAudiencePrefix => 'For:';

  @override
  String forAudience(String audience) {
    return 'For: $audience';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotificationYet => 'No notification yet!';

  @override
  String get unread => 'Unread';

  @override
  String get unreadLabel => 'Unread';

  @override
  String get readAll => 'Read All';

  @override
  String get noUnreadNotifications => 'No unread notifications found.';

  @override
  String get allNotificationsRead => 'All notifications marked as read.';

  @override
  String get allNotificationsMarkedRead => 'All notifications marked as read.';

  @override
  String get defaultNotificationMessage =>
      'You have received a new notification.';

  @override
  String get user => 'User';

  @override
  String get patient => 'Patient';

  @override
  String get doctor => 'Doctor';

  @override
  String get userNotLoggedIn => 'User not logged in.';

  @override
  String get notLoggedIn => 'Not Logged In';

  @override
  String get pleaseLoginAgain => 'Please login again.';

  @override
  String get pleaseLoginFirst => 'Please login first.';

  @override
  String get incompleteProfileTitle => 'Complete your profile';

  @override
  String get incompleteProfileDesc =>
      'Your profile is incomplete. Please add Age, Marital Status, Medication and Cancer in family.';

  @override
  String get completeNow => 'Complete Now';

  @override
  String get later => 'Later';

  @override
  String get openProfileFromBottomNav =>
      'Open Patient Profile tab from bottom nav';

  @override
  String get connected => 'Connected';

  @override
  String get connectedMessage => 'You are now connected with each other.';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get done => 'Done';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get info => 'Info';

  @override
  String get failed => 'Failed';

  @override
  String get loading => 'Loading...';

  @override
  String get send => 'Send';

  @override
  String get typeMessage => 'Type Message';

  @override
  String get chatNow => 'Chat Now';

  @override
  String get chatRoom => 'Chat Room';

  @override
  String get chatRoomTitle => 'Chat Room';

  @override
  String get chatRequestsTitle => 'Chat Requests';

  @override
  String get chatARequest => 'Chat Request';

  @override
  String get viewChatRequest => 'View Chat Request';

  @override
  String get requestChat => 'Request a Chat';

  @override
  String get noApprovedDoctorFound => 'No approved doctor found yet.';

  @override
  String get noDoctorsAvailable =>
      'No doctors available right now! We’ll notify you as soon as a doctor is available.';

  @override
  String get noChatAvailableYet => 'No chat available yet.';

  @override
  String get noChatYet => 'No chat yet!';

  @override
  String get noMessagesYet => 'No messages yet!';

  @override
  String get chatErrorLabel => 'Chat error:';

  @override
  String get chatErrorPrefix => 'Chat error';

  @override
  String get chatTipLongPressImage =>
      'Tip: Long-press an image bubble to see HTTP error details.';

  @override
  String get lastMessageImage => '📷 Image';

  @override
  String get lastMessagePdf => '📄 PDF';

  @override
  String get patientFallbackName => 'Patient';

  @override
  String get doctorFallbackName => 'Doctor';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get viewMedia => 'View Media';

  @override
  String get viewMediaTitle => 'View Media';

  @override
  String get imageGallery => 'Image (Gallery)';

  @override
  String get imageCamera => 'Image (Camera)';

  @override
  String get pdf => 'PDF';

  @override
  String get pdfDocument => 'PDF Document';

  @override
  String get sendFailedTitle => 'Send failed';

  @override
  String get uploadFailedTitle => 'Upload Failed';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get pdfErrorTitle => 'PDF Error';

  @override
  String get unableToReadPdfBytes => 'Unable to read PDF bytes.';

  @override
  String get invalidFileUrl => 'Invalid file URL';

  @override
  String get couldNotOpenFileTitle => 'Could not open file';

  @override
  String get couldNotOpenFile => 'Could not open file.';

  @override
  String get failedToLoadImage => 'Failed to load image.';

  @override
  String get failedToLoadImageNoPeriod => 'Failed to load image';

  @override
  String get failedToLoadImageShort => 'Failed to load image';

  @override
  String get tapBelowToSeeWhy => 'Tap below to see why (HTTP details).';

  @override
  String get showErrorDetails => 'Show Error Details';

  @override
  String get holdToDebug => 'Hold to debug';

  @override
  String get stackLabel => 'Stack';

  @override
  String get invalidUrlTitle => 'Invalid URL';

  @override
  String get invalidUrlDesc => 'The stored URL is empty or malformed.';

  @override
  String get fileLoadDebugTitle => 'File Load Debug';

  @override
  String get requestFailedTitle => 'Request Failed';

  @override
  String get httpStatusLabel => 'HTTP Status:';

  @override
  String get urlLabel => 'URL:';

  @override
  String get headersLabel => 'Headers:';

  @override
  String get bodyPreviewLabel => 'Body Preview:';

  @override
  String get rawLabel => 'raw:';

  @override
  String get fixedLabel => 'fixed:';

  @override
  String get imageFailedTitle => 'Image Failed';

  @override
  String get requestErrorLabel => 'Request error:';

  @override
  String get flutterErrorLabel => 'Flutter error:';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get yourFeedback => 'Your Feedback';

  @override
  String get adminResponse => 'Admin Response:';

  @override
  String get noResponseYet => 'No response yet.';

  @override
  String get noFeedbackYet => 'No feedback yet!';

  @override
  String get addFeedbackTitle => 'Add Feedback';

  @override
  String get addFeedback => 'Add Feedback';

  @override
  String get add => 'Add';

  @override
  String get yourMessage => 'Your Message:';

  @override
  String get pleaseWriteFeedbackFirst => 'Please write feedback first.';

  @override
  String get feedbackSentSuccessfully => 'Feedback sent successfully!';

  @override
  String get feedbackUpdatedSuccessfully => 'Feedback updated successfully!';

  @override
  String get feedbackDeletedSuccessfully => 'Feedback deleted successfully!';

  @override
  String get failedToSendFeedback => 'Failed to send feedback';

  @override
  String get errorUpdatingFeedback => 'Error updating feedback';

  @override
  String get failedToDeleteFeedback => 'Failed to delete feedback';

  @override
  String get cantEditAdminResponded =>
      'You can’t edit because admin already responded.';

  @override
  String get cantDeleteAdminResponded =>
      'You can’t delete because admin already responded.';

  @override
  String get editFeedback => 'Edit Feedback';

  @override
  String get updateYourMessage => 'Update your message...';

  @override
  String get messageCannotBeEmpty => 'Message cannot be empty.';

  @override
  String get deleteFeedbackTitle => 'Delete Feedback';

  @override
  String get deleteFeedbackConfirm =>
      'Are you sure you want to delete this feedback?';

  @override
  String get feedbackHint => 'Write your feedback here...';

  @override
  String get addButton => 'Add';

  @override
  String get cancelUpper => 'CANCEL';

  @override
  String get updateUpper => 'UPDATE';

  @override
  String get fbLoginTitle => 'Login';

  @override
  String get fbEmptyTitle => 'Empty';

  @override
  String get fbEmptyDesc => 'Please write feedback first.';

  @override
  String get fbSuccessTitle => 'Success';

  @override
  String get fbSuccessDesc => 'Feedback sent successfully!';

  @override
  String get fbFailedTitle => 'Failed';

  @override
  String get fbFailedDesc => 'Failed to send feedback.';

  @override
  String get fbUpdatedTitle => 'Updated';

  @override
  String get fbUpdatedDesc => 'Feedback updated.';

  @override
  String get fbDeletedTitle => 'Deleted';

  @override
  String get fbDeletedDesc => 'Feedback deleted.';

  @override
  String get fbLockedTitle => 'Locked';

  @override
  String get fbLockedEditDesc =>
      'You can’t edit because admin already responded.';

  @override
  String get fbLockedDeleteDesc =>
      'You can’t delete because admin already responded.';

  @override
  String get fbEditDialogTitle => 'Edit Feedback';

  @override
  String get fbDeleteTitle => 'Delete';

  @override
  String get fbDeleteConfirmDesc =>
      'Are you sure you want to delete this feedback?';

  @override
  String get fbNotifyAdminsNewFeedback => 'New patient feedback received.';

  @override
  String get fbNotifyAdminsUpdated => 'A patient updated their feedback.';

  @override
  String get fbNotifyAdminsDeleted => 'A patient deleted their feedback.';

  @override
  String get fbNotifyUserSent => 'Your feedback has been sent to admin.';

  @override
  String get fbNotifyUserUpdated => 'Your feedback has been updated.';

  @override
  String get fbNotifyUserDeleted => 'Your feedback has been deleted.';

  @override
  String get patientProfileTitle => 'Patient Profile';

  @override
  String get patientProfileNotFound => 'Patient profile not found.';

  @override
  String get patientDataNotFound => 'Patient data not found.';

  @override
  String get name => 'Name';

  @override
  String get enterName => 'Enter your name';

  @override
  String get age => 'Age';

  @override
  String get enterAge => 'Enter age';

  @override
  String get email => 'Email';

  @override
  String get maritalStatus => 'Marital Status';

  @override
  String get anyMedication => 'Any Medication';

  @override
  String get cancerInFamily => 'Cancer in family?';

  @override
  String get select => 'Select';

  @override
  String get single => 'Single';

  @override
  String get married => 'Married';

  @override
  String get validation => 'Validation';

  @override
  String get profileIncompleteDesc => 'Your profile is incomplete.';

  @override
  String get profileFixHighlighted => 'Please fix the highlighted fields.';

  @override
  String get fixHighlightedFields => 'Please fix the highlighted fields.';

  @override
  String get profileLoginAgain => 'Please login again.';

  @override
  String get saveFailed => 'Save Failed';

  @override
  String get failedToSaveProfile => 'Failed to save profile.';

  @override
  String get profileSaved => 'Profile Saved ✅';

  @override
  String get profileSavedIncompleteDesc =>
      'Profile saved, but some fields are still incomplete.';

  @override
  String get profileCompleted => 'Profile Completed ✅';

  @override
  String get profileCompletedDesc => 'Your profile is completed successfully.';

  @override
  String get profileCompletedTitle => 'Profile Completed ✅';

  @override
  String get profileSavedTitle => 'Profile Saved ✅';

  @override
  String get profileSavedDesc => 'Saved, but still incomplete.';

  @override
  String get profileSaveFailedDesc => 'Failed to save profile.';

  @override
  String get profileNameRequired => 'Name is required';

  @override
  String get profileNameMin2 => 'Name must be at least 2 characters';

  @override
  String get profileNameLettersOnly =>
      'Name must contain only letters and spaces';

  @override
  String get profileEmailRequired => 'Email is required';

  @override
  String get profileEmailInvalid => 'Enter a valid email';

  @override
  String get profileAgeRequired => 'Age is required';

  @override
  String get profileAgeInvalid => 'Enter a valid age';

  @override
  String get profileAgeRange => 'Age must be between 10 and 120';

  @override
  String profileFieldRequired(Object fieldName) {
    return '$fieldName is required';
  }

  @override
  String get doctorNotLoggedIn => 'Doctor not logged in!';

  @override
  String get doctorNotLoggedInBang => 'Doctor not logged in!';

  @override
  String get approvedPatients => 'Approved Patients';

  @override
  String get noApprovedPatientsYet => 'No approved patients yet!';

  @override
  String get pleaseSelectPatientFirst => 'Please select a patient first.';

  @override
  String get failedToSendMessage => 'Failed to send message.';

  @override
  String get approvedDoctors => 'Approved Doctors';

  @override
  String get sendingRequest => 'Sending request...';

  @override
  String get successTitle => 'Success';

  @override
  String get requestSentSuccessfully => 'Request sent successfully!';

  @override
  String get pleaseSelectDoctorFirst => 'Please select a doctor first.';

  @override
  String get alreadyRequestedDoctor => 'You already requested this doctor.';

  @override
  String get failedToSendRequest => 'Failed to send request.';

  @override
  String get queryErrorPrefix => 'Query error:';

  @override
  String get noRequestYet => 'No request yet!';

  @override
  String get approveRequestTitle => 'Approve Request';

  @override
  String approveRequestDesc(String name) {
    return 'Are you sure you want to approve $name?';
  }

  @override
  String get rejectRequestTitle => 'Reject Request';

  @override
  String rejectRequestDesc(String name) {
    return 'Are you sure you want to reject $name?';
  }

  @override
  String get requestApprovedSuccessfully => 'Request approved successfully!';

  @override
  String get requestRejectedSuccessfully => 'Request rejected successfully!';

  @override
  String get failedToUpdateRequest => 'Failed to update request. Try again.';

  @override
  String get upload => 'Upload';

  @override
  String get uploadExerciseTitle => 'Upload Exercise';

  @override
  String get uploadExercise => 'Upload Exercise';

  @override
  String get selectMediaLabel => 'Select Media (Image / Video)';

  @override
  String get tapToPickMedia => 'Tap to pick image/video';

  @override
  String get couldNotReadFilePath => 'Could not read file path. Try again.';

  @override
  String get onlyImagesAndVideosAllowed =>
      'Only images and videos are allowed.';

  @override
  String get fileTooLarge => 'File too large';

  @override
  String get maxAllowed => 'Max allowed';

  @override
  String get pickFailed => 'Pick failed';

  @override
  String get selectedFileEmpty => 'Selected file is empty.';

  @override
  String get fileTooLargeBytes => 'File too large';

  @override
  String get maxAllowedBytes => 'Max allowed';

  @override
  String get pleaseEnterTitle => 'Please enter title.';

  @override
  String get pleaseEnterDescription => 'Please enter description.';

  @override
  String get pleaseSelectMediaFirst => 'Please select an image or video first.';

  @override
  String get pleaseRepickFile => 'Please re-pick the file.';

  @override
  String get uploadReturnedEmptyUrl =>
      'Upload succeeded but server returned empty url/path.';

  @override
  String get exerciseUploadedSuccessfully => 'Exercise uploaded successfully!';

  @override
  String get videoFailedToLoad => 'Video failed to load';

  @override
  String get manageUploads => 'Manage Uploads';

  @override
  String get noUploadsYet => 'No uploads yet!';

  @override
  String get untitled => 'Untitled';

  @override
  String get editUpload => 'Edit Upload';

  @override
  String get titleLabel => 'Title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get deletedTitle => 'Deleted';

  @override
  String get uploadDeletedSuccessfully => 'Upload deleted successfully.';

  @override
  String get updatedTitle => 'Updated ✅';

  @override
  String get uploadUpdatedSuccessfully => 'Upload updated successfully.';

  @override
  String get errorTitle => 'Error';

  @override
  String get errorPrefix => 'Error';

  @override
  String get manageOwnUploadsOnly => 'You can only manage your own uploads.';

  @override
  String get missingFilePathReupload =>
      'Missing filePath in Firestore. Please re-upload this media.';

  @override
  String get mediaTypeVideo => 'VIDEO';

  @override
  String get mediaTypeImage => 'IMAGE';

  @override
  String get noDescriptionDash => '-';

  @override
  String get titleLabelPlain => 'Title';

  @override
  String get descriptionLabelPlain => 'Description';

  @override
  String get invalidMediaUrl => 'Invalid media URL';

  @override
  String get doctorNotificationsTitle => 'Doctor Notifications';

  @override
  String get completeYourProfile => 'Complete Your Profile';

  @override
  String get completeProfileDesc =>
      'Add experience, specialization, qualification and description to complete your doctor profile.';

  @override
  String get yourProfileIncomplete => 'Your profile is incomplete.';

  @override
  String get manageDoctorProfile => 'Manage Doctor Profile';

  @override
  String get firstName => 'First Name';

  @override
  String get enterFirstName => 'Enter first name';

  @override
  String get lastName => 'Last Name';

  @override
  String get enterLastName => 'Enter last name';

  @override
  String get emailReadonly => 'Email (Read-only)';

  @override
  String get experienceYears => 'Experience (Years)';

  @override
  String get enterExperience => 'Enter years of experience';

  @override
  String get specialization => 'Specialization';

  @override
  String get enterSpecialization => 'e.g. Physiotherapist';

  @override
  String get qualification => 'Qualification';

  @override
  String get enterQualification => 'e.g. MBBS FCPS';

  @override
  String get description => 'Description';

  @override
  String get enterDescriptionHint => 'Write about yourself (min 20 chars)';

  @override
  String get imageError => 'Image Error';

  @override
  String get couldNotPickImage => 'Could not pick image.';

  @override
  String get profileImageUploadFailed => 'Profile image upload failed.';

  @override
  String get doctorProfileTitle => 'Doctor Profile';

  @override
  String get doctorLabel => 'Doctor';

  @override
  String get doctorBio =>
      'I am a board-certified oncologist specializing in breast cancer diagnosis and treatment. I focus on patient-centered care and early detection.';

  @override
  String get experience => 'Experience';

  @override
  String get qualifications => 'Qualifications';

  @override
  String get years => 'years';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get logoutConfirmDesc => 'Are you sure you want to logout?';

  @override
  String get logoutFailed => 'Logout Failed';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get manageProfile => 'Manage Profile';

  @override
  String get resetPasswordOptional => 'Reset Password (Optional)';

  @override
  String get emailMissingAt =>
      'Your email does not contain @. Please include @.';

  @override
  String get passwordTooShort => 'Password can\'t be less than 8 characters';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get languageUpdatedTitle => 'Language Updated 🎉';

  @override
  String languageUpdatedDesc(String lang) {
    return 'Your app language has been changed to $lang successfully!';
  }

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get selectYourImages => 'Select your images';

  @override
  String get selectImages => 'Select images';

  @override
  String get note => 'Note:';

  @override
  String get uploadNoteDesc =>
      'Simply upload your breast tissue microscope images at any magnification (40×, 100×, 200×, or 400×) and let our AI help identify the cancer type.';

  @override
  String get startDiagnoses => 'Start Diagnoses';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get selectedLabel => 'Selected';

  @override
  String get selectAtLeastOneImage => 'Please select at least 1 image.';

  @override
  String get startingDiagnoses => 'Starting diagnoses...';

  @override
  String get invalidImageTitle => 'Invalid Image';

  @override
  String get invalidImageDesc =>
      'Only breast tissue microscope images are allowed.\nRandom photos (watch, guitar, glass, etc.) are rejected.';

  @override
  String get limitReachedTitle => 'Limit Reached';

  @override
  String get limitReachedDesc => 'You can select maximum 4 images.';

  @override
  String get scanFailedDesc => 'Failed to scan image:';

  @override
  String get saved => 'Saved';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get modelLoadingFailed => 'Model loading failed:';

  @override
  String get modelsNotReadyYet => 'Models are not ready yet...';

  @override
  String get loadingModel => 'Loading model...';

  @override
  String get resultCancerous => 'Cancerous';

  @override
  String get resultNotCancerous => 'Not Cancerous';

  @override
  String get predictionLabel => 'Prediction';

  @override
  String get confidenceLabel => 'Confidence';

  @override
  String get myReport => 'My Report';

  @override
  String get noReportsYet => 'No reports yet!';

  @override
  String get pleaseLoginToViewReports => 'Please login to view reports.';

  @override
  String get failedToLoadReports => 'Failed to load reports:';

  @override
  String get imageReportsTitle => 'Image Reports';

  @override
  String get symptomReportsTitle => 'Symptom Reports';

  @override
  String get noSymptomReportsYet => 'No symptom assessment reports yet.';

  @override
  String get viewReport => 'View Report';

  @override
  String get statusMalignant => 'Malignant';

  @override
  String get statusBenign => 'Benign';

  @override
  String get confidence => 'Confidence';

  @override
  String get riskLevel => 'Risk level';

  @override
  String get likelihoodMeter => 'Likelihood meter';

  @override
  String get riskLowConcern => 'Low concern';

  @override
  String get riskMildConcern => 'Mild concern';

  @override
  String get riskReviewRecommended => 'Review recommended';

  @override
  String get riskModerateConcern => 'Moderate concern';

  @override
  String get riskHighConcern => 'High concern';

  @override
  String get riskReviewUrgently => 'Review urgently';

  @override
  String get refreshImages => 'Refresh Images';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get failedToLoadImages => 'Failed to load images.';

  @override
  String get noImagesForReport => 'No images available for this report.';

  @override
  String get reportImages => 'Report Images';

  @override
  String get breastHealthReport => 'Breast Health Report';

  @override
  String get diagnosis => 'Diagnosis:';

  @override
  String get typeLabel => 'Type:';

  @override
  String get dateLabel => 'Date:';

  @override
  String get whatThisMeansTitle => 'What this means';

  @override
  String get commonSymptomsTitle => 'Common symptoms';

  @override
  String get riskFactorsTitle => 'Possible causes / risk factors';

  @override
  String get nextStepsTitle => 'Recommended next steps';

  @override
  String get resultTypeMalignant =>
      'Result Type: Malignant (cancerous pattern)';

  @override
  String get resultTypeBenign => 'Result Type: Benign (non-cancerous pattern)';

  @override
  String get disclaimer =>
      'Disclaimer: This AI report is an assistive tool and does not replace clinical diagnosis.';

  @override
  String get pdfReadyTitle => 'PDF Ready';

  @override
  String get pdfReadyDesc => 'Your report PDF has been generated.';

  @override
  String get symptomDiagnosisTitle => 'Symptom Diagnosis';

  @override
  String get symptomAssessmentReportPdfTitle => 'Symptom Assessment Report';

  @override
  String get scoreLabel => 'Score';

  @override
  String get riskLabel => 'Risk';

  @override
  String get urgencyLabel => 'Urgency';

  @override
  String get keyFindingsTitle => 'Key Findings';

  @override
  String get recommendedTestsTitle => 'Recommended Tests';

  @override
  String get diagnoseSymptomsTitle => 'Diagnose Symptoms';

  @override
  String get pageLabel => 'Page';

  @override
  String get pleaseAnswerAllQuestions =>
      'Please answer all questions on this page to continue.';

  @override
  String get symptomsSavedSuccessfully => 'Symptoms saved successfully.';

  @override
  String get failedToSaveSymptoms => 'Failed to save symptoms:';

  @override
  String get symptomQ1 => 'Do you feel a new lump or thickening in the breast?';

  @override
  String get symptomQ2 =>
      'Do you feel a lump or swelling in the underarm area?';

  @override
  String get symptomQ3 =>
      'Have you noticed a change in the size of one breast?';

  @override
  String get symptomQ4 =>
      'Have you noticed a change in the shape of one breast?';

  @override
  String get symptomQ5 =>
      'Is one breast suddenly looking different from the other?';

  @override
  String get symptomQ6 => 'Do you feel heaviness in one breast?';

  @override
  String get symptomQ7 =>
      'Do you have persistent breast pain that does not go away?';

  @override
  String get symptomQ8 => 'Does the pain increase over time?';

  @override
  String get symptomQ9 => 'Have you noticed swelling in part of the breast?';

  @override
  String get symptomQ10 =>
      'Have you observed unusual firmness in the breast tissue?';

  @override
  String get symptomQ11 =>
      'Have you noticed nipple discharge without squeezing?';

  @override
  String get symptomQ12 => 'Is the nipple discharge bloody or clear?';

  @override
  String get symptomQ13 =>
      'Has your nipple recently turned inward (inversion)?';

  @override
  String get symptomQ14 => 'Have you noticed nipple itching or burning?';

  @override
  String get symptomQ15 => 'Do you see crusting or scaling on the nipple?';

  @override
  String get symptomQ16 => 'Is there redness around the nipple or breast skin?';

  @override
  String get symptomQ17 =>
      'Do you notice dimpling or puckering of the breast skin?';

  @override
  String get symptomQ18 => 'Does the skin look like an orange peel texture?';

  @override
  String get symptomQ19 =>
      'Is there a sore or wound on the breast that does not heal?';

  @override
  String get symptomQ20 =>
      'Have you noticed visible veins or skin thickening on the breast?';

  @override
  String get symptomQ21 =>
      'Has the lump increased in size over the last few weeks?';

  @override
  String get symptomQ22 => 'Does the lump feel hard or irregular in shape?';

  @override
  String get symptomQ23 => 'Is the lump painless most of the time?';

  @override
  String get symptomQ24 => 'Have you noticed swelling near the collarbone?';

  @override
  String get symptomQ25 =>
      'Do you feel enlarged lymph nodes in the neck or armpit?';

  @override
  String get symptomQ26 =>
      'Have symptoms worsened over time instead of improving?';

  @override
  String get symptomQ27 =>
      'Do you feel breast discomfort even without touching?';

  @override
  String get symptomQ28 =>
      'Have you experienced breast tightness or pulling sensation?';

  @override
  String get symptomQ29 =>
      'Do you notice unusual breast asymmetry developing recently?';

  @override
  String get symptomQ30 =>
      'Have you observed a lump that does not move easily?';

  @override
  String get symptomQ31 =>
      'Do you have a family history of breast cancer (mother/sister/daughter)?';

  @override
  String get symptomQ32 => 'Do you have a family history of ovarian cancer?';

  @override
  String get symptomQ33 => 'Have you ever had a breast biopsy before?';

  @override
  String get symptomQ34 =>
      'Have you been diagnosed with benign breast disease previously?';

  @override
  String get symptomQ35 =>
      'Have you ever had radiation therapy to the chest area?';

  @override
  String get symptomQ36 => 'Did you start menstruation before age 12?';

  @override
  String get symptomQ37 => 'Did you reach menopause after age 55?';

  @override
  String get symptomQ38 => 'Have you ever used hormone replacement therapy?';

  @override
  String get symptomQ39 =>
      'Have you ever been diagnosed with a BRCA gene mutation?';

  @override
  String get symptomQ40 =>
      'Have you had your first pregnancy after age 30 or never been pregnant?';

  @override
  String get symptomQ41 =>
      'Have you experienced unexplained weight loss recently?';

  @override
  String get symptomQ42 => 'Do you feel unusual tiredness or fatigue daily?';

  @override
  String get symptomQ43 =>
      'Do you have frequent unexplained fever or weakness?';

  @override
  String get symptomQ44 => 'Do you smoke regularly?';

  @override
  String get symptomQ45 => 'Do you consume alcohol frequently?';

  @override
  String get symptomQ46 =>
      'Do you have a sedentary lifestyle with little physical activity?';

  @override
  String get symptomQ47 => 'Are you overweight or obese?';

  @override
  String get symptomQ48 =>
      'Do you experience stress or anxiety about breast symptoms?';

  @override
  String get symptomQ49 => 'Have you delayed seeing a doctor despite symptoms?';

  @override
  String get symptomQ50 =>
      'Do you feel symptoms are affecting your daily life?';

  @override
  String get chatWithDoctors => 'Chat with Doctors';

  @override
  String get diagnoseSymptom => 'Diagnose Symptom';

  @override
  String get doctors => 'Doctors';

  @override
  String get selectDoctor => 'Select Doctor';

  @override
  String get request => 'Request';

  @override
  String get failedToLoadProfile => 'Failed to load profile.';

  @override
  String get completeYourProfileTitle => 'Complete Your Profile';

  @override
  String get addDoctorTitle => 'Add Doctor';

  @override
  String get doctorNameLabel => 'Doctor Name';

  @override
  String get enterDoctorName => 'Enter doctor name';

  @override
  String get genderLabel => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get emailCannotBeEmpty => 'Email cannot be empty';

  @override
  String get passwordCannotBeEmpty => 'Password cannot be empty';

  @override
  String get infoTitle => 'Info';

  @override
  String announcementAddedSuccessfullyFor(String audience) {
    return 'Announcement added successfully for $audience!';
  }

  @override
  String get adminFeedbackResponsesTitle => 'Feedback & Responses';

  @override
  String get failedToLoadFeedbacks => 'Failed to load feedbacks';

  @override
  String get pending => 'Pending';

  @override
  String get responded => 'Responded';

  @override
  String get role => 'Role';

  @override
  String get na => 'N/A';

  @override
  String get viewResponse => 'View Response';

  @override
  String get response => 'Response';

  @override
  String get admin => 'Admin';

  @override
  String get feedbackResponsesTitle => 'Feedback & Responses';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get monitorChats => 'Monitor Chats';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get manageResponse => 'Manage Response';

  @override
  String get manageAnnouncements => 'Manage Announcements';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get viewDoctorsTitle => 'View Doctors';

  @override
  String get noApprovedDoctorsYet => 'No approved doctors yet!';

  @override
  String get qualificationLabel => 'Qualification';

  @override
  String get specializationLabel => 'Specialization';

  @override
  String get experienceLabel => 'Experience';

  @override
  String get doctorFallback => 'Doctor';

  @override
  String get yearsSuffix => 'y';

  @override
  String get feedbackResponses => 'Feedback & Responses';

  @override
  String get errorLabel => 'Error';

  @override
  String get monitorChatsTitle => 'Monitor Chats';

  @override
  String get monitorChatsSubtitle =>
      'All active chats between doctors and patients will appear below.';

  @override
  String get active => 'Active';

  @override
  String get monitor => 'Monitor';

  @override
  String get patientFallback => 'Patient';

  @override
  String get couldNotOpenFileDesc => 'The system could not open this URL:';

  @override
  String get urlEmptyOrMalformedDesc => 'URL is empty or malformed:';

  @override
  String get httpStatusCodeLabel => 'HTTP request statusCode:';

  @override
  String get present => '(present)';

  @override
  String get none => '(none)';

  @override
  String get statusLabel => 'status:';

  @override
  String get redirectsLabel => 'redirects:';

  @override
  String get first700CharsLabel => 'first 700 chars';

  @override
  String get requestErrorDesc => 'Request error:';

  @override
  String get failedToLoadImageDesc => 'Failed to load image.';

  @override
  String get monitoringModeTitle => 'Monitoring Mode';

  @override
  String get readOnly => 'Read-only';

  @override
  String get patientLabel => 'Patient';

  @override
  String get monitorTipLongPress =>
      'Tip: Long-press an image bubble to see HTTP error details.';

  @override
  String get manageExerciseTitle => 'Manage Exercise';

  @override
  String get search => 'Search';

  @override
  String get noMediaYet => 'No media yet!';

  @override
  String get manageAnnouncementsTitle => 'Manage Announcements';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get noAnnouncementsYet => 'No announcements yet!';

  @override
  String get editAnnouncementTitle => 'Edit Announcement';

  @override
  String get sendToLabel => 'Send To';

  @override
  String get announcementHint => 'Write your announcement here...';

  @override
  String get audiencePatient => 'Patient';

  @override
  String get audienceDoctor => 'Doctor';

  @override
  String get audienceBoth => 'Both';

  @override
  String get deleteTitle => 'Delete';

  @override
  String get deleteAnnouncementConfirmDesc =>
      'Are you sure you want to delete this announcement?';

  @override
  String get loginTitle => 'Login';

  @override
  String get adminNotLoggedIn => 'Admin not logged in!';

  @override
  String get announcementDeletedSuccessDesc =>
      'Announcement deleted successfully.';

  @override
  String get announcementUpdatedSuccessDesc =>
      'Announcement updated successfully.';

  @override
  String get failedTitle => 'Failed';

  @override
  String get emptyTitle => 'Empty';

  @override
  String get writeAnnouncementFirstDesc =>
      'Please write an announcement first.';

  @override
  String get announcementDeletedFor => 'Announcement deleted for';

  @override
  String get announcementEditedFor => 'Announcement edited for';

  @override
  String get adminAnnouncementDeletedNotif => 'An announcement was deleted.';

  @override
  String get adminAnnouncementEditedNotif => 'An announcement was edited.';

  @override
  String get userAnnouncementRemovedNotif => 'An announcement was removed.';

  @override
  String get userAnnouncementUpdatedNotif => 'An announcement was updated.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get firstNameLabel => 'First Name';

  @override
  String get firstNameHint => 'Enter first name';

  @override
  String get lastNameLabel => 'Last Name';

  @override
  String get lastNameHint => 'Enter last name';

  @override
  String get ageLabel => 'Age';

  @override
  String get ageHint => 'Enter age';

  @override
  String get emailReadOnlyLabel => 'Email (Read only)';

  @override
  String get emailHint => 'Email';

  @override
  String get loadFailedTitle => 'Load Failed';

  @override
  String get couldNotLoadProfileDesc => 'Could not load profile.';

  @override
  String get imageErrorTitle => 'Image Error';

  @override
  String get couldNotPickImageDesc => 'Could not pick image.';

  @override
  String get imageUploadFailedDesc => 'Image upload failed.';

  @override
  String get validationTitle => 'Validation';

  @override
  String get fixHighlightedFieldsDesc => 'Please fix the highlighted fields.';

  @override
  String get notLoggedInTitle => 'Not Logged In';

  @override
  String get pleaseLoginAgainDesc => 'Please login again.';

  @override
  String get profileUpdatedSuccessDesc => 'Profile updated successfully.';

  @override
  String get saveFailedTitle => 'Save Failed';

  @override
  String get failedUpdateProfileDesc => 'Failed to update profile.';

  @override
  String get profileUpdatedNotificationMsg =>
      'Your profile was updated successfully.';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get firstNameMin2 => 'First name must be at least 2 characters';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get lastNameMin2 => 'Last name must be at least 2 characters';

  @override
  String get ageRequired => 'Age is required';

  @override
  String get enterValidAge => 'Enter a valid age';

  @override
  String get ageRange10to120 => 'Age must be between 10 and 120';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get allReadTitle => 'All Read!';

  @override
  String get allReadDesc => 'All notifications have been marked as read.';

  @override
  String get nothingNewTitle => 'Nothing New';

  @override
  String get nothingNewDesc => 'No unread notifications found.';

  @override
  String get markReadFailedDesc => 'Failed to mark all as read.';

  @override
  String get failedLoadNotifications => 'Failed to load notifications';

  @override
  String get noNotificationsYet => 'No notification yet!';

  @override
  String get notificationFallback => 'Notification';

  @override
  String get feedbackDetailTitle => 'Feedback Detail';

  @override
  String get failedToLoadFeedback => 'Failed to load feedback';

  @override
  String get feedbackUserNotFound => 'Feedback user not found.';

  @override
  String get pleaseWriteResponseFirst => 'Please write a response first.';

  @override
  String get adminUpdatedResponseToYourFeedback =>
      'Admin updated the response to your feedback.';

  @override
  String get adminRespondedToYourFeedback =>
      'Admin responded to your feedback.';

  @override
  String get feedbackResponseEdited => 'A feedback response was edited.';

  @override
  String get feedbackResponseSent => 'A feedback response was sent.';

  @override
  String get editResponseTitle => 'Edit Response';

  @override
  String get writeResponseTitle => 'Write Response';

  @override
  String get responseHint => 'Write your response here...';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get sendResponse => 'Send Response';

  @override
  String get updated => 'Updated';

  @override
  String get sent => 'Sent';

  @override
  String get responseUpdatedSuccessfully => 'Response updated successfully.';

  @override
  String get responseSentToUser => 'Response sent to the user.';

  @override
  String get empty => 'Empty';

  @override
  String get login => 'Login';

  @override
  String get emptyAnnouncementTitle => 'Empty Announcement';

  @override
  String get emptyAnnouncementDesc => 'Please write an announcement first.';

  @override
  String get addAnnouncementTitle => 'Add Announcement';

  @override
  String get sendTo => 'Send To';

  @override
  String get both => 'Both';

  @override
  String get announcementAddedFor => 'Announcement added for';

  @override
  String get failedToAddAnnouncement => 'Failed to add announcement.';

  @override
  String welcome(String name) {
    return 'Welcome $name!';
  }
}
