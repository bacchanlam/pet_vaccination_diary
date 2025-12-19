import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/pet_provider.dart';
import '../providers/vaccination_provider.dart';
import '../services/auth_service.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';
import 'profile_screen.dart';
import '../models/user.dart' as models;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  int _selectedIndex = 0;
  models.UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Load user profile từ Firestore
        _userProfile = await AuthService().getUserProfile(user.uid);

        if (mounted) {
          setState(() {
            _userName = _userProfile?.name;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }

    if (mounted) {
      context.read<PetProvider>().loadPets();
      context.read<VaccinationProvider>().loadVaccinations();
    }
  }

  String _getDisplayName(User? user) {
    // Ưu tiên: Firestore name > Display name > Email name > "Bạn"
    if (_userName != null && _userName!.isNotEmpty) {
      return _userName!;
    }

    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user?.email != null) {
      // Lấy phần trước @ của email
      return user!.email!.split('@')[0];
    }

    return 'Bạn';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng!';
    if (hour < 18) return 'Chào buổi chiều!';
    return 'Chào buổi tối!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildHomeContent()
            : _selectedIndex == 1
            ? _buildPetsContent()
            : _selectedIndex == 2
            ? _buildVaccinationsContent()
            : const ProfileScreen(), // Dùng ProfileScreen riêng
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFF9966),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              activeIcon: Icon(Icons.pets),
              label: 'Thú cưng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.vaccines_outlined),
              activeIcon: Icon(Icons.vaccines),
              label: 'Lịch tiêm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with greeting
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Chuyển sang tab Tài khoản
                    setState(() {
                      _selectedIndex = 3;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF9966),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFFF9966),
                      backgroundImage: _userProfile?.avatarUrl != null
                          ? NetworkImage(_userProfile!.avatarUrl!)
                          : null,
                      child: _userProfile?.avatarUrl == null
                          ? Text(
                              _getDisplayName(
                                user,
                              ).substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Chuyển sang tab Tài khoản
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, ${_getDisplayName(user)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Show notifications
                  },
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thú cưng...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF9966)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
          const SizedBox(height: 20),

          // Vaccination Alert Card
          Consumer<VaccinationProvider>(
            builder: (context, vacProvider, _) {
              final upcoming = vacProvider
                  .getUpcomingVaccinations()
                  .where((v) => v.isDueSoon())
                  .toList();
              final overdue = vacProvider.getOverdueVaccinations();

              if (upcoming.isEmpty && overdue.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: overdue.isNotEmpty
                          ? [Colors.red[400]!, Colors.red[600]!]
                          : [const Color(0xFFFF9966), const Color(0xFFFF8C5A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (overdue.isNotEmpty
                                    ? Colors.red
                                    : const Color(0xFFFF9966))
                                .withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          overdue.isNotEmpty ? Icons.warning : Icons.vaccines,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              overdue.isNotEmpty
                                  ? 'Cảnh báo quá hạn!'
                                  : 'Sắp đến lịch tiêm',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overdue.isNotEmpty
                                  ? '${overdue.length} lịch tiêm đã quá hạn'
                                  : '${upcoming.length} lịch tiêm sắp tới',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thao tác nhanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.add_circle,
                        title: 'Thêm thú cưng',
                        color: const Color(0xFFFF9966),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddPetScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.vaccines,
                        title: 'Lịch tiêm',
                        color: Colors.blue,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 2;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // My Pets Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thú cưng của tôi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(color: Color(0xFFFF9966)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Pet List
          Consumer2<PetProvider, VaccinationProvider>(
            builder: (context, petProvider, vacProvider, _) {
              if (petProvider.pets.isEmpty) {
                return _buildEmptyState();
              }

              return SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: petProvider.pets.length > 3
                      ? 3
                      : petProvider.pets.length,
                  itemBuilder: (context, index) {
                    final pet = petProvider.pets[index];
                    final vaccinations = vacProvider.getVaccinationsForPet(
                      pet.id!,
                    );
                    return _buildPetCard(pet, vaccinations.length);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(pet, int vaccinationCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PetDetailScreen(pet: pet)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: pet.imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        pet.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const Center(child: Icon(Icons.pets, size: 50)),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.pets, size: 50, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.type} • ${pet.getAge()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9966).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$vaccinationCount lần tiêm',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF9966),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có thú cưng nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm thú cưng đầu tiên của bạn!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetsContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<PetProvider, VaccinationProvider>(
      builder: (context, petProvider, vacProvider, _) {
        if (petProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (petProvider.pets.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách thú cưng',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFFFF9966),
                    ),
                    iconSize: 32,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPetScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: petProvider.pets.length,
                itemBuilder: (context, index) {
                  final pet = petProvider.pets[index];
                  final vaccinations = vacProvider.getVaccinationsForPet(
                    pet.id!,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(
                          0xFFFF9966,
                        ).withOpacity(0.1),
                        backgroundImage: pet.imageUrl != null
                            ? NetworkImage(pet.imageUrl!)
                            : null,
                        child: pet.imageUrl == null
                            ? const Icon(Icons.pets, color: Color(0xFFFF9966))
                            : null,
                      ),
                      title: Text(
                        pet.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${pet.type} • ${pet.breed} • ${pet.gender}'),
                          Text(
                            '${pet.getAge()} • ${vaccinations.length} lần tiêm',
                            style: const TextStyle(color: Color(0xFFFF9966)),
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
    );
  }

  Widget _buildVaccinationsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.vaccines, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Trang Lịch tiêm',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Đang phát triển...', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
