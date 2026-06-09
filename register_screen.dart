import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  final _firstNameController =
  TextEditingController();

  final _lastNameController =
  TextEditingController();

  final _emailController =
  TextEditingController();

  final _phoneController =
  TextEditingController();

  final _passwordController =
  TextEditingController();

  String _selectedRole = 'Customer';

  bool _hidePassword = true;
  bool _isLoading = false;

  static const Color gradientStart =
  Color(0xFF81D4FA);

  static const Color gradientEnd =
  Color(0xFF0288D1);

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? result =
      await _authService.register(
        email: _emailController.text.trim(),
        password:
        _passwordController.text.trim(),
        firstName:
        _firstNameController.text.trim(),
        lastName:
        _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
      );

      setState(() => _isLoading = false);

      if (result == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Registration Successful",
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor:
            Colors.redAccent,
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
                colors: [
                  gradientStart,
                  gradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Positioned(
            top: -80,
            right: -40,
            child: _buildCircle(
              220,
              Colors.white.withOpacity(0.08),
            ),
          ),

          Positioned(
            bottom: -70,
            left: -30,
            child: _buildCircle(
              220,
              Colors.white.withOpacity(0.08),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
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
                        height: 95,
                        width: 95,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                          Icons.person_add_alt_1,
                          size: 70,
                          color: gradientEnd,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Card
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
                        const EdgeInsets.all(22),
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
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                    _buildInputField(
                                      controller:
                                      _firstNameController,
                                      label:
                                      "First Name",
                                      icon:
                                      Icons.person,
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 12),

                                  Expanded(
                                    child:
                                    _buildInputField(
                                      controller:
                                      _lastNameController,
                                      label:
                                      "Last Name",
                                      icon:
                                      Icons.person,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                  height: 16),

                              _buildInputField(
                                controller:
                                _emailController,
                                label: "Email",
                                icon:
                                Icons.email,
                              ),

                              const SizedBox(
                                  height: 16),

                              _buildInputField(
                                controller:
                                _phoneController,
                                label:
                                "Phone Number",
                                icon:
                                Icons.phone,
                              ),

                              const SizedBox(
                                  height: 16),

                              _buildInputField(
                                controller:
                                _passwordController,
                                label: "Password",
                                icon: Icons.lock,
                                isPassword: true,
                              ),

                              const SizedBox(
                                  height: 16),

                              Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 15,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(
                                      0.12),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      18),
                                ),
                                child:
                                DropdownButtonHideUnderline(
                                  child:
                                  DropdownButtonFormField<
                                      String>(
                                    value:
                                    _selectedRole,
                                    dropdownColor:
                                    gradientEnd,
                                    style:
                                    const TextStyle(
                                      color:
                                      Colors.white,
                                    ),
                                    decoration:
                                    const InputDecoration(
                                      border:
                                      InputBorder
                                          .none,
                                      labelText:
                                      "Register As",
                                      labelStyle:
                                      TextStyle(
                                        color: Colors
                                            .white70,
                                      ),
                                    ),
                                    items: [
                                      'Customer',
                                      'Rider'
                                    ]
                                        .map(
                                          (role) =>
                                          DropdownMenuItem(
                                            value:
                                            role,
                                            child:
                                            Text(
                                              role,
                                            ),
                                          ),
                                    )
                                        .toList(),
                                    onChanged:
                                        (value) {
                                      setState(() {
                                        _selectedRole =
                                        value!;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  height: 25),

                              _isLoading
                                  ? const CircularProgressIndicator(
                                color:
                                Colors
                                    .white,
                              )
                                  : SizedBox(
                                width:
                                double.infinity,
                                height: 55,
                                child:
                                ElevatedButton(
                                  onPressed:
                                  _register,
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
                                    "REGISTER",
                                    style:
                                    TextStyle(
                                      fontSize:
                                      17,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),
                                ),
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