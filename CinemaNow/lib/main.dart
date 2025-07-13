import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

void main() => runApp(const MyApp());

// --- User Authentication Models ---
class User {
  final String uname, dname, email, pass, gender;
  final DateTime dob;
  final List<Booking> bookings;

  User({required this.uname, required this.dname, required this.email, required this.pass,
    required this.gender, required this.dob, this.bookings = const []});
}

class UserService {
  static final UserService _inst = UserService._internal();
  factory UserService() => _inst;
  UserService._internal();

  final Map<String, User> _byUname = {}, _byEmail = {};
  User? _currentUser;

  bool register(User u) {
    if (_byUname.containsKey(u.uname) || _byEmail.containsKey(u.email)) return false;

    // Add sample bookings for testing
    final movieService = MovieService();
    final theaterService = TheaterService();
    final movies = movieService.getNowPlayingMovies();
    final theaters = theaterService.getTheaters();

    final sampleBookings = [
      Booking(
        id: 'b1', movie: movies[0], theater: theaters[0],
        showtime: theaters[0].screens[0].showtimes[0], seats: ['A1', 'A2'],
        totalPrice: 398.0, bookingTime: DateTime.now(),
        paymentMethod: PaymentMethod.creditCard,
      ),
      Booking(
        id: 'b2', movie: movies[1], theater: theaters[1],
        showtime: theaters[1].screens[1].showtimes[1], seats: ['B3', 'B4'],
        totalPrice: 498.0, bookingTime: DateTime.now().subtract(const Duration(days: 2)),
        paymentMethod: PaymentMethod.upi,
      ),
    ];

    final userWithBookings = User(
      uname: u.uname, dname: u.dname, email: u.email, pass: u.pass,
      gender: u.gender, dob: u.dob, bookings: sampleBookings,
    );

    _byUname[u.uname] = userWithBookings;
    _byEmail[u.email] = userWithBookings;
    return true;
  }

  bool login(String id, String pass) {
    User? u = _byUname[id] ?? _byEmail[id];
    if (u != null && u.pass == pass) {
      _currentUser = u;
      return true;
    }
    return false;
  }

  User? get currentUser => _currentUser;
  void logout() => _currentUser = null;
  bool unameExists(String uname) => _byUname.containsKey(uname);
  bool emailExists(String email) => _byEmail.containsKey(email);
  bool resetPass(String email) => _byEmail.containsKey(email);
  List<Booking> get userBookings => _currentUser?.bookings ?? [];

  void addBooking({required String id, required Movie movie, required Theater theater,
    required Showtime showtime, required List<String> seats, required double totalPrice,
    required PaymentMethod paymentMethod}) {
    if (_currentUser != null) {
      final booking = Booking(
        id: id, movie: movie, theater: theater, showtime: showtime,
        seats: seats, totalPrice: totalPrice, bookingTime: DateTime.now(),
        paymentMethod: paymentMethod,
      );

      final updatedBookings = List<Booking>.from(_currentUser!.bookings)..add(booking);
      _updateCurrentUser(bookings: updatedBookings);
    }
  }

  void _updateCurrentUser({List<Booking>? bookings}) {
    if (_currentUser != null) {
      _currentUser = User(
        uname: _currentUser!.uname, dname: _currentUser!.dname, email: _currentUser!.email,
        pass: _currentUser!.pass, gender: _currentUser!.gender, dob: _currentUser!.dob,
        bookings: bookings ?? _currentUser!.bookings,
      );
      _byUname[_currentUser!.uname] = _currentUser!;
      _byEmail[_currentUser!.email] = _currentUser!;
    }
  }
}

// --- Movie Models ---
class Movie {
  final String id, title, posterUrl, backdropUrl, description, director;
  final List<String> genres, cast;
  final int duration;
  final double rating;
  final bool isNowPlaying;
  final DateTime releaseDate;

  Movie({required this.id, required this.title, required this.posterUrl,
    required this.backdropUrl, required this.genres, required this.description,
    required this.duration, required this.rating, required this.isNowPlaying,
    required this.releaseDate, required this.director, required this.cast});
}

class Theater {
  final String id, name, location;
  final List<Screen> screens;
  final double ticketPrice;

  Theater({required this.id, required this.name, required this.location,
    required this.screens, this.ticketPrice = 199.0});

  List<Showtime> getShowtimes(DateTime date, String movieId) {
    return screens
        .expand((screen) => screen.showtimes)
        .where((showtime) => showtime.movie.id == movieId &&
        showtime.time.year == date.year &&
        showtime.time.month == date.month &&
        showtime.time.day == date.day)
        .toList();
  }
}

class Screen {
  final String id, name;
  final int rows, seatsPerRow;
  final List<Showtime> showtimes;

  Screen({required this.id, required this.name, required this.rows,
    required this.seatsPerRow, required this.showtimes});
}

class Showtime {
  final String id;
  final Movie movie;
  final DateTime time;
  final List<List<SeatStatus>> seats;
  final Map<String, double> seatPrices;

  Showtime({required this.id, required this.movie, required this.time,
    required this.seats, required this.seatPrices});

  List<String> get availableSeatTypes => seatPrices.keys.toList();
  String format(BuildContext context) => TimeOfDay.fromDateTime(time).format(context);
}

enum SeatStatus { available, reserved, selected, booked }

class Booking {
  final String id;
  final Movie movie;
  final Theater theater;
  final Showtime showtime;
  final List<String> seats;
  final double totalPrice;
  final DateTime bookingTime;
  final PaymentMethod paymentMethod;

  Booking({required this.id, required this.movie, required this.theater,
    required this.showtime, required this.seats, required this.totalPrice,
    required this.bookingTime, required this.paymentMethod});
}

enum PaymentMethod {
  upi, creditCard, googlePay, phonePe, paytm, netBanking, paypal,
}

// --- App UI Components ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CinemaNow',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.indigo,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: Colors.grey[50],
      brightness: Brightness.light,
    ),
    darkTheme: ThemeData(
      primarySwatch: Colors.indigo,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
    ),
    themeMode: ThemeMode.system,
    home: const AuthScreen(),
  );
}

// --- Logo Widget ---
class CinemaNowLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const CinemaNowLogo({super.key, this.size = 80, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoColor = color ?? theme.primaryColor;

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: logoColor,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(
          color: logoColor.withOpacity(0.5),
          blurRadius: 10, spreadRadius: 2,
        )],
      ),
      child: Center(
        child: Icon(Icons.movie_outlined, size: size * 0.6, color: Colors.white),
      ),
    );
  }
}

