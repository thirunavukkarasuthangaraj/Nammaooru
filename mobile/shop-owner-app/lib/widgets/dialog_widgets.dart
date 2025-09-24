import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'common_widgets.dart';

/// Confirmation dialog
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.icon,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: confirmColor ?? AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading3,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTextStyles.body,
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        CustomButton(
          text: confirmText,
          backgroundColor: confirmColor ?? AppColors.primary,
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Success dialog
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading3,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTextStyles.body,
      ),
      actions: [
        CustomButton(
          text: buttonText,
          backgroundColor: AppColors.success,
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Error dialog
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading3,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTextStyles.body,
      ),
      actions: [
        CustomButton(
          text: buttonText,
          backgroundColor: AppColors.error,
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Loading dialog
class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({
    super.key,
    required this.message,
  });

  static Future<void> show({
    required BuildContext context,
    required String message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single selection dialog
class SingleSelectionDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemBuilder;
  final ValueChanged<T>? onItemSelected;

  const SingleSelectionDialog({
    super.key,
    required this.title,
    required this.items,
    this.selectedItem,
    required this.itemBuilder,
    this.onItemSelected,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    T? selectedItem,
    required String Function(T) itemBuilder,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => SingleSelectionDialog<T>(
        title: title,
        items: items,
        selectedItem: selectedItem,
        itemBuilder: itemBuilder,
        onItemSelected: (item) => Navigator.of(context).pop(item),
      ),
    );
  }

  @override
  State<SingleSelectionDialog<T>> createState() => _SingleSelectionDialogState<T>();
}

class _SingleSelectionDialogState<T> extends State<SingleSelectionDialog<T>> {
  T? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: AppTextStyles.heading3,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected = item == _selectedItem;

            return RadioListTile<T>(
              title: Text(widget.itemBuilder(item)),
              value: item,
              groupValue: _selectedItem,
              onChanged: (value) {
                setState(() {
                  _selectedItem = value;
                });
                if (widget.onItemSelected != null) {
                  widget.onItemSelected!(value!);
                }
              },
              activeColor: AppColors.primary,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Multi-selection dialog
class MultiSelectionDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) itemBuilder;
  final ValueChanged<List<T>>? onSelectionChanged;

  const MultiSelectionDialog({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.itemBuilder,
    this.onSelectionChanged,
  });

  static Future<List<T>?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required List<T> selectedItems,
    required String Function(T) itemBuilder,
  }) {
    return showDialog<List<T>>(
      context: context,
      builder: (context) => MultiSelectionDialog<T>(
        title: title,
        items: items,
        selectedItems: selectedItems,
        itemBuilder: itemBuilder,
        onSelectionChanged: (items) => Navigator.of(context).pop(items),
      ),
    );
  }

  @override
  State<MultiSelectionDialog<T>> createState() => _MultiSelectionDialogState<T>();
}

class _MultiSelectionDialogState<T> extends State<MultiSelectionDialog<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: AppTextStyles.heading3,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected = _selectedItems.contains(item);

            return CheckboxListTile(
              title: Text(widget.itemBuilder(item)),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedItems.add(item);
                  } else {
                    _selectedItems.remove(item);
                  }
                });
              },
              activeColor: AppColors.primary,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Done',
          onPressed: () {
            if (widget.onSelectionChanged != null) {
              widget.onSelectionChanged!(_selectedItems);
            }
          },
        ),
      ],
    );
  }
}

/// Input dialog
class InputDialog extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? initialValue;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String confirmText;
  final String cancelText;
  final ValueChanged<String>? onConfirm;

  const InputDialog({
    super.key,
    required this.title,
    this.hintText,
    this.initialValue,
    this.keyboardType,
    this.maxLines = 1,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
    TextInputType? keyboardType,
    int? maxLines,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => InputDialog(
        title: title,
        hintText: hintText,
        initialValue: initialValue,
        keyboardType: keyboardType,
        maxLines: maxLines,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: (value) => Navigator.of(context).pop(value),
      ),
    );
  }

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: AppTextStyles.heading3,
      ),
      content: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelText),
        ),
        CustomButton(
          text: widget.confirmText,
          onPressed: () {
            if (widget.onConfirm != null) {
              widget.onConfirm!(_controller.text);
            }
          },
        ),
      ],
    );
  }
}

/// Date picker dialog
class DatePickerDialog extends StatelessWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateSelected;

  const DatePickerDialog({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // This is handled by showDatePicker
  }
}

/// Time picker dialog
class TimePickerDialog extends StatelessWidget {
  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay>? onTimeSelected;

  const TimePickerDialog({
    super.key,
    this.initialTime,
    this.onTimeSelected,
  });

  static Future<TimeOfDay?> show({
    required BuildContext context,
    TimeOfDay? initialTime,
  }) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // This is handled by showTimePicker
  }
}