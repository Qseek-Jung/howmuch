import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ledger_project.dart';
import '../models/ledger_expense.dart';
import '../services/excel_service.dart';

// Key for SharedPreferences
const String _ledgerStorageKey = 'ledger_projects_v1';

final ledgerProvider =
    StateNotifierProvider<LedgerNotifier, List<LedgerProject>>((ref) {
      return LedgerNotifier();
    });

final excelServiceProvider = Provider<ExcelService>((ref) {
  return ExcelService();
});

class LedgerNotifier extends StateNotifier<List<LedgerProject>> {
  LedgerNotifier() : super([]) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_ledgerStorageKey);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        state = decoded.map((e) => LedgerProject.fromJson(e)).toList();
      } catch (e) {
        state = [];
      }
    } else {
      state = [];
    }
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_ledgerStorageKey, jsonString);
  }

  // Create Project
  Future<void> createProject(LedgerProject project) async {
    state = [...state, project];
    await _saveProjects();
  }

  // Update Project (edit metadata)
  Future<void> updateProject(LedgerProject updatedProject) async {
    state = [
      for (final p in state)
        if (p.id == updatedProject.id) updatedProject else p,
    ];
    await _saveProjects();
  }

  // Delete Project
  Future<void> deleteProject(String projectId) async {
    state = state.where((p) => p.id != projectId).toList();
    await _saveProjects();
  }

  // Add Expense to Project
  Future<void> addExpense(String projectId, LedgerExpense expense) async {
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(expenses: [...p.expenses, expense])
        else
          p,
    ];
    await _saveProjects();
  }

  // Update Expense
  Future<void> updateExpense(
    String projectId,
    LedgerExpense updatedExpense,
  ) async {
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            expenses: [
              for (final e in p.expenses)
                if (e.id == updatedExpense.id) updatedExpense else e,
            ],
          )
        else
          p,
    ];
    await _saveProjects();
  }

  // Delete Expense
  Future<void> deleteExpense(String projectId, String expenseId) async {
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            expenses: p.expenses.where((e) => e.id != expenseId).toList(),
          )
        else
          p,
    ];
    await _saveProjects();
  }

  // Helper: Get active project for today
  LedgerProject? getActiveProjectForDate(DateTime date) {
    try {
      return state.firstWhere((p) {
        // Simple date range check (inclusive)
        // Ignoring time components for stricter day comparison if needed,
        // but simple comparison usually works if startDate is 00:00 and endDate is 23:59 set properly
        final start = DateTime(
          p.startDate.year,
          p.startDate.month,
          p.startDate.day,
        );
        final end = DateTime(
          p.endDate.year,
          p.endDate.month,
          p.endDate.day,
        ).add(const Duration(days: 1)); // End includes the full end day
        final target = DateTime(date.year, date.month, date.day);

        return target.isAfter(start.subtract(const Duration(seconds: 1))) &&
            target.isBefore(end);
      });
    } catch (_) {
      return null;
    }
  }
}
