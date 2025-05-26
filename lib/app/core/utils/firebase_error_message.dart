String getFriendlyErrorMessage(String error) {
  if (error.contains('email-already-in-use')) {
    return 'this email is already existed';
  } else if (error.contains('invalid-email')) {
    return 'invalid email.';
  } else if (error.contains('weak-password')) {
    return 'Your password is too simple. Please create a stronger one.';
  } else if (error.contains('network-request-failed')) {
    return 'Please check your internet connection.';
  } else if (error.contains('The supplied auth credential is incorrect')) {
    return 'Invalid username or password. Please try again';
  } else {
    return 'Something error. please try again';
  }
}
