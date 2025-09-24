import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// Custom text form field with consistent styling
class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final bool enabled;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}

/// Custom dropdown form field
class CustomDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemBuilder;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;

  const CustomDropdownFormField({
    super.key,
    this.value,
    required this.items,
    required this.itemBuilder,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemBuilder(item)),
        );
      }).toList(),
    );
  }
}

/// Custom switch form field
class CustomSwitchFormField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool enabled;

  const CustomSwitchFormField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(
          title,
          style: AppTextStyles.body,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        secondary: icon != null ? Icon(icon) : null,
        activeColor: AppColors.primary,
      ),
    );
  }
}

/// Custom checkbox form field
class CustomCheckboxFormField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String title;
  final String? subtitle;
  final String? Function(bool?)? validator;
  final bool enabled;

  const CustomCheckboxFormField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: field.hasError ? AppColors.error : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CheckboxListTile(
                value: value,
                onChanged: enabled ? (value) {
                  onChanged(value);
                  field.didChange(value);
                } : null,
                title: Text(
                  title,
                  style: AppTextStyles.body,
                ),
                subtitle: subtitle != null
                    ? Text(
                        subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  field.errorText!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Custom radio form field
class CustomRadioFormField<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final String title;
  final String? subtitle;
  final bool enabled;

  const CustomRadioFormField({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<T>(
        value: value,
        groupValue: groupValue,
        onChanged: enabled ? onChanged : null,
        title: Text(
          title,
          style: AppTextStyles.body,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        activeColor: AppColors.primary,
      ),
    );
  }
}

/// Custom slider form field
class CustomSliderFormField extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final String Function(double)? labelBuilder;
  final bool enabled;

  const CustomSliderFormField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.divisions,
    required this.label,
    this.labelBuilder,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              labelBuilder?.call(value) ?? value.toStringAsFixed(1),
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          onChanged: enabled ? onChanged : null,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}

/// Custom date picker form field
class CustomDatePickerFormField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  const CustomDatePickerFormField({
    super.key,
    this.value,
    required this.onChanged,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      readOnly: true,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon ?? Icons.calendar_today,
      initialValue: value != null ? _formatDate(value!) : null,
      validator: (text) {
        if (validator != null) {
          return validator!(value);
        }
        return null;
      },
      onTap: enabled ? () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (date != null) {
          onChanged(date);
        }
      } : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}

/// Custom time picker form field
class CustomTimePickerFormField extends StatelessWidget {
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(TimeOfDay?)? validator;
  final bool enabled;

  const CustomTimePickerFormField({
    super.key,
    this.value,
    required this.onChanged,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      readOnly: true,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon ?? Icons.access_time,
      initialValue: value?.format(context),
      validator: (text) {
        if (validator != null) {
          return validator!(value);
        }
        return null;
      },
      onTap: enabled ? () async {
        final time = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (time != null) {
          onChanged(time);
        }
      } : null,
    );
  }
}

/// Custom multi-line text form field
class CustomMultiLineFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const CustomMultiLineFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.initialValue,
    this.maxLines = 3,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      initialValue: initialValue,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

/// Form section widget
class FormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const FormSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children.map((child) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: child,
          )),
        ],
      ),
    );
  }
}