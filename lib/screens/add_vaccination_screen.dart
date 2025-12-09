import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/vaccination.dart';
import '../providers/vaccination_provider.dart';

class AddVaccinationScreen extends StatefulWidget {
  final String petId;
  final Vaccination? vaccination;

  const AddVaccinationScreen({
    Key? key,
    required this.petId,
    this.vaccination,
  }) : super(key: key);

  @override
  State<AddVaccinationScreen> createState() => _AddVaccinationScreenState();
}

class _AddVaccinationScreenState extends State<AddVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vaccineNameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _vaccinationDate = DateTime.now();
  DateTime? _nextDate;
  bool _hasNextDate = false;
  bool _isLoading = false;

  final List<String> _commonVaccines = [
    'Dại (Rabies)',
    '6 bệnh (DHPPI)',
    '7 bệnh (DHPPiL)',
    '8 bệnh (DHPPiLC)',
    'Care (Viêm phổi)',
    'Giun tim',
    'Viêm gan',
    'FeLV (Mèo)',
    'FIV (Mèo)',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.vaccination != null) {
      _vaccineNameController.text = widget.vaccination!.vaccineName;
      _vaccinationDate = widget.vaccination!.vaccinationDate;
      _nextDate = widget.vaccination!.nextDate;
      _hasNextDate = _nextDate != null;
      _notesController.text = widget.vaccination!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectVaccinationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _vaccinationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _vaccinationDate) {
      setState(() {
        _vaccinationDate = picked;
      });
    }
  }

  Future<void> _selectNextDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _vaccinationDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _nextDate = picked;
      });
    }
  }

  Future<void> _saveVaccination() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final vaccination = Vaccination(
      petId: widget.petId,
      vaccineName: _vaccineNameController.text.trim(),
      vaccinationDate: _vaccinationDate,
      nextDate: _hasNextDate ? _nextDate : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final provider = context.read<VaccinationProvider>();
    bool success;

    if (widget.vaccination != null) {
      success = await provider.updateVaccination(
        widget.vaccination!.id!,
        vaccination,
      );
    } else {
      success = await provider.addVaccination(vaccination);
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vaccination != null
                ? 'Cập nhật thành công!'
                : 'Thêm lịch tiêm thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra, vui lòng thử lại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vaccination != null
            ? 'Sửa lịch tiêm'
            : 'Thêm lịch tiêm'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Common vaccines chips
            const Text(
              'Vaccine phổ biến:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonVaccines.map((vaccine) {
                return ActionChip(
                  label: Text(vaccine),
                  onPressed: () {
                    setState(() {
                      _vaccineNameController.text = vaccine;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Vaccine name field
            TextFormField(
              controller: _vaccineNameController,
              decoration: const InputDecoration(
                labelText: 'Tên vaccine *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vaccines),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên vaccine';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Vaccination date picker
            InkWell(
              onTap: _selectVaccinationDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày tiêm *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(_vaccinationDate)),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Next date checkbox
            CheckboxListTile(
              title: const Text('Lên lịch tiêm tiếp theo'),
              value: _hasNextDate,
              onChanged: (value) {
                setState(() {
                  _hasNextDate = value!;
                  if (_hasNextDate && _nextDate == null) {
                    _nextDate = _vaccinationDate.add(const Duration(days: 30));
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Next date picker
            if (_hasNextDate) ...[
              InkWell(
                onTap: _selectNextDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày tiêm tiếp theo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_nextDate != null
                          ? DateFormat('dd/MM/yyyy').format(_nextDate!)
                          : 'Chọn ngày'),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Ghi chú về phản ứng, liều lượng...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveVaccination,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.vaccination != null ? 'Cập nhật' : 'Thêm lịch tiêm',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}