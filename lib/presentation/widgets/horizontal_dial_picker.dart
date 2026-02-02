import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HorizontalDialPicker<T> extends StatefulWidget {
  final List<T> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final Widget Function(BuildContext, T, double opacity, double scale)
  itemBuilder;
  final double viewportFraction;

  const HorizontalDialPicker({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.itemBuilder,
    required this.viewportFraction,
  });

  @override
  State<HorizontalDialPicker<T>> createState() =>
      _HorizontalDialPickerState<T>();
}

class _HorizontalDialPickerState<T> extends State<HorizontalDialPicker<T>> {
  late PageController _controller;
  late double _currentPage;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.items.indexOf(widget.selectedValue);
    _currentPage = initialIndex.toDouble();
    _controller = PageController(
      initialPage: initialIndex,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Picker (Bottom)
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                setState(() {
                  _currentPage = _controller.page ?? 0;
                });
              }
              if (notification is ScrollEndNotification) {
                final int newIndex = _controller.page!.round();
                if (widget.items[newIndex] != widget.selectedValue) {
                  HapticFeedback.lightImpact();
                  widget.onChanged(widget.items[newIndex]);
                }
              }
              return true;
            },
            child: PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final double difference = (index - _currentPage).abs();
                final double opacity = (1 - (difference * 0.5)).clamp(0.2, 1.0);
                final double scale = (1.2 - (difference * 0.2)).clamp(0.8, 1.2);

                return Center(
                  child: widget.itemBuilder(
                    context,
                    widget.items[index],
                    opacity,
                    scale,
                  ),
                );
              },
            ),
          ),

          // 2. Edge Fading & Glassy Overlay (Middle)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF2C2C2E),
                            const Color(0xFF2C2C2E).withOpacity(0),
                            const Color(0xFF2C2C2E).withOpacity(0),
                            const Color(0xFF2C2C2E),
                          ]
                        : [
                            Colors.white,
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0),
                            Colors.white,
                          ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Arrows (Middle, on top of gradient)
          Positioned(
            left: 12,
            child: IgnorePointer(
              child: Icon(
                CupertinoIcons.chevron_left,
                size: 20,
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            right: 12,
            child: IgnorePointer(
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 20,
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.15),
              ),
            ),
          ),

          // 4. Touch Targets (Top)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_controller.page! > 0) {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                const Spacer(flex: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_controller.page! < widget.items.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
