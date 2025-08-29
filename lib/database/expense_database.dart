import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:mini_exp_tracker/models/expense.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseDatabase extends ChangeNotifier {
  static late Isar isar;
  List<Expense> _allExpenses = [];
  ExpenseDatabase() {
    readExpense();
  }

  //*SETUP*//

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  //*GETTER*//
  List<Expense> get allExpense => _allExpenses;

  //*OPERATIONS*//
  //create - add a new expense
  Future<void> createNewExpenses(Expense newExpense) async {
    await isar.writeTxn(() => isar.expenses.put(newExpense));
    await readExpense();
  }

  //read - exp from db
  Future<void> readExpense() async {
    List<Expense> fetchExpenses = await isar.expenses.where().findAll();
    //give to local exp list
    _allExpenses.clear();
    _allExpenses.addAll(fetchExpenses);
    //update UI
    notifyListeners();
  }

  //update
  Future<void> updateExpense(int id, Expense updatedExpense) async {
    updatedExpense.id =
        id; //make sure the new expense has the same id  as the existing one
    //update in db
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));
    //re-read from db
    await readExpense();
  }

  //delete - an exp
  Future<void> deleteExpense(int id) async {
    //delete an exp
    await isar.writeTxn(() => isar.expenses.delete(id));
    //re-read from db
    await readExpense();
  }

  //*HELPER*//

  //calculate total expense for each month
  Future<Map<String, double>> calculateMonthlyTotals() async {
    await readExpense();
    //create a map to keep the track of totall expense per month ,year
    Map<String, double> monthlyTotals = {};

    //iterate overall exp.
    for (var expense in _allExpenses) {
      //extract year & month from the date of the expense
      String yearMonth = '${expense.date.year}-${expense.date.month}';
      //if the year-month is not in the map
      if (!monthlyTotals.containsKey(yearMonth)) {
        monthlyTotals[yearMonth] = 0;
      }
      // add the expense amt
      monthlyTotals[yearMonth] = monthlyTotals[yearMonth]! + expense.amount;
    }
    return monthlyTotals;
  }

  //cAlculate current month total
  Future<double> calculateCurrentMonthTotal() async {
    //ensure expense are from db
    await readExpense();

    //get current month, year
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    //filter the expense to include  those for this month ,year
    List<Expense> currentMonthExpenses = _allExpenses.where((expense) {
      return expense.date.month == currentMonth &&
          expense.date.year == currentYear;
    }).toList();

    //calculate total amt for the current month
    double total = currentMonthExpenses.fold(
      0,
      (sum, expense) => sum + expense.amount,
    );
    return total;
  }

  //get start month
  int getStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().month;
    }
    //sort the expense by date
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));
    return _allExpenses.first.date.month;
  }

  //get start year
  int getStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().year;
    }
    //sort the expense by date
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));
    return _allExpenses.first.date.year;
  }
}

//calculate the no of month since the fst month
int calculateMonthCount(int startYear, startMonth, currentYear, currentMonth) {
  int monthCount =
      (currentYear - startYear) * 12 + currentMonth - startMonth + 1;
  return monthCount;
}