// --- Authentication Screens ---
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
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
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
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
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
                        style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500,
                        ),
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
          const CinemaNowLogo(size: 100),
          const SizedBox(height: 16),
          Text('CinemaNow', style: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2,
          )),
          const SizedBox(height: 10),
          Text(isLogin ? 'Welcome Back!' : 'Create Account', style: const TextStyle(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 10),
          Text(isLogin ? 'Sign in to continue' : 'Sign up to get started',
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20, offset: const Offset(0, 10),
          )],
        ),
        child: _showForgotPass
            ? ForgotPassForm(userSvc: _userSvc, onBack: _toggleForgotPass)
            : isLogin
            ? LoginForm(
          userSvc: _userSvc,
          onForgotPass: _toggleForgotPass,
          onSuccess: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          ),
        )
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
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      width: double.infinity, height: 50,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.enabled ? const Color(0xFF6A11CB) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => FractionallySizedBox(
              widthFactor: _anim.value,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF90EE90),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled ? _trigger : null,
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Center(
                child: Text(widget.text, style: TextStyle(
                  color: widget.enabled ? Colors.white : Colors.grey.shade500,
                  fontSize: 16, fontWeight: FontWeight.bold,
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



//rammmmmm
class LoginForm extends StatefulWidget {
  final UserService userSvc;
  final VoidCallback onForgotPass, onSuccess;
  const LoginForm({
    super.key,
    required this.userSvc,
    required this.onForgotPass,
    required this.onSuccess,
  });

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
    if (!(_formKey.currentState?.validate() ?? false) || !_isHuman) return;

    if (widget.userSvc.login(_idCtrl.text.trim(), _passCtrl.text)) {
      _idCtrl.clear();
      _passCtrl.clear();
      setState(() => _isHuman = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!'), backgroundColor: Colors.green),
      );
      widget.onSuccess();
    } else {
      setState(() => _error = 'Invalid credentials');
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
                onPressed: () => setState(() => _hidePass = !_hidePass),
              ),
            ),
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
              activeColor: const Color(0xFF6A11CB),
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
    _isValid = (_formKey.currentState?.validate() ?? false) && _isHuman && _dob != null && _gender != null;
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
      setState(() { _dob = picked; _validate(); });
    }
  }

  void _signup() {
    if (!(_formKey.currentState?.validate() ?? false) || _dob == null || _gender == null || !_isHuman) return;

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
      _unameCtrl.clear();
      _dnameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
      _confirmPassCtrl.clear();
      setState(() {
        _dob = null;
        _gender = null;
        _isHuman = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created!'), backgroundColor: Colors.green),
      );
      widget.onSuccess();
    } else {
      setState(() => _error = 'Failed to create account');
    }
  }

  @override
  void dispose() {
    _unameCtrl.dispose();
    _dnameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
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
              icon: Icon(isConfirm ? (_hideConfirm ? Icons.visibility_off : Icons.visibility) :
              (_hidePass ? Icons.visibility_off : Icons.visibility)),
              onPressed: () => setState(() => isConfirm ? _hideConfirm = !_hideConfirm : _hidePass = !_hidePass),
            ) : null,
          ),
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!)) return 'Invalid email';
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
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
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
              )),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date of Birth', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          _dob == null ? 'Select' : DateFormat('dd/MM/yyyy').format(_dob!),
                          style: TextStyle(color: _dob == null ? Colors.grey.shade600 : Colors.black),
                        )),
                      ]),
                    ),
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 16),
            _buildField('Create Password', _passCtrl, Icons.lock_outline, 'Create password', isPass: true),
            _buildField('Confirm Password', _confirmPassCtrl, Icons.lock_outline, 'Confirm password', isPass: true, isConfirm: true),
            Row(children: [
              Checkbox(
                value: _isHuman,
                onChanged: (v) => setState(() { _isHuman = v ?? false; _validate(); }),
                activeColor: const Color(0xFF6A11CB),
              ),
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
  bool _isValid = false, _success = false;
  String? _msg;

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
          const Text('Enter your email address below. We\'ll send you a link to reset your password.',
              style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14)),
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

class MovieService {
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;
  MovieService._internal();

  final List<Movie> _movies = [
    Movie(
      id: 'm1',
      title: 'Avengers: Endgame',
      posterUrl:
      'https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
      backdropUrl:
      'https://image.tmdb.org/t/p/original/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg',
      genres: ['Action', 'Adventure', 'Sci-Fi'],
      description:
      'After Thanos wiped out half of all life in the universe, the Avengers must do whatever it takes to undo the devastation.',
      duration: 181,
      rating: 8.4,
      isNowPlaying: true,
      releaseDate: DateTime(2025, 3, 26),
      director: 'Anthony Russo, Joe Russo',
      cast: [
        'Robert Downey Jr.',
        'Chris Evans',
        'Mark Ruffalo',
        'Chris Hemsworth',
        'Scarlett Johansson',
      ],
    ),
    Movie(
      id: 'm2',
      title: 'Dune',
      posterUrl:
      'https://m.media-amazon.com/images/M/MV5BN2FjNmEyNWMtYzM0ZS00NjIyLTg5YzYtYThlMGVjNzE1OGViXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
      backdropUrl:
      'https://m.media-amazon.com/images/M/MV5BN2FjNmEyNWMtYzM0ZS00NjIyLTg5YzYtYThlMGVjNzE1OGViXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
      genres: ['Sci-Fi', 'Adventure', 'Drama'],
      description:
      'Feature adaptation of Frank Herbert\'s science fiction novel about the son of a noble family entrusted with the protection of the most valuable asset in the galaxy.',
      duration: 155,
      rating: 8.0,
      isNowPlaying: true,
      releaseDate: DateTime(2025, 4, 2),
      director: 'Denis Villeneuve',
      cast: [
        'Timothée Chalamet',
        'Rebecca Ferguson',
        'Oscar Isaac',
        'Josh Brolin',
        'Zendaya',
      ],
    ),
    Movie(
      id: 'm3',
      title: 'RRR',
      posterUrl:
      'https://m.media-amazon.com/images/M/MV5BODUwNDNjYzctODUxNy00ZTA2LWIyYTEtMDc5Y2E5ZjBmNTMzXkEyXkFqcGdeQXVyODE5NzE3OTE@._V1_.jpg',
      backdropUrl:
      'https://m.media-amazon.com/images/M/MV5BODUwNDNjYzctODUxNy00ZTA2LWIyYTEtMDc5Y2E5ZjBmNTMzXkEyXkFqcGdeQXVyODE5NzE3OTE@._V1_.jpg',
      genres: ['Action', 'Drama', 'History'],
      description:
      'A tale of two legendary revolutionaries and their journey far away from home.',
      duration: 187,
      rating: 7.8,
      isNowPlaying: true,
      releaseDate: DateTime(2025, 4, 3),
      director: 'S.S. Rajamouli',
      cast: [
        'N.T. Rama Rao Jr.',
        'Ram Charan',
        'Ajay Devgn',
        'Alia Bhatt',
        'Olivia Morris',
      ],
    ),
    Movie(
      id: 'm4',
      title: 'Mission: Impossible - Dead Reckoning',
      posterUrl:
      'https://m.media-amazon.com/images/M/MV5BYzFiZjc1YzctMDY3Zi00NGE5LTlmNWEtN2Q3OWFjYjY1NGM2XkEyXkFqcGdeQXVyMTUyMTUzNjQ0._V1_.jpg',
      backdropUrl:
      'https://m.media-amazon.com/images/M/MV5BYzFiZjc1YzctMDY3Zi00NGE5LTlmNWEtN2Q3OWFjYjY1NGM2XkEyXkFqcGdeQXVyMTUyMTUzNjQ0._V1_.jpg',
      genres: ['Action', 'Adventure', 'Thriller'],
      description:
      'Ethan Hunt and his IMF team must track down a dangerous weapon before it falls into the wrong hands.',
      duration: 163,
      rating: 0,
      isNowPlaying: false,
      releaseDate: DateTime(2025, 5, 5),
      director: 'Christopher McQuarrie',
      cast: [
        'Tom Cruise',
        'Hayley Atwell',
        'Ving Rhames',
        'Simon Pegg',
        'Rebecca Ferguson',
      ],
    ),
    Movie(
      id: 'm5',
      title: 'The Batman',
      posterUrl:
      'https://m.media-amazon.com/images/M/MV5BMDdmMTBiNTYtMDIzNi00NGVlLWIzMDYtZTk3MTQ3NGQxZGEwXkEyXkFqcGdeQXVyMzMwOTU5MDk@._V1_.jpg',
      backdropUrl:
      'https://m.media-amazon.com/images/M/MV5BMDdmMTBiNTYtMDIzNi00NGVlLWIzMDYtZTk3MTQ3NGQxZGEwXkEyXkFqcGdeQXVyMzMwOTU5MDk@._V1_.jpg',
      genres: ['Action', 'Crime', 'Drama'],
      description:
      'When the Riddler, a sadistic serial killer, begins murdering key political figures in Gotham, Batman is forced to investigate the city\'s hidden corruption.',
      duration: 176,
      rating: 7.9,
      isNowPlaying: true,
      releaseDate: DateTime(2025, 4, 14),
      director: 'Matt Reeves',
      cast: [
        'Robert Pattinson',
        'Zoë Kravitz',
        'Jeffrey Wright',
        'Colin Farrell',
        'Paul Dano',
      ],
    ),
    Movie(
      id: 'm6',
      title: 'Oppenheimer',
      posterUrl:
      'https://m.media-amazon.com/images/M/MV5BMDBmYTZjNjUtN2M1MS00MTQ2LTk2ODgtNzc2M2QyZGE5NTVjXkEyXkFqcGdeQXVyNzAwMjU2MTY@._V1_.jpg',
      backdropUrl:
      'https://m.media-amazon.com/images/M/MV5BMDBmYTZjNjUtN2M1MS00MTQ2LTk2ODgtNzc2M2QyZGE5NTVjXkEyXkFqcGdeQXVyNzAwMjU2MTY@._V1_.jpg',
      genres: ['Biography', 'Drama', 'History'],
      description:
      'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb.',
      duration: 180,
      rating: 0,
      isNowPlaying: false,
      releaseDate: DateTime(2025, 5, 15),
      director: 'Christopher Nolan',
      cast: [
        'Cillian Murphy',
        'Emily Blunt',
        'Matt Damon',
        'Robert Downey Jr.',
        'Florence Pugh',
      ],
    ),
    Movie(
      id: 'm7',
      title: 'Avengers: Doomsday',
      posterUrl:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDHeFI_Ws8Q8dk-eeTmQ8LCGHv9wx8YY_R5g&s',
      backdropUrl:
      'https://preview.redd.it/i-made-an-avengers-doomsday-fan-made-poster-v0-kjrrjtx9xdie1.png?width=640&crop=smart&auto=webp&s=d9a453038aad95c210b1b82ba2b8a77ac2569291',
      genres: ['Action', 'Adventure', 'Sci-Fi'],
      description:
      'The Avengers face their greatest challenge yet as they battle against an apocalyptic threat that could end all existence.',
      duration: 0,
      rating: 0.0,
      isNowPlaying: false,
      releaseDate: DateTime(2025, 5, 12),
      director: 'Destin Daniel Cretton',
      cast: [
        'Brie Larson',
        'Teyonah Parris',
        'Iman Vellani',
        'Samuel L. Jackson',
      ],
    ),
    Movie(
      id: 'm8',
      title: 'Jab Tak Hai Jaan',
      posterUrl:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQZk6VpIwbHNGVH0TPYsLOa4MQp2BgvWmkCDw&s',
      backdropUrl:
      'https://www.yashrajfilms.com/images/default-source/Movies/Jab-Tak-Hai-Jaan/Jab-Tak-Hai-Jaan-Gallery/shahrukh-khan-and-katrina-kaif-in-jab-tak-hai-jaan28789ca026f56f7f9f64ff0000090313.jpg?sfvrsn=f18df3cc_2',
      genres: ['Romance', 'Drama', 'Musical'],
      description:
      'A passionate love story spanning a decade, following an army officer torn between his past love and a new relationship, with fateful consequences.',
      duration: 176,
      rating: 7.3,
      isNowPlaying: true,
      releaseDate: DateTime(2025, 4, 15),
      director: 'Yash Chopra',
      cast: ['Shah Rukh Khan', 'Katrina Kaif', 'Anushka Sharma', 'Anupam Kher'],
    ),
    Movie(
      id: 'm9',
      title: 'Top Gun: Maverick',
      posterUrl:
      'https://m.media-amazon.com/images/M/MV5BZWYzOGEwNTgtNWU3NS00ZTQ0LWJkODUtMmVhMjIwMjA1ZmQwXkEyXkFqcGdeQXVyMjkwOTAyMDU@._V1_.jpg',
      backdropUrl:
      'https://c7.alamy.com/comp/2GB3T33/top-gun-maverick-2021-paramount-pictures-film-with-tom-cruise-2GB3T33.jpg',
      genres: ['Action', 'Drama'],
      description:
      'After more than thirty years of service as one of the Navy\'s top aviators, Pete "Maverick" Mitchell is where he belongs, pushing the envelope as a courageous test pilot and dodging the advancement in rank that would ground him.',
      duration: 131,
      rating: 8.3,
      isNowPlaying: true,
      releaseDate: DateTime(2025, 4, 19),
      director: 'Joseph Kosinski',
      cast: [
        'Tom Cruise',
        'Miles Teller',
        'Jennifer Connelly',
        'Jon Hamm',
        'Val Kilmer',
      ],
    ),
    Movie(
      id: 'm10',
      title: '3 Idiots',
      posterUrl:
      'https://i.scdn.co/image/ab67616d0000b273593dd16691c117c716e210ae',
      backdropUrl:
      'https://akm-img-a-in.tosshub.com/indiatoday/images/story/202407/a-still-from-3-idiots-124609938-16x9_0.jpg?VersionId=U5ASEhmqaJAmN7lRe3.gWe0AIZTnOpXu&size=690:388',
      genres: ['Comedy', 'Drama'],
      description:
      'Two friends embark on a quest to find their long-lost college companion, whose unconventional wisdom and unique outlook on life inspired them to think differently.',
      duration: 170,
      rating: 8.4,
      isNowPlaying: true, // Released in 2009
      releaseDate: DateTime(2025, 4, 21),
      director: 'Rajkumar Hirani',
      cast: [
        'Aamir Khan',
        'R. Madhavan',
        'Sharman Joshi',
        'Kareena Kapoor',
        'Boman Irani',
      ],
    ),
    Movie(
      id: 'm11',
      title: 'Fast X',
      posterUrl:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRNhPnC5GXoCwNQOUSWXoJQw4LDs5AN1hJ-dg&s',
      backdropUrl:
      'https://comicyears.com/wp-content/uploads/2023/02/intro-1584392169.jpg',
      genres: ['Action', 'Adventure', 'Crime'],
      description:
      'Dom Toretto and his family are targeted by the vengeful son of drug kingpin Hernan Reyes, forcing them to confront their most dangerous opponent yet in a high-stakes battle across the globe.',
      duration: 141,
      rating: 6.0,
      isNowPlaying: true,
      releaseDate: DateTime(2025, 4, 23),
      director: 'Louis Leterrier',
      cast: [
        'Vin Diesel',
        'Jason Momoa',
        'Michelle Rodriguez',
        'Charlize Theron',
        'John Cena',
        'Jordana Brewster',
      ],
    ),
    Movie(
      id: 'm12',
      title: 'Ek Tha Tiger',
      posterUrl:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR0uFRDYb-BnH3i1C655eqxCgTmXBchHB9UTg&s',
      backdropUrl:
      'https://www.yashrajfilms.com/images/default-source/Movies/Ek-Tha-Tiger/Ek-Tha-Tiger-Gallery/salman-khan-and-katrina-kaif-in-ek-tha-tigerf8829ca026f56f7f9f64ff0000090313.jpg?sfvrsn=2177f3cc_2',
      genres: ['Action', 'Romance', 'Thriller'],
      description:
      'An Indian spy falls in love with a Pakistani spy during an investigation in Dublin.',
      duration: 133,
      rating: 7.1,
      isNowPlaying: true,
      releaseDate: DateTime(2025, 4, 22),
      director: 'Kabir Khan',
      cast: ['Salman Khan', 'Katrina Kaif', 'Girish Karnad', 'Ranvir Shorey'],
    ),
    Movie(
      id: 'm13',
      title: 'Taare Zameen Par',
      posterUrl: 'https://wallpapercave.com/wp/wp7874481.jpg',
      backdropUrl: 'https://wallpapercave.com/wp/wp7874522.jpg',
      genres: ['Drama', 'Family'],
      description:
      'An eight-year-old boy is thought to be a lazy trouble-maker until a new art teacher discovers the real problem behind his struggles in school.',
      duration: 165,
      rating: 8.4,
      isNowPlaying: true,
      releaseDate: DateTime(2025, 3, 29),
      director: 'Aamir Khan',
      cast: ['Darsheel Safary', 'Aamir Khan', 'Tisca Chopra', 'Vipin Sharma'],
    ),
    Movie(
      id: 'm15',
      title: 'Mission Mangal',
      posterUrl:
      'https://assets-in.bmscdn.com/iedb/movies/images/mobile/thumbnail/xlarge/mission-mangal-et00089473-16-10-2020-03-16-03.jpg',
      backdropUrl:
      'https://sm.mashable.com/mashable_in/seo/5/5796/5796_j4xt.jpg',
      genres: ['Drama', 'History', 'Sci-Fi'],
      description:
      'Based on the true story of the scientists at ISRO who contributed to India\'s first interplanetary mission, Mars Orbiter Mission.',
      duration: 0,
      rating: 0.0,
      isNowPlaying: false,
      releaseDate: DateTime(2025, 5, 21),
      director: 'Jagan Shakti',
      cast: ['Akshay Kumar', 'Vidya Balan', 'Taapsee Pannu', 'Sonakshi Sinha'],
    ),
  ];

  List<Movie> getNowPlayingMovies() => _movies.where((m) => m.isNowPlaying).toList();
  List<Movie> getComingSoonMovies() => _movies.where((m) => !m.isNowPlaying).toList();
  Movie? getMovieById(String id) => _movies.firstWhere((m) => m.id == id);
}

class TheaterService {
  static final TheaterService _instance = TheaterService._internal();
  factory TheaterService() => _instance;
  TheaterService._internal();

  final MovieService _movieService = MovieService();
  final Random _random = Random();

  List<Theater> getTheaters() => [
    _generateTheater('t1', 'CineMax Multiplex', 'Downtown Metro Center'),
    _generateTheater('t2', 'PVR Cinemas', 'East End Mall'),
    _generateTheater('t3', 'INOX Movies', 'West Plaza'),
    _generateTheater('t4', 'Grand Cinemas', 'South Gate Mall'),
  ];

  Theater getTheaterById(String id) => getTheaters().firstWhere((t) => t.id == id,
      orElse: () => throw Exception('Theater not found for ID: $id'));

  Theater _generateTheater(String id, String name, String location) => Theater(
    id: id,
    name: name,
    location: location,
    screens: List.generate(3, (i) => _generateScreen(id, i + 1)),
  );

  Screen _generateScreen(String theaterId, int screenNumber) => Screen(
    id: '$theaterId-s$screenNumber',
    name: 'Screen $screenNumber',
    rows: 8,
    seatsPerRow: 10,
    showtimes: _generateShowtimes('$theaterId-s$screenNumber', 3),
  );

  List<Showtime> _generateShowtimes(String screenId, int count) {
    final now = DateTime.now();
    final movies = _movieService.getNowPlayingMovies();
    final List<Showtime> showtimes = [];

    for (int i = 0; i < count; i++) {
      for (int d = 0; d < 3; d++) {
        final movie = movies[_random.nextInt(movies.length)];
        final time = DateTime(now.year, now.month, now.day + d, 10 + (i * 3) + _random.nextInt(2), _random.nextBool() ? 0 : 30);

        showtimes.add(Showtime(
          id: '$screenId-st-${i + 1}-$d',
          movie: movie,
          time: time,
          seats: _generateSeats(8, 10),
          seatPrices: {
            'Regular': (150.0 + _random.nextDouble() * 50).roundToDouble(),
            'Premium': (250.0 + _random.nextDouble() * 50).roundToDouble(),
            'Recliner': (350.0 + _random.nextDouble() * 100).roundToDouble(),
          },
        ));
      }
    }
    return showtimes;
  }

  List<List<SeatStatus>> _generateSeats(int rows, int cols) {
    final seats = List.generate(rows, (_) => List.filled(cols, SeatStatus.available));
    final numBookedSeats = _random.nextInt((rows * cols) ~/ 4);

    for (int i = 0; i < numBookedSeats; i++) {
      final r = _random.nextInt(rows);
      final c = _random.nextInt(cols);
      seats[r][c] = SeatStatus.booked;
    }
    return seats;
  }

  String getSeatType(int row, int screenId) => row < 2 ? 'Regular' : row < 6 ? 'Premium' : 'Recliner';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MovieService _movieService = MovieService();
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _currentIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true, pinned: true, expandedHeight: 140.0, elevation: 4,
              forceElevated: innerBoxIsScrolled,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(bottom: 54, left: 20),
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: innerBoxIsScrolled ? 1.0 : 0.8,
                  child: Text('CinemaNow', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22,
                    fontFamily: 'Montserrat', letterSpacing: 0.5,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black.withOpacity(0.6), offset: const Offset(1, 1))],
                  )),
                ),
                background: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.5), Colors.transparent],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
                  blendMode: BlendMode.darken,
                  child: Hero(
                    tag: 'app_header',
                    child: Image.network(
                      'https://source.unsplash.com/random/800x600/?cinema',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white, indicatorWeight: 3,
                labelColor: Colors.white, unselectedLabelColor: Colors.white.withOpacity(0.7),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                tabs: const [Tab(text: 'Now Playing'), Tab(text: 'Coming Soon')],
              ),
            ),
          ],
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMovieList(_movieService.getNowPlayingMovies()),
                _buildMovieList(_movieService.getComingSoonMovies()),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < 2 ? 0 : _currentIndex - 1,
        onTap: (index) => _handleNavTap(index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 10, unselectedFontSize: 10,
        backgroundColor: Theme.of(context).cardColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 20), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 20), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number, size: 20), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 20), label: 'Profile'),
        ],
      ),
    );
  }

  void _handleNavTap(int index) {
    if (index == 0 && _scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else if (index == 1) {
      Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchScreen()));
    } else if (index == 2) {
      Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TicketsScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
          child: child,
        ),
      ));
    } else if (index == 3) {
      Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ProfileScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      ));
    }
    setState(() => _currentIndex = index == 0 ? _tabController.index : index + 1);
  }

  Widget _buildMovieList(List<Movie> movies) {
    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1), () => setState(() {})),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 16,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) => AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, child) => AnimatedOpacity(
              opacity: 1.0, duration: const Duration(milliseconds: 400),
              child: AnimatedSlide(offset: Offset.zero, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic, child: child),
            ),
            child: MovieCard(
              movie: movies[index],
              onTap: () => Navigator.push(context, PageRouteBuilder(
                pageBuilder: (_, __, ___) => MovieDetailScreen(movie: movies[index]),
                transitionsBuilder: (_, animation, __, child) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'movie-${movie.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4), spreadRadius: 1,
              )],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.network(
                      movie.posterUrl, fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          )),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.movie, size: 40, color: Colors.grey)),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(16)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(movie.rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ]),
                      ),
                    ),
                    Positioned(bottom: 0, left: 0, right: 0, height: 60, child: Container(
                      decoration: BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      )),
                    )),
                  ]),
                )),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(movie.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(movie.genres.first, style: TextStyle(
                            fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
                      ),
                      const Spacer(),
                      Icon(Icons.bookmark_border, size: 18, color: Theme.of(context).colorScheme.primary),
                    ]),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final MovieService _movieService = MovieService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Movie> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchMovies(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = _movieService.getNowPlayingMovies().where((m) => m.title.toLowerCase().contains(query.toLowerCase())).toList();
        _animationController.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(pinned: true, floating: true, title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search movies...', border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () { _searchController.clear(); _searchMovies(''); },
            ) : null,
          ),
          onChanged: _searchMovies,
        )),
        if (_isSearching) SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final movie = _searchResults[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
                    CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          movie.posterUrl, width: 50, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey, width: 50, height: 80, child: const Icon(Icons.movie)),
                        ),
                      ),
                      title: Text(movie.title),
                      subtitle: Text(movie.genres.join(', ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie))),
                    ),
                  ),
                ),
              ),
            );
          }, childCount: _searchResults.length),
        )
        else SliverFillRemaining(
          child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Theme.of(context).primaryColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('Search for movies', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            ],
          )),
        ),
      ]),
    );
  }
}

