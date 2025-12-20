import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/pet_provider.dart';
import '../providers/vaccination_provider.dart';
import '../providers/post_provider.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'create_post_screen.dart';
import 'pets_list_screen.dart';
import 'vaccinations_list_screen.dart';
import '../widgets/post_card.dart';
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
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
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
      context.read<PostProvider>().loadPosts();
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await context.read<PostProvider>().searchUsers(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  String _getDisplayName(User? user) {
    if (_userName != null && _userName!.isNotEmpty) {
      return _userName!;
    }

    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user?.email != null) {
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
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            _HomeContentWidget(), // News Feed
            PetsListScreen(), // Trang Thú cưng
            VaccinationsListScreen(), // Trang Lịch tiêm
            ProfileScreen(), // Trang Tài khoản
          ],
        ),
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                ).then((_) {
                  context.read<PostProvider>().loadPosts();
                });
              },
              backgroundColor: const Color(0xFFFF9966),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// Widget riêng cho News Feed
class _HomeContentWidget extends StatefulWidget {
  const _HomeContentWidget({Key? key}) : super(key: key);

  @override
  State<_HomeContentWidget> createState() => _HomeContentWidgetState();
}

class _HomeContentWidgetState extends State<_HomeContentWidget> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  models.UserProfile? _userProfile;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userProfile = await AuthService().getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userName = _userProfile?.name;
        });
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await context.read<PostProvider>().searchUsers(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  String _getDisplayName(User? user) {
    if (_userName != null && _userName!.isNotEmpty) {
      return _userName!;
    }

    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user?.email != null) {
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
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<PostProvider>().loadPosts();
      },
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
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
                              _getDisplayName(user)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _searchUsers,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm người dùng...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFFFF9966)),
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),

                  // Search results
                  if (_searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isSearching
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _searchResults.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Không tìm thấy người dùng',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final searchUser = _searchResults[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFFFF9966),
                                        backgroundImage:
                                            searchUser['avatarUrl'] != null
                                                ? NetworkImage(
                                                    searchUser['avatarUrl'])
                                                : null,
                                        child: searchUser['avatarUrl'] == null
                                            ? Text(
                                                searchUser['name']
                                                    .toString()
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(searchUser['name']),
                                      subtitle: Text(searchUser['email']),
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Xem hồ sơ ${searchUser['name']}'),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Posts Feed
          Consumer<PostProvider>(
            builder: (context, postProvider, _) {
              if (postProvider.isLoading) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (postProvider.posts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.article,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có bài viết nào',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy chia sẻ khoảnh khắc đầu tiên!',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = postProvider.posts[index];
                      return PostCard(post: post);
                    },
                    childCount: postProvider.posts.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}