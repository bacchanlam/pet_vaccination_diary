import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/vaccination_provider.dart';
import '../providers/pet_provider.dart';
import 'add_vaccination_screen.dart';

class VaccinationsListScreen extends StatefulWidget {
  const VaccinationsListScreen({Key? key}) : super(key: key);

  @override
  State<VaccinationsListScreen> createState() => _VaccinationsListScreenState();
}

class _VaccinationsListScreenState extends State<VaccinationsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  String _selectedPetFilter = 'all';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredVaccinations(VaccinationProvider vacProvider) {
    var vaccinations = vacProvider.vaccinations;

    // Filter by pet
    if (_selectedPetFilter != 'all') {
      vaccinations = vaccinations
          .where((v) => v.petId == _selectedPetFilter)
          .toList();
    }

    // Filter by status
    switch (_selectedFilter) {
      case 'upcoming':
        vaccinations = vaccinations
            .where(
              (v) =>
                  v.nextDate != null &&
                  v.nextDate!.isAfter(DateTime.now()) &&
                  !v.isOverdue(),
            )
            .toList();
        break;
      case 'overdue':
        vaccinations = vaccinations.where((v) => v.isOverdue()).toList();
        break;
      default:
        break;
    }

    return vaccinations;
  }

  List<dynamic> _getVaccinationsForDay(
    DateTime day,
    VaccinationProvider vacProvider,
  ) {
    return vacProvider.vaccinations.where((v) {
      return isSameDay(v.vaccinationDate, day) ||
          (v.nextDate != null && isSameDay(v.nextDate, day));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<VaccinationProvider, PetProvider>(
      builder: (context, vacProvider, petProvider, _) {
        return Scaffold(
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9966), Color(0xFFFF8C5A)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lịch tiêm phòng',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_getFilteredVaccinations(vacProvider).length} lịch tiêm',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Filter button
                        IconButton(
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () =>
                              _showFilterDialog(context, petProvider),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatCard(
                            icon: Icons.vaccines,
                            value: '${vacProvider.vaccinations.length}',
                            label: 'Tổng số',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniStatCard(
                            icon: Icons.warning_amber,
                            value:
                                '${vacProvider.getOverdueVaccinations().length}',
                            label: 'Quá hạn',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniStatCard(
                            icon: Icons.schedule,
                            value:
                                '${vacProvider.getUpcomingVaccinations().where((v) => v.isDueSoon()).length}',
                            label: 'Sắp tới',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFFF9966),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFFF9966),
                  tabs: const [
                    Tab(icon: Icon(Icons.list), text: 'Danh sách'),
                    Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListView(vacProvider, petProvider, isDark),
                    _buildTimelineView(vacProvider, petProvider, isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // LIST VIEW
  Widget _buildListView(
    VaccinationProvider vacProvider,
    PetProvider petProvider,
    bool isDark,
  ) {
    final vaccinations = _getFilteredVaccinations(vacProvider);

    if (vacProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (petProvider.pets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.info_outline,
        title: 'Chưa có thú cưng',
        subtitle: 'Thêm thú cưng trước để tạo lịch tiêm',
        isDark: isDark,
      );
    }

    if (vaccinations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.vaccines,
        title: 'Chưa có lịch tiêm nào',
        subtitle: 'Nhấn nút "Thêm lịch" để bắt đầu',
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await vacProvider.loadVaccinations();
        await petProvider.loadPets();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vaccinations.length,
        itemBuilder: (context, index) {
          final vaccination = vaccinations[index];
          final pet = petProvider.getPetById(vaccination.petId);
          return _buildEnhancedVaccinationCard(
            context,
            vaccination,
            pet,
            vacProvider,
            isDark,
          );
        },
      ),
    );
  }

  // TIMELINE VIEW
  Widget _buildTimelineView(
    VaccinationProvider vacProvider,
    PetProvider petProvider,
    bool isDark,
  ) {
    final vaccinations = _getFilteredVaccinations(vacProvider);

    if (vaccinations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.timeline,
        title: 'Chưa có dữ liệu',
        subtitle: 'Thêm lịch tiêm để xem timeline',
        isDark: isDark,
      );
    }

    // Group by month
    Map<String, List<dynamic>> groupedVaccinations = {};
    for (var vac in vaccinations) {
      final monthKey = DateFormat('MM/yyyy').format(vac.vaccinationDate);
      if (!groupedVaccinations.containsKey(monthKey)) {
        groupedVaccinations[monthKey] = [];
      }
      groupedVaccinations[monthKey]!.add(vac);
    }

    final sortedKeys = groupedVaccinations.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final monthKey = sortedKeys[index];
        final monthVaccinations = groupedVaccinations[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9966).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tháng $monthKey',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9966),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF9966).withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Timeline items
            ...monthVaccinations.map((vac) {
              final pet = petProvider.getPetById(vac.petId);
              return _buildTimelineItem(context, vac, pet, vacProvider, isDark);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    dynamic vaccination,
    dynamic pet,
    VaccinationProvider provider,
    bool isDark,
  ) {
    final isOverdue = vaccination.isOverdue();
    final isDueSoon = vaccination.isDueSoon();

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red
                      : isDueSoon
                      ? Colors.orange
                      : const Color(0xFFFF9966),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Container(width: 2, height: 60, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOverdue
                      ? Colors.red.withOpacity(0.3)
                      : isDueSoon
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vaccination.vaccineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Sửa'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Xóa',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddVaccinationScreen(
                                  petId: vaccination.petId,
                                  vaccination: vaccination,
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            _confirmDeleteVaccination(
                              context,
                              vaccination,
                              provider,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (pet != null)
                    Row(
                      children: [
                        Icon(Icons.pets, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          pet.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(vaccination.vaccinationDate),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (vaccination.nextDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: isOverdue
                              ? Colors.red
                              : isDueSoon
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tiêm tiếp: ${DateFormat('dd/MM/yyyy').format(vaccination.nextDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue
                                ? Colors.red
                                : isDueSoon
                                ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedVaccinationCard(
    BuildContext context,
    dynamic vaccination,
    dynamic pet,
    VaccinationProvider provider,
    bool isDark,
  ) {
    final isOverdue = vaccination.isOverdue();
    final isDueSoon = vaccination.isDueSoon();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withOpacity(0.3)
              : isDueSoon
              ? Colors.orange.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showVaccinationDetails(
              context,
              vaccination,
              pet,
              provider,
              isDark,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOverdue
                          ? [Colors.red[400]!, Colors.red[600]!]
                          : isDueSoon
                          ? [Colors.orange[400]!, Colors.orange[600]!]
                          : [const Color(0xFFFF9966), const Color(0xFFFF8C5A)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.vaccines,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccination.vaccineName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (pet != null)
                        Row(
                          children: [
                            Icon(Icons.pets, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              pet.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đã tiêm: ${DateFormat('dd/MM/yyyy').format(vaccination.vaccinationDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (vaccination.nextDate != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 14,
                              color: isOverdue
                                  ? Colors.red
                                  : isDueSoon
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Tiêm tiếp: ${DateFormat('dd/MM/yyyy').format(vaccination.nextDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue
                                      ? Colors.red
                                      : isDueSoon
                                      ? Colors.orange
                                      : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Column(
                  children: [
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Quá hạn',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isDueSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sắp tới',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9966).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: const Color(0xFFFF9966)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, PetProvider petProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Lọc lịch tiêm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'all';
                        _selectedPetFilter = 'all';
                      });
                      setModalState(() {});
                    },
                    child: const Text('Đặt lại'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Trạng thái:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedFilter == 'all',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'all');
                      setModalState(() {});
                    },
                  ),
                  FilterChip(
                    label: const Text('Sắp tới'),
                    selected: _selectedFilter == 'upcoming',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'upcoming');
                      setModalState(() {});
                    },
                  ),
                  FilterChip(
                    label: const Text('Quá hạn'),
                    selected: _selectedFilter == 'overdue',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'overdue');
                      setModalState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Thú cưng:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedPetFilter == 'all',
                    onSelected: (selected) {
                      setState(() => _selectedPetFilter = 'all');
                      setModalState(() {});
                    },
                  ),
                  ...petProvider.pets
                      .map(
                        (pet) => FilterChip(
                          label: Text(pet.name),
                          selected: _selectedPetFilter == pet.id,
                          onSelected: (selected) {
                            setState(
                              () => _selectedPetFilter = selected
                                  ? pet.id!
                                  : 'all',
                            );
                            setModalState(() {});
                          },
                        ),
                      )
                      .toList(),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9966),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Áp dụng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _showAddVaccinationDialog(BuildContext context, PetProvider petProvider) {
  //   if (petProvider.pets.length == 1) {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => AddVaccinationScreen(petId: petProvider.pets.first.id!),
  //       ),
  //     );
  //   } else {
  //     showModalBottomSheet(
  //       context: context,
  //       shape: const RoundedRectangleBorder(
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //       ),
  //       builder: (context) => Container(
  //         padding: const EdgeInsets.all(24),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const Text(
  //               'Chọn thú cưng',
  //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(height: 16),
  //             ...petProvider.pets.map((pet) => ListTile(
  //               leading: CircleAvatar(
  //                 backgroundColor: const Color(0xFFFF9966),
  //                 backgroundImage: pet.imageUrl != null ? NetworkImage(pet.imageUrl!) : null,
  //                 child: pet.imageUrl == null ? const Icon(Icons.pets, color: Colors.white) : null,
  //               ),
  //               title: Text(pet.name),
  //               subtitle: Text('${pet.type} - ${pet.breed}'),
  //               trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => AddVaccinationScreen(petId: pet.id!),
  //                   ),
  //                 );
  //               },
  //             )).toList(),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  // }

  void _showVaccinationDetails(
    BuildContext context,
    dynamic vaccination,
    dynamic pet,
    VaccinationProvider provider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9966), Color(0xFFFF8C5A)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.vaccines,
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
                          vaccination.vaccineName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (pet != null)
                          Text(
                            pet.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'Ngày tiêm',
                value: DateFormat(
                  'dd/MM/yyyy',
                ).format(vaccination.vaccinationDate),
              ),
              if (vaccination.nextDate != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.event,
                  label: 'Ngày tiêm tiếp theo',
                  value: DateFormat('dd/MM/yyyy').format(vaccination.nextDate!),
                  valueColor: vaccination.isOverdue()
                      ? Colors.red
                      : vaccination.isDueSoon()
                      ? Colors.orange
                      : Colors.green,
                ),
              ],
              if (vaccination.notes != null &&
                  vaccination.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Ghi chú',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vaccination.notes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddVaccinationScreen(
                              petId: vaccination.petId,
                              vaccination: vaccination,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Sửa'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeleteVaccination(
                          context,
                          vaccination,
                          provider,
                        );
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        'Xóa',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9966).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFF9966), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVaccination(
    BuildContext context,
    dynamic vaccination,
    VaccinationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa lịch tiêm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteVaccination(vaccination.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa lịch tiêm'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
