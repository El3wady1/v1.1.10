import 'package:flutter/material.dart';

class Customintextformfeild extends StatelessWidget {
    String label;
     IconData icon;
     var validator;
     var onSaved;
     var scrollController;
    var keyboardType;
    var controller;
    Customintextformfeild({
      required this.label,
      required this.icon,
      required this.validator,
       this.onSaved,
      required this.scrollController,
             this.keyboardType,
             this.controller

    });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
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