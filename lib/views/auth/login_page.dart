import 'package:flutter/material.dart';
import '../../viewmodels/login_viewmodel.dart';
import '../../viewmodels/signup_viewmodel.dart';
import '../../viewmodels/customer_dashboard_viewmodel.dart';
import '../../services/firestore_service.dart';
import '../../models/order_detail_model.dart';
import '../../models/service_model.dart';
import '../customer/customer_dashboard_page.dart';
import '../customer/customer_order_detail_page.dart';
import '../employee/employee_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Login
  final usernameLoginController = TextEditingController();
  final passwordLoginController = TextEditingController();
  bool _obscureLogin = true;

  // ── Sign Up
  final signupFormKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameSignupController = TextEditingController();
  final passwordSignupController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  bool _obscureSignup = true;

  // ── Track Order
  final orderCodeController = TextEditingController();

  final loginViewModel = LoginViewModel();
  final signupViewModel = SignupViewModel();
  final firestoreService = FirestoreService();

  bool isLoadingLogin = false;
  bool isLoadingSignup = false;
  bool isLoadingTrack = false;
  String loginError = '';
  String signupError = '';
  String trackError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          loginError = '';
          signupError = '';
          trackError = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    usernameLoginController.dispose();
    passwordLoginController.dispose();
    nameController.dispose();
    usernameSignupController.dispose();
    passwordSignupController.dispose();
    phoneController.dispose();
    addressController.dispose();
    orderCodeController.dispose();
    super.dispose();
  }

  // ── Login logic ────────────────────────────────────────────────────────────

  Future<void> _login() async {
    setState(() {
      isLoadingLogin = true;
      loginError = '';
    });

    try {
      final user = await loginViewModel.login(
        usernameLoginController.text,
        passwordLoginController.text,
      );

      if (!mounted) return;

      if (user == null) {
        setState(() {
          isLoadingLogin = false;
          loginError = 'Incorrect username or password';
        });
        return;
      }

      setState(() => isLoadingLogin = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user.role == 'Customer'
              ? CustomerDashboardPage(user: user)
              : EmployeeDashboardPage(user: user),
        ),
      );
    } catch (e) {
      setState(() {
        isLoadingLogin = false;
        loginError = e.toString();
      });
    }
  }

  // ── Sign Up logic ──────────────────────────────────────────────────────────

  Future<void> _signUp() async {
    if (!signupFormKey.currentState!.validate()) return;

    setState(() {
      isLoadingSignup = true;
      signupError = '';
    });

    try {
      final user = await signupViewModel.signUp(
        name: nameController.text,
        username: usernameSignupController.text,
        password: passwordSignupController.text,
        phone: phoneController.text,
        address: addressController.text.isNotEmpty
            ? addressController.text
            : null,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerDashboardPage(user: user),
        ),
      );
    } catch (e) {
      setState(() {
        isLoadingSignup = false;
        signupError = e.toString();
      });
    }
  }

  // ── Track Order logic ──────────────────────────────────────────────────────

  Future<void> _trackOrder() async {
    final code = orderCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => trackError = 'Please enter an order code');
      return;
    }

    setState(() {
      isLoadingTrack = true;
      trackError = '';
    });

    try {
      final order = await firestoreService.getOrderByCode(code);

      if (!mounted) return;

      if (order == null) {
        setState(() {
          isLoadingTrack = false;
          trackError = 'Order not found. Please check the code and try again.';
        });
        return;
      }

      final orderDetails = await firestoreService.getOrderDetails();
      final services = await firestoreService.getServices();

      final detail = orderDetails.firstWhere(
        (d) => d.orderId == order.orderId,
        orElse: () => OrderDetailModel(
          orderDetailId: 0,
          orderId: order.orderId,
          serviceId: 0,
          weight: 0,
        ),
      );

      final service = services.firstWhere(
        (s) => s.serviceId == detail.serviceId,
        orElse: () => ServiceModel(
          serviceId: 0,
          serviceName: 'Unknown Service',
          estimatedDays: 0,
          servicePrice: 0,
          description: 'No description',
          isActive: false,
        ),
      );

      if (!mounted) return;

      setState(() => isLoadingTrack = false);

      final item = CustomerOrderItem(
        order: order,
        serviceName: service.serviceName,
        estimatedDays: service.estimatedDays,
        servicePrice: service.servicePrice,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerOrderDetailPage(item: item),
        ),
      );
    } catch (e) {
      setState(() {
        isLoadingTrack = false;
        trackError = e.toString();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.08),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: const BoxDecoration(
                    color: Color(0xff4A90E2),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.local_laundry_service,
                          size: 56, color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        'LaundryIn',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Laundry Management System',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tab Bar ───────────────────────────────────────────────
                Container(
                  color: const Color(0xff3A7BD5),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                      Tab(text: 'Track Order'),
                    ],
                  ),
                ),

                // ── Tab Content ───────────────────────────────────────────
                SizedBox(
                  height: 520,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginTab(),
                      _buildSignUpTab(),
                      _buildTrackOrderTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Login Tab ──────────────────────────────────────────────────────────────

  Widget _buildLoginTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: usernameLoginController,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordLoginController,
            obscureText: _obscureLogin,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLogin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureLogin = !_obscureLogin),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => isLoadingLogin ? null : _login(),
          ),
          if (loginError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              loginError,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoadingLogin ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4A90E2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLoadingLogin ? 'Logging in...' : 'Login',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text(
                "Don't have an account? Sign Up",
                style: TextStyle(color: Color(0xff4A90E2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sign Up Tab ────────────────────────────────────────────────────────────

  Widget _buildSignUpTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: signupViewModel.validateName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: usernameSignupController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: signupViewModel.validateUsername,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordSignupController,
              obscureText: _obscureSignup,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSignup
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureSignup = !_obscureSignup),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: signupViewModel.validatePassword,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: signupViewModel.validatePhone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address (optional)',
                prefixIcon: const Icon(Icons.home_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (signupError.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                signupError,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoadingSignup ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLoadingSignup ? 'Creating account...' : 'Sign Up',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => _tabController.animateTo(0),
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Color(0xff4A90E2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Track Order Tab ────────────────────────────────────────────────────────

  Widget _buildTrackOrderTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffE6F1FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Color(0xff185FA5), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enter your order code to track your laundry without logging in.',
                    style: TextStyle(
                      color: Color(0xff185FA5),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: orderCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Order Code',
              hintText: 'e.g. ORD-2025-0041',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => isLoadingTrack ? null : _trackOrder(),
          ),
          if (trackError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              trackError,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoadingTrack ? null : _trackOrder,
              icon: isLoadingTrack
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.local_shipping_outlined),
              label: Text(
                isLoadingTrack ? 'Searching...' : 'Track Order',
                style: const TextStyle(fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4A90E2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text(
                'Have an account? Login instead',
                style: TextStyle(color: Color(0xff4A90E2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}