import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pcte_event_management/Api_Calls/api_calls.dart';
import 'package:pcte_event_management/Controllers/login_controller.dart';
import 'package:pcte_event_management/LocalStorage/Secure_Store.dart';
import 'package:pcte_event_management/Models/user_model.dart';
import 'package:pcte_event_management/Providers/login_provider.dart';
import 'package:pcte_event_management/Providers/pass_provider.dart';
import 'package:pcte_event_management/ui/bottomNavBar.dart';
import 'package:pcte_event_management/ui/forgot_email.dart';
import 'package:pcte_event_management/widgets/bottomNavBar.dart';
import 'package:pcte_event_management/widgets/dropdown.dart';
import 'package:provider/provider.dart';


import 'home.dart';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey();
  final FocusNode _focusNodePassword = FocusNode();
  final FocusNode _focusNodeUserName = FocusNode();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _bubbleAnimation;
  final storage = FlutterSecureStorage();
  final SecureStorage secureStorage = SecureStorage();
  final dropDownList = ['Admin','Teacher','Convenor'];


  @override
  void initState() {
    super.initState();
    _animationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);

    _bubbleAnimation = Tween<double>(begin: -20, end: 20)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bul, obj){
        
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      },

      child: Scaffold(
        body: Stack(
          children: [
            _buildGradientBackground(),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    _buildBubble(size, 60, Color.fromRGBO(255,0,0,0.3), -40, _bubbleAnimation.value),
                    _buildBubble(size, 90, Color.fromRGBO(255,0,0,0.2), size.width - 80, -_bubbleAnimation.value),
                    _buildBubble(size, 70,Color.fromRGBO(255,0,0,0.1), 30, size.height * 0.4 + _bubbleAnimation.value),
                    _buildBubble(size, 100,Color.fromRGBO(255,0,0,0.3), size.width - 100, size.height * 0.7 - _bubbleAnimation.value),
                  ],
                );
              },
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(size),
                  SizedBox(height: size.height * 0.05),
                  _buildLoginCard(size),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFA8072), Color(0xFFFFDAB9)], // Soft red-orange gradient
        ),
      ),
    );
  }

  Widget _buildBubble(Size size, double diameter, Color color, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: Color.fromRGBO(255,0,0,0.5), blurRadius: 10, spreadRadius: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: size.height * 0.15,
          child: Image.asset("assets/img/logo1.png"),
        ),
      ],
    );
  }

  Widget _buildLoginCard(Size size) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 3),
        ],
      ),

      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              "Welcome Back",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              "Login to your account",
              style: TextStyle(color: Colors.grey[700], fontSize: 14),

            ),

            SizedBox(height: size.height * 0.03),
            DropDown.showDropDown('Login as',Icon(Icons.person_add_alt),dropDownList,_focusNodeUserName),
            SizedBox(height: size.height * 0.02),
            _buildTextField((_){
              FocusScope.of(context).requestFocus(_focusNodePassword);
            },
                _focusNodeUserName,
                "Email",
                Icons.person_outline,
                _controllerEmail,
                TextInputType.name
            ),
            SizedBox(height: size.height * 0.02),
            Consumer<PassProvider>(
              builder: (context, passCheck, child) {
                return _buildTextField(
                  (value) async {

                    final apiCalls = ApiCalls();
                    final loginController = LoginController(apiCalls);
                    if (_formKey.currentState?.validate() ?? false) {
                      loginController.logInfo(
                          ctx: context,
                          email: _controllerEmail.text,
                          password: _controllerPassword.text
                      );
                      await apiCalls.loginCall(loginController.loginCred).then((value) async {
                        await secureStorage.saveData("jwtToken",apiCalls.tkn);
                        String? s = await secureStorage.getData("jwtToken");
                        log("Testing ::: $s");
                        if(value)
                        {

                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (value) => HomeScreen() ));
                        }
                      });


                    }

                  },
                  _focusNodePassword,
                  "Password",
                  Icons.lock_outline,
                  _controllerPassword,
                  TextInputType.visiblePassword,
                  obscureText: passCheck.obscurePass,
                  suffixIcon: IconButton(
                    icon: Icon(passCheck.obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => passCheck.passHider(),
                  ),
                );
              },
            ),
            TextButton(onPressed:()=> Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotEmail() )),
                child: Text("Forgot Password", style: TextStyle(color: Colors.blueAccent),)),

            SizedBox(height: size.height * 0.03),

            _buildLoginButton(size),

            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(Function(String)? onFinalSubmission, FocusNode focusNode, String label, IconData icon, TextEditingController controller, TextInputType type,
      {bool obscureText = false, Widget? suffixIcon}) {
    return TextFormField(
      onFieldSubmitted: onFinalSubmission,
      focusNode: focusNode,
      controller: controller,
      keyboardType: type,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black45),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? "Please enter $label." : null,
    );
  }

  Widget _buildLoginButton(Size size) {
    return Consumer<LoginProvider>(
      builder: (context,providur,child) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF9E2A2F),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 5,
          ),
          onPressed: () async {
            try {
              final apiCalls = ApiCalls();
              final loginController = LoginController(apiCalls);
              if (_formKey.currentState?.validate() ?? false) {
                providur.checkLoading();
                loginController.logInfo(
                    ctx: context,
                    email: _controllerEmail.text,
                    password: _controllerPassword.text
                );
                await apiCalls.loginCall(loginController.loginCred).then((value) async {


                  if(value)
                  {
                    await secureStorage.saveData("jwtToken",apiCalls.tkn);
                    String? s = await secureStorage.getData('jwtToken');
                    await apiCalls.getUserCall(s!);
                    providur.checkLoading();

                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavBar() ));
                  }
                  else
                  {
                    providur.checkLoading();
                    return ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                          content: Text(
                              'Wrong Credentials '
                          )
                      ),
                    );
                  }
                });


              }
            } on Exception catch (e) {
              log('Error in login function : ${e.toString()}');
            }
          },
          child: providur.isLoading
              ?
          Center(child: CircularProgressIndicator(strokeWidth: 3,),)
              :
          Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        );
      },

    );
  }



  @override
  void dispose() {
    _animationController.dispose();
    _focusNodePassword.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }
}
