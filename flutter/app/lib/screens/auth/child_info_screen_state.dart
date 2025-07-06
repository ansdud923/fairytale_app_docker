// lib/child_info_screen.dart
import 'package:flutter/material.dart';
import '../../main.dart';

class ChildInfoScreen extends StatefulWidget {
  @override
  _ChildInfoScreenState createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends State<ChildInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Child Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter child name',
                  fillColor: Color(0xFFFFE7B0),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text('Birth Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 56,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE7B0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                        : 'Select birth date',
                    style: TextStyle(fontSize: 16, color: Color(0xFF3B2D2C)),
                  ),
                ),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF6B756),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: Text('SAVE'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text('NO THANKS', style: TextStyle(color: Color(0xFF9E9E9E))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
