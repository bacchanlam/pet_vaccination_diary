// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../models/user.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      setState(() => _isLoading = true);
      
      _userProfile = await _authService.getUserProfile(user.uid);
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getDisplayName() {
    if (_userProfile?.name != null && _userProfile!.name.isNotEmpty) {
      return _userProfile!.name;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    
    if (user?.email != null) {
      return user!.email!.split('@')[0];
    }
    
    return 'Người dùng';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header with gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9966), Color(0xFFFF8C5A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: _userProfile?.avatarUrl != null
                                ? NetworkImage(_userProfile!.avatarUrl!)
                                : null,
                            child: _userProfile?.avatarUrl == null
                                ? Text(
                                    _getDisplayName().substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFFFF9966),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getDisplayName(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Edit Profile Button
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                            
                            // Reload nếu có thay đổi
                            if (result == true) {
                              _loadUserData();
                            }
                          },
                          icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                          label: const Text(
                            'Chỉnh sửa hồ sơ',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account Section
                  _buildSectionTitle('Tài khoản'),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Đổi mật khẩu',
                    subtitle: 'Cập nhật mật khẩu của bạn',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // App Settings Section
                  _buildSectionTitle('Cài đặt'),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Thông báo',
                    subtitle: 'Quản lý thông báo',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.language_outlined,
                    title: 'Ngôn ngữ',
                    subtitle: 'Tiếng Việt',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Giao diện',
                    subtitle: context.watch<ThemeProvider>().isDarkMode 
                        ? 'Chế độ tối' 
                        : 'Chế độ sáng',
                    trailing: Switch(
                      value: context.watch<ThemeProvider>().isDarkMode,
                      onChanged: (value) {
                        context.read<ThemeProvider>().toggleTheme();
                      },
                      activeColor: const Color(0xFFFF9966),
                    ),
                    onTap: () {
                      context.read<ThemeProvider>().toggleTheme();
                    },
                  ),

                  const SizedBox(height: 12),

                  // Support Section
                  _buildSectionTitle('Hỗ trợ'),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Trợ giúp & Hỗ trợ',
                    subtitle: 'Câu hỏi thường gặp',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Chính sách bảo mật',
                    subtitle: 'Điều khoản sử dụng',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'Về ứng dụng',
                    subtitle: 'Phiên bản 1.0.0',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Pet Vaccination Diary',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.pets,
                          size: 48,
                          color: Color(0xFFFF9966),
                        ),
                        children: const [
                          Text(
                            'Ứng dụng quản lý lịch tiêm phòng cho thú cưng của bạn.',
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  
                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Đăng xuất',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9966).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFF9966), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: trailing ?? 
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.signOut();
    }
  }
}