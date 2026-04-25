import 'package:dream_attend/models/employee.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/api_service.dart';
import '/services/employee_service.dart';
import '/services/onesignal_service.dart';
import 'home_page.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'register_page.dart';
import 'utils/app_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final sessionId = prefs.getString('sessionId');
    final email = prefs.getString('email') ?? 'Unknown';
    final employeeId = prefs.getString('employeeId') ?? 'N/A';
    final address = prefs.getString('address') ?? 'N/A';
    final mobile = prefs.getString('mobile') ?? 'N/A';
    final numericId = prefs.getInt('numericId') ?? 0;
    final employeeName = prefs.getString('employeeName') ?? email;
    List<String> groups = [];
    try {
      final groupsJson = prefs.getString('groups') ?? '[]';
      groups = List<String>.from(jsonDecode(groupsJson));
    } catch (e) {
      debugPrint('Failed to parse stored groups: $e');
    }

    if (isLoggedIn && sessionId != null && sessionId.isNotEmpty) {
      final hasValidSession = await ApiService()
          .validateStoredSession()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint(
          'Stored session validation timed out, continuing with local session',
        );
        return true;
      });
      if (!hasValidSession) {
        debugPrint('Stored session expired on server, redirecting to login');
        await prefs.clear();
        return const MyHomePage(title: 'Login');
      }

      debugPrint('Using stored session data for user: $email, groups: $groups');
      return HomePage(
        name: employeeName,
        employeeId: employeeId,
        numericId: numericId,
        groups: groups,
        address: address,
        mobile: mobile,
        jobTitle: '',
      );
    } else {
      debugPrint('No valid session found or cleared, redirecting to login');
      await prefs.clear();
      return const MyHomePage(title: 'Login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Employee Attendance',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 241, 246, 249),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 205, 214, 219),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(255, 207, 214, 217),
        ),
      ),
      routes: {
        '/login': (context) => const MyHomePage(title: 'Login'),
        '/register': (context) => const RegisterPage(),
        '/no_internet': (context) => const NoInternetPage(),
      },
      home: FutureBuilder<Widget>(
        future: _getInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            debugPrint('Error in _getInitialPage: ${snapshot.error}');
            return const MyHomePage(title: 'Login');
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  bool _isObscure = true;
  bool _isLoading = false;
  bool _agreedToTnC = false; // Added for Terms and Conditions
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final EmployeeService _employeeService = EmployeeService();
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _logoAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializePushNotifications(
    SharedPreferences prefs,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final oneSignalService = OneSignalService();
      await oneSignalService
          .initOneSignal(sessionData['user_id'].toString())
          .timeout(const Duration(seconds: 8));

      final status = await OneSignal.shared
          .getDeviceState()
          .timeout(const Duration(seconds: 5));
      final playerId = status?.userId;
      if (playerId == null || playerId.isEmpty) {
        debugPrint('No valid player ID received from OneSignal');
        return;
      }

      await _apiService.savePlayerId(
        playerId: playerId,
        sessionId: sessionData['sessionId'],
      );
      await prefs.setString('player_id', playerId);
    } on TimeoutException catch (e) {
      debugPrint('Push initialization timed out: $e');
    } catch (e) {
      debugPrint('Player ID save failed: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTnC) {
      errorSnackBar('Error', 'Please agree to the Terms and Conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.mobile) &&
          !connectivityResult.contains(ConnectivityResult.wifi)) {
        Navigator.pushNamed(context, '/no_internet');
        setState(() => _isLoading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      final sessionData = await _apiService.authenticateUser(
        email: email,
        password: password,
      );

      // Fetch user groups if not included in auth response
      List<String> groups = sessionData['groups'];
      if (groups.isEmpty) {
        groups = await _apiService.getUserGroups(
          sessionId: sessionData['sessionId'],
          userId: sessionData['user_id'].toString(),
        );
        if (groups.isEmpty) {
          warningSnackBar(
            'Warning',
            'Could not fetch user permissions. Limited access granted.',
          );
        }
      }

      // Fetch employee info
      final employees = await _employeeService
          .getEmployees()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint(
          'Employee fetch timed out during login, using session fallback',
        );
        return <Employee>[];
      });
      final employee = employees.firstWhere(
        (e) => e.email.toLowerCase() == email.toLowerCase(),
        orElse: () => Employee(
          id: sessionData['user_id'],
          name: sessionData['name'],
          employeeId: 'N/A',
          jobTitle: '',
          dob: '',
          address: 'N/A',
          mobile: 'N/A',
          email: email,
          roleType: sessionData['role'] ?? '',
          gender: '',
        ),
      );

      // Save session data
      await prefs.setString('email', email);
      await prefs.setString('employeeId', employee.employeeId ?? 'N/A');
      await prefs.setString('address', employee.address);
      await prefs.setString('mobile', employee.mobile);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('sessionId', sessionData['sessionId']);
      await prefs.setInt('numericId', employee.id);
      await prefs.setString('employeeName', employee.name);
      await prefs.setString('device_id', sessionData['device_id']);
      await prefs.setString('groups', jsonEncode(groups));

      // debugPrint('handleLogin: groups = $groups');

      if (!mounted) return;

      successSnackBar('Success', 'Login Successful!');

      unawaited(_initializePushNotifications(prefs, sessionData));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            name: employee.name,
            numericId: employee.id,
            employeeId: employee.employeeId ?? 'N/A',
            groups: groups,
            address: employee.address,
            mobile: employee.mobile,
            jobTitle: employee.jobTitle,
          ),
        ),
      );
    } catch (e) {
      String errorMessage = _mapError(e.toString());
      // debugPrint('Login error: $errorMessage');
      errorSnackBar('Error', errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapError(String error) {
    if (error.contains('Device is already associated')) {
      return 'This device is already associated with another account. Contact your administrator.';
    } else if (error.contains('Account is locked to another device')) {
      return 'Your account is locked to another device. Contact your administrator.';
    } else if (error.contains('Invalid email or password') ||
        error.toLowerCase().contains('access denied')) {
      return 'Invalid email or password';
    } else if (error.contains('SocketException') ||
        error.contains('Connection refused') ||
        error.contains('Network is unreachable') ||
        error.contains('timed out') ||
        error.contains('TimeoutException') ||
        error.contains('Cleartext HTTP traffic')) {
      return 'Unable to reach server';
    }
    return error.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _logoAnimation,
                      child: Image.asset(
                        'assets/images/logo1.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF073850),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Color(0xFF073850)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF073850),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF073850)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF073850),
                          ),
                          onPressed: () =>
                              setState(() => _isObscure = !_isObscure),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF073850),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter password'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTnC,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTnC = value ?? false;
                            });
                          },
                        ),
                        Flexible(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('I agree to '),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      insetPadding: EdgeInsets.zero,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(context).size.width,
                                          maxHeight: MediaQuery.of(context)
                                              .size
                                              .height,
                                        ),
                                        child: Scaffold(
                                          appBar: AppBar(
                                            backgroundColor:
                                                const Color(0xFF073850),
                                            title: const Text(
                                              'नियम',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            iconTheme: const IconThemeData(
                                              color: Colors.white,
                                            ),
                                            actions: [
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                          body: const SingleChildScrollView(
                                            padding: EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '''
१) दुकान मध्ये वेळेवर हजर राहणे.

२) दुकानच्या बाहेर जायचे असल्यास परवानगी शिवाय जाऊ नये.

३) कोणत्याही सेल्समन ने मॅनेजरशी उद्धट पणे बोलल्यास किंवा सांगितलेले काम न केल्यास त्याच्या वर योग्य ती कारवाई केली जाईल.

४) कॅश काऊंटर वाल्याने आणि त्यामागील हेल्परने परवानगी शिवाय काऊंटर सोडून जाऊ नये.

५) कोणत्याही कामगाराने दुसऱ्या कामगाराशी बोलताना रिस्पेक्ट देऊनच बोलावे, तसे न आढळल्यास त्याच्यावर कारवाई केली जाईल.

६) दुकानमधये व्यसन करण्यास सक्त मनाई आहे.

७) कोणता ही कामगार टाईमपास करताना दिसू नये.

८) कोणत्याही कामगारास कोणी भेटायला आल्यास परवानगी घेऊनच बाहेर जाणे.

९) दुकान मधये आल्यांनतर ठरवून दिलेल्या प्रमाणे स्वच्छता काळीच पाहिजे, आणि प्रत्येक ठिकाणचे कपडे दाखविण्याच्या काऊंटरची देखील स्वच्छता वेळोवेळी काळीच पाहिजे.

१०) महिलांनी जेवण करायच्या ठिकाणी दर दोन दिवसाने साफ सफाई करावी.

११) प्रत्येक मांडणी स्वच्छ आणि टापटीप असायला हवी.

१२) कामगाराने कस्टमरशी व्यवस्थित आणि हसतमुख चेहर्‍याने बोलावे.

१३) कोणतेही काम सिनीयर ने सांगितल्यास तालेच पाहिजे, त्यास नकारार्थी शब्द नको.

१४) कामाच्या वेळेस मोबाईल चा वापर करू नये, अन्यथा त्यावर फाईन लावण्यात येईल.

१५) कोणत्याही फ्लोर वरील कामगार दुसऱ्या फ्लोर वर विना कारण टाईम पास करताना दिसू नये अन्यथा कारवाई करण्यात येईल.

१६) जेवणाचा वेळ १ तास आणि चहाचा वेळ १० मिनिटे आहे हे लक्षात घ्यावे, आणि प्रत्येकाने ते वेळेतच पूर्ण करावे.

१७) कोणता ही कामगार न सांगता घरी राहिल्यास त्यावर कडक कारवाई करण्यात येईल.

१८) कोणत्याही कामगारास काम सोडून जायचे असल्यास किमान ३० दिवस आधी अर्ज करावा, असे नाही केल्यास राहिलेलं पगार मिळणार नाही.

१९) कोणत्याही कर्मचार्‍याला अँडवांस पगार मिळणार नाही किंवा पगार झाल्यानंतर एकस्ट्रा पैसे मिळणार नाहीत.

२०) सेल्समन च्या परफॉर्मन्स वर त्याचे महत्व ठरविणे जाईल, असे न आढळल्यास त्याचा हिशोब कमी केला जाईल.

२१) प्रत्येक कामगाराला बँक अकाऊंट असणे बंधनकारक आहे.

२२) वरील सर्व नियम मला मान्य असून मी खाली स्वखुशीने सही करत आहे.
                                                  ''',
                                                  style:
                                                      TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Terms and Conditions',
                                  style: TextStyle(
                                    color: Color(0xFF073850),
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ScaleTransition(
                      scale: _buttonAnimation,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoading || !_agreedToTnC) ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF073850),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.grey.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF073850),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/no_internet.PNG',
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.4,
              ),
              const SizedBox(height: 24),
              const Text(
                "You're Offline",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF073850),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF073850),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.grey.withOpacity(0.4),
                ),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
