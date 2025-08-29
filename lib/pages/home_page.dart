import 'package:flutter/material.dart';
import 'package:mini_exp_tracker/bar%20graph/bar_graph.dart';
import 'package:mini_exp_tracker/components/my_list_tile.dart';
import 'package:mini_exp_tracker/database/expense_database.dart';
import 'package:mini_exp_tracker/helper/helper_functions.dart';
import 'package:mini_exp_tracker/models/expense.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //text controller
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  //futures to load ghaph data & monthly total
  Future<Map<String, double>>? _monthlyTotalsFuture;
  Future<double>? _calculateCurrentMonthTotal;

  @override
  void initState() {
    Provider.of<ExpenseDatabase>(context, listen: false).readExpense();
    //load futures
    refreshData();

    super.initState();
  }

  //refresh graph data
  void refreshData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(
      context,
      listen: false,
    ).calculateMonthlyTotals();
    _calculateCurrentMonthTotal = Provider.of<ExpenseDatabase>(
      context,
      listen: false,
    ).calculateCurrentMonthTotal();
  }

  //open a expense
  void openNewExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("New Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //exp name input
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Name"),
            ),

            //exp amount input
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: "Amount"),
            ),
          ],
        ),
        actions: [
          //cancel button
          _cancelButton(),
          //save button
          _createNewExpenseButton(),
        ],
      ),
    );
  }

  //open edit box
  void openEditBox(Expense expense) {
    //pre fill the existing value
    String existingName = expense.name;
    String existingSmount = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //exp name input
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: existingName),
            ),

            //exp amount input
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: existingSmount),
            ),
          ],
        ),
        actions: [
          //cancel button
          _cancelButton(),
          //save button
          _editExpenseButton(expense),
        ],
      ),
    );
  }

  //open delete box
  void openDeleteBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense"),

        actions: [
          //cancel button
          _cancelButton(),
          //delete button
          _deleteExpenseButton(expense.id),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) {
        //get dates
        int startMonth = value.getStartMonth();
        int startYear = value.getStartYear();
        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;

        //cal. the no. of month sinse the fst month
        int monthCount = calculateMonthCount(
          startYear,
          startMonth,
          currentYear,
          currentMonth,
        );

        //only display the expense of current month
        List<Expense> currentMonthExpenses = value.allExpense.where((expense) {
          return expense.date.year == currentYear &&
              expense.date.month == currentMonth;
        }).toList();

        //return UI
        return Scaffold(
          backgroundColor: Colors.grey.shade300,
          floatingActionButton: FloatingActionButton(
            onPressed: openNewExpenseBox,
            child: Icon(Icons.add),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: FutureBuilder<double>(
              future: _calculateCurrentMonthTotal,
              builder: (context, snapshot) {
                //loaded
                if (snapshot.connectionState == ConnectionState.done) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //total amt
                      Text('\₹${snapshot.data!.toStringAsFixed(2)}'),

                      //month name
                      Text(getCurrentMonthName()),
                    ],
                  );
                }
                //loading
                else {
                  return const Text("Loading..");
                }
              },
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                //Graph UI
                SizedBox(
                  height: 250,
                  child: FutureBuilder(
                    future: _monthlyTotalsFuture,
                    builder: (context, snapshot) {
                      //data is loaded
                      if (snapshot.connectionState == ConnectionState.done) {
                        Map<String, double> monthlyTotals = snapshot.data ?? {};

                        //create the list of monthly summary
                        List<double>
                        monthlySummary = List.generate(monthCount, (index) {
                          //calculate  year-month considering startMonth & index
                          int year = startYear + (startMonth + index - 1) ~/ 12;
                          int month = (startMonth + index - 1) % 12 + 1;

                          //create the key in the format 'year-month'
                          String yearMonthKey = '$year-$month';

                          //return the total for year-month or 0.0 if not-existent
                          return monthlyTotals[yearMonthKey] ?? 0.0;
                        });
                        return MyBarGraph(
                          monthlySummary: monthlySummary,
                          startMonth: startMonth,
                        );
                      }
                      //loading..
                      else {
                        return const Center(child: Text("Loading.."));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 25),

                //Expense List UI
                Expanded(
                  child: ListView.builder(
                    itemCount: currentMonthExpenses.length,
                    itemBuilder: (context, index) {
                      //reverse the index to show the latest item fst
                      int reversedIndex =
                          currentMonthExpenses.length - 1 - index;

                      //get individual expense
                      Expense individualExpense =
                          currentMonthExpenses[reversedIndex];

                      //return list tile UI
                      return MyListTile(
                        title: individualExpense.name,
                        trailing: formatAmount(individualExpense.amount),
                        onEditPressed: (context) =>
                            openEditBox(individualExpense),
                        onDeletePressed: (context) =>
                            openDeleteBox(individualExpense),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //cancel button
  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        //pop box
        Navigator.pop(context);
        //clear controllers
        nameController.clear();
        amountController.clear();
      },
      child: const Text("Cancel"),
    );
  }

  //save button
  Widget _createNewExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        //save if there is something in the textfield
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          //pop box
          Navigator.pop(context);
          //create new exp
          Expense newExpense = Expense(
            name: nameController.text,
            amount: convertStringToDouble(amountController.text),
            date: DateTime.now(),
          );
          //save to db
          await context.read<ExpenseDatabase>().createNewExpenses(newExpense);

          //refresh graph
          refreshData();

          //clear controllers
          nameController.clear();
          amountController.clear();
        }
      },
      child: const Text("Save"),
    );
  }

  //edit expense button
  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          //pop box
          Navigator.pop(context);
          //create a new updated exp
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty
                ? nameController.text
                : expense.name,
            amount: amountController.text.isNotEmpty
                ? convertStringToDouble(amountController.text)
                : expense.amount,
            date: DateTime.now(),
          );

          //old expense id
          int existingId = expense.id;

          //save to db
          await context.read<ExpenseDatabase>().updateExpense(
            existingId,
            updatedExpense,
          );
          //refresh graph
          refreshData();
        }
      },
      child: const Text("Save"),
    );
  }

  //delete button
  Widget _deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        //pop box
        Navigator.pop(context);
        //delete expense from db
        await context.read<ExpenseDatabase>().deleteExpense(id);
        //refresh graph
        refreshData();
      },
      child: const Text("Delete"),
    );
  }
}
