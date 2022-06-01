class Validators {
  static final RegExp emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );
  static final RegExp imageUrlRegExp = RegExp(
    r'(http(s?):)([/|.|\w|\s|-])*\.(?:jpg|gif|png)',
  );

  static final RegExp ageRegExp = RegExp(
    r'^[1-9][1-9]?$|^100$',
  );

  static isValidEmail(String email) {
    return emailRegExp.hasMatch(email);
  }

  static isValidImageUrl(String imageUrl){
    return imageUrlRegExp.hasMatch(imageUrl);
  }

  static isValidUsername(String username) {
    return true; // No solution as of now. Will implement later
  }

  static isValidAge(int age){
    return ageRegExp.hasMatch(age.toString());
  }

  static validateEmail(String value){
    String pattern = r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
    RegExp regExp = new RegExp(pattern);
    if (value.length == 0) {
      return false;
    }
    else if (!regExp.hasMatch(value)) {
      return false;
    } else return true;
  }

  static validatePhoneNumber(String value) {
    String pattern = r'(^(?:[+0]8)?[0-9]{10,12}$)';
    RegExp regExp = new RegExp(pattern);
    if (value.length == 0) {
      return false;
    }
    else if (!regExp.hasMatch(value)) {
      return false;
    } else return handleFilterPhoneNumber(value);
  }

  static handleFilterPhoneNumber(String phoneNumber) {
    if (phoneNumber.length == 10) {
      var string = phoneNumber.substring(0, 3);
      if (['086', '096', '097', '098', '039', '038', '037', '036', '035', '033', '034', '032'].contains(string)) return true;
      if (['090', '093', '070', '079', '077', '076', '078', '089'].contains(string)) return true;
      if (['091', '094', '083', '084', '085', '081', '082', '088'].contains(string)) return true;
      if (['092', '056', '058'].contains(string)) return true;
      if (['099', '059'].contains(string)) return true;
    }

    if (phoneNumber.length == 11 && (phoneNumber.startsWith("01") || phoneNumber.startsWith("84"))) {
      var stringPre4 = phoneNumber.substring(0, 4);
      if (['0162', '0163', '0164', '0165', '0166', '0167', '0168', '0169', '8486', '8496', '8497', '8498', '8439', '8438', '8437', '8436', '8435', '8433', '8434', '8432'].contains(stringPre4)) return true;
      if (['0120', '0121', '0122', '0126', '0128', '8490', '8493', '8470', '8479', '8477', '8476', '8478', '8489'].contains(stringPre4)) return true;
      if (['0123', '0124', '0125', '0127', '0129', '8491', '8494', '8483', '8484', '8485', '8481', '8482', '8488'].contains(stringPre4)) return true;
      if (['0188', '0186', '8492', '8456', '8458'].contains(stringPre4)) return true;
      if (['0199', '8499', '8459'].contains(stringPre4)) return true;
    }
    return false;
  }
}