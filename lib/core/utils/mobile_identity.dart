/// Canonical identity used by validation and all authentication API requests.
/// National Indian numbers default to +91; explicit international numbers retain
/// their country code. No account or authorization decision belongs here.
String normalizeMobileIdentity(String value) {
  var number = value.trim().replaceAll(RegExp(r'[\s()-]'), '');
  if (number.startsWith('00')) number = '+${number.substring(2)}';
  if (RegExp(r'^[6-9]\d{9}$').hasMatch(number)) {
    number = '+91$number';
  } else if (RegExp(r'^0[6-9]\d{9}$').hasMatch(number)) {
    number = '+91${number.substring(1)}';
  } else if (RegExp(r'^91[6-9]\d{9}$').hasMatch(number)) {
    number = '+$number';
  }
  if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number)) {
    throw const FormatException(
        'Enter a 10-digit Indian mobile number or include the country code.');
  }
  return number;
}
