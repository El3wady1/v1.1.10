import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Accepteddropbox extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? value;
  final Function(String?)? onChanged;
  final FormFieldValidator<String>? validator;

  const Accepteddropbox({
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
            hintStyle:   GoogleFonts.cairo(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
            labelText: label,
            labelStyle:   GoogleFonts.cairo(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueAccent),
          style:  GoogleFonts.cairo(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(item, textAlign: TextAlign.right,style:  GoogleFonts.cairo(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
