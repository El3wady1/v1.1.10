import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArabicKeyboard extends StatelessWidget {
  final void Function(String) onTextInput;
  final VoidCallback onBackspace;

  const ArabicKeyboard({
    Key? key,
    required this.onTextInput,
    required this.onBackspace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4EF), // لون الخلفية #F3F4EF
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildRow(['0', '✖']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return _KeyButton(
          keySymbol: key,
          onTap: () => key == '✖' ? onBackspace() : onTextInput(key),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String keySymbol;
  final VoidCallback onTap;

  const _KeyButton({
    required this.keySymbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBackspace = keySymbol == '✖';
    final bool isArabicFive = keySymbol == '٥';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFCDBCA2), // لون الأزرار #CDBCA2
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined, 
                  size: 20, 
                  color: const Color(0xFF74826A), // لون الأيقونة #74826A
                )
              : Text(
                  isArabicFive ? '٥' : keySymbol,
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF74826A), // لون الأرقام #74826A
                  ),
                ),
        ),
      ),
    );
  }
}