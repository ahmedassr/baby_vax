Map<String, String> en = {
  "app_name": "Baby Vax",
  // Shared → →
  // Label:
  "email_label": "Email",
  "password_label": "Password",
  "name_label": "Name",
  "weight_label": "Weight",
  "height_label": "Height",
  "blood_percentage_label": "Blood Percentage",
  "head_size_label": "Head Size",
  "full_name_label": "Full Name",
  "date_of_birth_label": "Date of Birth",
  // Messages:
  "unexpected_error": "An unexpected error occurred.",
  "no_description": "No description available.",
  "empty_email_error_msg": "Email can't be empty.",
  "empty_password_error_msg": "Password can't be empty.",
  "empty_name_error_msg": "Name can't be empty.",
  "empty_date_of_birth_error_msg": "Date of birth can't be empty.",
  "empty_blood_percentage_error_msg": "Blood percentage can't be empty.",
  "empty_weight_error_msg": "Weight can't be empty.",
  "empty_head_size_error_msg": "Head size can't be empty.",
  "empty_height_error_msg": "Height can't be empty.",
  // Alert Title
  "attention": "Attention",
  "error": "Error",
  "success": "Success",
  // Alert Button Text:
  "yes": "Yes",
  "cancel": "Cancel",

  // Auth - Login → Controller:
  "LoginController_login_failed_msg": "Failed to login.",
  // View
  "LoginView_login_title": "Login",
  "LoginView_login_hint": "Log in to continue",
  "LoginView_create_new_account": "Create New Account",

  // Auth - SignUp → Controller:
  "SignupController_create_user_failed_msg":
      "Failed to create user profile. Please try again.",
  "SignupController_create_user_success_msg": "User created successfully.",
  "SignupController_updated_user_success_msg": "User updated successfully.",
  // View
  "SignupView_sign_up_title": "Sign Up",
  "SignupView_sign_up_hint": "Create an account for your baby care journey",
  "SignupView_baby_information_label": "Baby Information",
  "SignupView_baby_measurements_label": "Baby's Measurements",
  "SignupView_weight_label": "Weight (kg)",
  "SignupView_height_label": "Height (cm)",
  "SignupView_head_size_label": "Head Size (cm)",
  "SignupView_blood_label": "Blood % (g/dl)",

  // Edit User → Controller:
  "EditUserController_update_user_failed": "Failed to update user.",
  // View
  "EditUserView_edit_user_title": "Edit User",
  "EditUserView_edit_label": "Edit",

  // Home → Controller:
  "HomeController_id_missing_msg": "The user ID is missing.",
  // Widgets
  "NextVaccinationCard_next_vaccination_title": "Next Vaccination",

  // MainMenu → Controller:
  "MainMenuController_home_title": "Home",
  "MainMenuController_medical_dates_title": "Medical Dates",
  "MainMenuController_tips_title": "Tips",
  "MainMenuController_settings_title": "Settings",

  // MedicalDateDetails → Controller:
  "MedicalDateDetailsController_missing_medical_dates_msg":
      "The current medical dates is missing",
  "MedicalDateDetailsController_fetch_failed_msg":
      "Failed to fetch medical date details",
  "MedicalDateDetailsController_state_update_failed_msg":
      "Failed to update the date state",
  // View
  "MedicalDateDetailsView_title": "Medical Date Details",
  "MedicalDateDetailsView_details_and_notes": "Vaccination details and notes",
  // Widgets
  "MedicalDateDetailCard_medical_date_label": "Medical date",
  "MedicalDateDetailCard_date_fallback_label": "Date not provided",
  "MedicalDateDetailCard_notes_label": "Notes",

  // MedicalDates → Controller:
  "MedicalDatesController_fetch_failed": "Failed to fetch medical dates.",
  // View
  "SearchOnMedicalDates_title": "Search Medical Dates",
  "SearchOnMedicalDates_search_field_label":
      "Which medical dates are you looking for?",
  // Widgets
  "MedicalDatesHeader_medical_dates_label": "Medical Dates",
  "MedicalDatesHeader_upcoming_appointments_label":
      "Track your baby's upcoming and past appointments.",
  "MedicalDatesHeader_no_upcoming_appointments_label":
      "No upcoming appointments. Add medical dates to stay on track.",

  // Settings → Controller:
  "SettingsController_logout_alert_msg": "Are you sure you want to log out?",
  // View:
  "SettingsView_language_label": "Language",
  "SettingsView_terms_and_conditions_label": "Terms And Conditions",
  "SettingsView_about_us_label": "About US",
  "SettingsView_logout_label": "Log Out",
  "SettingsView_select_language": "Select Language",
  // Widgets
  "AppSettingDarkModeSwitch_dark_mode_label": "Dark Mode",
  "AppSettingDarkModeSwitch_light_mode_label": "Light Mode",

  // Tip Details → Controller:
  "TipDetailsController_missing_tip_msg": "The current tip is missing",
  // View
  "TipDetailsView_tip_details_title": "Tip Details",
  "TipDetailsView_empty_state_text": "Tip details are not available.",

  // Tips → Controller:
  "TipsController_fetch_failed_msg": "Failed to fetch Tips.",
  // View
  "SearchOnTips_title": "Search Tips",
  "SearchOnTips_search_field_label": "Which tips are you looking for?",
  "TipsView_empty_state_text": "No tips available yet. Check back later!",
  //Widgets
  "TipsHeader_tips_title": "Tips",
  "TipsHeader_tips_hint":
      "Helpful advice to care for your baby’s health and growth.",

  // Enum → → →

  // Vaccination Time Status Enum:
  "VaccinationTimeStatusEnum_overdue": "Overdue",
  "VaccinationTimeStatusEnum_today": "Today",
  "VaccinationTimeStatusEnum_tomorrow": "Tomorrow",
  "VaccinationTimeStatusEnum_hoursLeft": "Hours Left",
  "VaccinationTimeStatusEnum_daysLeft": "Days Left",
  "VaccinationTimeStatusEnum_weeksLeft": "Weeks Left",
  "VaccinationTimeStatusEnum_monthsLeft": "Months Left",
  "VaccinationTimeStatusEnum_yearsLeft": "Years Left",
  "show": "Show",
  "hide": "Hide",
  // Medical disclaimer:
  "MedicalDisclaimer_title": "This is not medical advice",
  "MedicalDisclaimer_body":
      "This schedule is for information only. Always follow your own doctor and your country's national immunization schedule, which may differ from what you see here.",
  "MedicalDisclaimer_source":
      "Based on the Palestinian Ministry of Health routine childhood schedule, which follows WHO EPI recommendations.",
  // Errors:
  "error_generic_msg": "Something went wrong. Please try again.",
  "error_offline_msg":
      "You appear to be offline. Your schedule is still available, but changes will not be saved until you reconnect.",
  "error_email_already_in_use_msg": "That email is already registered.",
  "error_invalid_email_msg": "That email address does not look right.",
  "error_weak_password_msg":
      "Your password is too simple. Please choose a stronger one.",
  "error_invalid_credentials_msg":
      "Incorrect email or password. Please try again.",
  "error_user_disabled_msg": "This account has been disabled.",
  "error_too_many_requests_msg":
      "Too many attempts. Please wait a moment and try again.",
  "error_session_expired_msg":
      "Your session has expired. Please sign in again.",
  "error_permission_denied_msg": "You do not have permission to do that.",
  "error_not_found_msg": "We could not find that record.",
  // Delete account:
  "SettingsView_delete_account_label": "Delete account",
  "DeleteAccount_title": "Delete your account",
  "DeleteAccount_warning_msg":
      "This permanently deletes your account, your child's profile and the whole vaccination schedule. Reminders will stop. This cannot be undone.",
  "DeleteAccount_password_label": "Confirm your password",
  "DeleteAccount_password_hint": "Password",
  "DeleteAccount_confirm_button": "Delete permanently",
  "DeleteAccount_cancel_button": "Keep my account",
  "DeleteAccount_empty_password_msg": "Please enter your password to continue.",
  "DeleteAccount_wrong_password_msg": "That password is not correct.",
  "DeleteAccount_requires_recent_login_msg":
      "For your security, please sign out, sign in again, and then delete your account.",
  "DeleteAccount_network_error_msg":
      "No connection. Deleting an account needs internet, so please try again when you are online.",
  "DeleteAccount_not_signed_in_msg": "You are not signed in.",
  "DeleteAccount_unknown_error_msg":
      "Something went wrong and your account was not deleted. Please try again.",
  "DeleteAccount_success_msg":
      "Your account and all of its data have been deleted.",
  // Birth date validation:
  "invalid_date_of_birth_error_msg": "Please enter a valid date of birth.",
  "future_date_of_birth_error_msg":
      "The date of birth cannot be in the future.",
  "too_old_date_of_birth_error_msg":
      "This app covers the vaccination schedule up to age 18.",
  // Notifications:
  "Notification_vaccine_today_title": "Vaccination due today",
  "Notification_vaccine_today_body":
      "@child - today is the appointment for: @vaccine",
  "Notification_vaccine_tomorrow_title": "Vaccination due tomorrow",
  "Notification_vaccine_tomorrow_body":
      "@child - tomorrow is the appointment for: @vaccine",
  "Notification_permission_denied_msg":
      "Notifications are turned off, so vaccine reminders will not appear. You can turn them on in your device settings.",
  // Medical Date State Enum:
  "Pending": "Pending",
  "Completed": "Completed",
  "Skipped": "Skipped",

  // Dose state actions:
  // Generated vaccines, by MedicalDatesModel.code:
  "Vaccine_bcg_hepb_birth_name": "BCG and Hepatitis B (1st dose)",
  "Vaccine_bcg_hepb_birth_description":
      "Protects against tuberculosis and hepatitis B. Given at birth.",
  "Vaccine_penta_opv_pcv_1_name": "First DTP-HepB-Hib, Polio and Pneumococcal",
  "Vaccine_penta_opv_pcv_1_description":
      "Prevents diphtheria, tetanus, whooping cough, hepatitis B, Hib, polio, and pneumonia. Given at 2 months.",
  "Vaccine_penta_opv_pcv_2_name": "Second DTP-HepB-Hib, Polio and Pneumococcal",
  "Vaccine_penta_opv_pcv_2_description":
      "Second dose to strengthen protection. Given at 4 months.",
  "Vaccine_penta_opv_pcv_3_name": "Third DTP-HepB-Hib, Polio and Pneumococcal",
  "Vaccine_penta_opv_pcv_3_description":
      "Final primary dose of early vaccines. Given at 6 months.",
  "Vaccine_measles_1_name": "Measles (1st dose)",
  "Vaccine_measles_1_description":
      "Protects against measles. Given at 9 months.",
  "Vaccine_mmr_varicella_pcv_booster_name":
      "MMR, Varicella and Pneumococcal Booster",
  "Vaccine_mmr_varicella_pcv_booster_description":
      "Protects against measles, mumps, rubella, chickenpox, and boosts pneumonia protection. Given at 12 months.",
  "Vaccine_penta_opv_mmr_2_booster_name":
      "Booster DTP-HepB-Hib, Polio and MMR (2nd dose)",
  "Vaccine_penta_opv_mmr_2_booster_description":
      "Booster for earlier vaccines and second dose of MMR. Given at 18 months.",
  "Vaccine_school_entry_boosters_name":
      "School Entry Boosters: DTP + Polio + Varicella (2nd dose)",
  "Vaccine_school_entry_boosters_description":
      "Boosters to protect before school: diphtheria, tetanus, polio, chickenpox. Given around 5 years.",
  "Vaccine_hpv_name": "HPV Vaccine",
  "Vaccine_hpv_description":
      "Protects against human papillomavirus. Given at age 10-12, mostly for girls (sometimes boys).",
  "Vaccine_td_booster_name": "Td Booster (Tetanus & Diphtheria)",
  "Vaccine_td_booster_description":
      "Teenage booster for tetanus and diphtheria. Given at age 15.",
  "Notification_open_settings": "Open settings",
  "Reminder_default_child_name": "Your baby",
  "saved_offline_msg":
      "Saved on this phone. It will sync when you are back online.",
  "MedicalDateActions_mark_completed": "Mark as given",
  "MedicalDateActions_mark_skipped": "Mark as skipped",
  "MedicalDateActions_undo": "Undo (mark as pending)",
  "MedicalDateDetails_confirm_future_completion_msg":
      "This dose is scheduled for @date. Mark it as given?"
};
