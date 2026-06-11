import 'package:flutter/material.dart';

import '../../viewmodels/login_viewmodel.dart';
import '../../viewmodels/signup_viewmodel.dart';
import '../../viewmodels/customer_dashboard_viewmodel.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
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

  // Login
  final usernameLoginController = TextEditingController();
  final passwordLoginController = TextEditingController();
  bool _obscureLogin = true;

  // Sign Up
  final signupFormKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameSignupController = TextEditingController();
  final passwordSignupController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  bool _obscureSignup = true;

  // Track Order
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

  Future<void> _login() async {
    // Validasi kosong dulu
    if (usernameLoginController.text.isEmpty) {
      setState(() => loginError = 'Username harus diisi');
      return;
    }
    if (passwordLoginController.text.isEmpty) {
      setState(() => loginError = 'Password harus diisi');
      return;
    }
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

      if (user.role == 'Customer') {
        await NotificationService().saveDeviceToken(user.userId.toString());
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

      await NotificationService().saveDeviceToken(user.userId.toString());

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Container(
              color: const Color(0xff3A7BD5),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'Login'),
                  Tab(text: 'Sign Up'),
                  Tab(text: 'Track Order'),
                ],
              ),
            ),

            Expanded(
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
      color: const Color(0xff4A90E2),
      child: const Column(
        children: [
          Icon(
            Icons.local_laundry_service,
            size: 58,
            color: Colors.white,
          ),
          SizedBox(height: 10),
          Text(
            'LaundryIn',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Laundry Management System',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          TextField(
            controller: usernameLoginController,
            decoration: inputDecoration(
              label: 'Username',
              icon: Icons.person_outline,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: passwordLoginController,
            obscureText: _obscureLogin,
            decoration: inputDecoration(
              label: 'Password',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLogin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureLogin = !_obscureLogin;
                  });
                },
              ),
            ),
            onSubmitted: (_) => isLoadingLogin ? null : _login(),
          ),

          if (loginError.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              loginError,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isLoadingLogin ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4A90E2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isLoadingLogin ? 'Logging in...' : 'Login',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

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

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            TextFormField(
              controller: nameController,
              decoration: inputDecoration(
                label: 'Full Name',
                icon: Icons.badge_outlined,
              ),
              validator: signupViewModel.validateName,
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: usernameSignupController,
              decoration: inputDecoration(
                label: 'Username',
                icon: Icons.person_outline,
              ),
              validator: signupViewModel.validateUsername,
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: passwordSignupController,
              obscureText: _obscureSignup,
              decoration: inputDecoration(
                label: 'Password',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSignup
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureSignup = !_obscureSignup;
                    });
                  },
                ),
              ),
              validator: signupViewModel.validatePassword,
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: inputDecoration(
                label: 'Phone Number',
                icon: Icons.phone_outlined,
              ),
              validator: signupViewModel.validatePhone,
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: addressController,
              decoration: inputDecoration(
                label: 'Address (optional)',
                icon: Icons.home_outlined,
              ),
            ),

            if (signupError.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                signupError,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoadingSignup ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4A90E2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isLoadingSignup ? 'Creating account...' : 'Sign Up',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

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

  Widget _buildTrackOrderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffE6F1FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xff185FA5),
                  size: 20,
                ),
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
            decoration: inputDecoration(
              label: 'Order Code',
              icon: Icons.search,
              hintText: 'e.g. ORD001',
            ),
            onSubmitted: (_) => isLoadingTrack ? null : _trackOrder(),
          ),

          if (trackError.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              trackError,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
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
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4A90E2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

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

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xff4A90E2),
          width: 1.5,
        ),
      ),
    );
  }
}