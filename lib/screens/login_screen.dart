import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventory_manage/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers cho form Đăng nhập
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();

  // Controllers cho form Đăng ký
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  final _regFormKey = GlobalKey<FormState>();

  bool _loginPasswordVisible = false;
  bool _regPasswordVisible = false;
  bool _regConfirmVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithEmail(
        email: _loginEmailCtrl.text,
        password: _loginPasswordCtrl.text,
      );
      // AuthWrapper sẽ tự điều hướng về HomeScreen
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.getErrorMessage(e));
    } catch (e) {
      _showError('Đăng nhập thất bại: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (!AuthService.isGoogleSignInSupported) {
      _showError(
        'Google Sign-In chưa hỗ trợ trên Windows/Linux native. '
        'Vui lòng đăng nhập bằng Email/Mật khẩu hoặc dùng bản web.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (result == null) {
        // Người dùng hủy — không báo lỗi
        setState(() => _isLoading = false);
        return;
      }
      // AuthWrapper sẽ tự điều hướng
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.getErrorMessage(e));
    } catch (e) {
      _showError('Đăng nhập Google thất bại: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.registerWithEmail(
        email: _regEmailCtrl.text,
        password: _regPasswordCtrl.text,
        displayName: _regNameCtrl.text,
      );
      _showSuccess('Tạo tài khoản thành công! Chào mừng bạn.');
      // AuthWrapper sẽ tự điều hướng
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.getErrorMessage(e));
    } catch (e) {
      _showError('Đăng ký thất bại: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _loginEmailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Vui lòng nhập email trước khi đặt lại mật khẩu.');
      return;
    }
    try {
      await AuthService.sendPasswordResetEmail(email);
      _showSuccess('Email đặt lại mật khẩu đã được gửi tới $email.');
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildTabCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Quản lý Kho hàng',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Đăng nhập để tiếp tục',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildTabCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              indicator: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Đăng nhập'),
                Tab(text: 'Đăng ký'),
              ],
            ),
          ),
          // Tab views
          SizedBox(
            height: 480,
            child: TabBarView(
              controller: _tabController,
              children: [_buildLoginForm(), _buildRegisterForm()],
            ),
          ),
        ],
      ),
    );
  }

  // ─── FORM ĐĂNG NHẬP ─────────────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _loginEmailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _loginPasswordCtrl,
              label: 'Mật khẩu',
              icon: Icons.lock_outline,
              obscure: !_loginPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _loginPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(
                  () => _loginPasswordVisible = !_loginPasswordVisible,
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildPrimaryButton(label: 'Đăng nhập', onPressed: _loginWithEmail),
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  // ─── FORM ĐĂNG KÝ ───────────────────────────────────────────────────────────
  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _regFormKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _regNameCtrl,
              label: 'Họ và tên',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _regEmailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _regPasswordCtrl,
              label: 'Mật khẩu',
              icon: Icons.lock_outline,
              obscure: !_regPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _regPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _regPasswordVisible = !_regPasswordVisible),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _regConfirmCtrl,
              label: 'Xác nhận mật khẩu',
              icon: Icons.lock_outline,
              obscure: !_regConfirmVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _regConfirmVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _regConfirmVisible = !_regConfirmVisible),
              ),
              validator: (v) {
                if (v != _regPasswordCtrl.text) return 'Mật khẩu không khớp';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildPrimaryButton(label: 'Tạo tài khoản', onPressed: _register),
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  // ─── SHARED WIDGETS ──────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'hoặc',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    final supported = AuthService.isGoogleSignInSupported;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: (_isLoading || !supported) ? null : _loginWithGoogle,
        icon: _GoogleIcon(),
        label: Text(
          supported
              ? 'Tiếp tục với Google'
              : 'Google chưa hỗ trợ trên desktop native',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade800,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) return 'Email không hợp lệ';
    return null;
  }
}

/// Icon Google thuần Flutter (không cần asset)
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Vẽ 4 cung màu của logo Google
    final colors = [
      const Color(0xFF4285F4), // xanh
      const Color(0xFF34A853), // lá
      const Color(0xFFFBBC05), // vàng
      const Color(0xFFEA4335), // đỏ
    ];
    final sweeps = [90.0, 90.0, 90.0, 90.0];
    double start = -90.0;
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.7),
        start * (3.14159 / 180),
        sweeps[i] * (3.14159 / 180),
        false,
        paint,
      );
      start += sweeps[i];
    }

    // Vạch trắng ở giữa bên phải (phần "G")
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - r * 0.18, r * 0.92, r * 0.36),
      whitePaint,
    );
    // Tô lại màu xanh cho phần bar ngang
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - r * 0.18, r * 0.88, r * 0.36),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
