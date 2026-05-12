import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zen_hr/core/theme.dart';

class CustomDropdownField<T> extends StatefulWidget {
  final String? labelText;
  final bool isRequired;
  final String hintText;
  final IconData prefixIcon;
  final List<Map<String, dynamic>> items;
  final String valueKey;
  final String labelKey;
  final T? value;
  final bool isLoading;
  final bool isEnabled;
  final Color fillColor;
  final Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const CustomDropdownField({
    super.key,
    this.labelText,
    this.isRequired = false,
    required this.hintText,
    required this.prefixIcon,
    required this.items,
    required this.valueKey,
    required this.labelKey,
    this.value,
    this.onChanged,
    this.validator,
    this.isLoading = false,
    this.isEnabled = true,
    this.fillColor = ThemeClass.textBlack,
  });

  @override
  State<CustomDropdownField<T>> createState() => _CustomDropdownFieldState<T>();
}

class _CustomDropdownFieldState<T> extends State<CustomDropdownField<T>> {
  bool _isDropdownOpen = false;
  late ValueNotifier<T?> _selectedValueNotifier;

  @override
  void initState() {
    super.initState();
    // Initialize notifier with the initial value if it exists in items
    final bool valueExists = widget.items.any(
      (item) => item[widget.valueKey]?.toString() == widget.value?.toString(),
    );
    _selectedValueNotifier = ValueNotifier<T?>(valueExists ? widget.value : null);
  }

  @override
  void didUpdateWidget(CustomDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final bool valueExists = widget.items.any(
        (item) => item[widget.valueKey]?.toString() == widget.value?.toString(),
      );
      _selectedValueNotifier.value = valueExists ? widget.value : null;
    }
  }

  @override
  void dispose() {
    _selectedValueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: CircularProgressIndicator(strokeWidth: 2.w),
            ),
            SizedBox(width: 12.w),
            Text(
              "Loading...",
              style: TextStyle(fontSize: 16.sp, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Row(
            children: [
              Text(
                widget.labelText!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 15.sp,
                  color: Colors.white70,
                ),
              ),
              if (widget.isRequired)
                Text(
                  " *",
                  style: TextStyle(color: Colors.red, fontSize: 15.sp, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          SizedBox(height: 6.h),
        ],
        DropdownButtonFormField2<T>(
          isExpanded: true,
          valueListenable: _selectedValueNotifier,
          hint: Text(
            widget.hintText,
            style: TextStyle(
              color: widget.isEnabled
                  ? ThemeClass.textWhite.withOpacity(0.7)
                  : ThemeClass.textWhite.withOpacity(0.4),
              fontSize: 16.sp,
            ),
          ),
          items: widget.items
              .where((item) => item[widget.valueKey] != null)
              .map(
                (item) => DropdownItem<T>(
                  value: item[widget.valueKey] as T,
                  height: 48.h,
                  child: Text(
                    item[widget.labelKey].toString(),
                    style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  ),
                ),
              )
              .toList(),
          onMenuStateChange: (isOpen) {
            setState(() {
              _isDropdownOpen = isOpen;
            });
          },
          onChanged: widget.isEnabled
              ? (val) {
                  _selectedValueNotifier.value = val;
                  if (widget.onChanged != null) {
                    widget.onChanged!(val);
                  }
                }
              : null,
          validator:
              widget.validator ??
              (val) {
                if (widget.isRequired && val == null) {
                  return "Please select ${widget.labelText?.toLowerCase() ?? 'a value'}";
                }
                return null;
              },
          decoration: InputDecoration(
            prefixIcon: Icon(
              widget.prefixIcon,
              color: widget.isEnabled ? ThemeClass.textWhite : Colors.grey,
            ),
            filled: true,
            fillColor: widget.isEnabled ? widget.fillColor : Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 0.w),
          ),
          iconStyleData: IconStyleData(
            icon: AnimatedRotation(
              turns: _isDropdownOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24.sp),
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 300.h,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: ThemeClass.darkCardColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          menuItemStyleData: MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 20.w),
          ),
        ),
      ],
    );
  }
}
