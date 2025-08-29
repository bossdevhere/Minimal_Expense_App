import 'package:intl/intl.dart';

//convert the string to double
double convertStringToDouble(String string) {
  double? amount = double.tryParse(string);
  return amount ?? 0;
}

//double amt into dollars & cents
String formatAmount(double amount) {
  final format = NumberFormat.currency(
    locale: "en_US",
    symbol: "\₹",
    decimalDigits: 2,
  );
  return format.format(amount);
}

//get current month name
String getCurrentMonthName() {
  DateTime now = DateTime.now();
  List<String> months = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
  ];
  return months[now.month - 1];
}
