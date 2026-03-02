import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// Business hours management screen and day configuration widget
class _BusinessHoursScreen extends StatefulWidget {
  final BusinessHours businessHours;
  final Function(BusinessHours) onSave;

  const _BusinessHoursScreen({
    required this.businessHours,
    required this.onSave,
  });

  @override
  State<_BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<_BusinessHoursScreen> {
  late BusinessHours hours;

  @override
  void initState() {
    super.initState();
    hours = widget.businessHours;
  }

  void _updateHours(int dayIndex, TimeRange newHours) {
    setState(() {
      switch (dayIndex) {
        case 0:
          hours.monday = newHours;
          break;
        case 1:
          hours.tuesday = newHours;
          break;
        case 2:
          hours.wednesday = newHours;
          break;
        case 3:
          hours.thursday = newHours;
          break;
        case 4:
          hours.friday = newHours;
          break;
        case 5:
          hours.saturday = newHours;
          break;
        case 6:
          hours.sunday = newHours;
          break;
      }
    });
  }

  void _save() {
    widget.onSave(hours);
    Navigator.pop(context);
    ToastHelper.showToast(context, 'Business hours updated');
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      ('Monday', hours.monday),
      ('Tuesday', hours.tuesday),
      ('Wednesday', hours.wednesday),
      ('Thursday', hours.thursday),
      ('Friday', hours.friday),
      ('Saturday', hours.saturday),
      ('Sunday', hours.sunday),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Hours'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final day = days[index];
          return _DayHoursCard(
            day: day.$1,
            hours: day.$2,
            onChanged: (newHours) => _updateHours(index, newHours),
          );
        },
      ),
    );
  }
}

/// Individual day hours configuration card
class _DayHoursCard extends StatelessWidget {
  final String day;
  final TimeRange hours;
  final Function(TimeRange) onChanged;

  const _DayHoursCard({
    required this.day,
    required this.hours,
    required this.onChanged,
  });

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final currentTime = isOpenTime ? hours.openTime : hours.closeTime;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isOpenTime) {
        onChanged(hours.copyWith(openTime: timeString));
      } else {
        onChanged(hours.copyWith(closeTime: timeString));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: hours.isOpen,
                  onChanged: (value) {
                    onChanged(hours.copyWith(isOpen: value));
                  },
                ),
                Text(hours.isOpen ? 'Open' : 'Closed'),
              ],
            ),
            if (hours.isOpen) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Opening Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(hours.openTime),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Closing Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(hours.closeTime),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
