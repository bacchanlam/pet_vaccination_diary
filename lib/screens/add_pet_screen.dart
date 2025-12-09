import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';

class AddPetScreen extends StatefulWidget {
  final Pet? pet;

  const AddPetScreen({Key? key, this.pet}) : super(key: key);

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  
  String _selectedType = 'Chó';
  String _selectedGender = 'Đực'; // Thêm giới tính
  DateTime _birthDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _petTypes = [
    'Chó',
    'Mèo',
    'Chim',
    'Thỏ',
    'Hamster',
    'Khác',
  ];

  final List<String> _genders = ['Đực', 'Cái']; // Danh sách giới tính

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _breedController.text = widget.pet!.breed;
      _selectedType = widget.pet!.type;
      _selectedGender = widget.pet!.gender;
      _birthDate = widget.pet!.birthDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final pet = Pet(
      name: _nameController.text.trim(),
      type: _selectedType,
      breed: _breedController.text.trim(),
      gender: _selectedGender,
      birthDate: _birthDate,
    );

    final petProvider = context.read<PetProvider>();
    bool success;

    if (widget.pet != null) {
      success = await petProvider.updatePet(widget.pet!.id!, pet);
    } else {
      success = await petProvider.addPet(pet);
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.pet != null
                ? 'Cập nhật thành công!'
                : 'Thêm thú cưng thành công!'),
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
        title: Text(widget.pet != null ? 'Sửa thông tin' : 'Thêm thú cưng'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên thú cưng *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Type dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Loại thú cưng *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _petTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Breed field
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Giống *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
                hintText: 'VD: Golden Retriever, Mèo Ba Tư...',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập giống';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Gender dropdown - THÊM MỚI
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Giới tính *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.male),
              ),
              items: _genders.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Birth date picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(_birthDate)),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _savePet,
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
                      widget.pet != null ? 'Cập nhật' : 'Thêm thú cưng',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}