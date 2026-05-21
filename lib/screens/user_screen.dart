import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventory_manage/services/auth_service.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tài khoản',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Không tìm thấy người dùng'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildAvatarSection(user),
                const SizedBox(height: 24),
                _buildInfoCard(user),
                const SizedBox(height: 24),
                _buildSignOutButton(context),
              ],
            ),
    );
  }

  Widget _buildAvatarSection(User user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.blue.shade100,
          backgroundImage: user.photoURL != null
              ? NetworkImage(user.photoURL!)
              : null,
          child: user.photoURL == null
              ? Icon(Icons.person, size: 52, color: Colors.blue.shade700)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          user.displayName ?? 'Người dùng',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? '',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildInfoCard(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              blurRadius: 10, color: Colors.black12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.email_outlined, 'Email', user.email ?? '-'),
          const Divider(height: 24),
          _infoRow(
            Icons.verified_user_outlined,
            'Xác minh email',
            user.emailVerified ? 'Đã xác minh' : 'Chưa xác minh',
            valueColor: user.emailVerified ? Colors.green : Colors.orange,
          ),
          const Divider(height: 24),
          _infoRow(
            Icons.login_outlined,
            'Đăng nhập qua',
            _getProviderName(user),
          ),
          const Divider(height: 24),
          _infoRow(
            Icons.calendar_today_outlined,
            'Ngày tạo',
            user.metadata.creationTime != null
                ? _formatDate(user.metadata.creationTime!)
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.blue.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.grey.shade800,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Đăng xuất'),
              content: const Text('Bạn có chắc muốn đăng xuất không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600),
                  child: const Text('Đăng xuất',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await AuthService.signOut();
            // AuthWrapper sẽ tự điều hướng về LoginScreen
          }
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text('Đăng xuất',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  String _getProviderName(User user) {
    if (user.providerData.isEmpty) return 'Email/Password';
    final provider = user.providerData.first.providerId;
    switch (provider) {
      case 'google.com':
        return 'Google';
      case 'password':
        return 'Email/Password';
      default:
        return provider;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}
