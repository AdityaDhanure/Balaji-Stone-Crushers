import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TimeInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String defaultPeriod;

  const TimeInputField({
    super.key,
    required this.controller,
    required this.label,
    this.defaultPeriod = 'AM',
  });

  @override
  State<TimeInputField> createState() => TimeInputFieldState();
}

class TimeInputFieldState extends State<TimeInputField> {
  late String _period;

  String get time24Hour {
    final input = widget.controller.text.trim();
    if (input.isEmpty) return '00:00:00';

    int hour = 0;
    int minute = 0;

    if (input.contains(':')) {
      final parts = input.split(':');
      hour = int.tryParse(parts[0]) ?? 0;
      minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    } else if (input.length <= 2) {
      hour = int.tryParse(input) ?? 0;
      minute = 0;
    } else if (input.length == 3) {
      hour = int.tryParse(input[0]) ?? 0;
      minute = int.tryParse(input.substring(1)) ?? 0;
    } else if (input.length == 4) {
      hour = int.tryParse(input.substring(0, 2)) ?? 0;
      minute = int.tryParse(input.substring(2)) ?? 0;
    }

    hour = hour.clamp(1, 12);
    minute = minute.clamp(0, 59);

    if (_period == 'AM') {
      if (hour == 12) hour = 0;
    } else {
      if (hour != 12) hour += 12;
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }

  @override
  void initState() {
    super.initState();
    final text = widget.controller.text.toUpperCase();
    _period = text.contains('PM') ? 'PM' : widget.defaultPeriod;
    widget.controller.text = text.replaceAll('AM', '').replaceAll('PM', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '9:30 or 9',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time, size: 18),
                    onPressed: () async {
                      final current = widget.controller.text;
                      final parts = current.split(':');
                      int h = int.tryParse(parts[0]) ?? 9;
                      int m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: _period == 'PM' && h != 12 ? h + 12 : h,
                          minute: m,
                        ),
                      );

                      if (picked != null) {
                        int displayHour = picked.hour;
                        setState(() {
                          if (picked.hour == 0) {
                            displayHour = 12;
                            _period = 'AM';
                          } else if (picked.hour < 12) {
                            displayHour = picked.hour;
                            _period = 'AM';
                          } else if (picked.hour == 12) {
                            displayHour = 12;
                            _period = 'PM';
                          } else {
                            displayHour = picked.hour - 12;
                            _period = 'PM';
                          }
                          widget.controller.text = '${displayHour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                ),
                onEditingComplete: () {
                  FocusScope.of(context).nextFocus();
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _period = 'AM'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: _period == 'AM' ? AppColors.primary : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                      ),
                      child: Text(
                        'AM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _period == 'AM' ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _period = 'PM'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: _period == 'PM' ? AppColors.primary : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                      ),
                      child: Text(
                        'PM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _period == 'PM' ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}