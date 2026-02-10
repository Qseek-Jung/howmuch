import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ledger_project.dart';
import '../models/ledger_expense.dart';
import '../models/ledger_backup.dart';
import '../services/excel_service.dart';
import '../services/ledger_file_service.dart';
import '../../../providers/settings_provider.dart';
import 'package:share_plus/share_plus.dart';

// Key for SharedPreferences
const String _ledgerStorageKey = 'ledger_projects_v1';

final ledgerProvider =
    StateNotifierProvider<LedgerNotifier, List<LedgerProject>>((ref) {
      return LedgerNotifier(ref);
    });

final excelServiceProvider = Provider<ExcelService>((ref) {
  return ExcelService();
});

class LedgerNotifier extends StateNotifier<List<LedgerProject>> {
  final Ref ref;
  LedgerNotifier(this.ref) : super([]) {
    _loadProjects();
  }

  final LedgerFileService _fileService = LedgerFileService();

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_ledgerStorageKey);

    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        state = decoded.map((e) => LedgerProject.fromJson(e)).toList();
        // Also sync to file just in case it's missing (using current settings)
        await _saveProjects();
        return;
      } catch (e) {
        print('Error decoding SharedPreferences: $e');
      }
    }

    // If SharedPreferences is empty or corrupted, try file backup
    final backup = await _fileService.loadFromFile();
    if (backup != null) {
      state = backup.projects;
      // Restore SharedPreferences from file backup
      await _saveToPrefs();
      // Apply settings if present
      await _applySettings(backup.settings);
    } else {
      state = [];
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_ledgerStorageKey, jsonString);
  }

  Future<void> _saveProjects() async {
    await _saveToPrefs();

    final settings = ref.read(settingsProvider);
    final backup = LedgerBackup(
      projects: state,
      settings: {
        'bank_name': settings.bankName,
        'account_number': settings.accountNumber,
        'account_holder': settings.accountHolder,
        'favorite_countries': settings.favoriteCountries,
      },
    );
    await _fileService.saveToFile(backup);
  }

  /// Manual restore from file with either provided data or picker
  Future<bool> restoreFromFile({LedgerBackup? manualData}) async {
    final backup = manualData ?? await _fileService.pickAndLoadBackup();
    if (backup != null) {
      state = backup.projects;
      await _saveToPrefs();
      await _applySettings(backup.settings);
      return true;
    }
    return false;
  }

  Future<void> _applySettings(Map<String, dynamic> settings) async {
    if (settings.isEmpty) return;

    final notifier = ref.read(settingsProvider.notifier);
    if (settings.containsKey('bank_name')) {
      await notifier.updateBankName(settings['bank_name']);
    }
    if (settings.containsKey('account_number')) {
      await notifier.updateAccountNumber(settings['account_number']);
    }
    if (settings.containsKey('account_holder')) {
      await notifier.updateAccountHolder(settings['account_holder']);
    }
    if (settings.containsKey('favorite_countries')) {
      final List<String> favorites = List<String>.from(
        settings['favorite_countries'],
      );
      // We need a bulk update for favorites to preserve everything
      // For now, update individual if possible or just overwrite prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_countries', favorites);
      // Logic for SettingsNotifier to reload
      await notifier
          .loadSettings(); // I should add this method to SettingsNotifier
    }
  }

  /// Share the backup file with timestamped name
  Future<void> shareBackup() async {
    final settings = ref.read(settingsProvider);
    final backup = LedgerBackup(
      projects: state,
      settings: {
        'bank_name': settings.bankName,
        'account_number': settings.accountNumber,
        'account_holder': settings.accountHolder,
        'favorite_countries': settings.favoriteCountries,
      },
    );
    final path = await _fileService.getExportPath(backup);
    if (path != null) {
      await Share.shareXFiles([XFile(path)], text: '얼마야? 여계부 백업 파일');
    }
  }

  /// Get auto-restore data if available (but don't apply)
  Future<LedgerBackup?> getAutoRestoreData() async {
    return await _fileService.loadFromFile();
  }

  /// Get list of backup files found in external storage
  Future<List<File>> getExternalBackupFiles() async {
    return await _fileService.findExternalBackups();
  }

  /// Load projects from a specific file (but don't apply)
  Future<LedgerBackup?> loadFromSpecificFile(File file) async {
    return await _fileService.loadFromFile(specificFile: file);
  }

  /// Force a manual backup
  Future<void> saveManualBackup() async {
    await _saveProjects();
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
