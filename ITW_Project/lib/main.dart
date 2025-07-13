import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(const MyApp());

class User {
  final String uname, dname, email, pass, gender;
  final DateTime dob;
  User({required this.uname, required this.dname, required this.email,
    required this.pass, required this.gender, required this.dob});
}

class UserService {
  static final UserService _inst = UserService._internal();
  factory UserService() => _inst;
  UserService._internal();

  final Map<String, User> _byUname = {}, _byEmail = {};

  bool register(User u) {
    if (_byUname.containsKey(u.uname) || _byEmail.containsKey(u.email)) return false;
    _byUname[u.uname] = u;
    _byEmail[u.email] = u;
    return true;
  }

  bool login(String id, String pass) {
    User? u = _byUname[id] ?? _byEmail[id];
    return u != null && u.pass == pass;
  }

  bool unameExists(String uname) => _byUname.containsKey(uname);
  bool emailExists(String email) => _byEmail.containsKey(email);
  bool resetPass(String email) => _byEmail.containsKey(email);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      home: const AuthScreen());
}

class AuthScreen extends StatefulWidget {
  final bool initialLogin;
  const AuthScreen({super.key, this.initialLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late bool isLogin;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final UserService _userSvc = UserService();
  bool _showForgotPass = false;

  @override
  void initState() {
    super.initState();
    isLogin = widget.initialLogin;
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
      _showForgotPass = false;
    });
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _toggleForgotPass() => setState(() => _showForgotPass = !_showForgotPass);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildHeader(),
                const SizedBox(height: 30),
                _buildFormContainer(),
                if (!_showForgotPass) ...[
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: TextButton(
                      onPressed: _toggleAuthMode,
                      child: Text(
                        isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Sign In',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => FadeTransition(
    opacity: _fadeAnim,
    child: SlideTransition(
      position: _slideAnim,
      child: Column(
        children: [
          Text(
            isLogin ? 'Welcome Back!' : 'Create Account',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            isLogin ? 'Sign in to continue' : 'Sign up to get started',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    ),
  );

  Widget _buildFormContainer() => FadeTransition(
    opacity: _fadeAnim,
    child: SlideTransition(
      position: _slideAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: _showForgotPass
            ? ForgotPassForm(userSvc: _userSvc, onBack: _toggleForgotPass)
            : isLogin
            ? LoginForm(userSvc: _userSvc, onForgotPass: _toggleForgotPass)
            : SignupForm(userSvc: _userSvc, onSuccess: _toggleAuthMode),
      ),
    ),
  );
}

class AnimBtn extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool enabled;
  const AnimBtn({super.key, required this.text, required this.onTap, this.enabled = true});

  @override
  State<AnimBtn> createState() => _AnimBtnState();
}

class _AnimBtnState extends State<AnimBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.addStatusListener(_handleAnimStatus);
  }

  void _handleAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _ctrl.reset();
      if (_pressed) {
        widget.onTap();
        setState(() => _pressed = false);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _trigger() {
    if (widget.enabled) {
      setState(() => _pressed = true);
      _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Stack(
        children: [
          Container(decoration: BoxDecoration(
              color: widget.enabled ? const Color(0xFF6A11CB) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10)
          )),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => FractionallySizedBox(
              widthFactor: _anim.value,
              child: Container(decoration: BoxDecoration(
                  color: const Color(0xFF90EE90),
                  borderRadius: BorderRadius.circular(10)
              )),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled ? _trigger : null,
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Center(child: Text(
                  widget.text,
                  style: TextStyle(
                      color: widget.enabled ? Colors.white : Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  )
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final UserService userSvc;
  final VoidCallback onForgotPass;
  const LoginForm({super.key, required this.userSvc, required this.onForgotPass});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController(), _passCtrl = TextEditingController();
  bool _isHuman = false, _hidePass = true, _isValid = false;
  String? _error;

  void _validate() => setState(() {
    _isValid = _formKey.currentState?.validate() ?? false && _isHuman;
    _error = null;
  });

  void _login() {
    if (_formKey.currentState!.validate() && _isHuman) {
      if (widget.userSvc.login(_idCtrl.text.trim(), _passCtrl.text)) {
        _idCtrl.clear();
        _passCtrl.clear();
        setState(() => _isHuman = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!'), backgroundColor: Colors.green)
        );
      } else {
        setState(() => _error = 'Invalid credentials');
      }
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(IconData icon, String hint, {Widget? suffix}) => InputDecoration(
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    filled: true,
    fillColor: const Color(0xFFF3F4F6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: _validate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Username or Email', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _idCtrl,
            decoration: _inputDeco(Icons.person_outline, 'Enter username or email'),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          const Text('Password', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _hidePass,
            decoration: _inputDeco(Icons.lock_outline, 'Enter password',
                suffix: IconButton(
                    icon: Icon(_hidePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hidePass = !_hidePass)
                )),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPass,
              child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF6A11CB), fontSize: 14)),
            ),
          ),
          Row(children: [
            Checkbox(
                value: _isHuman,
                onChanged: (v) => setState(() { _isHuman = v ?? false; _validate(); }),
                activeColor: const Color(0xFF6A11CB)
            ),
            const Text('I am human', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14)),
          ]),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
          const SizedBox(height: 20),
          AnimBtn(text: 'LOGIN', onTap: _login, enabled: _isValid),
        ],
      ),
    );
  }
}

class SignupForm extends StatefulWidget {
  final UserService userSvc;
  final VoidCallback onSuccess;
  const SignupForm({super.key, required this.userSvc, required this.onSuccess});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _unameCtrl = TextEditingController(), _dnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(), _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  DateTime? _dob;
  String? _gender;
  bool _isHuman = false, _hidePass = true, _hideConfirm = true, _isValid = false;
  String? _error;
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  void _validate() => setState(() {
    _isValid = _formKey.currentState?.validate() ?? false &&
        _isHuman && _dob != null && _gender != null;
    _error = null;
  });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
        _validate();
      });
    }
  }

