import 'dart:ui';

class DEuroColors {
  static const dEuroGold = Color.fromARGB(255, 242, 146, 43);
  static const grey = Color.fromARGB(255, 189, 193, 206);
  static const neutralGrey = Color.fromARGB(255, 133, 141, 173);
  static const neutralGrey98 = Color.fromARGB(255, 243, 244, 247);
  static const neutralGrey93 = Color.fromARGB(255, 233, 234, 241);
  static const anthracite = Color.fromARGB(255, 39, 43, 56);
  static const titanGray60 = Color.fromARGB(255, 139, 146, 168);
}

class RealUnitColors {
  static final basic = _Basic();
  static final status = _Status();

  static const realUnitBlue = Color.fromARGB(255, 25, 136, 198);
  static const realUnitBlack = Color.fromARGB(255, 52, 50, 51);
  static const brand700 = Color.fromARGB(255, 236, 243, 249);
  static const darkBlue = Color.fromARGB(255, 3, 76, 129);
  static const green = Color.fromARGB(255, 76, 172, 54);
  static const okker = Color(0xFFE9AD3F);

  static const neutral900 = Color.fromARGB(255, 15, 23, 42);
  static const neutral500 = Color.fromARGB(255, 100, 116, 139);
  static const neutral400 = Color.fromARGB(255, 148, 163, 184);
  static const neutral300 = Color(0xFFCED5DE);
  static const neutral200 = Color.fromARGB(255, 226, 232, 240);
  static const neutral100 = Color.fromARGB(255, 242, 245, 248);
  static const neutral50 = Color(0xFFF8FAFC);
}

class _Basic {
  final white = Color(0xFFFFFFFF);
  final black = Color(0xFF000000);
}

class _Status {
  final red600 = Color(0xFFE02523);
  final red100 = Color(0xFFFCE8E8);
}
