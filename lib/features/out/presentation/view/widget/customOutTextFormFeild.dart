import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Customouttextformfeild extends StatelessWidget {
    String label;
     IconData icon;
     var validator;
     var onSaved;
     var scrollController;
    var keyboardType;
    var controller;
    Customouttextformfeild({
      required this.label,
      required this.icon,
       this.validator,
       this.onSaved,
       this.scrollController,
             this.keyboardType,
             this.controller

    });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintStyle:   GoogleFonts.cairo(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          labelStyle:   GoogleFonts.cairo(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
      onFieldSubmitted: (_) => scrollController.animateTo(
        scrollController.position.pixels + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    );
  }
}