import 'package:flutter/material.dart';

class VitalsScroll extends StatelessWidget {
  const VitalsScroll({super.key});

  Widget vital(String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right:10),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height:60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          vital("HR 78"),
          vital("Chol 210"),
          vital("Sugar 110"),
          vital("Sleep 6h"),
        ],
      ),
    );
  }
}