  void _signup() {
    if (_formKey.currentState!.validate() && _dob != null && _gender != null && _isHuman) {
      final uname = _unameCtrl.text.trim();
      final email = _emailCtrl.text.trim();

      if (widget.userSvc.unameExists(uname)) {
        setState(() => _error = 'Username exists');
        return;
      }
      if (widget.userSvc.emailExists(email)) {
        setState(() => _error = 'Email exists');
        return;
      }

      final user = User(
        uname: uname,
        dname: _dnameCtrl.text.trim(),
        email: email,
        pass: _passCtrl.text,
        gender: _gender!,
        dob: _dob!,
      );

      if (widget.userSvc.register(user)) {
        _unameCtrl.clear(); _dnameCtrl.clear(); _emailCtrl.clear();
        _passCtrl.clear(); _confirmPassCtrl.clear();
        setState(() {
          _dob = null;
          _gender = null;
          _isHuman = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created!'), backgroundColor: Colors.green)
        );
        widget.onSuccess();
      } else {
        setState(() => _error = 'Failed to create account');
      }
    }
  }


  @override
  void dispose() {
    _unameCtrl.dispose(); _dnameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmPassCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(IconData icon, String hint, {Widget? suffix}) => InputDecoration(
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    filled: true,
    fillColor: const Color(0xFFF3F4F6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, String hint,
      {bool isPass = false, bool isEmail = false, bool isConfirm = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: isPass ? (isConfirm ? _hideConfirm : _hidePass) : false,
          keyboardType: isEmail ? TextInputType.emailAddress : null,
          decoration: _inputDeco(icon, hint,
            suffix: isPass ? IconButton(
              icon: Icon(isConfirm
                  ? (_hideConfirm ? Icons.visibility_off : Icons.visibility)
                  : (_hidePass ? Icons.visibility_off : Icons.visibility)),
              onPressed: () => setState(() =>
              isConfirm ? _hideConfirm = !_hideConfirm : _hidePass = !_hidePass),
            ) : null,
          ),
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!))
              return 'Invalid email';
            if (isPass && v!.length < 6) return 'Min 6 chars';
            if (isConfirm && v != _passCtrl.text) return 'Mismatch';
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: _validate,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('Username', _unameCtrl, Icons.person_outline, 'Choose username'),
            _buildField('Display Name', _dnameCtrl, Icons.badge_outlined, 'Enter display name'),
            _buildField('Email', _emailCtrl, Icons.email_outlined, 'Enter email', isEmail: true),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gender', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _gender,
                          hint: const Text('Select'),
                          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() { _gender = v; _validate(); }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date of Birth', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dob == null ? 'Select' : DateFormat('dd/MM/yyyy').format(_dob!),
                              style: TextStyle(color: _dob == null ? Colors.grey.shade600 : Colors.black),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildField('Create Password', _passCtrl, Icons.lock_outline, 'Create password', isPass: true),
            _buildField('Confirm Password', _confirmPassCtrl, Icons.lock_outline, 'Confirm password', isPass: true, isConfirm: true),
            Row(children: [
              Checkbox(value: _isHuman, onChanged: (v) => setState(() { _isHuman = v ?? false; _validate(); }), activeColor: const Color(0xFF6A11CB)),
              Expanded(child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 14),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(text: 'Terms of Service', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500)),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
            ]),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
            const SizedBox(height: 20),
            AnimBtn(text: 'SIGN UP', onTap: _signup, enabled: _isValid),
          ],
        ),
      ),
    );
  }
}

class ForgotPassForm extends StatefulWidget {
  final UserService userSvc;
  final VoidCallback onBack;
  const ForgotPassForm({super.key, required this.userSvc, required this.onBack});

  @override
  State<ForgotPassForm> createState() => _ForgotPassFormState();
}

class _ForgotPassFormState extends State<ForgotPassForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isValid = false;
  String? _msg;
  bool _success = false;

  void _validate() => setState(() {
    _isValid = _formKey.currentState?.validate() ?? false;
    _msg = null;
  });

  void _reset() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _success = widget.userSvc.resetPass(_emailCtrl.text.trim());
        _msg = _success ? 'Reset link sent' : 'Email not found';
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: _validate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reset Password', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Enter your email address below. We\'ll send you a link to reset your password.', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14)),
          const SizedBox(height: 24),
          const Text('Email', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined),
              hintText: 'Enter email',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!)) return 'Invalid email';
              return null;
            },
          ),
          if (_msg != null) Text(_msg!, style: TextStyle(color: _success ? Colors.green : Colors.red, fontSize: 14)),
          const SizedBox(height: 20),
          AnimBtn(text: 'RESET', onTap: _reset, enabled: _isValid),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: widget.onBack,
              child: const Text('Back to Login', style: TextStyle(color: Color(0xFF6A11CB), fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}