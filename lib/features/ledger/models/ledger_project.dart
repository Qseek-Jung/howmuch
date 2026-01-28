import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'ledger_expense.dart';
import 'ledger_sub_project.dart';

class LedgerProject {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> countries; // Currency codes managed
  final List<String> members; // "Me", "Friend A"...
  final String defaultCurrency;
  final List<LedgerExpense> expenses;
  final List<LedgerSubProject> subProjects;

  LedgerProject({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.countries,
    required this.members,
    required this.defaultCurrency,
    required this.expenses,
    this.subProjects = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'countries': countries,
      'members': members,
      'defaultCurrency': defaultCurrency,
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'subProjects': subProjects.map((s) => s.toJson()).toList(),
    };
  }

  factory LedgerProject.fromJson(Map<String, dynamic> json) {
    return LedgerProject(
      id: json['id'],
      title: json['title'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      countries: List<String>.from(json['countries']),
      members: List<String>.from(json['members']),
      defaultCurrency: json['defaultCurrency'],
      expenses:
          (json['expenses'] as List?)
              ?.map((e) => LedgerExpense.fromJson(e))
              .toList() ??
          [],
      subProjects:
          (json['subProjects'] as List?)
              ?.map((s) => LedgerSubProject.fromJson(s))
              .toList() ??
          [],
    );
  }

  LedgerProject copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? countries,
    List<String>? members,
    String? defaultCurrency,
    List<LedgerExpense>? expenses,
    List<LedgerSubProject>? subProjects,
  }) {
    return LedgerProject(
      id: id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      countries: countries ?? this.countries,
      members: members ?? this.members,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      expenses: expenses ?? this.expenses,
      subProjects: subProjects ?? this.subProjects,
    );
  }
}
