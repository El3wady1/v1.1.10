import 'package:flutter/material.dart';

class Unitdropbox extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? value;
  final Function(String?)? onChanged;
  final FormFieldValidator<String>? validator;

  const Unitdropbox({
    Key? key,
    required this.label,
    required this.icon,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19.0, vertical: 5),
      child: Directionality( // هذا يتحكم في اتجاه النص داخل الدروب داون
        textDirection: TextDirection.rtl,
        child: DropdownButtonFormField<String>(
          initialValue: value,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueAccent),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(item, textAlign: TextAlign.right),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
