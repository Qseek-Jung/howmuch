import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'home/currency_provider.dart';
import '../../core/design_system.dart';

import '../../data/models/currency_model.dart';
import '../../core/currency_data.dart';

class CurrencyManageScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  final String? initialSelectedId;
  final bool excludeKrw;

  const CurrencyManageScreen({
    super.key,
    this.isSelectionMode = false,
    this.initialSelectedId,
    this.excludeKrw = false,
  });

  @override
  ConsumerState<CurrencyManageScreen> createState() =>
      _CurrencyManageScreenState();
}

class _CurrencyManageScreenState extends ConsumerState<CurrencyManageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  String _searchQuery = "";
  List<dynamic> _displayList = []; // Can be String (Header) or Currency
  Map<String, int> _indexOffsets = {};
  List<String> _indexChars = [];

  bool _scrolledToInitial = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitialSound(String text) {
    if (text.isEmpty) return '';
    int code = text.codeUnitAt(0);
    if (code >= 0xAC00 && code <= 0xD7A3) {
      int initialIndex = (code - 0xAC00) ~/ (21 * 28);
      const initials = [
        'ㄱ',
        'ㄲ',
        'ㄴ',
        'ㄷ',
        'ㄸ',
        'ㄹ',
        'ㅁ',
        'ㅂ',
        'ㅃ',
        'ㅅ',
        'ㅆ',
        'ㅇ',
        'ㅈ',
        'ㅉ',
        'ㅊ',
        'ㅋ',
        'ㅌ',
        'ㅍ',
        'ㅎ',
      ];
      return initials[initialIndex];
    }
    if (code >= 65 && code <= 90) return String.fromCharCode(code);
    if (code >= 97 && code <= 122)
      return String.fromCharCode(code).toUpperCase();
    return '#';
  }

  void _prepareData(List<Currency> allCurrencies, List<String> favoriteCodes) {
    _displayList = [];
    _indexOffsets = {};
    _indexChars = [];

    // Filter
    final filtered = allCurrencies.where((c) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          (c.countryEn?.toLowerCase().contains(q) ?? false) ||
          (c.currencyName?.toLowerCase().contains(q) ?? false);
    }).toList();

    // Separation
    final favorites = <Currency>[];
    final others = <Currency>[];

    // Build favorites in the order they appear in favoriteCodes
    for (var code in favoriteCodes) {
      final match = filtered.cast<Currency?>().firstWhere(
        (c) => c?.uniqueId == code,
        orElse: () => null,
      );
      if (match != null) {
        favorites.add(match);
      }
    }

    // Others: Filtered items that are NOT in favorites
    for (var c in filtered) {
      // Filter out Korea if requested (only checking strictly by code/name)
      if (widget.excludeKrw && (c.code == 'KRW' || c.name == '대한민국')) {
        continue;
      }

      if (!favoriteCodes.contains(c.uniqueId)) {
        others.add(c);
      }
    }

    // Sort Others by Name
    others.sort((a, b) => a.name.compareTo(b.name));

    int currentIndex = 0;

    // 1. Favorites Section (Always Top)
    // We render Favorites with ReorderableListView if NO search and using specific UI?
    // User requested "Scroll while bookmark function".
    // If I use ScrollablePositionedList, I lose ReorderableListView's drag-and-drop easily.
    // BUT the user said "Keep existing behaviors like Favorites at top".
    // And "Scroll while bookmark function" for the List below.
    // So: Top part (Favorites) -> Reorderable (if no search).
    // Bottom part (Others) -> Indexable List.
    // I can put Reorderable List inside the ScrollablePositionedList as the *first item*?
    // No, that makes it one giant item.
    // Or I keep Favorites fixed at top (Sliver style) or just put them in the list.
    // If they want "Start from 'ㄹ'", they usually mean the main list.
    // Let's settle on:
    // - Favorites Section (drag reorder supported via custom Widget or just keep UI)
    // - Divider
    // - Indexable List of Others

    // Actually, simple solution for mixed needs:
    // Use CustomScrollView.
    // Sliver 1: Favorites Header + Reorderable List
    // Sliver 2: Sticky Header List?
    // Implementing Index Scroll with CustomScrollView is hard.
    // ScrollablePositionedList is best for "Jump to Index".
    // Can I implement Reorderable inside it? Hard.
    // User said: "Scroll while bookmark function" -> This implies jumping to section.
    // "Existing favorites at top maintained".
    // Let's keep the UI: Search -> Favorites (Reorderable) -> Others (Indexed).
    // But how to jump to 'Others' sections?
    // I can put the Favorites section as a HEADER of the ScrollablePositionedList (Index 0).
    // The "Others" start from Index 1?

    if (_searchQuery.isEmpty) {
      // Special Item: Favorites Block
      _displayList.add({'type': 'FAVORITES_BLOCK', 'data': favorites});
      currentIndex++;
    } else {
      // In search mode, just list everything? Or keep structure?
      // Usually search disables sections.
      if (favorites.isNotEmpty) {
        _displayList.add({'type': 'HEADER', 'title': '검색된 즐겨찾기'});
        currentIndex++;
        for (var f in favorites) {
          _displayList.add({'type': 'ITEM', 'data': f});
          currentIndex++;
        }
      }
    }

    // Others Section
    if (others.isNotEmpty) {
      String lastInitial = '';
      for (var c in others) {
        final initial = _getInitialSound(c.name);
        if (initial != lastInitial) {
          lastInitial = initial;
          _indexOffsets[initial] = currentIndex;
          _indexChars.add(initial);
          _displayList.add({'type': 'HEADER', 'title': initial});
          currentIndex++;
        }
        _displayList.add({'type': 'ITEM', 'data': c});
        currentIndex++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyListAsync = ref.watch(currencyListProvider);
    final favoriteCodes = ref.watch(favoriteCurrenciesProvider);
    final notifier = ref.read(favoriteCurrenciesProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isSelectionMode ? "국가 선택" : "국가 즐겨찾기 관리",
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            if (_searchQuery.isNotEmpty) {
              _searchController.clear();
              setState(() {
                _searchQuery = "";
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: currencyListAsync.when(
        data: (allCurrencies) {
          _prepareData(allCurrencies, favoriteCodes);

          _prepareData(allCurrencies, favoriteCodes);

          // Auto Scroll Logic
          if (!_scrolledToInitial && widget.initialSelectedId != null) {
            _scrolledToInitial = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              int targetIndex = -1;
              for (int i = 0; i < _displayList.length; i++) {
                final item = _displayList[i];
                if (item['type'] == 'ITEM' &&
                    item['data'].uniqueId == widget.initialSelectedId) {
                  targetIndex = i;
                  break;
                }
                // Favorites Block check
                if (item['type'] == 'FAVORITES_BLOCK') {
                  final List<Currency> favs = item['data'];
                  if (favs.any((f) => f.uniqueId == widget.initialSelectedId)) {
                    targetIndex = i; // Scroll to block
                    break;
                  }
                }
              }
              if (targetIndex != -1 && _itemScrollController.isAttached) {
                // Scroll with offset to center it roughly
                _itemScrollController.scrollTo(
                  index: targetIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: 0.1, // Near top but with padding
                );
              }
            });
          }

          return Column(
            children: [
              // Search
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "국가 또는 통화 검색",
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white70 : AppColors.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? Colors.grey[800]
                        : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      itemCount: _displayList.length,
                      itemBuilder: (context, index) {
                        final item = _displayList[index];
                        final type = item['type'];

                        if (type == 'FAVORITES_BLOCK') {
                          final List<Currency> favs = item['data'];
                          if (favs.isEmpty && _searchQuery.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "즐겨찾기가 없습니다.\n아래에서 추가해보세요.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          // Render Reorderable List inside here?
                          // ReorderableListView cannot easily be inside a ScrollablePositionedList item unless restricted.
                          // Let's use a Column of tiles with handle logic implemented manually or just simple list if too complex.
                          // User wants reorder.
                          // I will use a Column, but use the `ReorderableListView` isn't compatible with slivers easily here.
                          // Alternative: Display them as normal list items but marked as "Favorites".
                          // But user wants "Favorites at top" and "Scroll index for bottom".
                          // Simplest: Don't allow reorder inside this specific screen if it complicates `ScrollablePositionedList`.
                          // OR: Use `ReorderableListView` for the WHOLE list is impossible with Index Jump.
                          // Compromise: Reordering functionality provided by `ReorderableListView` is distinct.
                          // I'll render a simple List of favorites here. If they want to reorder, maybe a separate mode?
                          // Or I just render them. The user said "Keep existing favorites at top".
                          // I will render them as a block.
                          return Container(
                            color: Theme.of(context).cardColor,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    "나의 즐겨찾기 (밀어서 순서 변경)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  buildDefaultDragHandles: false,
                                  itemCount: favs.length,
                                  onReorder: (oldIndex, newIndex) {
                                    notifier.reorder(oldIndex, newIndex);
                                  },
                                  itemBuilder: (context, index) {
                                    final c = favs[index];
                                    return Container(
                                      key: ValueKey(c.uniqueId),
                                      color: Theme.of(context).cardColor,
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                        // 1. Sandwich Drag Handle (Left)
                                        leading: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ReorderableDragStartListener(
                                              index: index,
                                              child: Container(
                                                padding: const EdgeInsets.only(
                                                  right: 16,
                                                  top: 8,
                                                  bottom: 8,
                                                ),
                                                color: Colors
                                                    .transparent, // Hit test
                                                child: Icon(
                                                  Icons.menu,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[500],
                                                ),
                                              ),
                                            ),
                                            Text(
                                              CurrencyData.getFlag(c.name),
                                              style: const TextStyle(
                                                fontSize: 28,
                                              ),
                                            ),
                                          ],
                                        ),
                                        title: Text(
                                          "${c.name} (${c.code})",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          c.countryEn ?? '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                        ),
                                        // If selection mode, tap selects.
                                        // If NOT selection mode, tap does nothing (or shows detail?), trailing removes.
                                        onTap: widget.isSelectionMode
                                            ? () => Navigator.pop(context, {
                                                'currency': c.code,
                                                'name': c.name,
                                                'uniqueId': c.uniqueId,
                                              })
                                            : null,
                                        trailing: widget.isSelectionMode
                                            ? (c.uniqueId ==
                                                      widget.initialSelectedId
                                                  ? Icon(
                                                      Icons.check,
                                                      color: AppColors.primary,
                                                    )
                                                  : null)
                                            : IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () => notifier
                                                    .removeFavorite(c.uniqueId),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }

                        if (type == 'HEADER') {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: isDark
                                ? Colors.grey[900]
                                : const Color(0xFFF3F4F6),
                            child: Text(
                              item['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          );
                        }

                        if (type == 'ITEM') {
                          final Currency c = item['data'];
                          final isSelected = favoriteCodes.contains(c.uniqueId);
                          return Container(
                            color: Theme.of(context).cardColor,
                            child: ListTile(
                              leading: Text(
                                CurrencyData.getFlag(c.name),
                                style: const TextStyle(fontSize: 28),
                              ),
                              title: Text(
                                "${c.name} (${c.code})",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                c.countryEn ?? '',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                              trailing: widget.isSelectionMode
                                  ? null
                                  : (isSelected
                                        ? Icon(
                                            Icons.check_circle,
                                            color: isDark
                                                ? Colors.greenAccent
                                                : AppColors.primary,
                                          )
                                        : const Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.grey,
                                          )),
                              onTap: () {
                                if (widget.isSelectionMode) {
                                  Navigator.pop(context, {
                                    'currency': c.code,
                                    'name': c.name,
                                    'uniqueId': c.uniqueId,
                                  });
                                } else {
                                  bool wasSearch = _searchQuery.isNotEmpty;
                                  if (!isSelected) {
                                    notifier.addFavorite(c.uniqueId);
                                    // User requested: After selecting searched item, go to favorite manage page (list view)
                                    if (wasSearch) {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = "";
                                      });
                                    }
                                  } else {
                                    notifier.removeFavorite(c.uniqueId);
                                  }
                                }
                              },
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    // Index Bar
                    if (_indexChars.isNotEmpty)
                      Positioned(
                        right: 2,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]!.withValues(alpha: 0.8)
                                  : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _indexChars.map((char) {
                                return GestureDetector(
                                  onTap: () {
                                    final index = _indexOffsets[char];
                                    if (index != null) {
                                      _itemScrollController.jumpTo(
                                        index: index,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      char,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
