import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LogDateSelector extends StatelessWidget {
  final List logDates;
  final String selectedDate;
  final Function(String) onDateSelected;

  const LogDateSelector({
    super.key,
    required this.logDates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  Widget _buildDateItem(date) {
    String str = date;
    return GestureDetector(
      onTap: () {
        onDateSelected(date);
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Column(
            children: [
              Text(
                str.substring(5),
              ),
              Text(
                str.substring(0, 4),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoScrollbar(
        child: ListView.separated(
          padding: const EdgeInsets.only(left: 20, right: 10, top: 20),
          itemBuilder: (context, i) {
            return _buildDateItem(logDates[i]);
          },
          separatorBuilder: (context, i) {
            return const SizedBox(height: 20);
          },
          itemCount: logDates.length,
        ),
      ),
    );
  }
}
