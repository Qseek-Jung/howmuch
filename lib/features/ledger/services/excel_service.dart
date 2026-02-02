import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img; // For EXIF orientation handling
import '../models/ledger_project.dart';
import '../models/ledger_expense.dart';

class ExcelExportOptions {
  final bool includeReceipts;
  final bool includeSettlement;
  final bool includeCharts; // Renamed from includeSummary
  final int roundingUnit;
  final String? managerName; // Who gets the surplus

  ExcelExportOptions({
    this.includeReceipts = true,
    this.includeSettlement = true,
    this.includeCharts = true,
    this.roundingUnit = 1000,
    this.managerName,
  });
}

class ExcelService {
  /// Generate Excel file for a Ledger Project
  Future<String> generateProjectReport(
    LedgerProject project, {
    ExcelExportOptions? options,
    List<int>? categoryChartBytes,
    List<int>? dailyChartBytes,
    List<int>? settlementChartBytes,
  }) async {
    final opts = options ?? ExcelExportOptions();
    // 1. Create a new Excel Document
    final Workbook workbook = Workbook();

    // 2. Access main sheet and rename
    final Worksheet mainSheet = workbook.worksheets[0];
    mainSheet.name = "정산보고서";

    // Set A4 Portrait
    mainSheet.pageSetup.paperSize = ExcelPaperSize.paperA4;
    mainSheet.pageSetup.orientation = ExcelPageOrientation.portrait;
    mainSheet.pageSetup.leftMargin = 0.5;
    mainSheet.pageSetup.rightMargin = 0.5;
    mainSheet.pageSetup.topMargin = 0.5;
    mainSheet.pageSetup.bottomMargin = 0.5;

    int currentRow = 1;

    // --- 1. Top Title (Business/Travel Report Style) ---
    final String reportTitle = project.title.contains("출장")
        ? "출장 정산보고서"
        : "여행 정산보고서";
    final Range titleRange = mainSheet.getRangeByIndex(
      currentRow,
      1,
      currentRow,
      10,
    );
    titleRange.merge();
    titleRange.setText(reportTitle);
    titleRange.cellStyle.fontSize = 24;
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.hAlign = HAlignType.center;
    titleRange.cellStyle.vAlign = VAlignType.center;
    currentRow += 2;

    // --- 2. Trip Metadata Section (출장개요) ---
    _addMetadata(mainSheet, currentRow, project);
    currentRow += 5;

    // --- 3. Detailed Expense List (세부 지출 내역) ---
    mainSheet.getRangeByIndex(currentRow, 1).setText("■ 세부 지출 내역");
    mainSheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
    mainSheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 14;
    currentRow++;

    _addHeader(mainSheet, currentRow);
    currentRow++;

    List<LedgerExpense> sortedExpenses = List.from(project.expenses)
      ..sort((a, b) => a.date.compareTo(b.date));

    final dateFormat = DateFormat('yyyy-MM-dd');

    for (int i = 0; i < sortedExpenses.length; i++) {
      final expense = sortedExpenses[i];
      int row = currentRow + i;

      mainSheet.getRangeByIndex(row, 1).setNumber((i + 1).toDouble());
      mainSheet
          .getRangeByIndex(row, 2)
          .setText(dateFormat.format(expense.date));
      mainSheet.getRangeByIndex(row, 3).setText(expense.title);
      mainSheet
          .getRangeByIndex(row, 4)
          .setText(_getCategoryLabel(expense.category));

      final localRange = mainSheet.getRangeByIndex(row, 5);
      localRange.setNumber(expense.amountLocal);
      localRange.numberFormat = expense.currencyCode == "KRW"
          ? "#,##0"
          : "#,##0.00";

      mainSheet.getRangeByIndex(row, 6).setText(expense.currencyCode);
      mainSheet.getRangeByIndex(row, 7).setNumber(expense.exchangeRate);
      mainSheet.getRangeByIndex(row, 7).numberFormat = "#,##0.##";

      final krwRange = mainSheet.getRangeByIndex(row, 8);
      krwRange.setNumber(expense.amountKrw.roundToDouble());
      krwRange.numberFormat = "#,##0";

      mainSheet.getRangeByIndex(row, 9).setText(expense.payers.join(", "));

      final memoCell = mainSheet.getRangeByIndex(row, 10);
      memoCell.setText(expense.memo ?? "");
      memoCell.cellStyle.wrapText = true;
      memoCell.cellStyle.vAlign = VAlignType.top;

      // Add borders
      for (int c = 1; c <= 10; c++) {
        mainSheet.getRangeByIndex(row, c).cellStyle.borders.all.lineStyle =
            LineStyle.thin;
      }
    }
    currentRow += sortedExpenses.length + 2;

    // --- 4. Visual Charts & Category Summary (지출 분석) ---
    if (opts.includeCharts) {
      mainSheet.getRangeByIndex(currentRow, 1).setText("■ 지출 분석");
      mainSheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      mainSheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 14;
      currentRow++;

      currentRow = _addSummaryToSheet(
        mainSheet,
        currentRow,
        project,
        categoryChartBytes,
        dailyChartBytes,
      );
      currentRow += 2;
    }

    // --- 5. Settlement Summary (정산 요약) ---
    if (opts.includeSettlement) {
      mainSheet.getRangeByIndex(currentRow, 1).setText("■ 정산 요약");
      mainSheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      mainSheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 14;
      currentRow++;

      currentRow = _addSettlementToSheet(mainSheet, currentRow, project, opts);

      // Place Settlement Chart right after the table
      if (settlementChartBytes != null) {
        currentRow += 3; // More space before chart
        final Picture picture = mainSheet.pictures.addStream(
          currentRow,
          1,
          settlementChartBytes,
        );
        picture.height = 350; // Square for perfect circle
        picture.width = 350; // Same as height
        currentRow += 18; // More rows for square image
      }

      currentRow += 2;
    }

    // Fit columns for main sheet with A4 in mind (approx 700px total for portrait)
    mainSheet.setColumnWidthInPixels(1, 40); // No (slightly increased)
    mainSheet.setColumnWidthInPixels(2, 75); // Date
    mainSheet.setColumnWidthInPixels(3, 110); // Title
    mainSheet.setColumnWidthInPixels(4, 60); // Category
    mainSheet.setColumnWidthInPixels(5, 80); // Amount Local
    mainSheet.setColumnWidthInPixels(6, 45); // Currency
    mainSheet.setColumnWidthInPixels(7, 55); // Rate
    mainSheet.setColumnWidthInPixels(8, 85); // Amount KRW
    mainSheet.setColumnWidthInPixels(9, 80); // Payers
    mainSheet.setColumnWidthInPixels(10, 110); // Memo (Wrapped)

    // 6. Create "Receipts" Sheet (Separate)
    if (opts.includeReceipts) {
      final Worksheet receiptSheet = workbook.worksheets.addWithName("증빙사진");
      _addReceipts(receiptSheet, sortedExpenses);
    }

    // 8. Save Report
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    Directory tempDir = await getTemporaryDirectory();
    String filePath =
        '${tempDir.path}/Report_${project.title}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';

    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);

