class Validations {
  static String? timeValidation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Time is required';
    }

    // Regular expression to match the time in 12-hour format with AM/PM
    RegExp regExp = RegExp(r'^(0?[1-9]|1[0-2]):[0-5][0-9]\s*(?:AM|PM|am|pm)?$');

    if (!regExp.hasMatch(value)) {
      return 'Invalid time format';
    }

    return null;
  }

  static String? ratingValidation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Rating is required';
    }
    try {
      double rating = double.parse(value);
      if (rating < 0.0 || rating > 5.0) {
        return 'Rating must be between 0.0 and 5.0';
      }
    } catch (e) {
      return 'Invalid rating format';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    var passNonNullValue = value ?? "";
    RegExp reg = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

    if (passNonNullValue.isEmpty) {
      return 'Please enter your email';
    } else if (!passNonNullValue.contains("@")) {
      return ("Email should contains @");
    } else if (!reg.hasMatch(passNonNullValue)) {
      return ("Email is not valid");
    }
    return null;
  }

  static String? passwordValidation(String? value) {
    var passNonNullValue = value ?? "";
    RegExp regex =
        RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    } else if (value.length <= 8) {
      return ("Password Must be more than 8 characters");
    } else if (!regex.hasMatch(passNonNullValue)) {
      return ("Password should contain upper,lower,digit and Special character ");
    }
    return null;
  }

  static String? nameValidation(String? value) {
    var nameNonNullValue = value ?? "";
    RegExp regExp = RegExp('[a-zA-Z]');
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    } else if (!regExp.hasMatch(nameNonNullValue)) {
      return ("No number and special characters allowed.");
    }
    return null;
  }

  static String? addressValidation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    }
    return null;
  }

  static String? mobileValidation(String? value) {
    RegExp regExp = RegExp(r'^\d{10}$');
    var phoneNonNullValue = value ?? "";

    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    } else if (!regExp.hasMatch(phoneNonNullValue)) {
      return ("Only 10 digit allowed");
    }
    return null;
  }

  static String? requireField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    }

    return null;
  }
}
