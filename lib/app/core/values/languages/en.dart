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
  "LoginView_login_title": "Log in",
  "LoginView_login_hint": "Log in to continue",
  "LoginView_create_new_account": "Create a new account",

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
  "EditUserView_edit_user_title": "Edit profile",
  "EditUserView_edit_label": "Edit",

  // Home → Controller:
  "HomeController_id_missing_msg": "The user ID is missing.",
  // Widgets
  "NextVaccinationCard_next_vaccination_title": "Next Vaccination",

  // MainMenu → Controller:
  "MainMenuController_home_title": "Home",
  "MainMenuController_medical_dates_title": "Schedule",
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
  "AppSettingDarkModeSwitch_dark_mode_label": "Dark",
  "AppSettingDarkModeSwitch_light_mode_label": "Light",

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
  "LoginView_welcome_back": "Welcome Back",
  "MedicalDatesView_add_custom_date": "Add a custom date",
  "SplashView_tagline": "Care • Protection • Growth",
  "AlertModel_field_required_msg": "@field is missing.",
  "VaccinationTimeStatus_hours_left_one": "1 hour left",
  "VaccinationTimeStatus_hours_left_other": "@count hours left",
  "VaccinationTimeStatus_days_left_one": "1 day left",
  "VaccinationTimeStatus_days_left_other": "@count days left",
  "VaccinationTimeStatus_weeks_left_one": "1 week left",
  "VaccinationTimeStatus_weeks_left_other": "@count weeks left",
  "VaccinationTimeStatus_months_left_one": "1 month left",
  "VaccinationTimeStatus_months_left_other": "@count months left",
  "VaccinationTimeStatus_years_left_one": "1 year left",
  "VaccinationTimeStatus_years_left_other": "@count years left",
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
      "This dose is scheduled for @date. Mark it as given?",
  // v1.1 design system
  "loading_label": "Loading",
  "optional_suffix": "(optional)",
  "status_semantic_label": "Status: @status",
  "state_error_title": "Something went wrong",
  "state_empty_title": "Nothing here yet",
  "retry_label": "Try again",
  "close_label": "Close",
  "progress_semantic_label": "@done of @total doses done",
  "step_counter": "Step @current of @total",
  "not_recorded_label": "not recorded",
  // v1.1 onboarding
  "Onboarding_skip": "Skip",
  "Onboarding_get_started": "Get started",
  "next_label": "Next",
  "back_label": "Back",
  "Onboarding_schedule_title": "Every dose, in one place",
  "Onboarding_schedule_body":
      "Add your baby's date of birth and Baby Vax builds the whole vaccination schedule, grouped by age, so you always know what is next.",
  "Onboarding_reminders_title": "Gentle reminders",
  "Onboarding_reminders_body":
      "A reminder the evening before and the morning of each dose. They are set on this phone, so they work without internet.",
  "Onboarding_record_title": "A record you can share",
  "Onboarding_record_body":
      "Note where and when each dose was given, follow your baby's growth, and share a vaccination card with your clinic.",
  // v1.1 sign-in and password reset
  "LoginView_forgot_password": "Forgot password?",
  "LoginView_no_account": "New to Baby Vax?",
  "short_password_error_msg": "Use at least @min characters.",
  "invalid_number_error_msg": "Please enter a number.",
  "out_of_range_error_msg": "Please enter a value between @min and @max.",
  "ForgotPassword_title": "Reset your password",
  "ForgotPassword_hint":
      "Enter the email you signed up with and we will send you a link to choose a new password.",
  "ForgotPassword_send": "Send reset link",
  "ForgotPassword_sent_title": "Check your inbox",
  "ForgotPassword_sent_body":
      "If an account exists for @email, a link to reset the password is on its way. It can take a few minutes, so check your spam folder too.",
  "ForgotPassword_back_to_login": "Back to log in",
  // v1.1 sign-up stepper
  "Signup_step_account": "Your account",
  "Signup_step_baby": "Your baby",
  "Signup_step_measurements": "Measurements",
  "Signup_step_reminders": "Reminders",
  "Signup_step_summary": "Check and create",
  "Signup_step_account_hint":
      "You will use this email and password to sign in on any phone.",
  "Signup_password_helper": "At least @min characters.",
  "Signup_step_baby_hint":
      "The vaccination schedule is built from your baby's date of birth.",
  "Signup_baby_name_label": "Baby's name",
  "Signup_birthday_hint": "Tap to choose a date",
  "Signup_birthday_helper": "Used to work out when each dose is due.",
  "Signup_sex_label": "Sex",
  "Signup_sex_helper": "Growth charts are different for girls and boys.",
  "sex_female": "Girl",
  "sex_male": "Boy",
  "empty_sex_error_msg": "Please choose one.",
  "Signup_step_measurements_hint":
      "If you have them from the birth or a recent check-up, add them here. You can skip this step and add them later.",
  "unit_kg": "kg",
  "unit_cm": "cm",
  "unit_g_dl": "g/dL",
  "Signup_skip_for_now": "Skip for now",
  "Signup_reminders_title": "Reminders that work offline",
  "Signup_reminders_body":
      "Baby Vax reminds you at @evening the evening before each dose and at @morning on the day. The reminders are set on this phone, so they work without internet.",
  "Signup_reminders_why":
      "Your phone will ask whether Baby Vax may send notifications. Without them the reminders cannot appear.",
  "Signup_reminders_turn_on": "Turn on reminders",
  "Signup_reminders_not_now": "Not now",
  "Signup_reminders_granted": "Reminders are on.",
  "Signup_reminders_denied":
      "Reminders are off for now. You can turn them on later in your phone's settings.",
  "Signup_step_summary_hint":
      "Check the details below. You can change anything before creating the account.",
  "Signup_create_account": "Create account",
  "Signup_schedule_note":
      "Baby Vax will build the vaccination schedule from this date of birth.",
  "reminders_on_label": "On",
  "reminders_off_label": "Off",
  "edit_label": "Edit",
  "edit_section_label": "Edit @section",
  // v1.1 schedule age groups
  "age_at_birth": "At birth",
  "age_other": "Other dates",
  "age_months_one": "1 month",
  "age_months_other": "@count months",
  "age_years_one": "1 year",
  "age_years_other": "@count years",
  // v1.1 home and schedule
  "HomeView_overline": "Vaccination schedule for",
  "HomeView_next_dose": "Next dose",
  "HomeView_overdue_dose": "Overdue dose",
  "HomeView_open_dose": "View dose",
  "HomeView_more_overdue": "Also overdue: @count",
  "HomeView_all_done_title": "Every dose is recorded",
  "HomeView_all_done_body":
      "Each dose in the schedule is marked as given or skipped.",
  "HomeView_no_schedule_title": "No schedule yet",
  "HomeView_no_schedule_body":
      "Pull down to refresh. If it stays empty, check your connection.",
  "HomeView_progress_title": "Schedule progress",
  "HomeView_progress_body": "@done of @total doses given",
  "HomeView_measurements_title": "Latest measurements",
  "HomeView_profile_title": "Profile",
  "HomeView_no_profile_title": "We could not find your profile",
  "HomeView_no_profile_body": "Check your connection and try again.",
  "Schedule_filter_all": "All",
  "Schedule_empty_filter_title": "No doses here",
  "Schedule_empty_filter_body": "Try another filter.",
  "Schedule_empty_title": "No schedule yet",
  "Schedule_empty_body":
      "Your baby's schedule appears here once the account is set up.",
  "Schedule_filter_label": "Show",
  // v1.1 alerts
  "ok_label": "OK",
  // v1.1 dose details
  "MedicalDateDetails_scheduled_label": "Scheduled",
  "MedicalDateDetails_age_label": "Age",
  "MedicalDateDetails_about_title": "About this dose",
  // v1.1 tips
  "TipsView_empty_title": "No tips yet",
  // v1.1 edit profile
  "EditUser_save": "Save changes",
  "EditUser_saved_msg": "Profile saved.",
  "EditUser_email_readonly": "Your sign-in email. It cannot be changed here.",
  "EditUser_birthday_helper":
      "Changing it moves every dose in the schedule to match.",
  "EditUser_birthday_change_confirm":
      "The date of birth changed, so every dose in the schedule will move to match it. Doses you marked as given or skipped keep their status, and reminders are rebuilt.",
  "EditUser_birthday_change_yes": "Move the schedule",
  // v1.1 settings
  "Settings_appearance": "Appearance",
  "Settings_theme_system": "System",
  "Settings_notifications": "Notifications",
  "Settings_notifications_hint": "Opens your phone's settings for Baby Vax.",
  "Settings_about": "About",
  "Settings_about_app": "About Baby Vax",
  // v1.1 vaccination record
  "Record_sheet_title": "Record this dose",
  "Record_sheet_hint":
      "Everything here is optional, but it makes the vaccination card more useful at the clinic.",
  "Record_given_date": "Date given",
  "Record_clinic": "Clinic or place",
  "Record_lot": "Batch / lot number",
  "Record_lot_hint": "Printed on the vial or your clinic card",
  "Record_note": "Note",
  "Record_save": "Save",
  "Record_skip_details": "Mark as given without details",
  "Record_section_title": "Vaccination record",
  "Record_add_details": "Add details",
  "Record_edit": "Edit details",
  "Record_none": "No details recorded yet.",
  // v1.1 vaccination card
  "Card_title": "Vaccination card",
  "Card_col_vaccine": "Vaccine",
  "Card_col_status": "Status",
  "Card_col_scheduled": "Scheduled",
  "Card_col_given": "Given",
  "Card_col_clinic": "Clinic",
  "Card_col_lot": "Lot",
  "Card_generated": "Generated by Baby Vax on this phone on",
  "Card_export": "Vaccination card",
  "Card_export_hint":
      "A PDF in English and Arabic to share with your clinic or print.",
  "Card_share": "Share",
  "Card_print": "Print",
  "Card_failed": "The card could not be created. Please try again.",
  "Card_preparing": "Preparing the card…",
  // v1.1 home quick actions
  "HomeView_quick_actions": "Quick actions",
  // v1.1 growth tracker
  "Growth_title": "Growth",
  "Growth_add": "Add measurement",
  "Growth_add_title": "Add a measurement",
  "Growth_edit_title": "Edit measurement",
  "Growth_sheet_hint":
      "Fill in any of the three, from the clinic or your own scale.",
  "Growth_date": "Date measured",
  "Growth_need_one_value": "Enter at least one measurement.",
  "Growth_delete": "Delete measurement",
  "Growth_delete_confirm": "Delete this measurement?",
  "Growth_save_failed": "The measurement could not be saved. Please try again.",
  "Growth_history": "History",
  "Growth_empty_title": "No measurements yet",
  "Growth_empty_body":
      "Add the weight, height or head size from a clinic visit to start the chart.",
  "Growth_axis_months": "Age (months)",
  "Growth_no_value_for_metric": "No measurement of this kind yet.",
  "Growth_reading_around": "Around the @ord percentile",
  "Growth_reading_below": "Below the 3rd percentile",
  "Growth_reading_above": "Above the 97th percentile",
  "Growth_reading_note":
      "Percentiles compare your baby with WHO reference children of the same age and sex. They are not a diagnosis: one reading means little on its own, so talk to your doctor about any concern.",
  "Growth_over_five":
      "The WHO growth standards used here cover birth to 5 years, so no percentile is shown for this measurement.",
  "Growth_no_sex":
      "Add your baby's sex in the profile to compare with the WHO growth standards.",
  "Growth_legend":
      "Lines: WHO 3rd, 15th, 50th, 85th and 97th percentiles. Dots: your measurements.",
  "Growth_attribution":
      "Reference curves: WHO Child Growth Standards (2006). Licence: CC BY-NC-SA 3.0 IGO.",
  "Growth_chart_semantic": "@metric chart, measurements: @count",
  // v1.1 custom reminders
  "Reminder_custom_default_body": "A reminder you set in Baby Vax.",
};
