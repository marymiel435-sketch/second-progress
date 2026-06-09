import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'customer_dashboard.dart';
import 'rider_dashboard.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _hidePassword = true;

  static const Color gradientStart = Color(0xFF81D4FA);
  static const Color gradientEnd = Color(0xFF0288D1);

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      if (_emailController.text == 'admin@vluerides.com' &&
          _passwordController.text == 'admin123') {
        setState(() => _isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboard(),
          ),
        );
        return;
      }

      try {
        String? result = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (result == null) {
          User? user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            final userData =
            await _authService.getUserData(user.uid);

            if (userData != null) {
              if (userData.role == 'Customer') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const CustomerDashboard(),
                  ),
                );
              } else if (userData.role == 'Rider') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const RiderDashboard(),
                  ),
                );
              }
            }
          }
        } else {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientStart,
                  gradientEnd,
                ],
              ),
            ),
          ),

          // Floating Effects
          Positioned(
            top: -80,
            left: -40,
            child: _buildCircle(
              220,
              Colors.white.withOpacity(0.08),
            ),
          ),

          Positioned(
            bottom: -70,
            right: -30,
            child: _buildCircle(
              220,
              Colors.white.withOpacity(0.08),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                          Icons.motorcycle_rounded,
                          size: 90,
                          color: gradientEnd,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "VLUE RIDES",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Fast • Safe • Reliable",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // Glass Card
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 15,
                        sigmaY: 15,
                      ),
                      child: Container(
                        padding:
                        const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.15),
                          borderRadius:
                          BorderRadius.circular(
                              30),
                          border: Border.all(
                            color: Colors.white
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildInputField(
                                controller:
                                _emailController,
                                label: "Email",
                                icon: Icons.email,
                              ),

                              const SizedBox(height: 20),

                              _buildInputField(
                                controller:
                                _passwordController,
                                label: "Password",
                                icon: Icons.lock,
                                isPassword: true,
                              ),

                              const SizedBox(height: 30),

                              _isLoading
                                  ? const CircularProgressIndicator(
                                color:
                                Colors.white,
                              )
                                  : SizedBox(
                                width:
                                double.infinity,
                                height: 58,
                                child:
                                ElevatedButton(
                                  onPressed:
                                  _login,
                                  style:
                                  ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                    Colors
                                        .white,
                                    foregroundColor:
                                    gradientEnd,
                                    elevation:
                                    10,
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          18),
                                    ),
                                  ),
                                  child:
                                  const Text(
                                    "SIGN IN",
                                    style:
                                    TextStyle(
                                      fontSize:
                                      18,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    style:
                                    TextStyle(
                                      color: Colors
                                          .white70,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Register",
                                      style:
                                      TextStyle(
                                        color: Colors
                                            .white,
                                        fontWeight:
                                        FontWeight
                                            .bold,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText:
      isPassword ? _hidePassword : false,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor:
        Colors.white.withOpacity(0.12),
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white70,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white,
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _hidePassword
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              _hidePassword =
              !_hidePassword;
            });
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(18),
          borderSide: BorderSide(
            color:
            Colors.white.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return "Required";
        }
        return null;
      },
    );
  }
}