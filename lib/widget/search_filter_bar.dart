import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onChanged;
  final bool showFilter;
  final VoidCallback? onFilterPressed;
  final EdgeInsetsGeometry padding;
  final Color iconColor;
  final BorderSide borderSide;
  final BorderSide enabledBorderSide;
  final BorderSide focusedBorderSide;
  final EdgeInsetsGeometry? contentPadding;
  final bool filled;
  final Color? fillColor;
  final List<Widget> extraSuffixActions;

  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.showFilter = false,
    this.onFilterPressed,
    this.padding = const EdgeInsets.all(16),
    this.iconColor = const Color(0xFF073850),
    this.borderSide = const BorderSide(color: Colors.black),
    this.enabledBorderSide = const BorderSide(color: Colors.black),
    this.focusedBorderSide = const BorderSide(color: Colors.black, width: 2),
    this.contentPadding,
    this.filled = true,
    this.fillColor = Colors.white,
    this.extraSuffixActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final suffixActions = <Widget>[
      if (controller.text.isNotEmpty)
        IconButton(
          icon: Icon(
            Icons.clear,
            color: iconColor,
          ),
          onPressed: () {
            controller.clear();
            onChanged();
          },
        ),
      ...extraSuffixActions,
      if (onFilterPressed != null)
        IconButton(
          icon: Icon(
            showFilter ? Icons.filter_list_off : Icons.filter_list,
            color: iconColor,
          ),
          onPressed: onFilterPressed,
        ),
    ];

    return Padding(
      padding: padding,
      child: 
      // TextField
      TextFormField 
      (
        controller: controller,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            color: iconColor,
          ),
          suffixIcon: suffixActions.isEmpty
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: suffixActions,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: borderSide,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: enabledBorderSide,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: focusedBorderSide,
          ),
          contentPadding: contentPadding,
          filled: filled,
          fillColor: fillColor,
        ),
      ),
    );
  }
}
