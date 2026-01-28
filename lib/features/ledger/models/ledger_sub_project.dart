import 'ledger_expense.dart';

class LedgerSubProject {
  final String id;
  final String title;
  final List<LedgerExpense>
  expenses; // Expenses specific to this sub-project (subset or separate?)
  // For simplicity MVP, let's keep subProjects just as a tag or separate list.
  // Actually expenses belong to Main Project, so subProjects might just be a logical grouping if needed.
  // But user plan said "Sub Project can collect expenses".
  // Let's make SubProject simple for now.

  LedgerSubProject({
    required this.id,
    required this.title,
    this.expenses = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
  }

  factory LedgerSubProject.fromJson(Map<String, dynamic> json) {
    return LedgerSubProject(
      id: json['id'],
      title: json['title'],
      expenses:
          (json['expenses'] as List?)
              ?.map((e) => LedgerExpense.fromJson(e))
              .toList() ??
          [],
    );
  }
}