    return filePath;
  }

  void _addHeader(Worksheet sheet, int row) {
    List<String> headers = [
      "번호",
      "날짜",
      "내역",
      "카테고리",
      "금액 (현지화)",
      "통화",
      "환율",
      "금액 (KRW)",
      "사용인원",
      "메모",
    ];

    for (int i = 0; i < headers.length; i++) {
      final Range range = sheet.getRangeByIndex(row, i + 1);
      range.setText(headers[i]);
      range.cellStyle.bold = true;
      range.cellStyle.hAlign = HAlignType.center;
      range.cellStyle.backColor = '#E0E0E0';
      range.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
  }

  void _addMetadata(Worksheet sheet, int startRow, LedgerProject project) {
    final List<List<String>> data = [
      ["프로젝트명", project.title, "정산통화", project.defaultCurrency],
      [
        "기간",
        "${DateFormat('yyyy.MM.dd').format(project.startDate)} ~ ${DateFormat('yyyy.MM.dd').format(project.endDate)}",
        "방문국가",
        project.countries.join(", "),
      ],
      [
        "작성일",
        DateFormat('yyyy.MM.dd').format(DateTime.now()),
        "동반자",
        project.members.join(", "),
      ],
    ];

    for (int i = 0; i < data.length; i++) {
      int row = startRow + i;

      // Label 1 (Merged Col 1-2)
      final rangeL1 = sheet.getRangeByIndex(row, 1, row, 2);
      rangeL1.merge();
      rangeL1.setText(data[i][0]);
      rangeL1.cellStyle.bold = true;
      rangeL1.cellStyle.backColor = '#F2F2F2';
      rangeL1.cellStyle.borders.all.lineStyle = LineStyle.thin;

      // Value 1 (Merged Col 3-5)
      final rangeV1 = sheet.getRangeByIndex(row, 3, row, 5);
      rangeV1.merge();
      rangeV1.setText(data[i][1]);
      rangeV1.cellStyle.borders.all.lineStyle = LineStyle.thin;

      // Label 2 (Merged Col 6-7)
      final rangeL2 = sheet.getRangeByIndex(row, 6, row, 7);
      rangeL2.merge();
      rangeL2.setText(data[i][2]);
      rangeL2.cellStyle.bold = true;
      rangeL2.cellStyle.backColor = '#F2F2F2';
      rangeL2.cellStyle.borders.all.lineStyle = LineStyle.thin;

      // Value 2 (Merged Col 8-10)
      final rangeV2 = sheet.getRangeByIndex(row, 8, row, 10);
      rangeV2.merge();
      rangeV2.setText(data[i][3]);
      rangeV2.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
  }

  int _addSettlementToSheet(
    Worksheet sheet,
    int startRow,
    LedgerProject project,
    ExcelExportOptions options,
  ) {
    int row = startRow;
    final List<Map<String, dynamic>> settlementHeaders = [
      {'title': "성명", 'span': 2},
      {'title': "정확한 금액 (원)", 'span': 1},
      {'title': "정산 금액 (올림)", 'span': 1},
      {'title': "정산 혜택 (절상 차액)", 'span': 1},
      {'title': "비고", 'span': 5},
    ];

    int currentCol = 1;
    for (var header in settlementHeaders) {
      final int span = header['span'];
      final Range range = sheet.getRangeByIndex(
        row,
        currentCol,
        row,
        currentCol + span - 1,
      );
      if (span > 1) range.merge();

      range.setText(header['title']);
      range.cellStyle.bold = true;
      range.cellStyle.hAlign = HAlignType.center;
      range.cellStyle.backColor = '#E0E0E0';
      range.cellStyle.borders.all.lineStyle = LineStyle.thin;
      currentCol += span;
    }
    row++;

    final Map<String, double> memberExacts = {};
    for (var member in project.members) {
      double myShareKrw = 0;
      for (var expense in project.expenses) {
        if (expense.payers.contains(member)) {
          myShareKrw += expense.amountKrw / expense.payers.length;
        }
      }
      memberExacts[member] = myShareKrw;
    }

    final int roundUnit = options.roundingUnit;

    for (var member in project.members) {
      double myShareKrw = memberExacts[member]!;
      double settlementAmount =
          (myShareKrw / roundUnit).ceil() * roundUnit.toDouble();

      String note = "";
      if (options.managerName == member) {
        // Collect all rounding differences from others first
        double accumulatedSurplus = 0;
        for (var m in project.members) {
          double mExact = memberExacts[m]!;
          double mRound = (mExact / roundUnit).ceil() * roundUnit.toDouble();
          accumulatedSurplus += (mRound - mExact);
        }
        settlementAmount = settlementAmount - accumulatedSurplus;
        note = "총무 정산 혜택 (+${accumulatedSurplus.round()}원) 반영됨";
      }

      final nameRange = sheet.getRangeByIndex(row, 1, row, 2);
      nameRange.merge();
      nameRange.setText(member);
      nameRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

      sheet.getRangeByIndex(row, 3).setNumber(myShareKrw.roundToDouble());
      sheet.getRangeByIndex(row, 4).setNumber(settlementAmount.roundToDouble());
      sheet
          .getRangeByIndex(row, 5)
          .setNumber((settlementAmount - myShareKrw).roundToDouble());

      final noteRange = sheet.getRangeByIndex(row, 6, row, 10);
      noteRange.merge();
      noteRange.setText(note);
      noteRange.cellStyle.wrapText = true;
      noteRange.cellStyle.vAlign = VAlignType.top;

      for (int col = 3; col <= 5; col++) {
        final cell = sheet.getRangeByIndex(row, col);
        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
        cell.numberFormat = "#,##0";
      }
      noteRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
      row++;
    }

    // Total Row
    final labelTotalRange = sheet.getRangeByIndex(row, 1, row, 2);
    labelTotalRange.merge();
    labelTotalRange.setText("합계");
    labelTotalRange.cellStyle.bold = true;
    labelTotalRange.cellStyle.backColor = '#F2F2F2';
    labelTotalRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

    double totalExact = project.expenses.fold(0, (sum, e) => sum + e.amountKrw);
    final rangeTotal = sheet.getRangeByIndex(row, 3);
    rangeTotal.setNumber(totalExact.roundToDouble());
    rangeTotal.numberFormat = "#,##0";
    rangeTotal.cellStyle.bold = true;
    rangeTotal.cellStyle.borders.all.lineStyle = LineStyle.thin;

    final totalEmptyRange = sheet.getRangeByIndex(row, 4, row, 10);
    totalEmptyRange.merge();
    totalEmptyRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

    row++;
    return row;
  }

  int _addSummaryToSheet(
    Worksheet sheet,
    int startRow,
    LedgerProject project,
    List<int>? catChart,
    List<int>? dailyChart,
  ) {
    int row = startRow;

    // --- Category Table ---
    final Map<ExpenseCategory, double> catSums = {};
    for (var e in project.expenses) {
      catSums[e.category] = (catSums[e.category] ?? 0) + e.amountKrw;
    }

    sheet.getRangeByIndex(row, 1).setText("■ 카테고리별 분석");
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 1).cellStyle.fontSize = 12;
    row++;

    final catHdr = sheet.getRangeByIndex(row, 1, row, 2);
    catHdr.merge();
    catHdr.setText("카테고리");

    final sumHdr = sheet.getRangeByIndex(row, 3, row, 4);
    sumHdr.merge();
    sumHdr.setText("합계 (KRW)");

    final pctHdrRange = sheet.getRangeByIndex(row, 5);
    pctHdrRange.setText("비중 (%)");

    for (int c = 1; c <= 5; c++) {
      Range r;
      if (c == 1)
        r = sheet.getRangeByIndex(row, 1, row, 2);
      else if (c == 3)
        r = sheet.getRangeByIndex(row, 3, row, 4);
      else if (c == 5)
        r = sheet.getRangeByIndex(row, 5);
      else
        continue;

      r.cellStyle.backColor = "#D9E1F2";
      r.cellStyle.bold = true;
      r.cellStyle.borders.all.lineStyle = LineStyle.thin;
      r.cellStyle.hAlign = HAlignType.center;
    }
    row++;

    double totalSpent = project.expenses.fold(0, (sum, e) => sum + e.amountKrw);
    catSums.forEach((cat, sum) {
      final nameRange = sheet.getRangeByIndex(row, 1, row, 2);
      nameRange.merge();
      nameRange.setText(_getCategoryLabel(cat));
      nameRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

      final valRange = sheet.getRangeByIndex(row, 3, row, 4);
      valRange.merge();
      valRange.setNumber(sum.roundToDouble());
      valRange.numberFormat = "#,##0";
      valRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

      final ptRange = sheet.getRangeByIndex(row, 5);
      ptRange.setNumber(totalSpent > 0 ? sum / totalSpent : 0);
      ptRange.numberFormat = "0.0%";
      ptRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

      row++;
    });

    if (catChart != null) {
      row += 2; // Space before chart
      final Picture picture = sheet.pictures.addStream(row, 1, catChart);
      picture.height = 350; // Square for perfect circle
      picture.width = 350; // Same as height
      row += 18;
    }

    row += 3; // Extra gap between Category and Daily sections

    // --- Daily Trend Table ---
    final Map<String, double> dailySums = {};
    final df = DateFormat('yyyy-MM-dd');
    for (var e in project.expenses) {
      final d = df.format(e.date);
      dailySums[d] = (dailySums[d] ?? 0) + e.amountKrw;
    }

    sheet.getRangeByIndex(row, 1).setText("■ 일별 분석");
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 1).cellStyle.fontSize = 12;
    row++;

    final dateHdr = sheet.getRangeByIndex(row, 1, row, 2);
    dateHdr.merge();
    dateHdr.setText("날짜");

    final dailyAmtHdr = sheet.getRangeByIndex(row, 3, row, 5);
    dailyAmtHdr.merge();
    dailyAmtHdr.setText("지출 (KRW)");

    dateHdr.cellStyle.bold = true;
    dateHdr.cellStyle.backColor = "#D9E1F2";
    dateHdr.cellStyle.borders.all.lineStyle = LineStyle.thin;
    dateHdr.cellStyle.hAlign = HAlignType.center;

    dailyAmtHdr.cellStyle.bold = true;
    dailyAmtHdr.cellStyle.backColor = "#D9E1F2";
    dailyAmtHdr.cellStyle.borders.all.lineStyle = LineStyle.thin;
    dailyAmtHdr.cellStyle.hAlign = HAlignType.center;
    row++;

    dailySums.keys.toList()
      ..sort()
      ..forEach((date) {
        final dateRange = sheet.getRangeByIndex(row, 1, row, 2);
        dateRange.merge();
        dateRange.setText(date);
        dateRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

        final valRange = sheet.getRangeByIndex(row, 3, row, 5);
        valRange.merge();
        valRange.setNumber(dailySums[date]!.roundToDouble());
        valRange.numberFormat = "#,##0";
        valRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

        row++;
      });

    row += 2; // Space before chart

    if (dailyChart != null) {
      final Picture picture = sheet.pictures.addStream(row, 1, dailyChart);
      picture.height = 280; // Reasonable height for bar chart
      picture.width = 450; // Wide for horizontal bars
      row += 14;
    }

    return row;
  }

  void _addReceipts(Worksheet sheet, List<LedgerExpense> expenses) {
    int currentRow = 1;

    final Range titleRange = sheet.getRangeByIndex(currentRow, 1);
    titleRange.setText("Receipt Images");
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontSize = 16;
    currentRow += 2;

    for (var expense in expenses) {
      if (expense.receiptPaths.isEmpty) continue;

      // Expense Header
      final Range headerRange = sheet.getRangeByIndex(currentRow, 1);
      headerRange.setText(
        "Expense: ${expense.title} (${DateFormat('yyyy-MM-dd').format(expense.date)})",
      );
      headerRange.cellStyle.bold = true;
      headerRange.cellStyle.fontSize = 12;
      headerRange.cellStyle.backColor = '#F5F5F5';

      // Merge across a few columns for header
      sheet.getRangeByIndex(currentRow, 1, currentRow, 5).merge();

      currentRow++;

      for (String path in expense.receiptPaths) {
        File imgFile = File(path);
        if (imgFile.existsSync()) {
          try {
            List<int> imageBytes = imgFile.readAsBytesSync();

            // CRITICAL: Handle EXIF orientation to prevent rotated images
            // Decode image with EXIF data (convert to Uint8List)
            img.Image? originalImage = img.decodeImage(
              Uint8List.fromList(imageBytes),
            );

            if (originalImage != null) {
              // Apply EXIF orientation (bakeOrientation fixes rotation based on EXIF)
              originalImage = img.bakeOrientation(originalImage);

              // SMART RESIZE: Preserve aspect ratio for both portrait and landscape
              const int maxDimension = 600; // Max size for either dimension

              final int originalWidth = originalImage.width;
              final int originalHeight = originalImage.height;

              // Calculate scale factor based on the larger dimension
              if (originalWidth > maxDimension ||
                  originalHeight > maxDimension) {
                final double widthRatio = maxDimension / originalWidth;
                final double heightRatio = maxDimension / originalHeight;

                // Use the smaller ratio to ensure both dimensions fit within max
                final double scale = widthRatio < heightRatio
                    ? widthRatio
                    : heightRatio;

                final int newWidth = (originalWidth * scale).round();
                final int newHeight = (originalHeight * scale).round();

                // Resize image
                originalImage = img.copyResize(
                  originalImage,
                  width: newWidth,
                  height: newHeight,
                  interpolation: img.Interpolation.linear,
                );
              }

              // Re-encode to JPEG
              imageBytes = img.encodeJpg(originalImage, quality: 85);
            }

            // Add Picture to Excel
            final Picture picture = sheet.pictures.addStream(
              currentRow,
              1,
              imageBytes,
            );

            // Calculate row span needed (1 row ~= 20 pixels)
            int rowsNeeded = (picture.height / 20).ceil() + 1;

            currentRow += rowsNeeded;

            // Add path as subtitle for reference?
            // sheet.getRangeByIndex(currentRow, 1).setText(path); // Debug info
            // currentRow++;
          } catch (e) {
            sheet
                .getRangeByIndex(currentRow, 1)
                .setText("Error loading image: ${e.toString()}");
            currentRow++;
          }
        } else {
          sheet
              .getRangeByIndex(currentRow, 1)
              .setText("Image file not found: $path");
          currentRow++;
        }

        currentRow++; // Spacer between images
      }
      currentRow++; // Spacer between expenses
    }

    // Set Column 1 width to be wide enough mostly
    sheet.getRangeByIndex(1, 1).columnWidth = 50;
  }

  String _getCategoryLabel(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.food:
        return "식비";
      case ExpenseCategory.lodging:
        return "숙박";
      case ExpenseCategory.transport:
        return "교통";
      case ExpenseCategory.shopping:
        return "쇼핑";
      case ExpenseCategory.tour:
        return "관광";
      case ExpenseCategory.golf:
        return "골프";
      case ExpenseCategory.activity:
        return "액티비티";
      case ExpenseCategory.medical:
        return "의료비";
      case ExpenseCategory.etc:
        return "기타";
    }
  }
}