// rammmmkmekrkek
// --- Movie Detail Screen ---
class MovieDetailScreen extends StatelessWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.favorite_border, color: Colors.white),
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.share, color: Colors.white),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                movie.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8.0, color: Colors.black, offset: Offset(0.0, 2.0))],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'movie-backdrop-${movie.id}',
                    child: Image.network(
                      movie.backdropUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.blueGrey),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Movie poster
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Hero(
                        tag: 'movie-poster-${movie.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 120,
                            height: 180,
                            child: Image.network(
                              movie.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.movie, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Movie info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${movie.rating}/10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                  ],
                                ),
                              ),
                              if (movie.isNowPlaying)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(16)),
                                  child: const Text('Now Playing', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            movie.genres.join(' • '),
                            style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 4),
                                  Text('${movie.duration} mins', style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 4),
                                  Text(DateFormat('dd MMM yyyy').format(movie.releaseDate), style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (movie.isNowPlaying)
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TheaterSelectionScreen(movie: movie))),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_activity),
                                  SizedBox(width: 8),
                                  Text('Book Tickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description, size: 20),
                        SizedBox(width: 8),
                        Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(movie.description, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: const Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('Cast & Crew', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: movie.cast.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              child: Text(
                                movie.cast[index][0],
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 80,
                            child: Text(
                              movie.cast[index],
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('Actor', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (movie.isNowPlaying)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_filled),
                    label: const Text('Watch Trailer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }
}

// --- Theater Selection Screen ---
class TheaterSelectionScreen extends StatefulWidget {
  final Movie movie;
  const TheaterSelectionScreen({super.key, required this.movie});

  @override
  State<TheaterSelectionScreen> createState() => _TheaterSelectionScreenState();
}

class _TheaterSelectionScreenState extends State<TheaterSelectionScreen> {
  final TheaterService _theaterService = TheaterService();
  final List<DateTime> _dates = [];
  int _selectedDateIndex = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      _dates.add(DateTime(now.year, now.month, now.day + i));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theaters = _theaterService.getTheaters();
    final selectedDate = _dates[_selectedDateIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.movie.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selection
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Theme.of(context).colorScheme.surface,
            child: SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = index == _selectedDateIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('EEE').format(date).toUpperCase(),
                              style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(DateFormat('d').format(date),
                              style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMM').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Theater list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: theaters.length,
              itemBuilder: (context, index) {
                final theater = theaters[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(theater.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(theater.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: theater.getShowtimes(selectedDate, widget.movie.id).map((showtime) {
                            return ElevatedButton(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => SeatSelectionScreen(movie: widget.movie, theater: theater, showtime: showtime, date: selectedDate))),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Theme.of(context).primaryColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                ),
                              ),
                              child: Text(showtime.format(context)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Seat Selection Screen ---
class SeatSelectionScreen extends StatefulWidget {
  final Movie movie;
  final Theater theater;
  final Showtime showtime;
  final DateTime date;

  const SeatSelectionScreen({super.key, required this.movie, required this.theater, required this.showtime, required this.date});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> with TickerProviderStateMixin {
  final Set<String> _selectedSeats = {};
  final TheaterService _theaterService = TheaterService();
  late List<List<SeatStatus>> _seats;
  late Map<String, double> _seatPrices;
  double _totalAmount = 0.0;
  late AnimationController _screenAnimationController, _seatsAnimationController;
  late Animation<double> _screenAnimation, _fadeAnimation, _slideAnimation;

  @override
  void initState() {
    super.initState();
    _seats = widget.showtime.seats;
    _seatPrices = widget.showtime.seatPrices;

    _screenAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _seatsAnimationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _screenAnimation = CurvedAnimation(parent: _screenAnimationController, curve: Curves.easeInOut);
    _fadeAnimation = CurvedAnimation(parent: _seatsAnimationController, curve: Curves.easeIn);
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _seatsAnimationController, curve: Curves.easeOutQuad),
    );

    // Start animations sequentially
    _screenAnimationController.forward().then((_) => _seatsAnimationController.forward());
  }

  @override
  void dispose() {
    _screenAnimationController.dispose();
    _seatsAnimationController.dispose();
    super.dispose();
  }

  void _toggleSeat(int row, int col) {
    if (_seats[row][col] == SeatStatus.available || _seats[row][col] == SeatStatus.selected) {
      setState(() {
        if (_seats[row][col] == SeatStatus.available) {
          _seats[row][col] = SeatStatus.selected;
          _selectedSeats.add('${String.fromCharCode(65 + row)}${col + 1}');
        } else {
          _seats[row][col] = SeatStatus.available;
          _selectedSeats.remove('${String.fromCharCode(65 + row)}${col + 1}');
        }
        _updateTotalAmount();
      });
    }
  }

  void _updateTotalAmount() {
    _totalAmount = 0.0;
    for (final seat in _selectedSeats) {
      final rowLetter = seat.substring(0, 1);
      final rowIndex = rowLetter.codeUnitAt(0) - 65;
      final seatType = _getSeatType(rowIndex);
      _totalAmount += _seatPrices[seatType] ?? 0;
    }
  }

  String _getSeatType(int row) {
    if (row < 3) return 'Regular';
    if (row < 6) return 'Premium';
    return 'Recliner';
  }

  Color _getSeatColor(SeatStatus status, int row) {
    switch (status) {
      case SeatStatus.available:
        if (row < 3) return const Color(0xFFE0E0E0); // Regular seats
        if (row < 6) return const Color(0xFF90CAF9); // Premium seats
        return const Color(0xFFCE93D8); // Recliner seats
      case SeatStatus.booked: return const Color(0xFFEF5350);
      case SeatStatus.selected: return const Color(0xFF66BB6A);
      case SeatStatus.reserved: return const Color(0xFFFFB74D);
    }
  }

  BorderRadius _getSeatBorderRadius(int row) {
    if (row < 3) return BorderRadius.circular(4);
    if (row < 6) return BorderRadius.circular(6);
    return BorderRadius.circular(8);
  }

  double _getSeatWidth(int row, SeatStatus status) {
    double baseWidth = row < 3 ? 22 : (row < 6 ? 24 : 26);
    return status == SeatStatus.selected ? baseWidth + 2 : baseWidth;
  }

  double _getSeatHeight(int row, SeatStatus status) {
    double baseHeight = row < 3 ? 22 : (row < 6 ? 24 : 28);
    return status == SeatStatus.selected ? baseHeight + 2 : baseHeight;
  }

  Widget _getSeatIcon(int row, SeatStatus status, int colIndex) {
    if (row >= 6) {
      return Icon(
        Icons.weekend_outlined,
        size: status == SeatStatus.selected ? 14 : 12,
        color: status == SeatStatus.selected ? Colors.white : Colors.black54,
      );
    } else {
      return Text(
        '${colIndex + 1}',
        style: TextStyle(
          fontSize: status == SeatStatus.selected ? 11 : 9,
          fontWeight: status == SeatStatus.selected ? FontWeight.bold : FontWeight.normal,
          color: status == SeatStatus.selected ? Colors.white : Colors.black54,
        ),
      );
    }
  }

  Widget _buildSeat(int rowIndex, int colIndex) {
    final status = _seats[rowIndex][colIndex];
    final isSelectable = status == SeatStatus.available || status == SeatStatus.selected;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnimation.value * (1 - _fadeAnimation.value) * (rowIndex * 0.3)),
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (rowIndex * 50) + (colIndex * 20)),
            tween: Tween<double>(begin: 0.6, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.5, vertical: rowIndex >= 6 ? 2 : 1),
              child: GestureDetector(
                onTap: isSelectable ? () => _toggleSeat(rowIndex, colIndex) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _getSeatWidth(rowIndex, status),
                  height: _getSeatHeight(rowIndex, status),
                  decoration: BoxDecoration(
                    color: _getSeatColor(status, rowIndex),
                    borderRadius: _getSeatBorderRadius(rowIndex),
                    boxShadow: status == SeatStatus.selected
                        ? [BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        blurRadius: 4, spreadRadius: 0.5, offset: const Offset(0, 1))]
                        : null,
                    border: rowIndex >= 6 && status != SeatStatus.selected
                        ? Border.all(color: Colors.purple.shade300, width: 0.5)
                        : null,
                  ),
                  child: Center(child: _getSeatIcon(rowIndex, status, colIndex)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom app bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movie.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('EEE, dd MMM').format(widget.date)} • ${DateFormat('hh:mm a').format(widget.showtime.time)}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Theater info header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.movie_outlined, color: Theme.of(context).primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.theater.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('IMAX Screen • 8x10 Seats', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Screen indicator
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              child: ScaleTransition(
                scale: _screenAnimation,
                child: Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade300,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                            Colors.grey.shade300,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(1)),
                        boxShadow: [BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 2),
                        )],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'SCREEN THIS WAY',
                        style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Column numbers
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: List.generate(10, (index) => Expanded(
                    child: Center(
                      child: Text('${index + 1}', style: TextStyle(
                        fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500,
                      )),
                    ),
                  )),
                ),
              ),
            ),

            // Seat layout
            Container(
              height: MediaQuery.of(context).size.height * 0.42,
              child: ShaderMask(
                shaderCallback: (Rect bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Colors.white, Colors.white.withOpacity(0.8)],
                  stops: const [0.0, 0.1, 0.9, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: TheaterFloorPainter())),
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _seats.length,
                      itemBuilder: (context, rowIndex) => Padding(
                        padding: EdgeInsets.symmetric(vertical: rowIndex >= 6 ? 4 : 3),
                        child: Row(
                          children: [
                            // Row label
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) => Opacity(
                                opacity: _fadeAnimation.value,
                                child: SizedBox(
                                  width: 20,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: rowIndex >= 6
                                            ? Colors.purple.shade100
                                            : rowIndex >= 3
                                            ? Colors.blue.shade100
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        String.fromCharCode(65 + rowIndex),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: rowIndex >= 6
                                              ? Colors.purple.shade800
                                              : rowIndex >= 3
                                              ? Colors.blue.shade800
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Seats with spacing
                            Expanded(
                              child: Transform(
                                transform: Matrix4.translationValues(0, 0, 0)..rotateX(0.01 * rowIndex),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_seats[rowIndex].length, (colIndex) {
                                    // Add aisle after seat 5
                                    if (colIndex == 5) {
                                      return Row(children: [
                                        SizedBox(width: 6),
                                        _buildSeat(rowIndex, colIndex),
                                      ]);
                                    }
                                    return _buildSeat(rowIndex, colIndex);
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Seat status legend
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                children: [
                  // Seat type prices
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSeatTypeLegend('Regular', const Color(0xFFE0E0E0), _seatPrices['Regular'] ?? 0),
                        _buildSeatTypeLegend('Premium', const Color(0xFF90CAF9), _seatPrices['Premium'] ?? 0),
                        _buildSeatTypeLegend('Recliner', const Color(0xFFCE93D8), _seatPrices['Recliner'] ?? 0),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Seat status legend
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem(Colors.grey[300]!, 'Available'),
                        _buildLegendItem(Colors.green.shade400, 'Selected'),
                        _buildLegendItem(Colors.red[300]!, 'Booked'),
                        _buildLegendItem(Colors.orange[300]!, 'Reserved'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom bar
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8, offset: const Offset(0, -2),
                )],
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedSeats.length} ${_selectedSeats.length == 1 ? 'Seat' : 'Seats'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Rs.${_totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: _selectedSeats.isEmpty ? 16 : 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 140, height: 44,
                    child: ElevatedButton(
                      onPressed: _selectedSeats.isEmpty ? null : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CheckoutScreen(
                          movie: widget.movie,
                          theater: widget.theater,
                          showtime: widget.showtime,
                          date: widget.date,
                          selectedSeats: _selectedSeats.toList(),
                          totalAmount: _totalAmount,
                        )),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: _selectedSeats.isEmpty ? 0 : 4,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (_selectedSeats.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildSeatTypeLegend(String type, Color color, double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 2, spreadRadius: 0)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 4),
              Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 2),
          Text('Rs.${price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Custom painter for the theater floor effect
class TheaterFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.grey.shade100.withOpacity(0.3),
          Colors.grey.shade200.withOpacity(0.4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(size.width / 2, size.height * 0.1, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Checkout Screen ---
class CheckoutScreen extends StatefulWidget {
  final Movie movie;
  final Theater theater;
  final Showtime showtime;
  final DateTime date;
  final List<String> selectedSeats;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.movie,
    required this.theater,
    required this.showtime,
    required this.date,
    required this.selectedSeats,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.creditCard;
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (_selectedPaymentMethod == PaymentMethod.upi && _upiIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter UPI ID'), backgroundColor: Colors.red),
      );
      return;
    } else if (_selectedPaymentMethod == PaymentMethod.creditCard &&
        (_cardNumberController.text.isEmpty || _expiryController.text.isEmpty ||
            _cvvController.text.isEmpty || _nameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all card details'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Create new booking
    final booking = Booking(
      id: 'b${DateTime.now().millisecondsSinceEpoch}',
      movie: widget.movie,
      theater: widget.theater,
      showtime: widget.showtime,
      seats: widget.selectedSeats,
      totalPrice: widget.totalAmount,
      bookingTime: DateTime.now(),
      paymentMethod: _selectedPaymentMethod,
    );

    // Add booking to user
    UserService().addBooking(
      id: booking.id,
      movie: booking.movie,
      theater: booking.theater,
      showtime: booking.showtime,
      seats: booking.seats,
      totalPrice: booking.totalPrice,
      paymentMethod: booking.paymentMethod,
    );

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isProcessing = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            movie: widget.movie,
            theater: widget.theater,
            showtime: widget.showtime,
            date: widget.date,
            selectedSeats: widget.selectedSeats,
            totalAmount: widget.totalAmount,
          ),
        ),
      );
    });
  }

  Widget _buildPaymentOption(PaymentMethod method, String label, IconData icon, Color color) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
          _animationController.reset();
          _animationController.forward();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          boxShadow: [
            if (isSelected) BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.black, fontSize: 16)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedPaymentMethod == PaymentMethod.upi) ...[
                  const Text('UPI Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _upiIdController,
                    decoration: InputDecoration(
                      labelText: 'UPI ID',
                      hintText: 'username@upi',
                      prefixIcon: const Icon(Icons.payment),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Popular UPI Apps', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildUpiAppIcon('Google Pay', Icons.account_balance_wallet, Colors.purple),
                      _buildUpiAppIcon('PhonePe', Icons.phone_android, Colors.blue),
                      _buildUpiAppIcon('PayTM', Icons.mobile_friendly, Colors.blueAccent),
                    ],
                  ),
                ] else if (_selectedPaymentMethod == PaymentMethod.creditCard) ...[
                  const Text('Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      hintText: 'XXXX XXXX XXXX XXXX',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiryController,
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            hintText: 'MM/YY',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            hintText: 'XXX',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name on Card',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else if (_selectedPaymentMethod == PaymentMethod.paypal) ...[
                  const Text('PayPal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'You will be redirected to PayPal to complete your payment securely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: Icon(Icons.account_balance_wallet, size: 48, color: Colors.blue[700])),
                ] else if (_selectedPaymentMethod == PaymentMethod.googlePay ||
                    _selectedPaymentMethod == PaymentMethod.phonePe ||
                    _selectedPaymentMethod == PaymentMethod.paytm) ...[
                  Text(
                    'Pay with ${_getPaymentMethodName(_selectedPaymentMethod)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(_selectedPaymentMethod),
                          size: 48,
                          color: _getPaymentMethodColor(_selectedPaymentMethod),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You will be redirected to complete your payment securely.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ] else if (_selectedPaymentMethod == PaymentMethod.netBanking) ...[
                  const Text('Select Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  _buildBankOption('State Bank of India', Icons.account_balance),
                  _buildBankOption('HDFC Bank', Icons.account_balance),
                  _buildBankOption('ICICI Bank', Icons.account_balance),
                  _buildBankOption('Axis Bank', Icons.account_balance),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.googlePay: return 'Google Pay';
      case PaymentMethod.phonePe: return 'PhonePe';
      case PaymentMethod.paytm: return 'PayTM';
      default: return '';
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.googlePay: return Icons.account_balance_wallet;
      case PaymentMethod.phonePe: return Icons.phone_android;
      case PaymentMethod.paytm: return Icons.mobile_friendly;
      default: return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.googlePay: return Colors.purpleAccent;
      case PaymentMethod.phonePe: return Colors.blue;
      case PaymentMethod.paytm: return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  Widget _buildUpiAppIcon(String name, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBankOption(String name, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      trailing: const Icon(Icons.chevron_right),
      onTap: () { /* Handle bank selection */ },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), elevation: 0),
      body: _isProcessing
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing payment...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary with animation
            ScaleTransition(
              scale: _fadeAnimation,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      _buildSummaryItem('Movie:', widget.movie.title),
                      _buildSummaryItem('Date:', DateFormat('EEE, dd MMM yyyy').format(widget.date)),
                      _buildSummaryItem('Time:', widget.showtime.format(context)),
                      _buildSummaryItem('Theater:', widget.theater.name),
                      _buildSummaryItem('Seats:', widget.selectedSeats.join(', ')),
                      const Divider(),
                      _buildSummaryItem('Total:', 'Rs.${widget.totalAmount.toStringAsFixed(2)}', isTotal: true),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Payment methods
            const Text('Choose Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildPaymentOption(PaymentMethod.creditCard, 'Credit/Debit Card', Icons.credit_card, Colors.blue),
            _buildPaymentOption(PaymentMethod.paypal, 'PayPal', Icons.account_balance_wallet, Colors.deepPurple),
            _buildPaymentOption(PaymentMethod.upi, 'UPI', Icons.payment, Colors.purple),
            _buildPaymentOption(PaymentMethod.googlePay, 'Google Pay', Icons.account_balance_wallet, Colors.purpleAccent),
            _buildPaymentOption(PaymentMethod.phonePe, 'PhonePe', Icons.phone_android, Colors.blue),
            _buildPaymentOption(PaymentMethod.paytm, 'PayTM', Icons.mobile_friendly, Colors.blueAccent),
            _buildPaymentOption(PaymentMethod.netBanking, 'Net Banking', Icons.account_balance, Colors.green),
            const SizedBox(height: 24),
            // Payment details section
            _buildPaymentDetails(),
            const SizedBox(height: 32),
            // Pay button with animation
            ScaleTransition(
              scale: _fadeAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 4,
                    shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                  child: Text(
                    'Pay Rs.${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? Theme.of(context).primaryColor : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Confirmation Screen ---
class ConfirmationScreen extends StatelessWidget {
  final Movie movie;
  final Theater theater;
  final Showtime showtime;
  final DateTime date;
  final List<String> selectedSeats;
  final double totalAmount;

  const ConfirmationScreen({
    super.key,
    required this.movie,
    required this.theater,
    required this.showtime,
    required this.date,
    required this.selectedSeats,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final ticketCode = 'CIN${Random().nextInt(90000) + 10000}';
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Success animation
                Hero(
                  tag: 'confirmationIcon',
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Booking Confirmed!',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your tickets have been booked successfully.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Ticket Card
                Card(
                  elevation: 8,
                  shadowColor: primaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      // Top part with movie info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withBlue((primaryColor.blue + 40).clamp(0, 255)),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              movie.title,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('EEEE, MMMM dd, yyyy').format(date),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time, color: Colors.white70, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  showtime.format(context),
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Ticket edge design
                      _buildTicketEdge(context),
                      // Bottom part with details
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          children: [
                            _buildTicketInfo(context, 'Theater', theater.name, Icons.theater_comedy),
                            _buildDivider(),
                            _buildTicketInfo(context, 'Seats', selectedSeats.join(', '), Icons.chair),
                            _buildDivider(),
                            _buildTicketInfo(context, 'Total', 'Rs.${totalAmount.toStringAsFixed(2)}', Icons.attach_money),
                            const SizedBox(height: 24),
                            // QR Code
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[850] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 0)],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    size: 160,
                                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Ticket Code: $ticketCode',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.download_rounded,
                        label: 'Download',
                        onPressed: () {
                          _showSnackBar(context, 'Ticket downloaded successfully!');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.share_rounded,
                        label: 'Share',
                        onPressed: () {
                          _showSnackBar(context, 'Sharing options opened');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text('$label:', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
            color: isDark ? Colors.grey[850] : Colors.grey[50],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).colorScheme.primary,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildTicketEdge(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(40, (index) => Container(width: 5, height: 1, color: Colors.grey.withOpacity(0.3))),
            ),
          ),
          Positioned(
            left: -12, top: 0, bottom: 0,
            child: CircleAvatar(radius: 12, backgroundColor: Theme.of(context).scaffoldBackgroundColor),
          ),
          Positioned(
            right: -12, top: 0, bottom: 0,
            child: CircleAvatar(radius: 12, backgroundColor: Theme.of(context).scaffoldBackgroundColor),
          ),
        ],
      ),
    );
  }
}

// --- Tickets Screen ---
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _userService.currentUser?.bookings ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(pinned: true, title: const Text('My Tickets')),
          if (bookings.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 64,
                        color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('No tickets booked yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen())),
                      child: const Text('Browse Movies'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final booking = bookings[index];
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
                        CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Card(
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ConfirmationScreen(
                              movie: booking.movie,
                              theater: booking.theater,
                              showtime: booking.showtime,
                              date: booking.showtime.time,
                              selectedSeats: booking.seats,
                              totalAmount: booking.totalPrice,
                            ),
                          )),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        booking.movie.posterUrl,
                                        width: 60, height: 90, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey,
                                          width: 60, height: 90,
                                          child: const Icon(Icons.movie),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(booking.movie.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text(booking.theater.name,
                                              style: TextStyle(color: Colors.grey[600])),
                                          const SizedBox(height: 4),
                                          Text('${DateFormat('MMM dd, yyyy').format(booking.showtime.time)} • ${booking.showtime.format(context)}',
                                              style: TextStyle(color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Seats: ${booking.seats.join(', ')}',
                                        style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text('Rs.${booking.totalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor)),
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
              }, childCount: bookings.length),
            ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserService().currentUser;
    final displayName = user?.dname ?? 'Guest';
    final email = user?.email ?? 'No email';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 60, color: Colors.white)),
          const SizedBox(height: 16),
          Text(displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          Text(email,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),

          _buildSectionTitle('Account Settings'),
          _buildProfileItem(icon: Icons.person_outline, title: 'Edit Profile', onTap: () {}),
          _buildProfileItem(icon: Icons.lock_outline, title: 'Change Password', onTap: () {}),
          _buildProfileItem(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
          _buildProfileItem(icon: Icons.payment_outlined, title: 'Payment Methods', onTap: () {}),

          const SizedBox(height: 16),
          _buildSectionTitle('Preferences'),
          _buildProfileItem(icon: Icons.language_outlined, title: 'Language', onTap: () {}),
          _buildProfileItem(icon: Icons.movie_filter_outlined, title: 'Favorite Genres', onTap: () {}),
          _buildProfileItem(icon: Icons.theater_comedy_outlined, title: 'Preferred Theaters', onTap: () {}),

          const SizedBox(height: 16),
          _buildSectionTitle('Activity'),
          _buildProfileItem(icon: Icons.history, title: 'Booking History', onTap: () {}),
          _buildProfileItem(icon: Icons.bookmark_outline, title: 'Watchlist', onTap: () {}),
          _buildProfileItem(icon: Icons.star_outline, title: 'Reviews', onTap: () {}),

          const SizedBox(height: 16),
          _buildSectionTitle('Support'),
          _buildProfileItem(icon: Icons.help_outline, title: 'Help Center', onTap: () {}),
          _buildProfileItem(icon: Icons.chat_bubble_outline, title: 'Contact Us', onTap: () {}),
          _buildProfileItem(icon: Icons.info_outline, title: 'About', onTap: () {}),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              UserService().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _buildProfileItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
