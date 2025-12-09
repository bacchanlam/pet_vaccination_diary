import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';
import '../providers/vaccination_provider.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetProvider>().loadPets();
      context.read<VaccinationProvider>().loadVaccinations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật Ký Tiêm Phòng'),
        elevation: 0,
      ),
      body: Consumer2<PetProvider, VaccinationProvider>(
        builder: (context, petProvider, vaccinationProvider, child) {
          if (petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (petProvider.pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thú cưng nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút + để thêm thú cưng',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Upcoming vaccinations alert
              _buildUpcomingAlert(vaccinationProvider, petProvider),
              
              // Pet list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: petProvider.pets.length,
                  itemBuilder: (context, index) {
                    final pet = petProvider.pets[index];
                    final petVaccinations = vaccinationProvider
                        .getVaccinationsForPet(pet.id!);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue[100],
                          child: pet.imageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    pet.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        const Icon(Icons.pets, size: 30),
                                  ),
                                )
                              : const Icon(Icons.pets, size: 30),
                        ),
                        title: Text(
                          pet.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${pet.type} - ${pet.breed} - ${pet.gender}'),
                            Text('${pet.getAge()}'),
                            const SizedBox(height: 4),
                            Text(
                              '${petVaccinations.length} lần tiêm',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PetDetailScreen(pet: pet),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPetScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUpcomingAlert(VaccinationProvider vaccinationProvider, PetProvider petProvider) {
    final upcoming = vaccinationProvider.getUpcomingVaccinations()
        .where((v) => v.isDueSoon())
        .toList();
    final overdue = vaccinationProvider.getOverdueVaccinations();

    if (upcoming.isEmpty && overdue.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: overdue.isNotEmpty ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: overdue.isNotEmpty ? Colors.red[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            overdue.isNotEmpty ? Icons.warning : Icons.notifications,
            color: overdue.isNotEmpty ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              overdue.isNotEmpty
                  ? '${overdue.length} lịch tiêm đã quá hạn!'
                  : '${upcoming.length} lịch tiêm sắp đến!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: overdue.isNotEmpty ? Colors.red[900] : Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}