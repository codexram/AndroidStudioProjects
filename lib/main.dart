//  CinemaNow
//  Backend : Hardcoded movies + optional Firestore sync
//  Auth    : Firebase Auth + Google Sign-In
//  DB      : Firestore

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';

// ─── ENTRY POINT ───────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ThemeService()),
    ChangeNotifierProvider(create: (_) => UserService()),
    ChangeNotifierProvider(create: (_) => MovieService()),
    ChangeNotifierProxyProvider<UserService, WishlistService>(
      create: (_) => WishlistService(),
      update: (_, us, ws) => ws!..updateUid(us.user?.uid),
    ),
  ], child: const CinemaNowApp()));
}

// ─── THEME SERVICE ─────────────────────────────────────────────────────────
class ThemeService extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
    notifyListeners();
  }
}

// ─── DESIGN TOKENS ─────────────────────────────────────────────────────────
class C {
  static const bgDark      = Color(0xFF07090F);
  static const surf1Dark   = Color(0xFF0E1420);
  static const surf2Dark   = Color(0xFF141C2E);
  static const cardDark    = Color(0xFF19243A);
  static const borderDark  = Color(0xFF22304D);
  static const bgLight     = Color(0xFFF2F5FF);
  static const surf1Light  = Color(0xFFFFFFFF);
  static const surf2Light  = Color(0xFFEEF2FF);
  static const cardLight   = Color(0xFFE6ECFF);
  static const borderLight = Color(0xFFCDD8FF);
  static const gold        = Color(0xFFFFBD00);
  static const goldGlow    = Color(0xFFFFD966);
  static const goldDim     = Color(0xFF7A5700);
  static const cyan        = Color(0xFF00C6FF);
  static const cyanDim     = Color(0xFF00384D);
  static const rose        = Color(0xFFFF3D5E);
  static const roseDim     = Color(0xFF500010);
  static const green       = Color(0xFF00E5A0);
  static const orange      = Color(0xFFFF8C00);
  static const purple      = Color(0xFF9B6FFF);
  static const indigo      = Color(0xFF4F6EFF);
  static const txPrimD = Color(0xFFF0F4FF);
  static const txSecD  = Color(0xFF8A9FCC);
  static const txMutD  = Color(0xFF4A5F80);
  static const txPrimL = Color(0xFF0A1433);
  static const txSecL  = Color(0xFF3A4F7A);
  static const txMutL  = Color(0xFF8A9FCC);
  static const bollywood = Color(0xFFFF6B35);
  static const hollywood = Color(0xFF4F6EFF);
  static const tollywood = Color(0xFF00C6FF);
  static const gradGold   = LinearGradient(colors: [Color(0xFFFFD000), Color(0xFFFFBD00), Color(0xFFFF9500)]);
  static const gradCyan   = LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]);
  static const gradRose   = LinearGradient(colors: [Color(0xFFFF6080), Color(0xFFFF2050)]);
  static const gradGreen  = LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00A870)]);
  static const gradPurple = LinearGradient(colors: [Color(0xFF9B6FFF), Color(0xFF5B3FDF)]);
  static const gradIndi   = LinearGradient(colors: [Color(0xFF4F6EFF), Color(0xFF2040DF)]);
  static const gradDark   = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A1020), Color(0xFF172033)],
  );

  static Color tx(bool d, {bool sec = false, bool muted = false}) {
    if (d) return muted ? txMutD : (sec ? txSecD : txPrimD);
    return muted ? txMutL : (sec ? txSecL : txPrimL);
  }
  static Color bg(bool d)     => d ? bgDark     : bgLight;
  static Color surf(bool d)   => d ? surf1Dark  : surf1Light;
  static Color surf2(bool d)  => d ? surf2Dark  : surf2Light;
  static Color card(bool d)   => d ? cardDark   : cardLight;
  static Color border(bool d) => d ? borderDark : borderLight;
}

ThemeData buildTheme(bool dark) {
  final base = dark ? ThemeData.dark() : ThemeData.light();
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: C.bg(dark),
    colorScheme: dark
        ? const ColorScheme.dark(
        primary: C.gold, secondary: C.cyan,
        surface: C.surf2Dark, onPrimary: Colors.black, onSurface: C.txPrimD)
        : const ColorScheme.light(
        primary: C.gold, secondary: Color(0xFF4F6EFF),
        surface: C.surf1Light, onPrimary: Colors.black, onSurface: C.txPrimL),
    fontFamily: 'Poppins',
    textTheme: base.textTheme.apply(
      bodyColor: dark ? C.txPrimD : C.txPrimL,
      displayColor: dark ? C.txPrimD : C.txPrimL,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0,
      iconTheme: IconThemeData(color: dark ? C.txPrimD : C.txPrimL),
      titleTextStyle: TextStyle(
          color: dark ? C.txPrimD : C.txPrimL,
          fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? C.surf2Dark : C.cardLight,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: C.border(dark))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: C.border(dark))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.gold, width: 1.5)),
      hintStyle: TextStyle(color: dark ? C.txMutD : C.txMutL),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}

// ─── MODELS ────────────────────────────────────────────────────────────────
enum SeatTier   { regular, premium, recliner }
enum SeatStatus { available, booked, selected }
enum PaymentMethod { upi, card, googlePay, phonePe, paytm, wallet }

class OmdbMovie {
  String get posterUrl {
    if (_posterUrl.contains('image.tmdb.org') && !_posterUrl.contains('weserv.nl')) {
      return 'https://images.weserv.nl/?url=$_posterUrl';
    }
    return _posterUrl;
  }
  final String _posterUrl;
  final String imdbId, title, overview, releaseDate, trailerYoutubeId;
  final double rating;
  final int voteCount;
  final List<String> genres, languages;
  bool isWishlisted;

  OmdbMovie({
    required this.imdbId,
    required this.title,
    this.overview = '',
    required String posterUrl,
    this.rating = 0.0,
    this.voteCount = 0,
    this.releaseDate = '',
    this.genres = const [],
    this.languages = const [],
    this.isWishlisted = false,
    this.trailerYoutubeId = '',
  }) : _posterUrl = posterUrl;

  /// Build from a Firestore document map
  factory OmdbMovie.fromFirestore(Map<String, dynamic> j) {
    return OmdbMovie(
      imdbId: j['id'] ?? j['imdbId'] ?? '',
      title: j['title'] ?? 'Unknown',
      overview: j['overview'] ?? '',
      posterUrl: j['posterUrl'] ?? _placeholder,
      rating: (j['rating'] ?? 0.0).toDouble(),
      voteCount: j['voteCount'] ?? 0,
      releaseDate: j['releaseDate'] ?? '',
      genres: List<String>.from(j['genres'] ?? []),
      languages: List<String>.from(j['languages'] ?? []),
      trailerYoutubeId: j['trailerYoutubeId'] ?? '',
    );
  }

  String get backdropUrl => posterUrl;
  String get ratingStr   => rating == 0.0 ? 'N/A' : rating.toStringAsFixed(1);
  String get year {
    final d = releaseDate;
    return d.length >= 4 ? d.substring(d.length - 4) : d;
  }
  bool get hasTrailer => trailerYoutubeId.isNotEmpty;

  static const _placeholder =
      'https://via.placeholder.com/300x450/19243A/FFB800?text=CinemaNow';
}

// ─── HARDCODED MOVIE DATABASE ───────────────────────────────────────────────
//
// FORMAT FOR FIRESTORE (collection: "movies", document id = movie id):
// {
//   "id": "tt16318530",
//   "title": "Jawan",
//   "overview": "A high-octane action thriller...",
//   "posterUrl": "https://...",
//   "rating": 7.0,
//   "voteCount": 85000,
//   "releaseDate": "07 Sep 2023",
//   "genres": ["Action", "Thriller"],
//   "languages": ["Hindi", "Tamil", "Telugu"],
//   "trailerYoutubeId": "4BfAnvstS7A",
//   "categories": ["bollywoodNew", "nowPlaying", "trending"]
// }
//
class MovieDatabase {
  static List<OmdbMovie> get all => _movies;

  static final List<OmdbMovie> _movies = [

    // ── BOLLYWOOD NEW ──────────────────────────────────────────────────────
    OmdbMovie(
      imdbId: 'tt16318530', title: 'Jawan',
      overview: 'A high-octane action thriller that outlines the emotional journey of a man who is set to rectify the wrongs in society.',
      posterUrl: 'https://www.tribuneindia.com/sortd-service/imaginary/v22-01/jpg/large/high?url=dGhldHJpYnVuZS1zb3J0ZC1wcm8tcHJvZC1zb3J0ZC9tZWRpYWQzODczNGYwLTRlNmQtMTFlZi1iMzFjLWM3ZTc5MGQ0OWM0MS5qcGc=',
      rating: 7.0, voteCount: 85000, releaseDate: '07 Sep 2023',
      genres: ['Action', 'Thriller'], languages: ['Hindi', 'Tamil', 'Telugu'],
      trailerYoutubeId: '4BfAnvstS7A',
    ),
    OmdbMovie(
      imdbId: 'tt15354892', title: 'Animal',
      overview: 'A hardened son vows revenge after his father is shot by unknown assailants. A tale of toxic obsession and brutal violence.',
      posterUrl: 'https://m.media-amazon.com/images/M/MV5BZThmNDg1NjUtNWJhMC00YjA3LWJiMjItNmM4ZDQ5ZGZiN2Y2XkEyXkFqcGc@._V1_FMjpg_UX1000_.jpg',
      rating: 6.2, voteCount: 50000, releaseDate: '01 Dec 2023',
      genres: ['Action', 'Crime', 'Drama'], languages: ['Hindi'],
      trailerYoutubeId: 'Dydmpavq7nU',
    ),
    OmdbMovie(
      imdbId: 'tt15445050', title: 'Pathaan',
      overview: 'An exiled spy returns to India to take on a vengeful rogue soldier who leads a terrorist organisation.',
      posterUrl: 'https://lh5.googleusercontent.com/proxy/2zoLVHwycxVXTMKeqcqb96yNpDiUim4l16heR3DOQaBbPCOFBXvKkxNzRJM6FOSZgH27T6G_K0viODgLlELW0lfOZYh7eQn7SHTKj3Vf8Q',
      rating: 5.9, voteCount: 60000, releaseDate: '25 Jan 2023',
      genres: ['Action', 'Thriller'], languages: ['Hindi'],
      trailerYoutubeId: 'vqu4z34wENw',
    ),
    OmdbMovie(
      imdbId: 'tt27277251', title: 'Stree 2',
      overview: 'The men of Chanderi face a new supernatural terror. The mysterious Stree returns to save the town from a headless ghost.',
      posterUrl: 'https://m.media-amazon.com/images/M/MV5BMTA1NmUxYzItZmVmNy00YmQxLTk4Y2UtZjVkMWUwMWQ5N2IxXkEyXkFqcGc@._V1_.jpg',
      rating: 7.5, voteCount: 65000, releaseDate: '15 Aug 2024',
      genres: ['Comedy', 'Horror'], languages: ['Hindi'],
      trailerYoutubeId: '1FNXWb_fXNg',
    ),
    OmdbMovie(
      imdbId: 'tt21190806', title: 'Rocky Aur Rani Kii Prem Kahaani',
      overview: 'A love story about two people from different backgrounds who must navigate family and societal expectations.',
      posterUrl: 'https://images.indianexpress.com/2023/05/Rocky-Aur-Rani-Kii-Prem-Kahaani-5.jpg?w=350',
      rating: 7.1, voteCount: 42000, releaseDate: '28 Jul 2023',
      genres: ['Drama', 'Romance'], languages: ['Hindi'],
      trailerYoutubeId: 'V2IbHJuVbMw',
    ),
    OmdbMovie(
      imdbId: 'tt15610982', title: 'Tu Jhoothi Main Makkaar',
      overview: 'A smooth-talking guy falls for a free-spirited girl and discovers their ideas of love are poles apart.',
      posterUrl: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxITEhUSExMWFhUXGBcVFRgYGBcVFhcYFhoYFxgYGBUYHiggGBolHRcWITEhJSkrLi4uFx8zODMtNygtLisBCgoKDg0OGhAQGyslHyUtLTAtLy0tLS0tLS0tLS0tKystLS0uLS0tLS0tLS0tKy0tLS0tLS0tLS0tLS0tLS0tLf/AABEIARQAtwMBIgACEQEDEQH/xAAcAAABBQEBAQAAAAAAAAAAAAAEAAIDBQYBBwj/xABDEAACAQIEAwYDBAcIAgEFAAABAhEAAwQSITEFQVEGEyJhcZEygaFCscHRBxQjUmJy8BVDU4KSouHxM7LSNGNzk8L/xAAaAQADAQEBAQAAAAAAAAAAAAACAwQBAAUG/8QAMhEAAgIBAwEGAwgDAQEAAAAAAAECEQMSITEEBRMiQVHwMmGRFFJxgaGx0eEVYsHxQv/aAAwDAQACEQMRAD8A0+BwauLck+N2QxGyqpEeetEYPh6OqnMQSouNqIyBmVo03AAPzqqs424q5FYgTOhI1019dBUv64zNmYkk6Ekmcv7vpXoSxuyTH1PkSgjltyneOVJ5jTfl68qjt1LNCo6WPll1R3QMnezBRYnU5uXWIpi99BlVB0jXTzke3vR4NORqO2BKUW/hQAj3v8Nf9W/5VKrXZAKAaEkzIBEwPu+tFXcMjwWG20Ejf/qmf2da/i5faPIQNvID2rdaMcFXwx/Ug7u/GyEx5gTA+kzXXW9GirPi3J/yz9Z9Kn/s61AABgCPiO0kx9TTRg7VsqQHJExBLQOc+/rXa17RqgvNRI2S7JgLHKdxpz689qRt340VZ8zA+WtMXCLGllxED4uUHr0iPmK6tlAf/DcgA6yx+JSIC7841rrRmmnWlfQ4VxGvgTnGp/yz9J9K7cF3WFG4jXfw6z08Ue3nXO7t/wCDe020b23/AKmicPg7ZAORxyAaQRBLTHLU71ur5gTx/wCqBbaXZ8QWNNjr5yNvbr864tu9BkKDpEajnPPrFTtwm10PP7R5wPwFdbhy/vOI2AdlGpJ2HmaYpL1J20n8KIDbu66KennqOU7xP0rjLdkQFjSZ+sUZYw4QEAsZ/eJY+5p5FdYGv/VfQrAt4jUKD78l6Hrm9hUzLRZFROtEmLnLV5JfgCstcW3Jj1qdhTE39/uo7FkeNw2XTSdNp5ieflFKpMSZHL68p6k0q6LdbmS52BQtPAp2WnqlJbKtB1DRCVEtupUWlS3KccpRJVFOApCpEpDTRapQlscC0gpqYJXctcpmTwqrIlSulamCmuha3UxfdQr0BwKHxfEEtfE2vTn/AMURxLEi1bZ9NNht9a8w4dwjGcQvXHR8qZiGdpyj+FQPiIH4UnNma2DxYF8VmtbttZXNmgAf6uU7eZilZ7bWX2Ux1/regsd+jWxbtNce/cYqCzbKNB01rzO4SpYAnLJ9YqZTbezK2kluj3bh2Ot3lzKRpuJ+vmKJZK8R4D2kvWHVgZCnUE7idR6GvauFY1L9pbtv4WHzB5g+YqzBlb2lyef1OFcxR0rTCtGm1UbW6qUiJ4mgQrUbLRbJUTrRqQpxBStMKUSVphWjUgHEFKUqIK1yt1A6QcJUiLUirU6CkNlqjZGiVKtupUFTqKW5D4wT8wcW66EosJTslB3gz7N6AoU08KanCU7JXa0d3EyECkaIyUsldrRjwzM52ztM2EuBdNU+rAT8jBoa5ebD4TDW8LcRLRUNcvEeIzEuqnmxkya1V2wrAqwlTuOvOqtOJM7mbaooJUCSWhdNVygLqNgTAqHqn4rRb0mOlTCMBdNy1JcuNRLKFJ89hIryft7w4DFhLCeJxJRRPinko2617DiLoyadKwmFwD/r1y5mXM1s92T9kyvvpU0ZaXZU4alR5fj+G37IU3LbIHmJGhjcTyOu1et/ohvZsLcU7q4PyZR+INZT9JfGrb91hbRBFuGcyDBAKhdJAJDEn0HWtp+iXBsmDLtP7RyVn91QB9+b2qnG29ydxUZUa8pTGSiDTSKoUmhc4RYI9uoHtUcwqNlpscjJp4E+CvZKjK1YOlQNbpymSTwNAhWlRBWlRaxfdEapUq26cqVMqUtsoSIwlSKtPCVIq1lm6RgFPFdyV3JS2kx0JyjwICnCmxTooNA5Z3W6O12min1mkJZbOVlbuHVb94ssy+YMYlecAx4QPLfnWsArM9ouzl+85ezdVZ3Vp3HRhMD5UnLByWw3Hkp7gXEe0KKsBpO2lZ/DftrhLDwwRB+VQXOE3bdzu7qEN13UjqCOVW3D8MUPyqGW2xbjXmYHtZwsWroZR4THv0r23skhGCw4Oh7pPurEvhLV64Ld6cjFQSNCNQZnl0+dekLdtqhKsuW2uymSFUcgOgFWdM7RB1lQlfFj64RTMLikuLmRgwPMVLFVvYmj4laZEabNSMKYRXUmdcoPYiao2FTEUwiiSoDW3yQFaVSEUq6zdvQSrUyLTkSplFa2JihgSnhaeBXQKWOTGZa5lqWKaVobGJWRxSipMtLLXaje7ZHFOApwSuhazUHGFHIoHjHEVw9s3CCx5KNyd/YCST5VYqhJgCo+JcODIVb7QynyEgkD1jWtjV7gdRJwg2uTzEdosTcxL2sQirIW5aCjZGGgB+15+c1bqJk+VT8X4CikPlPgJ7sruqk5iscxMx0mn2rByz18on5VH1WJxlq8h/Z/VRyQ0N+JeRTWbJYz0NaUX17g3bm6ABI0Z3OyzzGhnyBoLBYeFbTmfxpXLDXb6WgfBbEmObGCT9w+VZ0kdU/kjO08qhh+b2Rb9jcMtu0EZBl5EaMJ1ieY9av+6tn7RHrBoPuxbWBVTxHE9K9Jx1Ozw4Z5YYUXl21GsgjqKhIqj4fxQ2yFPwsYM7VfONaGUXEu6bqI5l8yIimEVKaYaHUUPEiEilTmpVti9AaqVIqVPkFcCUGo7QRhK7lqTLXIrrOoiiuEVIRTTXGpjKUV2lWDFIUV1VkxXBT1aAeu351yR0p1Fsl7wLoKHa5J8hTL9yhw9NUTzMmRtiurNR47DhrcqPEuvrG49qldW5R86HGMZNHQgddx9K2UdSoXDJ3c1Ir8sg6dfrRvA8LGa4d2JPyG1RW4LADZiI+esVY3VyWwo6R8pP51N0sHHUmX9fkWTRJccguJu5ieg2qm4gdJqwxDgVWcSaVA6kVfE8XK7K/EXP8Axztmb6gD860PZnGG7ZzHWGI+Wn/fzrD9oMVlKp0afcVquxzkZrZ2dQyjzXl7UWWNxC6KejMr8zRmmGnmm1CfR2MIpU4ilXWcW0UHxnidrC2Wv3mhF+ZYnQKo5knSKOivAO0faF8bxCGc9ytwJbSTlCg7xtJ11oG6Fx3Zuv1nH4z9o179VsuQLdtNXIO2ZhqTGu4EcqvMBwO0dBi8S5BytFwASNxEHqOdROEyqxbKEOYH5EcvImg+E8Sw9sBVvBi9y5MkqZbO8ARrr1jT2qTvGy3ul5GownB1Qyt+8dToz5lPkQQdvKKfh7rEsrplIJA1DBl5MCNtNwdqrOHYxASc05obyAMgAe3vNOtcdHesI/rajWbTyLeFsuIpsU0YtGGmlS2taessWIeOSGRQmPu5YO2h/CrPuh1+6oMRh1YQSSDpBA/Ku75JgTwucauikOKn7v8AmpLN0Gq+zhsM73LSXixRoZVYErpzjbb6VBjLTW/FauZoMFWiD5BtIO+/0qxSi0Qy7P6lb1f4Ggt3KlLA71n+F8W7yYEFdGB3BqztXyxiucaJIzC7eDt/FzBnfprtQvEMRt0j3qTId5+VAYuWK+n410VudknUaQMzk1Hi7fiTy1qfL4gKdjyI86auSarTPNeO3s+LcdGA+6tfhMR3a2rg+yQfz+k1ksfgLiYo3HELeAuWz1EAH8PetDYbNbj2pvKFT2aPQCQdRsdR6HWmkVX9mrxawob4k8P+X7NWcV58lTo+lw5O8xqRERSqXLXaAMK4xd7uxef9227eyk18rNeZXzg6hs3zma+ne2d0Dh+JYH+6aPnp+NfLuJOpoXuctj0fh3bAXO7LmAGGcf5SNuYkg/Kj+CXLBLm6N3eCDyLEqdPIj2ryDORsaNwfE3UwXIX3qaWH0K4dRvuer3b6WlbJcZp5NEAeUHz+tDcJ4lN3fp8686v8WYnIrNroGMA67adKtP0dPcfHW1ksPExB12/5NA8Tq2P+0xukj3vhokDSrRNKFw8KNSJ9ag4lxAIkhgJOXNIhfMyYj8SK2MXwKacmG3sSAQNyTEDWNJ15D59RQd3EXCTEKBt9qdOcbQfuqutYpSplxBAMyTMgROg+h50HxLHoFKyxYgnOuo0gcvhGm2vPerI4khsMW5C+GAhs4EfC6EEEQIDSIYHz8hNBX8dm7xP2RywVKNMjWMy7qQeQJHnXP1rUT4so+LfwmZBQbGJH+bYcibeCDqbioqgrC6EExGmuvlPPyphZ8PJXcPxgFxgu5ChhvqBod62GDKovnzrGX7OU5iuRhrO6k8xPMfdrpVxw7Hd58W40inxdxo+V7VwSw9Q5peGXHpfmXeJvyOmoqFwAJ8yKgvtI+tPx9wZN41+8UVHmOV2D59aCxN0uHPQaU5bmhiuYAFgdKOqENt7EnaLg+fD2HA8VpQD/ACsqz9QKoeHoVgMI5jzr0rDKGtrzBUfdWUxfDmXEkv4vtJyUKOUcooMWTmJb13T1pyR4aQ3heLFm+EOzwrEmBLbQPWK1pt151xIsSXGhmQdhvp616Nw+73lpH5lQSOhjUe9Lzrhjezcl3j/MWSlRGSlU56xW/pBIHD8R0ygfLMtfL+K3r6d7TXhfwd62AGBtsG3kGOaxIOxr5mxKyRS1JPg5xa5AopsVMRzqMrRAnLZaQo1J0Hz5TX0H2E7F4bB2w5Ge+yjO598qDZVn5mBNeC8PtzetDrcQe7AV9LWHhFjpU+aVUUYY3uFX8LaOptofVQaquKvbTKqqoBDaAKokRr6jX61FxHi2XSqYcRDuQ0nwE7Ajca7iSOlBhk3kSLcUN7OHG5RDMBGgaJiZyhzrB8mB9aGa/mkZVMnQ225mQfgMrpvpzGnTuOxK6ZmXMIAYqSDlkRnXT7Xw5QaBvXAW/aOIE5gug5biBEyfPQ16BfGNhfC8I1yWljbX4VMS+p0jQEDTXrWlYEZSdvCMoPTTUkknlp1GprN2O/ukG3kUH7OYhoC6NEQqaaCaN4biXhSxJEidAxknTQaGD0mhUk+BU435ht+yBoZA3BJ1M66zsR8x51U3WCPmU6/hJ0n5HfpFaS9hAVXxAuPhneQNW0+0NG8jVJjsIIgaHfYifMjfqek0cXTsQ8cM0XjmrRYYbEi4srvz8q7i1ZlIAJ+EeXKaz+Gvm05BnKTHQHnI5Gtdhrqm3K8wRVKdqz43qukn0+V45/k/VAC2sojnzqWwkVXm+dhqxNWF0FbZJOsURJEvOz+IzB0/dgj0P/I+tc49hvt8shHoevnv9KznZbiR/WkGsPKH2kfUCtvxa0zWnCgExsdZjXTzpElpmephffdM16GBwNjM0nTz3b0k7VocDxJs4sYe0HCx3hmAs855nf2rJcTu3EQW7YIdhEkEZOpPsan/AEd2Th8YyEyLyHWftJqPXc0OfMotRA6DpJzi8l0v1PS8lKpIpUg9YqcRw0BDBM8tdRMaA9K+eu33D1sY2+iiFDmPKQDH1r6bRRFfPX6RMKTjcTmMKLjETqdAkegIZdf4TS4wo1zbVMwxGlMyVMajutyowSbA+G4jfuuh9mB/Cvo/CrNselfNWbSa+i+zN/vMNaufvIje4FTZ1wUYHsyv47hsy5RpqKvD2IwpADByRuQxWZ9OVD45BmQdXUe5ArXEVmBU2xmXJKNaWYziHYlVtu2Hu3FubicrSOagkSD0rBNgBZYMzNcbfIygAPy0+1z32ma9uIqr4p2fsXzLAhv3l0M9SIinT1Phm4+rnxJs88suMs5AzSS4mDcaJI/kUcvvk0uGADwhdyQJBUAwdAp5DYSJgVfcU7I9yvercLgEAqRrqYkkeZ19femwhi60nxgQs9QdyY2296LBBq2y7BJSi2jQcOwyEahJiFjl10O4naaFx3DW8ZJGvTy1BkjeobVhsjOWGoymCGICnUAk9BtyqexiJVZYyWKtPiJMaDoojppTwd07MrjZ2BO20zJXc5upkH50b2c40Ya0Y0+EzvTuLWCATGxleeh5a7nN9/Ss00q8gwfrrsP660cJU9xHaXSLqentfFHdf9Rp/wBYbvO7WPi1j16mrriQItnUbVm+HYnMyt1iau8fckQOlVS5PhVsmVvZi6beKV2HgkNPQHn8jXrdeW4Ed3ZD8x4T6V6HwLErcsIymYAXzldNfPakdR6np9mz5h+YRjsILttkPMaeRGxrzPGzh79u5/hXAT/KTDD2mvUs1YbtqGV3C5YuKu4JKlSDO/VfrXn5q5PcxN3SNnbxCvqrAjaQZ16ac6VZXsFduNh2e4AMzkLB0OWQSBuJ03NKiTtWKkmnRsSNa8M/TBaV8ce7BkIou9CwmPoda91G9eX/AKTODMrfrC+FXOW65EqkkBX01GmnrTGAeIYgx4RvzoejuJIA5CkkHVSdyCSBPtNAhfyoQjjma+g/0f8A/wBBh/8A8SfdXhHDeHtdYqFJMEiIAEaksWIgASflXv3ZfDmzh7VqZyIqzBWYAEwdR86RmeyHYeWFXm/bWRy7xT7GfwrX1lLMfrNsnkW2/lNalHBEgzWYuDcvkOIpjNqBT6FvmW3HKnISd4nbzWbg/gb7q83uqoMFiRuYPufPaZ5V6XjCO7f+VvurznFWwGJjQGR0HOPfSm4+C/onszjX1CkD4QIiTmMxI6azJJ5DSnWsQRlHhBjkJEeHRRE7H/brUFqbYkkamTrGaNo576fOmX15nTQxuSZ5D/npTC3TfIVjVLKZAXf5nXLpt/3WNxanX5H6Vr7VwaLtG8n3BHMVWcbwA+MaDqN/Sfma5jcT07MruEX9F5Qa0K4jM2hn0maxdg5XE9QD5HXnW84daGhim/aEo78nyHW9kSjnbi/C90PxFg93lHOtL2Vw72bJzx4mldZ8telVyirvh18ZYPKkTzOSo3D0UcUtV7hTsTMEiPf25VjO1GPUXBmBGYhY5zoIrUG2x0ByA/6jHSsxi+Hs2JgqSqBiIOs/CJPKTPtUWVWj1cFJhfAsY1u01tUJhgREfak89tjypUBwiznxdzKTFtBmj+KAv/8AVdoY3Rs61cnouaqPtkS2DvosyU5bxILD/Tmqye9AJoJb0nUbVayI8G7d8MspdtmyIXubbNrIlp26ag6DpWe7N8GuYu8tq2DqRJicqkgFj6TXpf6Suy4Ny41hYm0LgQRHgY58o/lMwPPSjf0dcEwow1plW3ddv/OrpbdlcdMy5lEHSDGs6zQPYNbmi7K9iLOFcO1w3GEboFEpmyEmTJAdufvFGCSzHqSfczUycTJzIUK7gH6dNNKZtU2SV7FGKLXI3h7j9ZUHkGP0j8av7JCgLoAPx1rMYSwrFrjEgZltqR+8f6HvU547YQENfVuWpE/frW4064DeOU3UU2afNVXew5yyD4iYBOoB2BI3InzoDgnaK3cudyJPhNwMSAIGXrrzn0qxxmNtW1LXGhR4geRjxfnTkmhc8M4S0tbmRxnG8TkZUuq4J7tSlrKjXDBZRmuFyAGBLRGtBXUYAgtm8RMkbeUDQTqOf1qw4hwt0i5ZKtbt5rlm3BNxjcBV9f5TI9B01AxD38rHLh7YU+JmkkkExCmd9aoienhUWvC1Xv0RAr6zrpmA25DXfyP1qB32nUdNTsdPIHf3qJ+IXAucXBzEBAJIJEAnzAG3OpkZg0vdLNkY5dQBEdJhpIgyBzoimUNKtjgy+NiANtRObU66sd9dh+75VLaIZYnTU8p0I99/oarsRiQhbM2mUsQpJ3BIB6mDv507EYgFS6jRQGBC6qANZG0yRqOtYDoaV+pS47CkM+pkEexjmDz6Vq+z2LzIBuV0b1H9TVHirZKLcIJX4W3jaVInSInXqB1ruBumw5O6tq23UiRz5UuSFdVieaHh5RvLRmrLhzbgbwaqMDfDgEdKsMMPEBtMj3oDw2E3sQqHMzagkxudVjblrVfxLjOSzduBDMKBpqZzCfwFH/qarngbDQnU+vlUPeKCC8EC3mM6wUbf1E0iVjo0C9kMCLVhrjAm7dIa5G43yrr0E/M1yiLPHAVY27bGI5aGdJnWlXRkkjpJt3RY4u7Cbc4oLDXtDM/8RRuIAKiKrLtwKfi+k/hVMuREVsN4jZ7yDJzgK1sgwQQTMA6QRII5iq/gPBES8z7MpkZCyqd9MhJyjfQaVbRIUyNo1B6/81LatgENpI0/oxQb2aNuoJ0G5n2/7oPH38oPWjbsSY/rrQOEt95ek/Db8R82+yPx+VTz8UtimHhjbDsHhittUIDQc2hjxbz561Udp8PZTDXW7m1nc5Ubu0zZn3MxM/EZq2x/ErNmFuXApBnWQCDzBiCNeVZbij3MfeVLE90n94QRbB5tJ0ZhsFGvoNaojBqq4H9JB61kntFbt/h5FRgrl1bTYe0SHuuWDASxUBbSqDpIzhtJ0y0fx2/mAsG2yrh0CtbzhhCKGJZknXLlX1cda2eB4XZVrbKgBtLkQnUgHc+Z1Pi38TdTRFrs/YLX3YFjfGV/IcwvSSAfkOlM1Kx77Qxuepx/m29/04MJi7167YbFM7ZUcLbUaB3JDOB/Cq6abwRsINXcvM7EXBEEs4OolSAqx/MQY55YrfYfs5aw4QveLpaLPZtvktIGYyST9phqRynlWd4l3Bm6MpaQJbKsGRrPXLqAPfWmwTasB9q4cc3jrnj5b7L35lAshgOSzcadR4fER5+J/nlrtq8wD3lyyRlYsCwJJBIABAUDTUzttpVy+BBLGNWUBgYERMkHSOWlK5hVFsW1UdDMtAAiY5mdZ511HpvMuK9Pov7MjfSZjTNp7nKunPef81aBlC+EDfKDmAh58WonRZgRzplrAl9lnoTsDz5a03E4VxoAfOkzzRiDlzxltfAHYuqi3EYsUkwniaViQI+zB58o2qThuBByvmJE6DnptNNwUK4zbHwt6MMp+ho7gqkIVO6PB+oNTrPKUqIc+eai9OxpuF2VQAAQKs7J8Q9aCwg0oxNxTjyGw7EC4e8hIkGCTIjTWIqut3FgM7oRlZRCnUSOk8wa0K45ABPSDoYqDvcO5jKDAJ+GPWlyhfmHCdcoq8NdtwcrGPT7p/ClVthjYWWUSeu5HlSoVBeqNcrfDAWxSDmMsdedMbGWuq+9VS8JT99j/kH504cNUc3/ANIou8kZoiWDY61+8sU9MfaOgIYxtFVw4Yp5ufkBU1nBLbltZ21jT2rHkkglCDI8bfyrPtTsBiLKoAcxbdiI1NR/q3esJ2idwOelF2+CiNP/AG/JaXBPkZNr4WdfG2SIyEjoTp7VE3FABCoAPXT2oPijW7GkBmiSCSQPX+uVchbdq2zkd46qwWOoBMgk6CY0qpYMjS+ZG+rxR1Lfw+6LjAX82pIHkNKuLDaVlkxC2cMt25LMwNwDbRiWCwOikD1oRuP3HtXUykMxtqkfx5yR7J/upkOnk/qJydXCLrzq/wCjR8cuBrJZVS5r4ZUXRzWVXmR+e1YuzBczuuYwFEKzsXbYAHw92PketXHCsVcfD2sPZWSLa945PhBaSxJ/mzeZjTqKrAYt2uBZDa92jPAABYAXTpv4OXMkSN6phjai4isfVwjljkcW/T0scqEsBAESWJ0gafEDsOQJ61OqI4aORImd8sqdeYkTXeIWFJ7m2CyKWDCJa46zLs2w/aeIkkDSAOVVNq4BYdCSMzOkqCSAwBJ686CeJuOzLH2tOUntSp/m18w9MRbUlVlwqqSF6knQddh70+9dY720QdD429Dpv6Gs9gbvdm7GkBVE6R4o/E1ZHiDKpgCWLFrp8chZUhAdAfDoayXSU3ornz38tyJ9ZrSeVt2vJ0k7pcFfxAKWkJlBVWjfcsNJ/lqXA3PG/wDEqv8AMQD9Qa7jEAGms6k7k+f3UFgG/aKP5h9J/OvLnKLy3FUrPbx45RwKM3bo2uCbSiwarsBtR61URssx8HqB+VRYawVaTtBqfDfBm6ab7c9qhYCf+TWNbnWQ2XI05EmuUc+F1JjTlAGxpUHdsLWiBgubLt9x8qXdR/Ev1FRKyEAEmYg+tK2xBkSflvW7Gbkt25lWRyHvFZfj3GT3n6uoOYgEn+aa0mPctacDeNN9OtZvC4XNdN6B4soDFZMC2IO4gk8qVkKcCXLLrgSEZiIYAKp5660ZxHHrZTMRrsq855eoqPh8qDLEtOp0A9hyqvx/BWvXc1y7+zEZVG4jcTy156nXlVHT6P8A7exJ1byW+7597mf4hhrl1bl2ZENbcnbM+uhGwWACepjlA72qDjJdYZbl1XcA/wB2ghbaDbYSx83PQVtsMiW1CroqiAPL8aB7QcMXEIIZQQGAkkDxDXYHpNWw6tOavZKzzp9E4Y2lu3X9lTiy7ZiRkNq2WjRiMuUW1jYFiZnopoaxw+4yqV3N5gpG0hERZI2Ct3hP8prWYrGWQRbZiS8wuuuUSdRt6+lB4fi6gKlq0coyqImFBVSvqAWIP8hrI53WyMl0sE/E/wCbv+Aazh2wt++qai7ZJt9S9sGB66udPKu9muDqcO2f7RUKeYFsaMPV2uHzBFFXeK3sxC2dAzAMekEId9ZaCfKfKo7nEMUdkRdDMkHXxAZeu6nWPhPWheSVVaXHn6BrFC903ztXqEYDBFMwYeLQZ+TqJI02BktPWaz+N4eFuQBoXFwb6ZGDEaaa7a1fMcU6LGQeFmZzIUyzBQog6gCdeo3oK5bfL+0YM0mSogeWlDrcU3a3GxxxlUafh8/+FMOGg3CwEhgc20CNQesyB7mmPhB3fdmOZ20liWOnSSa0XBrUsZ2iD86qcYkEj1qXN1GRSi74K8XSYnGUa59/uUN8wMsgkaHUH0OlR8CtBsRbXq/3qw++Knxompuy1knFW49T6Lr+H1qW052j0EnHHTd7F/hVgkedGilxGzDkgaUy1Vh55a4R/AV6j8a49mfuofh13xgTAqxvWiT8VY0dfkCMT50qfcwcn4q5Q1ILwlMlm4ft+XOnHD3P3/vp9oRI6mfXbX1qZPWhCBxg25v/AF70xsCyjRiY10AzE+UkCKJa+QT4DA5ygU+c5tPn1pqY7+Hnp47f3Zq3RZim0qQJasvIBt3YJ1abfWJjNtzroR/8G772tv8AVRjcQ/g9Ze2I/wB1cHFBvl8vjtAe+ajaX3f1F2/vEfdvytsdJ1KAz0jXy9/KiER+aNsftL0JH1EfMU0cR1IyiRy7y0Pvan/2mB9kf/st++rVv5GW/U4XugaWW/1p+HzpKzHU2TMndwdMpMkz1AX5iq+4V0Ja91nv7cf+461wOoMhrnw5fFetwZ1BnMZj8RRPT6e/qClK+ff0LBbz6fsPXxKaluYm4CctmRAM5l5jURVYbaQAVbcSe9QHSRr4vPl5U0Nbg6PvMd7b56H7e2416/Ou8Pv/ANMal6+/oXWIxdwKoNliY2Vl023kjqdulVV7FOYBsuCSRuhjnJg7b+3mKWIdGMZX3n/y29woXk+0L7maEuW7cjwtz/vUMZpB+15mmVGvf8meL19/QPwF+4qk90fPVf63qo4jiWzaIeu43O4j1rt7uwAAGkf/AHUOojlmiPCPahcRi5k5f9yfnUuVpvZX7/ErwxaW7fv8ivxF081+taDszhLltTeNqWaAozAQpkk689F+RHnVVwq2HuZ3WVWDGa2JJIAmWGn/AAOdar+0xuF8hL2td9dHrMcfNpBZZ7aU/f0FjcTcI1sneB4ljbQ+/KuW9hpGm3TyrmJ4gpU6DnHjTl8/X2oP+0RHwj/Wn5+vtVHPCJVt5hitlYHzFXLXaziXy2sQORlTPsatBd211IpcnQaVhZuGYpUJ3vXb+uYNcoNQVAJxNtdCVHkSs/UzT1xaE6MGJEgKVJMTty5GsSO1NgsbhsOWIA+IKIGwj51232rsqZFm4DBUEOAFBEQF25k0OiR6X+Py18Lv8v5NpYutcDBrTIBHx5SG3/dJ2I5xyoh7ClQco9CoM/KsRg+2Vu3PgvtOkvdDnmdCRpqfOiR2+t/4FwejrPua6EZ14uRT7O6jyj+xqhhY/vG1jZbf/wAIA/KpEwWurtt/DH3b/nWSPb62TrZuZf3Qya+pj6VIn6Qbc64d4GwzJFM8Rn+O6j7n7Gs/UomXf55D8x4aTYUwBnaZmYtz/wClZJf0h25JNh5P8a7DbQ0rf6QrYmbFwz0ZAPau8R3+N6j7pq2wuvxtHQ5Pvyz5b8qDulEORrrzCxJX7bFRAI6g1nx2/txH6vcga6Ov10rlztWjjMcJfJKp4gYEIS6nTTmTRY+fFwKy9ndVp8Ed/m/7L0d3IOZ/FBUwksCwXQxMSRv1pzZQGIa4Qhh//H+6GJ1XYA1nH7QKGNs4S/Kxs0lPEGUCBAEr848qktcdFwMP1a6dUZj3qocxVcoPyyn560xqHlZOuh65LeK+W698l/fvoSxFxzlknw2iIEqx+GdCINRKFOZQ7Su58A3mPhETp67Vn8R2it+InC301zEs5TWS3ONzJjmaiHapRLdxdltJZp25a9M31osjjp8N2Hi7O61zWqKr8V79C4xVv+Jj/p19dKrbtiTEn/b+VV17tQp/u2HzFMwvaZFYMbbGPNd/nUOnIep9hy1tE2WB4cFQAMQR8QK2/n9iiGsaSXeInZP/AIwKy13ttbMRZcQZOq/9e9K523Qlf2LQJkSsHyiYo0ponfZ2dv4DVphhOrvrzGWIgTyqO/ZAaIHsKy47cLJ/YtBG0rM9Z6Ryrl7tshM9y/8AqWjjq8wX2b1H3f2NOzAaaCjUuDKPENuv5Vgn7WWjE2GMeY/Knp2rw4Efqpnnqh5zzE0Uo2tzF2f1SfwGnwvEnbENZOXKM+wfN4csTrGuY8uVKsza7WWFuG6MO2YzJlee+ulKkaGUZehzSa0wrb5GRpUqVUn0wqVKlXGCpUqVcaKlSpVxw9LzAMoMBozDrBkfWp14reywHKroAogAQoURz2EV2lXASjF8oS8TvB8/eHNIM6SSAVE/JmHzNL+1busNlksTHPNlnflCqAOQFdpVxvdwrhDL/ELriHcttv5THtJ96eOK3/8AEb6dI6dKVKuMcI+iB795nOZiSep8qjpUq4NCpUqVcaKlSpVxwqVKlXGCpUqVccf/2Q==',
      rating: 6.8, voteCount: 30000, releaseDate: '08 Mar 2023',
      genres: ['Comedy', 'Romance'], languages: ['Hindi'],
      trailerYoutubeId: 'G5MKZgkFNPY',
    ),
    OmdbMovie(
      imdbId: 'tt29107931', title: 'Fighter',
      overview: 'India\'s first aerial action film starring Hrithik Roshan as a fearless IAF pilot on a dangerous mission.',
      posterUrl: 'https://m.media-amazon.com/images/M/MV5BNjk2YjI2ZTUtOGUzMC00ZWNkLThiY2EtMzZjZTk0NDNhYjQyXkEyXkFqcGc@._V1_.jpg',
      rating: 6.4, voteCount: 38000, releaseDate: '25 Jan 2024',
      genres: ['Action', 'Drama'], languages: ['Hindi'],
      trailerYoutubeId: 'qP_S766vK1w',
    ),
    OmdbMovie(
      imdbId: 'tt17154562', title: 'Dunki',
      overview: 'A heartfelt journey of friends who take an illegal immigration route called Donkey Flight to reach their dream country.',
      posterUrl: 'data:image/jpeg;base64,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 ',
      rating: 6.1, voteCount: 35000, releaseDate: '22 Dec 2023',
      genres: ['Drama', 'Comedy'], languages: ['Hindi'],
      trailerYoutubeId: 'p2C8N2Y1A0k',
    ),

    // ── BOLLYWOOD CLASSIC ──────────────────────────────────────────────────
    OmdbMovie(
      imdbId: 'tt1187043', title: '3 Idiots',
      overview: 'Two friends are on a search for their long-lost companion. They revisit their college days and recall events that shaped their lives.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/66A9MqXOyVFCssoloscw79z8Tew.jpg',
      rating: 8.4, voteCount: 400000, releaseDate: '25 Dec 2009',
      genres: ['Comedy', 'Drama'], languages: ['Hindi'],
      trailerYoutubeId: 'K0eDlFX9Gmc',
    ),
    OmdbMovie(
      imdbId: 'tt0470752', title: 'Dangal',
      overview: 'Former wrestler Mahavir Singh Phogat trains his daughters Geeta and Babita to become world-class wrestlers.',
      posterUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR8dwLgmiyIS_yxdboRUVREPCkTt2Soy5ACuQ&s',
      rating: 8.3, voteCount: 300000, releaseDate: '23 Dec 2016',
      genres: ['Biography', 'Drama', 'Sport'], languages: ['Hindi'],
      trailerYoutubeId: '9mtnO6_SBYE',
    ),
    OmdbMovie(
      imdbId: 'tt0169102', title: 'Lagaan',
      overview: 'In 1893 colonial India, a small village bets on a cricket match against British officers to avoid paying taxes for three years.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/i7Bfh0OkQi65OQjJPWKjVLZ8BQM.jpg',
      rating: 8.1, voteCount: 95000, releaseDate: '15 Jun 2001',
      genres: ['Drama', 'Sport'], languages: ['Hindi'],
      trailerYoutubeId: 'OSa_WvAnm7Q',
    ),
    OmdbMovie(
      imdbId: 'tt1477834', title: 'Zindagi Na Milegi Dobara',
      overview: 'Three friends decide to turn their bachelor trip into a soul-searching journey across Spain, confronting their fears along the way.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/swk7NGtGWkdOaRQi1GJQ3qMDLjz.jpg',
      rating: 8.1, voteCount: 100000, releaseDate: '15 Jul 2011',
      genres: ['Adventure', 'Comedy', 'Drama'], languages: ['Hindi'],
      trailerYoutubeId: 'pVie3tqYQYc',
    ),

    // ── HOLLYWOOD NEW ──────────────────────────────────────────────────────
    OmdbMovie(
      imdbId: 'tt15398776', title: 'Oppenheimer',
      overview: 'The story of J. Robert Oppenheimer\'s role in the development of the atomic bomb during World War II.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
      rating: 8.3, voteCount: 650000, releaseDate: '21 Jul 2023',
      genres: ['Biography', 'Drama', 'History'], languages: ['English'],
      trailerYoutubeId: 'uYPbbksJxIg',
    ),
    OmdbMovie(
      imdbId: 'tt1517268', title: 'Barbie',
      overview: 'Barbie and Ken are having the time of their lives in the colorful and seemingly perfect world of Barbie Land. When they get a chance to go to the real world, things get complicated.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg',
      rating: 6.9, voteCount: 410000, releaseDate: '21 Jul 2023',
      genres: ['Adventure', 'Comedy'], languages: ['English'],
      trailerYoutubeId: 'pBk4NYhWNMM',
    ),
    OmdbMovie(
      imdbId: 'tt9362722', title: 'Spider-Man: Across the Spider-Verse',
      overview: 'Miles Morales catapults across the Multiverse, where he encounters a team of Spider-People charged with protecting its very existence.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',
      rating: 8.6, voteCount: 295000, releaseDate: '02 Jun 2023',
      genres: ['Animation', 'Action'], languages: ['English', 'Hindi'],
      trailerYoutubeId: 'shW9i6k8cB0',
    ),
    OmdbMovie(
      imdbId: 'tt3447590', title: 'Deadpool & Wolverine',
      overview: 'Deadpool is recruited by the TVA and forms an unlikely alliance with a variant Wolverine to battle a common threat.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      rating: 7.7, voteCount: 350000, releaseDate: '26 Jul 2024',
      genres: ['Action', 'Comedy', 'Sci-Fi'], languages: ['English'],
      trailerYoutubeId: '73_1biulkYk',
    ),
    OmdbMovie(
      imdbId: 'tt23696836', title: 'Dune: Part Two',
      overview: 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
      rating: 8.5, voteCount: 500000, releaseDate: '01 Mar 2024',
      genres: ['Action', 'Adventure', 'Drama'], languages: ['English'],
      trailerYoutubeId: 'Way9Dexny3w',
    ),
    OmdbMovie(
      imdbId: 'tt22022452', title: 'Inside Out 2',
      overview: 'Riley enters high school and Joy must deal with a new crop of emotions: Anxiety, Envy, Ennui, and Embarrassment.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
      rating: 7.8, voteCount: 250000, releaseDate: '14 Jun 2024',
      genres: ['Animation', 'Comedy'], languages: ['English'],
      trailerYoutubeId: 'LEjhY15eCx0',
    ),
    OmdbMovie(
      imdbId: 'tt9218116', title: 'The Creator',
      overview: 'Amidst a future war between the human race and AI, a soldier discovers a weapon that could end the war — a child AI.',
      posterUrl: 'https://m.media-amazon.com/images/M/MV5BMDkxMTUxOTQtYzM4Yi00YzA2LTgzOTYtNDg2NTliODE0ZTRjXkEyXkFqcGc@._V1_FMjpg_UX1000_.jpg',
      rating: 6.7, voteCount: 120000, releaseDate: '29 Sep 2023',
      genres: ['Action', 'Drama', 'Sci-Fi'], languages: ['English'],
      trailerYoutubeId: 'ex3C1-5Dhb8',
    ),
    OmdbMovie(
      imdbId: 'tt18259086', title: 'Mission: Impossible — Dead Reckoning Part One',
      overview: 'Ethan Hunt and his IMF team must track down a terrifying new weapon that threatens all of humanity before it falls into the wrong hands.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/NNxYkU70HPurnNCSiCjYAmacwm.jpg',
      rating: 7.7, voteCount: 230000, releaseDate: '12 Jul 2023',
      genres: ['Action', 'Thriller'], languages: ['English'],
      trailerYoutubeId: 'avz06PDqgbQ',
    ),

    // ── HOLLYWOOD CLASSIC ──────────────────────────────────────────────────
    OmdbMovie(
      imdbId: 'tt0111161', title: 'The Shawshank Redemption',
      overview: 'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/lyQBXzOQSuE59IsHyhrp0qIiPAz.jpg',
      rating: 9.3, voteCount: 2600000, releaseDate: '14 Oct 1994',
      genres: ['Drama'], languages: ['English'],
      trailerYoutubeId: '6hB3S9bIaco',
    ),
    OmdbMovie(
      imdbId: 'tt0468569', title: 'The Dark Knight',
      overview: 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological tests of his ability to fight injustice.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
      rating: 9.0, voteCount: 2700000, releaseDate: '18 Jul 2008',
      genres: ['Action', 'Crime', 'Drama'], languages: ['English'],
      trailerYoutubeId: 'EXeTwQWrcwY',
    ),
    OmdbMovie(
      imdbId: 'tt0816692', title: 'Interstellar',
      overview: 'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      rating: 8.7, voteCount: 1800000, releaseDate: '07 Nov 2014',
      genres: ['Adventure', 'Drama', 'Sci-Fi'], languages: ['English'],
      trailerYoutubeId: 'zSWdZVtXT7E',
    ),
    OmdbMovie(
      imdbId: 'tt1375666', title: 'Inception',
      overview: 'A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg',
      rating: 8.8, voteCount: 2300000, releaseDate: '16 Jul 2010',
      genres: ['Action', 'Adventure', 'Sci-Fi'], languages: ['English'],
      trailerYoutubeId: 'YoHD9XEInc0',
    ),
    OmdbMovie(
      imdbId: 'tt4154796', title: 'Avengers: Endgame',
      overview: 'After Thanos destroys half of all life in the universe, the Avengers must reassemble to reverse the damage.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
      rating: 8.4, voteCount: 1200000, releaseDate: '26 Apr 2019',
      genres: ['Action', 'Adventure', 'Drama'], languages: ['English'],
      trailerYoutubeId: 'TcMBFSGVi1c',
    ),
    OmdbMovie(
      imdbId: 'tt0245429', title: 'Spirited Away',
      overview: 'During her family\'s move to the suburbs, a sullen 10-year-old girl wanders into a world ruled by gods, witches, and spirits.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg',
      rating: 8.6, voteCount: 780000, releaseDate: '20 Jul 2001',
      genres: ['Animation', 'Adventure', 'Family'], languages: ['Japanese', 'English'],
      trailerYoutubeId: 'ByXuk9QqQkk',
    ),

    // ── SOUTH INDIAN (TOLLYWOOD / KOLLYWOOD / SANDALWOOD) NEW ──────────────
    OmdbMovie(
      imdbId: 'tt16478946', title: 'Kalki 2898 AD',
      overview: 'In a dystopian future, a warrior named Bhairava rises to protect humanity from the oppressive Supreme Yaskin, guided by an immortal warrior.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/aosm8NMQ3UyoBVpSxyimorCQykC.jpg',
      rating: 6.8, voteCount: 80000, releaseDate: '27 Jun 2024',
      genres: ['Action', 'Sci-Fi'], languages: ['Telugu', 'Hindi'],
      trailerYoutubeId: 'yHOq2SqyCQY',
    ),
    OmdbMovie(
      imdbId: 'tt22827016', title: 'Salaar: Part 1 — Ceasefire',
      overview: 'A ferocious warrior helps his friend, the heir to a violent kingdom, claim the throne and maintain peace, leading to devastating consequences.',
      posterUrl: 'https://cdn.district.in/movies-assets/images/cinema/Salaar-(1)%20(1)-3bc0e140-af31-11f0-b3dc-814b56ab3dc9.png?im=Resize,width=400',
      rating: 6.3, voteCount: 55000, releaseDate: '22 Dec 2023',
      genres: ['Action', 'Crime'], languages: ['Telugu', 'Hindi'],
      trailerYoutubeId: 'wGqaxMn6I14',
    ),
    OmdbMovie(
      imdbId: 'tt21882868', title: 'Leo',
      overview: 'A mild-mannered cafe owner\'s past as a feared gangster resurfaces, plunging him and his family into danger.',
      posterUrl: 'https://images.indianexpress.com/2023/09/leo3.jpg',
      rating: 6.7, voteCount: 60000, releaseDate: '19 Oct 2023',
      genres: ['Action', 'Crime'], languages: ['Tamil', 'Hindi'],
      trailerYoutubeId: 'R-PVGEfNflU',
    ),
    OmdbMovie(
      imdbId: 'tt25621978', title: 'Pushpa: The Rule — Part 2',
      overview: 'Pushpa Raj expands his red sandalwood smuggling empire while facing a deadly rivalry with a ruthless police officer.',
      posterUrl: 'https://popcornreviewss.com/wp-content/uploads/2024/12/Pushpa-2-The-Rule-2024-Action-Crime-Thriller-Telugu-Movie-Review.jpg',
      rating: 7.4, voteCount: 90000, releaseDate: '05 Dec 2024',
      genres: ['Action', 'Crime', 'Drama'], languages: ['Telugu', 'Hindi'],
      trailerYoutubeId: 'YAXcBTBqVZ8',
    ),
    OmdbMovie(
      imdbId: 'tt26488560', title: 'Devara: Part 1',
      overview: 'A fearsome crime lord named Devara instils terror across sea coasts, but his pacifist son must reclaim his father\'s feared legacy.',
      posterUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSaVhDRBQqO0iRLGY8iVxoV-XekZZI2rrWeuA&s',
      rating: 6.2, voteCount: 45000, releaseDate: '27 Sep 2024',
      genres: ['Action', 'Drama'], languages: ['Telugu', 'Hindi'],
      trailerYoutubeId: 'V1LWTrBQLvs',
    ),
    OmdbMovie(
      imdbId: 'tt16410050', title: 'Jailer',
      overview: 'A retired jailer goes on a rampage to find and punish his son\'s killers, battling a ruthless underworld kingpin.',
      posterUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQkh-nrmAf73zreG_3AmyXG8iVsEdVckBMd_w&s',
      rating: 6.9, voteCount: 65000, releaseDate: '10 Aug 2023',
      genres: ['Action', 'Drama'], languages: ['Tamil', 'Hindi'],
      trailerYoutubeId: '1kVK0MZlbI4',
    ),

    // ── SOUTH INDIAN CLASSIC ───────────────────────────────────────────────
    OmdbMovie(
      imdbId: 'tt7334528', title: 'RRR',
      overview: 'Two legendary Indian revolutionaries — Alluri Sitarama Raju and Komuram Bheem — before they began their fight for independence.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/nEufeZlyAOLqO2brrs0yeF1lgXO.jpg',
      rating: 7.8, voteCount: 150000, releaseDate: '25 Mar 2022',
      genres: ['Action', 'Drama'], languages: ['Telugu', 'Hindi'],
      trailerYoutubeId: 'NgBoJJ9W6Sg',
    ),
    OmdbMovie(
      imdbId: 'tt15239678', title: 'Kantara',
      overview: 'A fierce clash between a tribal demi-god man, who dons the godly costume during the ritual, and a dutiful forest officer.',
      posterUrl: 'https://m.media-amazon.com/images/M/MV5BNDU2ZTYxYTMtMjhlZC00ZjEwLThhNDUtMzdlNWM4ZDcyYTM1XkEyXkFqcGc@._V1_.jpg',
      rating: 8.2, voteCount: 95000, releaseDate: '30 Sep 2022',
      genres: ['Action', 'Drama'], languages: ['Kannada', 'Hindi'],
      trailerYoutubeId: '6oH9v3hN6k8',
    ),
    OmdbMovie(
      imdbId: 'tt13186482', title: 'KGF: Chapter 2',
      overview: 'Rocky\'s name strikes fear into the underworld. An informant tells the story of his brutal past to Ramika Sen.',
      posterUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT1_seBZhNdl1I9eswYs5UXDuJKXlU8kPzXig&s',
      rating: 8.2, voteCount: 95000, releaseDate: '14 Apr 2022',
      genres: ['Action', 'Drama'], languages: ['Kannada', 'Hindi'],
      trailerYoutubeId: 'iBi1BMBW5xI',
    ),
    OmdbMovie(
      imdbId: 'tt4824302', title: 'Baahubali 2: The Conclusion',
      overview: 'The mystery of why Kattappa killed Baahubali is revealed, as the rebel son of the great warrior Baahubali fights a bloody revolution.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/f7YKJBOB5EqF2VoL3aQdz4lAIFN.jpg',
      rating: 8.2, voteCount: 300000, releaseDate: '28 Apr 2017',
      genres: ['Action', 'Drama'], languages: ['Telugu', 'Hindi'],
      trailerYoutubeId: 'G62HrubdD6o',
    ),
    OmdbMovie(
      imdbId: 'tt10698742', title: 'Pushpa: The Rise — Part 1',
      overview: 'A laborer rises through the ranks of a red sandalwood smuggling syndicate, and deals with the police and rival smugglers.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/rugyJdeoJm7cSJL1q4jBpTNbxyU.jpg',
      rating: 7.6, voteCount: 120000, releaseDate: '17 Dec 2021',
      genres: ['Action', 'Crime', 'Drama'], languages: ['Telugu', 'Hindi'],
      trailerYoutubeId: 'pOKk1lNDTG4',
    ),

    // ── UPCOMING / COMING SOON ─────────────────────────────────────────────
    OmdbMovie(
      imdbId: 'tt13186044', title: 'Singham Again',
      overview: 'Bajirao Singham fights a new menace in the third instalment of the beloved cop franchise.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/dBzA2JDNE8zB3gKkHbizrXjJPMf.jpg',
      rating: 0.0, voteCount: 0, releaseDate: '2025',
      genres: ['Action', 'Crime'], languages: ['Hindi'],
      trailerYoutubeId: 'o17f_68S69w',
    ),
    OmdbMovie(
      imdbId: 'tt15440234', title: 'Venom: The Last Dance',
      overview: 'Eddie Brock and his symbiote Venom face an all-new villain as they seek to find their place in a changing world.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/aosm8NMQ3UyoBVpSxyimorCQykC.jpg',
      rating: 0.0, voteCount: 0, releaseDate: '2024',
      genres: ['Action', 'Sci-Fi'], languages: ['English'],
      trailerYoutubeId: 'nulvWqzHUXo',
    ),
    OmdbMovie(
      imdbId: 'tt5992334', title: 'Gladiator II',
      overview: 'Years after witnessing the death of Maximus, Lucius must enter the Colosseum to fight powerful forces that threaten Rome.',
      posterUrl: 'https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
      rating: 0.0, voteCount: 0, releaseDate: '2024',
      genres: ['Action', 'Drama'], languages: ['English'],
      trailerYoutubeId: '6COmYeLsz4c',
    ),
  ];

  // ── Category selectors ────────────────────────────────────────────────────
  static List<OmdbMovie> get nowPlaying => _byIds([
    'tt16318530','tt15354892','tt15445050','tt27277251','tt3447590',
    'tt16478946','tt22827016','tt21882868','tt25621978','tt16410050',
  ]);
  static List<OmdbMovie> get upcoming => _byIds([
    'tt13186044','tt15440234','tt5992334','tt29107931','tt17154562',
  ]);
  static List<OmdbMovie> get trending => _byIds([
    'tt27277251','tt16318530','tt3447590','tt22022452','tt23696836',
    'tt25621978','tt16410050','tt21882868','tt15354892','tt26488560',
  ]);
  static List<OmdbMovie> get topRated => _byIds([
    'tt0111161','tt0468569','tt0816692','tt1375666','tt4154796',
    'tt0245429','tt1187043','tt0470752','tt7334528','tt15239678',
    'tt13186482','tt4824302',
  ]);
  static List<OmdbMovie> get bollywoodNew => _byIds([
    'tt16318530','tt15354892','tt15445050','tt27277251','tt21190806',
    'tt15610982','tt29107931','tt17154562',
  ]);
  static List<OmdbMovie> get bollywoodClassic => _byIds([
    'tt1187043','tt0470752','tt0169102','tt1477834',
  ]);
  static List<OmdbMovie> get hollywoodNew => _byIds([
    'tt15398776','tt1517268','tt9362722','tt3447590','tt23696836',
    'tt22022452','tt9218116','tt18259086',
  ]);
  static List<OmdbMovie> get hollywoodClassic => _byIds([
    'tt0111161','tt0468569','tt0816692','tt1375666','tt4154796','tt0245429',
  ]);
  static List<OmdbMovie> get tollywoodNew => _byIds([
    'tt16478946','tt22827016','tt21882868','tt25621978','tt26488560','tt16410050',
  ]);
  static List<OmdbMovie> get tollywoodClassic => _byIds([
    'tt7334528','tt15239678','tt13186482','tt4824302','tt10698742',
  ]);

  static List<OmdbMovie> _byIds(List<String> ids) {
    return ids
        .map((id) => _movies.firstWhere((m) => m.imdbId == id, orElse: () => OmdbMovie(imdbId: id, title: '', posterUrl: '')))
        .where((m) => m.title.isNotEmpty)
        .toList();
  }

  static OmdbMovie? findById(String id) {
    try { return _movies.firstWhere((m) => m.imdbId == id); } catch (_) { return null; }
  }

  static List<OmdbMovie> search(String query) {
    final q = query.toLowerCase();
    return _movies.where((m) =>
    m.title.toLowerCase().contains(q) ||
        m.genres.any((g) => g.toLowerCase().contains(q)) ||
        m.languages.any((l) => l.toLowerCase().contains(q)) ||
        m.overview.toLowerCase().contains(q)
    ).toList();
  }
}

// ─── MOVIE SERVICE — reads from hardcoded DB (optionally syncs from Firestore) ──
class MovieService extends ChangeNotifier {
  List<OmdbMovie> nowPlaying       = [];
  List<OmdbMovie> upcoming         = [];
  List<OmdbMovie> trending         = [];
  List<OmdbMovie> topRated         = [];
  List<OmdbMovie> bollywoodNew     = [];
  List<OmdbMovie> bollywoodClassic = [];
  List<OmdbMovie> hollywoodNew     = [];
  List<OmdbMovie> hollywoodClassic = [];
  List<OmdbMovie> tollywoodNew     = [];
  List<OmdbMovie> tollywoodClassic = [];
  bool loadingHero = true;
  bool loadingAll  = false;
  String? error;

  MovieService() { _bootstrap(); }

  Future<void> _bootstrap() async {
    // 1. Instantly populate from local hardcoded database
    _loadFromLocal();
    loadingHero = false;
    notifyListeners();

    // 2. Optionally try to enrich from Firestore in the background
    _syncFromFirestore();
  }

  void _loadFromLocal() {
    nowPlaying       = MovieDatabase.nowPlaying;
    upcoming         = MovieDatabase.upcoming;
    trending         = MovieDatabase.trending;
    topRated         = MovieDatabase.topRated;
    bollywoodNew     = MovieDatabase.bollywoodNew;
    bollywoodClassic = MovieDatabase.bollywoodClassic;
    hollywoodNew     = MovieDatabase.hollywoodNew;
    hollywoodClassic = MovieDatabase.hollywoodClassic;
    tollywoodNew     = MovieDatabase.tollywoodNew;
    tollywoodClassic = MovieDatabase.tollywoodClassic;
  }

  /// Optionally fetch movies from Firestore collection "movies"
  /// and override the local list if documents are present.
  Future<void> _syncFromFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('movies')
          .get()
          .timeout(const Duration(seconds: 6));
      if (snap.docs.isEmpty) return;

      final List<OmdbMovie> remote = snap.docs
          .map((d) => OmdbMovie.fromFirestore({'id': d.id, ...d.data()}))
          .where((m) => m.title.isNotEmpty)
          .toList();

      // Helper: pick movies whose category list contains a given tag
      List<OmdbMovie> byCategory(String cat) =>
          remote.where((m) => (m as dynamic).categories?.contains(cat) ?? false).toList();

      // We only override if Firestore returned movies with category tags
      final hasCategories = snap.docs.any((d) => d.data().containsKey('categories'));
      if (!hasCategories) return; // Firestore has movies but no category tags — skip

      nowPlaying       = byCategory('nowPlaying').isNotEmpty       ? byCategory('nowPlaying')       : nowPlaying;
      upcoming         = byCategory('upcoming').isNotEmpty         ? byCategory('upcoming')         : upcoming;
      trending         = byCategory('trending').isNotEmpty         ? byCategory('trending')         : trending;
      topRated         = byCategory('topRated').isNotEmpty         ? byCategory('topRated')         : topRated;
      bollywoodNew     = byCategory('bollywoodNew').isNotEmpty     ? byCategory('bollywoodNew')     : bollywoodNew;
      bollywoodClassic = byCategory('bollywoodClassic').isNotEmpty ? byCategory('bollywoodClassic') : bollywoodClassic;
      hollywoodNew     = byCategory('hollywoodNew').isNotEmpty     ? byCategory('hollywoodNew')     : hollywoodNew;
      hollywoodClassic = byCategory('hollywoodClassic').isNotEmpty ? byCategory('hollywoodClassic') : hollywoodClassic;
      tollywoodNew     = byCategory('tollywoodNew').isNotEmpty     ? byCategory('tollywoodNew')     : tollywoodNew;
      tollywoodClassic = byCategory('tollywoodClassic').isNotEmpty ? byCategory('tollywoodClassic') : tollywoodClassic;
      notifyListeners();
    } catch (_) {
      // Firestore unavailable — local data already loaded, no action needed
    }
  }

  Future<OmdbMovieDetail?> fetchDetail(String imdbId) async {
    // 1. Try Firestore first
    try {
      final doc = await FirebaseFirestore.instance
          .collection('movies').doc(imdbId).get()
          .timeout(const Duration(seconds: 4));
      if (doc.exists && doc.data() != null) {
        final movie = OmdbMovie.fromFirestore({'id': doc.id, ...doc.data()!});
        return _toDetail(movie);
      }
    } catch (_) {}

    // 2. Fall back to local
    final local = MovieDatabase.findById(imdbId);
    if (local != null) return _toDetail(local);
    return null;
  }

  OmdbMovieDetail _toDetail(OmdbMovie movie) {
    return OmdbMovieDetail(
      movie: movie,
      runtime: 0, // Not stored — can be added to Firestore
      director: '',
      rated: 'UA',
      languages: movie.languages,
      cast: [],
      awards: '',
      youtubeId: movie.trailerYoutubeId.isNotEmpty ? movie.trailerYoutubeId : null,
    );
  }

  Future<List<OmdbMovie>> search(String query) async {
    if (query.length < 2) return [];
    return MovieDatabase.search(query);
  }
}

// ─── FIRESTORE SEED DATA FORMAT ──────────────────────────────────────────────
//
// Run this in a one-time Firebase admin script or Firestore console.
// Collection: "movies"
// Document ID: the movie's imdbId string (e.g. "tt16318530")
//
// Example documents (copy-paste into Firestore console or admin SDK):
//
// Document: tt16318530
// {
//   "id": "tt16318530",
//   "title": "Jawan",
//   "overview": "A high-octane action thriller that outlines the emotional journey of a man...",
//   "posterUrl": "https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/cGOPbv9wA5gEejkUS4swY9ojylo.jpg",
//   "rating": 7.0,
//   "voteCount": 85000,
//   "releaseDate": "07 Sep 2023",
//   "genres": ["Action", "Thriller"],
//   "languages": ["Hindi", "Tamil", "Telugu"],
//   "trailerYoutubeId": "4BfAnvstS7A",
//   "categories": ["bollywoodNew", "nowPlaying", "trending"]
// }
//
// Document: tt0111161
// {
//   "id": "tt0111161",
//   "title": "The Shawshank Redemption",
//   "overview": "Two imprisoned men bond over a number of years...",
//   "posterUrl": "https://images.weserv.nl/?url=https://image.tmdb.org/t/p/w500/lyQBXzOQSuE59IsHyhrp0qIiPAz.jpg",
//   "rating": 9.3,
//   "voteCount": 2600000,
//   "releaseDate": "14 Oct 1994",
//   "genres": ["Drama"],
//   "languages": ["English"],
//   "trailerYoutubeId": "6hB3S9bIaco",
//   "categories": ["hollywoodClassic", "topRated"]
// }

// ─── REST OF MODELS ────────────────────────────────────────────────────────
class OmdbMovieDetail {
  final OmdbMovie movie;
  final int runtime;
  final String director, rated, awards;
  final List<String> languages;
  final List<CastMember> cast;
  final String? youtubeId;
  OmdbMovieDetail({
    required this.movie, this.runtime = 0, this.director = '',
    this.rated = 'UA', this.languages = const [], this.cast = const [],
    this.awards = '', this.youtubeId,
  });
}

class CastMember { final String name; const CastMember({required this.name}); }

class Showtime {
  final String id, language, format;
  final DateTime time;
  final List<List<SeatStatus>> seats;
  final Map<SeatTier, double> prices;
  const Showtime({
    required this.id, required this.time, required this.seats,
    required this.prices, this.language = 'English', this.format = 'Standard',
  });
  String formatTime(BuildContext ctx) => TimeOfDay.fromDateTime(time).format(ctx);
  int get total     => seats.expand((r) => r).length;
  int get available => seats.expand((r) => r).where((s) => s == SeatStatus.available).length;
  double get fillPct => total == 0 ? 0 : (1 - available / total);
}

class Theater {
  final String id, name, address, city;
  final double rating;
  final List<String> amenities;
  final List<Screen> screens;
  const Theater({
    required this.id, required this.name, required this.address, required this.city,
    this.rating = 4.2, this.amenities = const [], this.screens = const [],
  });
}

class Screen {
  final String id, name, type;
  final int rows, cols;
  final List<Showtime> showtimes;
  const Screen({
    required this.id, required this.name, required this.type,
    required this.rows, required this.cols, this.showtimes = const [],
  });
}

class SnackItem {
  final String id, name, category, emoji;
  final double price;
  int qty;
  SnackItem({
    required this.id, required this.name, required this.price,
    required this.category, required this.emoji, this.qty = 0,
  });
}

class Booking {
  final String id;
  final OmdbMovie movie;
  final Theater theater;
  final Showtime showtime;
  final List<String> seats;
  final double total;
  final DateTime bookedAt;
  final PaymentMethod payment;
  final List<SnackItem> snacks;
  const Booking({
    required this.id, required this.movie, required this.theater,
    required this.showtime, required this.seats, required this.total,
    required this.bookedAt, required this.payment, this.snacks = const [],
  });

  Map<String, dynamic> toMap(String uid) => {
    'id': id, 'uid': uid,
    'movieId': movie.imdbId, 'movieTitle': movie.title, 'moviePoster': movie.posterUrl,
    'theaterId': theater.id, 'theaterName': theater.name, 'theaterAddress': theater.address,
    'showtimeId': showtime.id, 'showtimeTime': Timestamp.fromDate(showtime.time),
    'showtimeFormat': showtime.format, 'showtimeLanguage': showtime.language,
    'seats': seats, 'total': total, 'bookedAt': Timestamp.fromDate(bookedAt),
    'payment': payment.index,
    'snacks': snacks.map((s) => {
      'name': s.name, 'qty': s.qty, 'price': s.price, 'emoji': s.emoji
    }).toList(),
  };

  factory Booking.fromMap(Map<String, dynamic> m) => Booking(
    id: m['id'] ?? '',
    movie: OmdbMovie(
        imdbId: m['movieId'] ?? '', title: m['movieTitle'] ?? '',
        posterUrl: m['moviePoster'] ?? ''),
    theater: Theater(
        id: m['theaterId'] ?? '', name: m['theaterName'] ?? '',
        address: m['theaterAddress'] ?? '', city: ''),
    showtime: Showtime(
        id: m['showtimeId'] ?? '',
        time: (m['showtimeTime'] as Timestamp).toDate(),
        format: m['showtimeFormat'] ?? '',
        language: m['showtimeLanguage'] ?? '',
        seats: [], prices: {}),
    seats: List<String>.from(m['seats'] ?? []),
    total: (m['total'] ?? 0).toDouble(),
    bookedAt: (m['bookedAt'] as Timestamp).toDate(),
    payment: PaymentMethod.values[m['payment'] ?? 0],
    snacks: (m['snacks'] as List? ?? []).map((s) => SnackItem(
        id: '', name: s['name'], price: (s['price'] ?? 0).toDouble(),
        category: '', emoji: s['emoji'] ?? '🍿', qty: s['qty'] ?? 0)).toList(),
  );
}

class MovieReview {
  final String id, userName, userId, content, photoUrl;
  final double rating;
  final DateTime createdAt;
  MovieReview({
    required this.id, required this.userName, required this.userId,
    required this.content, required this.rating, required this.createdAt,
    this.photoUrl = '',
  });
  Map<String, dynamic> toMap() => {
    'userName': userName, 'userId': userId, 'content': content,
    'rating': rating, 'createdAt': createdAt, 'photoUrl': photoUrl,
  };
  factory MovieReview.fromMap(String id, Map<String, dynamic> m) => MovieReview(
    id: id, userName: m['userName'] ?? 'Anonymous', userId: m['userId'] ?? '',
    content: m['content'] ?? '', rating: (m['rating'] ?? 0.0).toDouble(),
    createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    photoUrl: m['photoUrl'] ?? '',
  );
}

class AppUser {
  final String uid, displayName, email, photoUrl, tier;
  final List<Booking> bookings;
  final List<String> wishlist;
  final int points;
  const AppUser({
    required this.uid, required this.displayName, required this.email,
    this.photoUrl = '', this.bookings = const [], this.wishlist = const [],
    this.points = 0, this.tier = 'Bronze',
  });
  Map<String, dynamic> toMap() => {
    'uid': uid, 'displayName': displayName, 'email': email,
    'photoUrl': photoUrl, 'points': points, 'tier': tier, 'wishlist': wishlist,
  };
  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    uid: m['uid'] ?? '', displayName: m['displayName'] ?? '',
    email: m['email'] ?? '', photoUrl: m['photoUrl'] ?? '',
    points: m['points'] ?? 0, tier: m['tier'] ?? 'Bronze',
    wishlist: List<String>.from(m['wishlist'] ?? []),
  );
  static String calcTier(int p) {
    if (p >= 2000) return 'Platinum';
    if (p >= 800)  return 'Gold';
    if (p >= 300)  return 'Silver';
    return 'Bronze';
  }
  AppUser copyWith({
    String? displayName, String? email,
    List<Booking>? bookings, List<String>? wishlist, int? points,
  }) => AppUser(
    uid: uid, displayName: displayName ?? this.displayName,
    email: email ?? this.email, photoUrl: photoUrl,
    bookings: bookings ?? this.bookings, wishlist: wishlist ?? this.wishlist,
    points: points ?? this.points,
    tier: AppUser.calcTier(points ?? this.points),
  );
}

// ─── WISHLIST SERVICE ──────────────────────────────────────────────────────
class WishlistService extends ChangeNotifier {
  String? _uid;
  final Set<String> _ids = {};
  void updateUid(String? uid) {
    if (_uid != uid) {
      _uid = uid;
      if (uid != null) { _load(); } else { _ids.clear(); notifyListeners(); }
    }
  }
  Future<void> _load() async {
    if (_uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (doc.exists) {
        _ids.clear();
        _ids.addAll(List<String>.from(doc.data()?['wishlist'] ?? []));
        notifyListeners();
      }
    } catch (_) {}
  }
  bool has(String id) => _ids.contains(id);
  void toggle(String id) async {
    _ids.contains(id) ? _ids.remove(id) : _ids.add(id);
    notifyListeners();
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users').doc(_uid).update({'wishlist': _ids.toList()});
      } catch (_) {}
    }
  }
  List<String> get ids => _ids.toList();
}

// ─── USER SERVICE ──────────────────────────────────────────────────────────
class UserService extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;
  bool get loggedIn => _user != null;
  bool _loading = false;
  bool get loading => _loading;

  UserService() { FirebaseAuth.instance.authStateChanges().listen(_onAuth); }

  Future<void> _onAuth(User? fu) async {
    if (fu == null) { _user = null; notifyListeners(); return; }
    _user = AppUser(
      uid: fu.uid,
      displayName: fu.displayName ?? fu.email?.split('@')[0] ?? 'User',
      email: fu.email ?? '',
      photoUrl: fu.photoURL ?? '',
    );
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(fu.uid).get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists && doc.data() != null) {
        _user = AppUser.fromMap(doc.data()!);
        try {
          final bks = await FirebaseFirestore.instance
              .collection('bookings')
              .where('uid', isEqualTo: fu.uid)
              .orderBy('bookedAt', descending: true).get();
          _user = _user!.copyWith(
              bookings: bks.docs.map((d) => Booking.fromMap(d.data())).toList());
        } catch (_) {
          final bks = await FirebaseFirestore.instance
              .collection('bookings').where('uid', isEqualTo: fu.uid).get();
          final list = bks.docs.map((d) => Booking.fromMap(d.data())).toList();
          list.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
          _user = _user!.copyWith(bookings: list);
        }
      } else {
        await FirebaseFirestore.instance
            .collection('users').doc(fu.uid).set(_user!.toMap());
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> reloadUser() async {
    final fu = FirebaseAuth.instance.currentUser;
    if (fu != null) await _onAuth(fu);
  }

  Future<String?> signInWithEmail(String email, String pass) async {
    try {
      _loading = true; notifyListeners();
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      return null;
    } on FirebaseAuthException catch (e) { return _authError(e); }
    finally { _loading = false; notifyListeners(); }
  }

  Future<String?> register(String name, String email, String pass) async {
    try {
      _loading = true; notifyListeners();
      final c = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      if (c.user != null) {
        await c.user!.updateDisplayName(name);
        final u = AppUser(uid: c.user!.uid, displayName: name, email: email);
        await FirebaseFirestore.instance.collection('users').doc(u.uid).set(u.toMap());
        _user = u; notifyListeners(); return null;
      }
      return 'Registration failed.';
    } on FirebaseAuthException catch (e) { return _authError(e); }
    finally { _loading = false; notifyListeners(); }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _loading = true; notifyListeners();
      final gu = await GoogleSignIn().signIn();
      if (gu == null) { _loading = false; notifyListeners(); return false; }
      final ga = await gu.authentication;
      await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
              accessToken: ga.accessToken, idToken: ga.idToken));
      return true;
    } catch (_) { return false; }
    finally { _loading = false; notifyListeners(); }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) { return _authError(e); }
  }

  void signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  void addBooking(Booking b) async {
    if (_user == null) return;
    _user = _user!.copyWith(
      bookings: [b, ..._user!.bookings],
      points: _user!.points + 75,
    );
    notifyListeners();
    try {
      await FirebaseFirestore.instance
          .collection('bookings').doc(b.id).set(b.toMap(_user!.uid));
      await FirebaseFirestore.instance
          .collection('users').doc(_user!.uid)
          .update({'points': _user!.points, 'tier': _user!.tier});
    } catch (_) {}
  }

  Future<String?> updateProfile({String? name, String? email}) async {
    if (_user == null) return 'Not logged in';
    try {
      _loading = true; notifyListeners();
      final u = <String, dynamic>{};
      if (name  != null) u['displayName'] = name;
      if (email != null) u['email']       = email;
      if (u.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users').doc(_user!.uid).update(u);
        if (name != null) await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
        _user = _user!.copyWith(displayName: name, email: email);
      }
      return null;
    } catch (e) { return e.toString(); }
    finally { _loading = false; notifyListeners(); }
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':        return 'No account found for this email.';
      case 'wrong-password':        return 'Incorrect password.';
      case 'invalid-email':         return 'Invalid email address.';
      case 'email-already-in-use':  return 'Email already in use.';
      case 'weak-password':         return 'Password must be at least 6 characters.';
      case 'invalid-credential':    return 'Invalid email or password.';
      default:                      return e.message ?? 'Authentication failed.';
    }
  }
}

// ─── THEATER & SNACK DATA ──────────────────────────────────────────────────
class TheaterData {
  static List<Theater> getForMovie(OmdbMovie m) => [
    Theater(id:'t1', name:'PVR IMAX Gold', address:'Phoenix Mall, Nagercoil', city:'Nagercoil', rating:4.7,
        amenities:['IMAX','Dolby Atmos','Gold Lounge','Valet','F&B'], screens:_buildScreens('t1', m)),
    Theater(id:'t2', name:'INOX Multiplex', address:'City Square, Raipur', city:'Raipur', rating:4.3,
        amenities:['4DX','Recliner','Parking','Café'], screens:_buildScreens('t2', m)),
    Theater(id:'t3', name:'Cinépolis', address:'R-City Mall, Mumbai', city:'Mumbai', rating:4.2,
        amenities:['Dolby Vision','Parking','Gaming Zone'], screens:_buildScreens('t3', m)),
    Theater(id:'t4', name:'SPI Goldklass', address:'Express Avenue, Chennai', city:'Chennai', rating:4.5,
        amenities:['IMAX','VIP Lounge','Valet'], screens:_buildScreens('t4', m)),
    Theater(id:'t5', name:'Miraj Cinemas', address:'Rajouri Garden, Delhi', city:'Delhi', rating:3.9,
        amenities:['Standard','Parking','Canteen'], screens:_buildScreens('t5', m)),
  ];

  static List<Screen> _buildScreens(String tid, OmdbMovie m) {
    const types = ['IMAX', '4DX', 'Standard'];
    return List.generate(3, (i) {
      final showtimes = <Showtime>[];
      final now = DateTime.now();
      for (int d = 0; d < 5; d++) {
        for (int t = 0; t < 4; t++) {
          final date    = DateTime(now.year, now.month, now.day + d);
          final dateStr = DateFormat('yyyyMMdd').format(date);
          final sid     = '${m.imdbId}-$tid-s${i+1}-$dateStr-$t';
          final rng     = Random(sid.hashCode);
          final h  = 9 + t * 3 + rng.nextInt(2);
          final mn = rng.nextBool() ? 0 : 30;
          showtimes.add(Showtime(
            id: sid, time: DateTime(date.year, date.month, date.day, h, mn),
            seats: _buildSeats(8, 12),
            prices: {
              SeatTier.regular:  150 + rng.nextDouble() * 50,
              SeatTier.premium:  260 + rng.nextDouble() * 60,
              SeatTier.recliner: 420 + rng.nextDouble() * 80,
            },
            language: m.languages.isNotEmpty ? m.languages[rng.nextInt(m.languages.length)] : 'Hindi',
            format: types[i < 3 ? i : 0],
          ));
        }
      }
      return Screen(
          id: '$tid-s${i+1}', name: 'Screen ${i+1}',
          type: types[i < 3 ? i : 0], rows: 8, cols: 12, showtimes: showtimes);
    });
  }

  static List<List<SeatStatus>> _buildSeats(int r, int c) =>
      List.generate(r, (_) => List.filled(c, SeatStatus.available));

  static List<Showtime> getShowtimesForDate(Theater t, DateTime date) =>
      t.screens.expand((s) => s.showtimes).where((st) =>
      st.time.year  == date.year &&
          st.time.month == date.month &&
          st.time.day   == date.day).toList();
}

class SnackData {
  static List<SnackItem> get all => [
    SnackItem(id:'s1', name:'Caramel Popcorn (L)', price:249, category:'Popcorn', emoji:'🍿'),
    SnackItem(id:'s2', name:'Cheese Popcorn (L)',  price:229, category:'Popcorn', emoji:'🍿'),
    SnackItem(id:'s3', name:'Butter Popcorn (M)',  price:179, category:'Popcorn', emoji:'🍿'),
    SnackItem(id:'s4', name:'Pepsi 500ml',          price:149, category:'Drinks', emoji:'🥤'),
    SnackItem(id:'s5', name:'Sprite 500ml',         price:149, category:'Drinks', emoji:'🥤'),
    SnackItem(id:'s6', name:'Cold Coffee',          price:179, category:'Drinks', emoji:'☕'),
    SnackItem(id:'s7', name:'Nachos & Salsa',       price:199, category:'Sides',  emoji:'🌽'),
    SnackItem(id:'s8', name:'Hot Dog',              price:189, category:'Sides',  emoji:'🌭'),
    SnackItem(id:'s9', name:'Mega Combo',           price:449, category:'Combo',  emoji:'🎬'),
    SnackItem(id:'s10', name:'Samosa (2 pcs)',      price:99,  category:'Sides',  emoji:'🥟'),
    SnackItem(id:'s11', name:'Veg Wrap',            price:149, category:'Sides',  emoji:'🌯'),
    SnackItem(id:'s12', name:'Cinema Punch',        price:199, category:'Drinks', emoji:'🍹'),
  ];
}

class OffersData {
  static List<Map<String, dynamic>> get all => [
    {'code':'CINEMA50',  'title':'₹50 off on first booking',  'desc':'Valid on all movies. Use at checkout.',    'color':C.gold,   'icon':Icons.confirmation_number_rounded, 'expiry':'31 Dec 2025'},
    {'code':'STREE2024', 'title':'20% off on Stree 2',        'desc':'Exclusive fan offer. Limited seats.',      'color':C.purple, 'icon':Icons.movie_filter_rounded,        'expiry':'15 Dec 2025'},
    {'code':'IMAX100',   'title':'₹100 off on IMAX tickets',  'desc':'For IMAX shows only. Weekend offer.',      'color':C.cyan,   'icon':Icons.hd_rounded,                  'expiry':'30 Nov 2025'},
    {'code':'FIRSTSHOW', 'title':'15% off on first-day shows','desc':'Be among the first to experience it!',     'color':C.rose,   'icon':Icons.event_rounded,               'expiry':'31 Dec 2025'},
    {'code':'COMBO499',  'title':'Mega Combo at ₹399',         'desc':'Popcorn + 2 drinks. Cinema experience!',  'color':C.green,  'icon':Icons.local_dining_rounded,        'expiry':'25 Dec 2025'},
    {'code':'GOLDPASS',  'title':'Gold Member — free upgrade', 'desc':'Gold tier members get seat upgrades free!','color':C.orange, 'icon':Icons.workspace_premium_rounded,   'expiry':'Ongoing'},
  ];
}

// ─── SHARED WIDGETS ────────────────────────────────────────────────────────
class EdgeHapticScroll extends StatelessWidget {
  final Widget child;
  const EdgeHapticScroll({super.key, required this.child});
  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
    onNotification: (_) => false,
    child: child,
  );
}

class GlassBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius, blur;
  final Color? tint;
  final Border? border;
  const GlassBox({
    super.key, required this.child, this.padding, this.radius = 16,
    this.blur = 16, this.tint, this.border,
  });
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (tint ?? (d ? Colors.white : Colors.black)).withOpacity(d ? 0.07 : 0.05),
            borderRadius: BorderRadius.circular(radius),
            border: border ?? Border.all(
                color: (d ? Colors.white : Colors.black).withOpacity(0.09)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const PressableScale({super.key, required this.child, this.onTap, this.scale = 0.96});
  @override State<PressableScale> createState() => _PSState();
}
class _PSState extends State<PressableScale> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: 100.ms);
    _s = Tween(begin: 1.0, end: widget.scale).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _s,
    child: GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _c.reverse(),
      child: widget.child,
    ),
  );
}

class GoldBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  final IconData? icon;
  final bool fullWidth;
  const GoldBtn({
    super.key, required this.label, this.onTap, this.height = 52,
    this.icon, this.fullWidth = true,
  });
  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: onTap,
    child: Container(
      height: height,
      width: fullWidth ? double.infinity : null,
      padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: onTap == null ? null : C.gradGold,
        color: onTap == null ? Colors.grey.withOpacity(0.3) : null,
        boxShadow: onTap == null ? null : [
          BoxShadow(color: C.gold.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon!, color: Colors.black, size: 18), const SizedBox(width: 8)],
        Text(label, style: TextStyle(
            color: onTap == null ? Colors.white54 : Colors.black,
            fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3)),
      ]),
    ),
  );
}

class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  final IconData? icon;
  const OutlineBtn({super.key, required this.label, this.onTap, this.height = 52, this.icon});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: height, width: double.infinity,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.border(d), width: 1.5),
            color: C.surf(d)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[
            Icon(icon!, color: d ? C.txPrimD : C.txPrimL, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label, style: TextStyle(
              color: d ? C.txPrimD : C.txPrimL,
              fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  final double rating;
  final bool small;
  const RatingBadge(this.rating, {super.key, this.small = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 8, vertical: small ? 2 : 4),
    decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.star_rounded, color: C.gold, size: small ? 10 : 13),
      const SizedBox(width: 3),
      Text(
          rating == 0.0 ? 'N/A' : rating.toStringAsFixed(1),
          style: TextStyle(
              color: Colors.white, fontSize: small ? 10 : 12, fontWeight: FontWeight.w800)),
    ]),
  );
}

class ShimmerBox extends StatelessWidget {
  final double width, height, radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 12});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Shimmer.fromColors(
      baseColor: d ? C.cardDark : C.cardLight,
      highlightColor: d ? C.borderDark : C.borderLight,
      child: Container(
          width: width, height: height,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(radius))),
    );
  }
}

class _WishBtn extends StatelessWidget {
  final OmdbMovie movie;
  final bool small;
  const _WishBtn({required this.movie, this.small = false});
  @override
  Widget build(BuildContext context) {
    final ws  = context.watch<WishlistService>();
    final has = ws.has(movie.imdbId);
    return GestureDetector(
      onTap: () => ws.toggle(movie.imdbId),
      child: Container(
        width: small ? 28 : 32, height: small ? 28 : 32,
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65), shape: BoxShape.circle),
        child: Icon(
            has ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: small ? 14 : 16,
            color: has ? C.gold : Colors.white),
      ),
    );
  }
}

// ─── AUTH SHARED WIDGETS ───────────────────────────────────────────────────
class _AuthBg extends StatelessWidget {
  final bool isDark;
  const _AuthBg({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: isDark
          ? [const Color(0xFF07090F), const Color(0xFF0E1420)]
          : [const Color(0xFFF2F5FF), const Color(0xFFE0E8FF)],
    )),
  );
}

Widget _fld(
    BuildContext ctx, String label, TextEditingController c, IconData icon, {
      bool pass = false, bool pv = false, VoidCallback? tp,
      String? Function(String?)? val, TextInputType? type,
    }) {
  final d = ctx.read<ThemeService>().isDark;
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(
        color: d ? C.txSecD : C.txSecL, fontSize: 11,
        fontWeight: FontWeight.w600, letterSpacing: 0.8)),
    const SizedBox(height: 6),
    TextFormField(
      controller: c, keyboardType: type, obscureText: pass && !pv,
      style: TextStyle(color: d ? C.txPrimD : C.txPrimL),
      validator: val,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: d ? C.txSecD : C.txSecL),
        suffixIcon: pass ? IconButton(
            icon: Icon(
                pv ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size: 18, color: d ? C.txSecD : C.txSecL),
            onPressed: tp) : null,
      ),
    ),
  ]);
}

class _LogoWidget extends StatelessWidget {
  final bool isDark;
  const _LogoWidget({required this.isDark});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13), gradient: C.gradGold,
            boxShadow: [BoxShadow(color: C.gold.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4))]),
        child: const Icon(Icons.movie_filter_rounded, color: Colors.black, size: 26)),
    const SizedBox(width: 12),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CinemaNow', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: isDark ? C.txPrimD : C.txPrimL),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('Book. Watch. Love.', style: TextStyle(
            fontSize: 10, color: isDark ? C.txSecD : C.txSecL, letterSpacing: 0.5),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  ]);
}

class _OrDiv extends StatelessWidget {
  final bool isDark;
  const _OrDiv({required this.isDark});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Container(height: 1, color: C.border(isDark))),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or', style: TextStyle(
            color: isDark ? C.txMutD : C.txMutL, fontSize: 13))),
    Expanded(child: Container(height: 1, color: C.border(isDark))),
  ]);
}

class _GoogleBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleBtn({this.onTap});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 52, width: double.infinity,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.border(d)),
            color: d ? C.surf2Dark : Colors.white),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: const Center(child: Text('G',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF4285F4))))),
          const SizedBox(width: 12),
          Text('Continue with Google', style: TextStyle(
              color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ),
    );
  }
}

class _ErrBox extends StatelessWidget {
  final String msg;
  const _ErrBox(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
        color: C.rose.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.rose.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: C.rose, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: C.rose, fontSize: 13))),
    ]),
  );
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 52,
    child: Center(child: CircularProgressIndicator(color: C.gold, strokeWidth: 2)),
  );
}

// ─── APP ROOT ───────────────────────────────────────────────────────────────
class CinemaNowApp extends StatelessWidget {
  const CinemaNowApp({super.key});
  @override
  Widget build(BuildContext context) {
    final ts = context.watch<ThemeService>();
    return MaterialApp(
      title: 'CinemaNow', debugShowCheckedModeBanner: false,
      theme: buildTheme(false), darkTheme: buildTheme(true), themeMode: ts.mode,
      home: const SplashPage(),
    );
  }
}

// ─── SPLASH PAGE ────────────────────────────────────────────────────────────
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override State<SplashPage> createState() => _SplashState();
}
class _SplashState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _ring, _logo, _text, _glow;

  @override void initState() {
    super.initState();
    _ring = AnimationController(vsync: this, duration: 1200.ms)..forward();
    _glow = AnimationController(vsync: this, duration: 2000.ms);
    _logo = AnimationController(vsync: this, duration: 700.ms);
    _text = AnimationController(vsync: this, duration: 600.ms);
    Future.delayed(400.ms, () => _logo.forward());
    Future.delayed(800.ms, () => _text.forward());
    Future.delayed(600.ms, () => _glow.repeat(reverse: true));
    Future.delayed(2600.ms, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, a, b) => const AuthGate(),
          transitionsBuilder: (_, a, b, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: 600.ms,
        ));
      }
    });
  }
  @override void dispose() {
    _ring.dispose(); _logo.dispose(); _text.dispose(); _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF07090F),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: Listenable.merge([_ring, _glow]),
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [C.gold.withOpacity(0.35 * _glow.value + 0.05), Colors.transparent],
                  radius: 0.8),
              boxShadow: [BoxShadow(
                  color: C.gold.withOpacity(0.25 * _glow.value),
                  blurRadius: 40, spreadRadius: 10)],
            ),
          ),
          Transform.scale(
            scale: Curves.elasticOut.transform(_ring.value.clamp(0, 1)),
            child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, gradient: C.gradGold,
                    boxShadow: [BoxShadow(
                        color: C.gold.withOpacity(0.6), blurRadius: 28, spreadRadius: 4)]),
                child: const Icon(Icons.movie_filter_rounded, color: Colors.black, size: 50)),
          ),
        ]),
      ),
      const SizedBox(height: 28),
      FadeTransition(opacity: _logo, child: const Text('CinemaNow',
          style: TextStyle(
              fontSize: 38, fontWeight: FontWeight.w900, color: Color(0xFFF0F4FF),
              letterSpacing: -1.5, fontFamily: 'Poppins'))),
      const SizedBox(height: 8),
      FadeTransition(opacity: _text, child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 28, height: 1.5, color: C.gold.withOpacity(0.5)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('YOUR CINEMATIC UNIVERSE',
                style: TextStyle(fontSize: 11, color: C.txSecD, letterSpacing: 2, fontWeight: FontWeight.w600))),
        Container(width: 28, height: 1.5, color: C.gold.withOpacity(0.5)),
      ])),
    ])),
  );
}

// ─── AUTH GATE / LOGIN / SIGNUP ────────────────────────────────────────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: C.gold)));
      }
      return snap.hasData ? const MainShell() : const _AuthToggle();
    },
  );
}

class _AuthToggle extends StatefulWidget {
  const _AuthToggle();
  @override State<_AuthToggle> createState() => _AuthToggleState();
}
class _AuthToggleState extends State<_AuthToggle> {
  bool _showLogin = true;
  @override
  Widget build(BuildContext context) => _showLogin
      ? LoginPage(onSwitch: () => setState(() => _showLogin = false))
      : SignupPage(onSwitch: () => setState(() => _showLogin = true));
}

class LoginPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const LoginPage({super.key, required this.onSwitch});
  @override State<LoginPage> createState() => _LoginState();
}
class _LoginState extends State<LoginPage> {
  final _eCtrl = TextEditingController(), _pCtrl = TextEditingController();
  bool _pv = false, _load = false;
  String? _err;
  final _fk = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _load = true);
    final err = await context.read<UserService>().signInWithEmail(
        _eCtrl.text.trim(), _pCtrl.text);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()));
    } else {
      setState(() => _err = err);
    }
    setState(() => _load = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Scaffold(body: Stack(children: [
      _AuthBg(isDark: d),
      SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 56),
          _LogoWidget(isDark: d),
          const SizedBox(height: 48),
          Text('Welcome back 👋', style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.w800, color: d ? C.txPrimD : C.txPrimL)),
          const SizedBox(height: 6),
          Text('Sign in to continue your cinematic journey',
              style: TextStyle(fontSize: 14, color: d ? C.txSecD : C.txSecL)),
          const SizedBox(height: 36),
          _fld(context, 'EMAIL ADDRESS', _eCtrl, Icons.email_outlined,
              type: TextInputType.emailAddress,
              val: (v) => v!.isEmpty ? 'Required' : !v.contains('@') ? 'Invalid email' : null),
          const SizedBox(height: 18),
          _fld(context, 'PASSWORD', _pCtrl, Icons.lock_outline_rounded,
              pass: true, pv: _pv, tp: () => setState(() => _pv = !_pv),
              val: (v) => v!.length < 6 ? 'Min 6 chars' : null),
          Align(alignment: Alignment.centerRight, child: TextButton(
              onPressed: () async {
                final email = _eCtrl.text.trim();
                if (email.isEmpty) { _showSnack(context, 'Enter your email first', C.rose); return; }
                final e = await context.read<UserService>().resetPassword(email);
                if (!mounted) return;
                _showSnack(context, e ?? 'Reset email sent!', e != null ? C.rose : C.green);
              },
              child: const Text('Forgot password?',
                  style: TextStyle(color: C.gold, fontSize: 13, fontWeight: FontWeight.w600)))),
          if (_err != null) _ErrBox(_err!).animate().fadeIn().shakeX(hz: 5),
          const SizedBox(height: 20),
          _load ? const _Loader() : GoldBtn(label: 'Sign In', icon: Icons.arrow_forward_ios_rounded, onTap: _login),
          const SizedBox(height: 20),
          _OrDiv(isDark: d), const SizedBox(height: 20),
          _GoogleBtn(onTap: () async {
            setState(() => _load = true);
            final ok = await context.read<UserService>().signInWithGoogle();
            if (!mounted) return;
            if (ok) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
            } else {
              setState(() => _err = 'Google sign-in failed.');
            }
            setState(() => _load = false);
          }),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Don't have an account? ",
                style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 14)),
            GestureDetector(onTap: widget.onSwitch,
                child: const Text('Create one',
                    style: TextStyle(color: C.gold, fontWeight: FontWeight.w700, fontSize: 14))),
          ]),
          const SizedBox(height: 40),
        ])),
      )),
    ]));
  }
}

class SignupPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const SignupPage({super.key, required this.onSwitch});
  @override State<SignupPage> createState() => _SignupState();
}
class _SignupState extends State<SignupPage> {
  final _nCtrl = TextEditingController(),
      _eCtrl = TextEditingController(),
      _pCtrl = TextEditingController();
  bool _pv = false;
  final _fk = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final d  = context.watch<ThemeService>().isDark;
    final us = context.watch<UserService>();
    return Scaffold(body: Stack(children: [
      _AuthBg(isDark: d),
      SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 40),
          Row(children: [
            PressableScale(
                onTap: widget.onSwitch,
                child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: C.surf(d), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: C.border(d))),
                    child: Icon(Icons.arrow_back_ios_rounded, size: 16, color: d ? C.txPrimD : C.txPrimL))),
            const SizedBox(width: 16),
            Text('Create Account', style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: d ? C.txPrimD : C.txPrimL)),
          ]).animate().fadeIn(),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.only(left: 50),
              child: Text('Join millions of movie lovers',
                  style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 14))),
          const SizedBox(height: 32),
          _fld(context, 'FULL NAME', _nCtrl, Icons.badge_outlined,
              val: (v) => v!.isEmpty ? 'Required' : null).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 18),
          _fld(context, 'EMAIL ADDRESS', _eCtrl, Icons.email_outlined,
              type: TextInputType.emailAddress,
              val: (v) => v!.isEmpty ? 'Required' : !v.contains('@') ? 'Invalid' : null).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 18),
          _fld(context, 'PASSWORD', _pCtrl, Icons.lock_outline_rounded,
              pass: true, pv: _pv, tp: () => setState(() => _pv = !_pv),
              val: (v) => v!.length < 6 ? 'Min 6 chars' : null).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          us.loading ? const _Loader() : GoldBtn(label: 'Create Account', onTap: () async {
            if (!_fk.currentState!.validate()) return;
            final e = await context.read<UserService>().register(
                _nCtrl.text.trim(), _eCtrl.text.trim(), _pCtrl.text);
            if (!mounted) return;
            if (e == null) {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()));
            } else {
              _showSnack(context, e, C.rose);
            }
          }).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 20),
          _OrDiv(isDark: d), const SizedBox(height: 20),
          _GoogleBtn(onTap: () => context.read<UserService>().signInWithGoogle().then((ok) {
            if (ok && mounted) {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()));
            }
          })).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Already have an account? ',
                style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 14)),
            GestureDetector(onTap: widget.onSwitch,
                child: const Text('Sign in',
                    style: TextStyle(color: C.gold, fontWeight: FontWeight.w700, fontSize: 14))),
          ]).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 40),
        ])),
      )),
    ]));
  }
}

// ─── MAIN SHELL ─────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _idx = 0;
  late List<AnimationController> _tabs;
  static const _pages = [HomePage(), SearchPage(), OffersPage(), TicketsPage(), ProfilePage()];
  static const _icons = [
    Icons.home_rounded, Icons.search_rounded,
    Icons.local_offer_rounded, Icons.local_activity_rounded, Icons.person_rounded
  ];
  static const _labels = ['Home', 'Explore', 'Offers', 'Tickets', 'Profile'];

  @override void initState() {
    super.initState();
    _tabs = List.generate(5, (_) => AnimationController(vsync: this, duration: 200.ms));
    _tabs[0].value = 1;
  }
  @override void dispose() { for (var c in _tabs) c.dispose(); super.dispose(); }

  void _tap(int i) {
    _tabs[_idx].reverse();
    setState(() => _idx = i);
    _tabs[i].forward();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: d ? C.surf2Dark : Colors.white,
          border: Border(top: BorderSide(color: C.border(d))),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(d ? 0.4 : 0.08), blurRadius: 20)],
        ),
        child: SafeArea(child: SizedBox(height: 62, child: Row(
          children: List.generate(5, (i) => Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _tap(i),
              child: AnimatedBuilder(
                animation: _tabs[i],
                builder: (_, __) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: _idx == i ? C.gold.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(_icons[i],
                          color: _idx == i ? C.gold : (d ? C.txMutD : C.txMutL),
                          size: 22 + _tabs[i].value * 2)),
                  const SizedBox(height: 2),
                  Text(_labels[i], style: TextStyle(
                      fontSize: 10,
                      fontWeight: _idx == i ? FontWeight.w700 : FontWeight.w400,
                      color: _idx == i ? C.gold : (d ? C.txMutD : C.txMutL))),
                ]),
              ),
            ),
          )),
        ))),
      ),
    );
  }
}

// ─── HOME PAGE ───────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override bool get wantKeepAlive => true;

  final _heroCtrl = PageController(viewportFraction: 0.82);
  late final AnimationController _autoScrollTimer;
  int _heroIdx = 0;
  int _catIdx = 0;
  int _subCatIdx = 0;
  String _genre    = 'All';
  String _language = 'All';
  bool   _showFilters = false;

  static const _catLabels    = ['Now Showing', 'Coming Soon'];
  static const _subCatLabels = ['All', '🎬 Bollywood', '🌟 Hollywood', '🎭 South Indian', '⭐ Top Rated'];
  static const _genres       = ['All', 'Action', 'Drama', 'Comedy', 'Animation', 'Thriller', 'Biography', 'Sci-Fi', 'Horror', 'Romance'];
  static const _langs        = ['All', 'Hindi', 'English', 'Tamil', 'Telugu', 'Malayalam', 'Kannada'];

  @override void initState() {
    super.initState();
    _autoScrollTimer = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _autoScrollTimer.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        _autoScrollTimer.reset();
        _autoScrollTimer.forward();
        final ms = context.read<MovieService>();
        final len = ms.trending.length;
        if (len > 0) {
          final next = (_heroIdx + 1) % len.clamp(1, 10);
          _heroCtrl.animateToPage(next, duration: 800.ms, curve: Curves.fastOutSlowIn);
        }
      }
    });
    _autoScrollTimer.forward();
  }

  @override void dispose() { _heroCtrl.dispose(); _autoScrollTimer.dispose(); super.dispose(); }

  List<OmdbMovie> _moviesForTab(MovieService ms) {
    if (_catIdx == 1) return ms.upcoming;
    switch (_subCatIdx) {
      case 1: return [...ms.bollywoodNew, ...ms.bollywoodClassic];
      case 2: return [...ms.hollywoodNew, ...ms.hollywoodClassic];
      case 3: return [...ms.tollywoodNew, ...ms.tollywoodClassic];
      case 4: return ms.topRated;
      default: return ms.nowPlaying;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d  = context.watch<ThemeService>().isDark;
    final ms = context.watch<MovieService>();

    return Scaffold(
      backgroundColor: C.bg(d),
      extendBodyBehindAppBar: true,
      body: EdgeHapticScroll(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(d, ms),
            SliverToBoxAdapter(child: Column(children: [
              if (ms.trending.isNotEmpty) _buildHeroCarousel(ms.trending, d),
              _buildQuickStats(d, ms),
              _buildCategoryTabs(d),
              if (_catIdx == 0) _buildSubCategoryTabs(d),
              _buildFilterToggle(d),
              if (_showFilters) ...[
                _buildGenreChips(d),
                _buildLanguageChips(d),
              ],
              const SizedBox(height: 24),
            ])),
            _buildMovieGridSliver(ms, d),
            if (_catIdx == 0 && _subCatIdx == 0) ...[
              SliverToBoxAdapter(child: Column(children: [
                const SizedBox(height: 16),
                if (ms.trending.isNotEmpty)
                  _buildHorizontalSection('🔥 Trending Now', ms.trending, d, accent: C.rose),
                if (ms.bollywoodNew.isNotEmpty)
                  _buildHorizontalSection('🎬 Bollywood Hits', ms.bollywoodNew, d, accent: C.bollywood),
                if (ms.tollywoodNew.isNotEmpty)
                  _buildHorizontalSection('🎭 South Indian', ms.tollywoodNew, d, accent: C.tollywood),
                if (ms.hollywoodNew.isNotEmpty)
                  _buildHorizontalSection('🌟 Hollywood', ms.hollywoodNew, d, accent: C.hollywood),
                if (ms.topRated.isNotEmpty)
                  _buildHorizontalSection('⭐ All-Time Greats', ms.topRated, d, accent: C.gold),
              ])),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool d, MovieService ms) => SliverAppBar(
    floating: true, pinned: true,
    backgroundColor: C.bg(d).withOpacity(0.7),
    elevation: 0,
    flexibleSpace: ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(color: Colors.transparent),
      ),
    ),
    title: _LogoWidget(isDark: d),
    actions: [
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
        child: Stack(children: [
          Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: d ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: d ? Colors.white10 : Colors.black12)),
              child: const Icon(Icons.notifications_outlined, size: 18, color: C.txSecD)),
          Positioned(top: 6, right: 6, child: Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(color: C.rose, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: C.rose, blurRadius: 4)]))),
        ]),
      ),
      IconButton(
          icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: d ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: d ? Colors.white10 : Colors.black12)),
              child: Icon(d ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 18, color: d ? C.txSecD : C.txSecL)),
          onPressed: () => context.read<ThemeService>().toggle()),
      const SizedBox(width: 4),
    ],
  );

  Widget _buildHeroCarousel(List<OmdbMovie> movies, bool d) {
    final ms = context.read<MovieService>();
    final limited = movies.take(10).toList();
    return RepaintBoundary(
      child: Column(children: [
        SizedBox(
          height: 460,
          child: PageView.builder(
            controller: _heroCtrl,
            itemCount: limited.length,
            onPageChanged: (i) => setState(() => _heroIdx = i),
            itemBuilder: (ctx, i) {
              final m   = limited[i];
              final sel = i == _heroIdx;
              final isComingSoon = ms.upcoming.any((mov) => mov.imdbId == m.imdbId);
              return AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeOutQuart,
                margin: EdgeInsets.only(
                  top: sel ? 20 : 50, bottom: sel ? 20 : 40, right: 12, left: 12,
                ),
                child: _HeroCard(movie: m, selected: sel, isComingSoon: isComingSoon),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(limited.length, (i) => AnimatedContainer(
              duration: 300.ms, margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _heroIdx ? 28 : 8, height: 8,
              decoration: BoxDecoration(
                color: i == _heroIdx ? C.gold : (d ? Colors.white24 : Colors.black26),
                borderRadius: BorderRadius.circular(4),
                boxShadow: i == _heroIdx ? [BoxShadow(color: C.gold.withOpacity(0.6), blurRadius: 10)] : null,
              ),
            ))),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildQuickStats(bool d, MovieService ms) {
    final total = MovieDatabase.all.length;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: GlassBox(
          radius: 20, blur: 15, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          border: Border.all(color: d ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _StatChip(Icons.movie_rounded, '$total+ Movies', C.gold, d),
            Container(width: 1, height: 28, color: d ? Colors.white10 : Colors.black12),
            _StatChip(Icons.theaters_rounded, '5 Theaters', C.cyan, d),
            Container(width: 1, height: 28, color: d ? Colors.white10 : Colors.black12),
            _StatChip(Icons.local_offer_rounded, '6 Offers', C.green, d),
          ]).animate().fadeIn(delay: 200.ms),
        )
    );
  }

  Widget _buildCategoryTabs(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
    child: SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _catLabels.length,
        itemBuilder: (_, i) {
          final sel = i == _catIdx;
          return GestureDetector(
            onTap: () => setState(() { _catIdx = i; _subCatIdx = 0; _genre = 'All'; _language = 'All'; }),
            child: AnimatedContainer(
              duration: 300.ms, margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: sel ? C.gradGold : null,
                color: sel ? null : (d ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? C.gold.withOpacity(0.5) : (d ? Colors.white10 : Colors.black12)),
                boxShadow: sel ? [BoxShadow(color: C.gold.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))] : null,
              ),
              child: Row(children: [
                if (sel) ...[
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                ],
                Text(_catLabels[i], style: TextStyle(
                    color: sel ? Colors.black : (d ? C.txSecD : C.txSecL),
                    fontWeight: FontWeight.w800, fontSize: 14)),
              ]),
            ),
          );
        },
      ),
    ),
  );

  Widget _buildSubCategoryTabs(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
    child: SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _subCatLabels.length,
        itemBuilder: (_, i) {
          final sel = i == _subCatIdx;
          return GestureDetector(
            onTap: () => setState(() { _subCatIdx = i; _genre = 'All'; _language = 'All'; }),
            child: AnimatedContainer(
              duration: 200.ms, margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? C.gold.withOpacity(0.15) : (d ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: sel ? C.gold : (d ? Colors.white10 : Colors.black12)),
                boxShadow: sel ? [BoxShadow(color: C.gold.withOpacity(0.1), blurRadius: 8)] : null,
              ),
              child: Text(_subCatLabels[i], style: TextStyle(
                  color: sel ? C.gold : (d ? C.txSecD : C.txSecL),
                  fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          );
        },
      ),
    ),
  );

  Widget _buildFilterToggle(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: GestureDetector(
      onTap: () => setState(() => _showFilters = !_showFilters),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _showFilters ? C.gold.withOpacity(0.12) : (d ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _showFilters ? C.gold : (d ? Colors.white10 : Colors.black12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune_rounded, color: _showFilters ? C.gold : (d ? C.txSecD : C.txSecL), size: 16),
          const SizedBox(width: 8),
          Text("Filter & Sort", style: TextStyle(
              color: _showFilters ? C.gold : (d ? C.txSecD : C.txSecL),
              fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Icon(_showFilters ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: _showFilters ? C.gold : (d ? C.txMutD : C.txMutL), size: 18),
          if (_genre != "All" || _language != "All") ...[
            const SizedBox(width: 10),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: C.gold.withOpacity(0.5), blurRadius: 4)]),
                child: const Text("Active", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800))),
          ],
        ]),
      ),
    ),
  );

  Widget _buildGenreChips(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 16, bottom: 10),
          child: Text("Genre", style: TextStyle(
              color: d ? C.txSecD : C.txSecL, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
      SizedBox(height: 38, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _genres.length,
        itemBuilder: (_, i) {
          final g = _genres[i]; final sel = g == _genre;
          return GestureDetector(
            onTap: () => setState(() => _genre = g),
            child: AnimatedContainer(
              duration: 200.ms, margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  gradient: sel ? C.gradGold : null,
                  color: sel ? null : (d ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? C.gold : (d ? Colors.white10 : Colors.black12))),
              child: Text(g, style: TextStyle(
                  color: sel ? Colors.black : (d ? C.txSecD : C.txSecL),
                  fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          );
        },
      )),
    ]),
  );

  Widget _buildLanguageChips(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 16, bottom: 10),
          child: Text("Language", style: TextStyle(
              color: d ? C.txSecD : C.txSecL, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
      SizedBox(height: 38, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _langs.length,
        itemBuilder: (_, i) {
          final l = _langs[i]; final sel = l == _language;
          return GestureDetector(
            onTap: () => setState(() => _language = l),
            child: AnimatedContainer(
              duration: 200.ms, margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: sel ? C.indigo.withOpacity(0.2) : (d ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? C.indigo : (d ? Colors.white10 : Colors.black12))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.language_rounded, size: 14, color: sel ? C.indigo : (d ? C.txMutD : C.txMutL)),
                const SizedBox(width: 6),
                Text(l, style: TextStyle(
                    color: sel ? C.indigo : (d ? C.txMutD : C.txMutL),
                    fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          );
        },
      )),
      const SizedBox(height: 8),
    ]),
  );

  Widget _buildMovieGridSliver(MovieService ms, bool d) {
    var movies = _moviesForTab(ms);
    if (_genre    != "All") movies = movies.where((m) => m.genres.contains(_genre)).toList();
    if (_language != "All") movies = movies.where((m) => m.languages.contains(_language)).toList();

    if (ms.loadingHero && movies.isEmpty) return _buildShimmerGridSliver();

    if (movies.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(children: [
            Icon(Icons.search_off_rounded, color: d ? C.txMutD : C.txMutL, size: 56),
            const SizedBox(height: 16),
            Text("No movies match your filters",
                style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 16)),
            const SizedBox(height: 16),
            TextButton(
                onPressed: () => setState(() { _genre = "All"; _language = "All"; }),
                child: const Text("Clear filters",
                    style: TextStyle(color: C.gold, fontWeight: FontWeight.w800, fontSize: 15))),
          ]),
        ),
      );
    }

    final currentTitle = _catIdx == 0
        ? (_subCatIdx == 0 ? "Now Showing" : _subCatLabels[_subCatIdx])
        : "Coming Soon";

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Row(children: [
              Container(width: 5, height: 20,
                  decoration: BoxDecoration(gradient: C.gradGold, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 12),
              Text(currentTitle, style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: d ? C.txPrimD : C.txPrimL)),
              const Spacer(),
              Text('${movies.length} movies',
                  style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 13)),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.60,
                crossAxisSpacing: 16, mainAxisSpacing: 20),
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _GridCard(movie: movies[i])
                  .animate().fadeIn(delay: (i * 30).ms)
                  .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic),
              childCount: movies.length > 10 ? 10 : movies.length,
            ),
          ),
          if (movies.length > 10)
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.only(top: 20),
                  child: GoldBtn(
                    label: 'See all ${movies.length} movies', height: 52,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AllMoviesPage(title: currentTitle, movies: movies))),
                  )),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerGridSliver() => SliverPadding(
    padding: const EdgeInsets.all(16),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.60,
          crossAxisSpacing: 16, mainAxisSpacing: 20),
      delegate: SliverChildBuilderDelegate(
              (_, __) => const ShimmerBox(width: double.infinity, height: double.infinity, radius: 20),
          childCount: 6),
    ),
  );

  Widget _buildHorizontalSection(String title, List<OmdbMovie> movies, bool d, {Color accent = C.gold}) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 16), child: Row(children: [
        Container(width: 5, height: 20,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 6)])),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w900, color: d ? C.txPrimD : C.txPrimL))),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AllMoviesPage(title: title, movies: movies))),
          child: Row(children: [
            Text("See all", style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w700)),
            Icon(Icons.chevron_right_rounded, color: accent, size: 18),
          ]),
        ),
      ])),
      RepaintBoundary(child: SizedBox(height: 285, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        cacheExtent: 500.0,
        itemBuilder: (ctx, i) => Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 20),
            child: _PosterCard(movie: movies[i], accent: accent))
            .animate().fadeIn(delay: (i * 30).ms),
      ))),
    ]);
  }
}

// ─── STAT CHIP ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon; final String label; final Color color; final bool isDark;
  const _StatChip(this.icon, this.label, this.color, this.isDark);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15), shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(color: isDark ? C.txPrimD : C.txPrimL, fontSize: 13, fontWeight: FontWeight.w800)),
  ]);
}

// ─── HERO CARD ─────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final OmdbMovie movie; final bool selected; final bool isComingSoon;
  const _HeroCard({required this.movie, this.selected = true, this.isComingSoon = false});

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return PressableScale(
      onTap: () => _toDetail(context, movie),
      scale: 0.96,
      child: Hero(
        tag: 'poster-${movie.imdbId}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: selected ? [
              BoxShadow(color: C.gold.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 15))
            ] : [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(fit: StackFit.expand, children: [
              CachedNetworkImage(
                imageUrl: movie.posterUrl, fit: BoxFit.cover,
                fadeInDuration: 400.ms, fadeOutDuration: 200.ms,
                memCacheHeight: 800,
                placeholder: (_, __) => const ShimmerBox(width: double.infinity, height: double.infinity, radius: 0),
                errorWidget: (_, __, ___) => Container(
                    color: C.card(d),
                    child: const Center(child: Icon(Icons.movie_rounded, color: C.gold, size: 52))),
              ),
              Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.95)],
                  stops: const [0.3, 1.0]))),
              Positioned(top: 16, right: 16,
                  child: Row(children: [
                    if (movie.hasTrailer)
                      const GlassBox(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          radius: 20, blur: 15, tint: Colors.black,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.play_circle_filled_rounded, color: C.rose, size: 16),
                            SizedBox(width: 6),
                            Text("TRAILER", style: TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ])),
                  ])),
              Positioned(top: 16, left: 16,
                  child: GlassBox(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      radius: 20, blur: 15, tint: Colors.black,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(isComingSoon ? Icons.event_available_rounded : Icons.local_fire_department_rounded,
                            color: C.gold, size: 14),
                        const SizedBox(width: 6),
                        Text(isComingSoon ? "COMING SOON" : "TRENDING", style: const TextStyle(
                            color: C.gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ]))),
              Positioned(bottom: 24, left: 24, right: 24, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(spacing: 8, children: movie.genres.take(3).map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white30)),
                      child: Text(g, style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))).toList()),
                  const SizedBox(height: 12),
                  Text(movie.title, style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900,
                      height: 1.1, shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))]),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(children: [
                    RatingBadge(movie.rating),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(movie.year, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                    if (movie.languages.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.language_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(movie.languages.first, style: const TextStyle(
                          color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ]),
                  if (selected) ...[
                    const SizedBox(height: 18),
                    PressableScale(
                      onTap: isComingSoon ? null : () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => TheaterSelectPage(movie: movie))),
                      child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              gradient: isComingSoon ? null : C.gradGold,
                              color: isComingSoon ? Colors.white.withOpacity(0.2) : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isComingSoon ? null : [BoxShadow(
                                  color: C.gold.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))]),
                          child: Text(isComingSoon ? "Notify Me" : "Book Tickets",
                              style: TextStyle(
                                  color: isComingSoon ? Colors.white70 : Colors.black,
                                  fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  ]
                ],
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── POSTER CARD ───────────────────────────────────────────────────────────
class _PosterCard extends StatelessWidget {
  final OmdbMovie movie; final Color accent;
  const _PosterCard({required this.movie, this.accent = C.gold});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return PressableScale(
      onTap: () => _toDetail(context, movie),
      scale: 0.95,
      child: SizedBox(width: 140, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Hero(
              tag: 'poster-${movie.imdbId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl, width: 140, height: 200, fit: BoxFit.cover,
                  fadeInDuration: 300.ms, memCacheHeight: 400,
                  placeholder: (_, __) => const ShimmerBox(width: 140, height: 200, radius: 20),
                  errorWidget: (_, __, ___) => Container(
                      width: 140, height: 200,
                      decoration: BoxDecoration(color: C.card(d), borderRadius: BorderRadius.circular(20)),
                      child: const Center(child: Icon(Icons.movie_rounded, color: C.gold, size: 40))),
                ),
              ),
            ),
          ),
          Positioned(top: 10, right: 10, child: RatingBadge(movie.rating, small: true)),
          Positioned(top: 10, left: 10, child: _WishBtn(movie: movie, small: true)),
          if (movie.hasTrailer)
            Positioned(bottom: -10, right: 10, child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(gradient: C.gradRose, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: C.rose.withOpacity(0.5), blurRadius: 8)]),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20))),
        ]),
        const SizedBox(height: 16),
        Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 4),
        Text(movie.genres.isNotEmpty ? movie.genres.first : "",
            style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12, fontWeight: FontWeight.w600)),
      ])),
    );
  }
}

// ─── GRID CARD ─────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final OmdbMovie movie;
  const _GridCard({required this.movie});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return PressableScale(
      onTap: () => _toDetail(context, movie),
      scale: 0.96,
      child: Container(
        decoration: BoxDecoration(
          color: C.card(d), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border(d)),
          boxShadow: d ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
              : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(fit: StackFit.expand, children: [
              Hero(
                tag: 'poster-${movie.imdbId}',
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl, fit: BoxFit.cover,
                  fadeInDuration: 300.ms, memCacheHeight: 400,
                  placeholder: (_, __) => const ShimmerBox(width: double.infinity, height: double.infinity, radius: 0),
                  errorWidget: (_, __, ___) => Container(
                      color: C.card(d), child: const Center(child: Icon(Icons.movie_rounded, color: C.gold, size: 40))),
                ),
              ),
              Positioned.fill(child: Container(decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      stops: const [0, 0.6])))),
              Positioned(bottom: 10, left: 10, right: 10,
                  child: Row(children: [
                    RatingBadge(movie.rating, small: true),
                    const Spacer(),
                    _WishBtn(movie: movie, small: true),
                  ])),
              if (movie.hasTrailer)
                Positioned(top: 10, right: 10, child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: C.rose.withOpacity(0.9), shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: C.rose.withOpacity(0.5), blurRadius: 6)]),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14))),
            ]),
          )),
          Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 4),
            Text(movie.genres.take(2).join(" · "),
                style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          ),
        ]),
      ),
    );
  }
}

// ─── ALL MOVIES PAGE ───────────────────────────────────────────────────────
class AllMoviesPage extends StatelessWidget {
  final String title; final List<OmdbMovie> movies;
  const AllMoviesPage({super.key, required this.title, required this.movies});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Scaffold(
      backgroundColor: C.bg(d),
      appBar: AppBar(title: Text(title)),
      body: EdgeHapticScroll(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.62,
              crossAxisSpacing: 12, mainAxisSpacing: 16),
          itemCount: movies.length,
          itemBuilder: (_, i) => _GridCard(movie: movies[i]).animate().fadeIn(delay: (i * 40).ms),
        ),
      ),
    );
  }
}

// ─── MOVIE DETAIL PAGE ─────────────────────────────────────────────────────
class MovieDetailPage extends StatefulWidget {
  final OmdbMovie movie;
  const MovieDetailPage({super.key, required this.movie});
  @override State<MovieDetailPage> createState() => _MovieDetailState();
}
class _MovieDetailState extends State<MovieDetailPage> with TickerProviderStateMixin {
  late TabController _tabs;
  OmdbMovieDetail? _detail;
  bool _loading = true, _expanded = false;
  YoutubePlayerController? _yt;
  int _activeTab = 0;

  @override void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      setState(() => _activeTab = _tabs.index);
    });
    _loadDetail();
  }
  @override void dispose() { _tabs.dispose(); _yt?.dispose(); super.dispose(); }

  Future<void> _loadDetail() async {
    final d = await context.read<MovieService>().fetchDetail(widget.movie.imdbId);
    if (!mounted) return;
    setState(() {
      _detail  = d;
      _loading = false;
      if (d?.youtubeId != null && d!.youtubeId!.isNotEmpty) {
        _yt = YoutubePlayerController(
            initialVideoId: d.youtubeId!,
            flags: const YoutubePlayerFlags(
                autoPlay: false, mute: false, isLive: false,
                enableCaption: true, loop: false,
                hideControls: false, controlsVisibleAtStart: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movie;
    final d = context.watch<ThemeService>().isDark;
    final ms = context.watch<MovieService>();
    final isComingSoon = ms.upcoming.any((mov) => mov.imdbId == m.imdbId);
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: C.bg(d),
      body: EdgeHapticScroll(
        child: CustomScrollView(slivers: [
          _buildAppBar(m, d),
          SliverToBoxAdapter(child: Column(children: [
            _buildMeta(d),
            _buildTabs(context, m, d),
            const SizedBox(height: 120),
          ])),
        ]),
      ),
      floatingActionButton: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw > 600 ? sw * 0.2 : 24),
          child: GoldBtn(
              label: isComingSoon ? '🔔  Notify Me' : '🎬  Book Tickets Now',
              onTap: isComingSoon
                  ? () => _showSnack(context, "We'll notify you when tickets go live!", C.cyan)
                  : () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TheaterSelectPage(movie: m)))),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar(OmdbMovie m, bool d) => SliverAppBar(
    expandedHeight: 330, pinned: true, stretch: true, backgroundColor: C.bg(d),
    leading: IconButton(
        icon: GlassBox(padding: const EdgeInsets.all(7), radius: 10, blur: 10,
            child: Icon(Icons.arrow_back_ios_rounded, size: 16, color: d ? Colors.white : Colors.black)),
        onPressed: () => Navigator.pop(context)),
    actions: [
      _WishBtn(movie: m),
      const SizedBox(width: 8),
      GestureDetector(
          onTap: () => Share.share('🎬 Watch ${m.title} on CinemaNow!'),
          child: GlassBox(padding: const EdgeInsets.all(7), radius: 10, blur: 10,
              child: Icon(Icons.share_rounded, size: 16, color: d ? Colors.white : Colors.black))),
      const SizedBox(width: 12),
    ],
    flexibleSpace: FlexibleSpaceBar(
      stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
      background: Hero(
        tag: 'poster-${m.imdbId}',
        child: Stack(fit: StackFit.expand, children: [
          CachedNetworkImage(
              imageUrl: m.posterUrl, fit: BoxFit.cover, alignment: Alignment.topCenter,
              fadeInDuration: 400.ms, memCacheHeight: 660,
              placeholder: (_, __) => ShimmerBox(width: double.infinity, height: 330, radius: 0),
              errorWidget: (_, __, ___) => Container(color: C.card(d))),
          Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, C.bg(d)], stops: const [0.35, 1.0]))),
          Positioned(left: 20, right: 20, bottom: 20,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)]),
                    child: ClipRRect(borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(imageUrl: m.posterUrl, width: 82, height: 116, fit: BoxFit.cover,
                            fadeInDuration: 200.ms, memCacheHeight: 232,
                            placeholder: (_, __) => ShimmerBox(width: 82, height: 116, radius: 14),
                            errorWidget: (_, __, ___) => Container(width: 82, height: 116, color: C.card(d))))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(m.title, style: TextStyle(
                      color: d ? Colors.white : C.txPrimL, fontSize: 20, fontWeight: FontWeight.w800),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    RatingBadge(m.rating),
                    const SizedBox(width: 8),
                    Text('${_fmtNum(m.voteCount)} votes',
                        style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: m.genres.take(3).map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: d ? C.surf2Dark : C.cardLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: C.border(d))),
                      child: Text(g, style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 11)))).toList()),
                ])),
              ])),
        ]),
      ),
    ),
  );

  Widget _buildMeta(bool d) {
    final lang = _detail?.languages.isNotEmpty == true ? _detail!.languages.first : widget.movie.languages.firstOrNull ?? '—';
    return Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _MetaTile(Icons.schedule_rounded, '—', 'Duration'),
          _VertDiv(d),
          _MetaTile(Icons.calendar_today_rounded, widget.movie.year, 'Year'),
          _VertDiv(d),
          _MetaTile(Icons.language_rounded, lang, 'Language'),
          _VertDiv(d),
          _MetaTile(Icons.verified_rounded, 'UA', 'Rated'),
        ]));
  }

  Widget _buildTabs(BuildContext ctx, OmdbMovie m, bool d) => Column(children: [
    Container(
      margin: const EdgeInsets.fromLTRB(12, 20, 12, 20),
      decoration: BoxDecoration(
          color: d ? C.surf2Dark : C.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.border(d))),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(gradient: C.gradGold, borderRadius: BorderRadius.circular(10)),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        labelColor: Colors.black,
        unselectedLabelColor: d ? C.txSecD : C.txSecL,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5, fontFamily: 'Poppins'),
        tabs: const [Tab(text: 'Trailer'), Tab(text: 'Overview'), Tab(text: 'Cast'), Tab(text: 'Reviews')],
      ),
    ),
    AnimatedSwitcher(
      duration: 300.ms,
      child: SizedBox(
        key: ValueKey<int>(_activeTab),
        child: _activeTab == 0 ? _trailerTab(d)
            : _activeTab == 1 ? _overviewTab(m, d)
            : _activeTab == 2 ? _castTab(d)
            : _reviewsTab(d),
      ),
    ),
  ]);

  Widget _trailerTab(bool d) {
    if (_loading) return const Center(child: Padding(
        padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: C.gold, strokeWidth: 2)));
    if (_yt == null) return Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 64, height: 64,
              decoration: BoxDecoration(color: C.rose.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.play_circle_outline_rounded, color: C.rose, size: 40)),
          const SizedBox(height: 16),
          Text('Trailer not available', style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 14)),
        ])));
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(18),
          child: YoutubePlayer(
              controller: _yt!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: C.gold,
              progressColors: const ProgressBarColors(
                  playedColor: C.gold, handleColor: C.goldGlow))),
      const SizedBox(height: 16),
      Row(children: [
        const Icon(Icons.youtube_searched_for_rounded, color: C.rose, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('Official Theatrical Trailer',
            style: TextStyle(color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w600, fontSize: 14))),
        IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: C.gold, size: 18),
            onPressed: () => Share.share('https://youtu.be/${_detail!.youtubeId}')),
      ]),
    ]));
  }

  Widget _overviewTab(OmdbMovie m, bool d) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedCrossFade(
          duration: 300.ms,
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Text(m.overview.isEmpty ? 'No plot summary available.' : m.overview,
              maxLines: 4, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: d ? C.txSecD : C.txSecL, height: 1.6, fontSize: 14)),
          secondChild: Text(m.overview.isEmpty ? 'No plot summary available.' : m.overview,
              style: TextStyle(color: d ? C.txSecD : C.txSecL, height: 1.6, fontSize: 14)),
        ),
      ),
      TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: C.gold, size: 16),
          label: Text(_expanded ? 'Less' : 'Read more',
              style: const TextStyle(color: C.gold, fontSize: 13))),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _StatCard('IMDb', m.ratingStr, C.gold)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard('Votes', _fmtNum(m.voteCount), C.cyan)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard('Year', m.year, C.purple)),
      ]),
      const SizedBox(height: 20),
      Text('Rating Breakdown',
          style: TextStyle(color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 12),
      ...[5, 4, 3, 2, 1].map((s) => _ratingBar(s, d)),
    ]),
  );

  Widget _ratingBar(int stars, bool d) {
    const pcts = [0.52, 0.28, 0.12, 0.05, 0.03];
    final p = pcts[5 - stars];
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
      Row(children: List.generate(stars, (_) => const Icon(Icons.star_rounded, color: C.gold, size: 12))),
      const SizedBox(width: 8),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: p, minHeight: 6,
              backgroundColor: d ? C.borderDark : C.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(C.gold)))),
      const SizedBox(width: 8),
      SizedBox(width: 32, child: Text('${(p * 100).toInt()}%',
          style: TextStyle(color: d ? C.txMutD : C.txMutL, fontSize: 11), textAlign: TextAlign.right)),
    ]));
  }

  Widget _castTab(bool d) => Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline_rounded, size: 48, color: d ? C.txMutD : C.txMutL),
        const SizedBox(height: 16),
        Text('Cast info not available', style: TextStyle(color: d ? C.txSecD : C.txSecL)),
        const SizedBox(height: 8),
        Text('Add cast data to Firestore to display here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: d ? C.txMutD : C.txMutL, fontSize: 12)),
      ])));

  Widget _reviewsTab(bool d) {
    final user = context.watch<UserService>().user;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('movies').doc(widget.movie.imdbId)
          .collection('reviews').orderBy('createdAt', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) return Center(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text('Error loading reviews', style: TextStyle(color: C.rose, fontSize: 13))));
        if (snap.connectionState == ConnectionState.waiting) return const Center(
            child: Padding(padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: C.gold, strokeWidth: 2)));
        final reviews = snap.hasData
            ? snap.data!.docs.map((d) => MovieReview.fromMap(d.id, d.data() as Map<String, dynamic>)).toList()
            : <MovieReview>[];
        return Padding(padding: const EdgeInsets.all(20), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${reviews.length} Reviews', style: TextStyle(
                color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 16)),
            TextButton.icon(
                onPressed: () => _showReviewDialog(context, user, d),
                icon: const Icon(Icons.rate_review_outlined, color: C.gold, size: 18),
                label: const Text('Write', style: TextStyle(color: C.gold, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 16),
          if (reviews.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Icon(Icons.rate_review_outlined, size: 48, color: d ? C.txMutD : C.txMutL),
                  const SizedBox(height: 12),
                  Text('No reviews yet. Be the first!',
                      style: TextStyle(color: d ? C.txSecD : C.txSecL)),
                ])))
          else
            ...reviews.map((r) => _reviewItem(r, d)),
        ]));
      },
    );
  }

  Widget _reviewItem(MovieReview r, bool d) => Container(
    margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border(d))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 16, backgroundColor: C.gold.withOpacity(0.2),
            backgroundImage: r.photoUrl.isNotEmpty ? CachedNetworkImageProvider(r.photoUrl) : null,
            child: r.photoUrl.isEmpty ? Text(r.userName[0],
                style: const TextStyle(color: C.gold, fontWeight: FontWeight.w800)) : null),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.userName, style: TextStyle(
              color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(DateFormat('MMM dd, yyyy').format(r.createdAt),
              style: TextStyle(color: d ? C.txMutD : C.txMutL, fontSize: 11)),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(gradient: C.gradGold, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: Colors.black, size: 12),
              const SizedBox(width: 3),
              Text('${r.rating}', style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12)),
            ])),
      ]),
      const SizedBox(height: 10),
      Text(r.content, style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 13, height: 1.5)),
    ]),
  );

  void _showReviewDialog(BuildContext ctx, AppUser? user, bool d) {
    if (user == null) { _showSnack(context, 'Login to write a review!', C.rose); return; }
    final c = TextEditingController();
    double rating = 5.0;
    showModalBottomSheet(
        context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => StatefulBuilder(builder: (ctx, setS) => GlassBox(
          radius: 24, blur: 20,
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Write a Review', style: TextStyle(
                color: d ? C.txPrimD : C.txPrimL, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Text('Rating: ${rating.toStringAsFixed(1)}',
                style: TextStyle(color: d ? C.txSecD : C.txSecL, fontWeight: FontWeight.w700)),
            Slider(value: rating, min: 1, max: 10, divisions: 18,
                activeColor: C.gold, inactiveColor: C.border(d),
                onChanged: (v) => setS(() => rating = v)),
            TextField(controller: c, maxLines: 3,
                style: TextStyle(color: d ? C.txPrimD : C.txPrimL),
                decoration: InputDecoration(
                    hintText: 'Share your cinematic experience…',
                    hintStyle: TextStyle(color: d ? C.txMutD : C.txMutL))),
            const SizedBox(height: 24),
            GoldBtn(label: 'Submit Review', onTap: () async {
              if (c.text.isEmpty) return;
              final r = MovieReview(
                  id: '', userName: user.displayName, userId: user.uid,
                  content: c.text, rating: rating, createdAt: DateTime.now(),
                  photoUrl: user.photoUrl);
              await FirebaseFirestore.instance
                  .collection('movies').doc(widget.movie.imdbId)
                  .collection('reviews').add(r.toMap());
              if (!mounted) return;
              Navigator.pop(ctx);
              _showSnack(context, 'Review submitted! 🎥', C.green);
            }),
          ]),
        )));
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon; final String value, label;
  const _MetaTile(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Column(children: [
      Icon(icon, color: C.gold, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w700, fontSize: 13)),
      Text(label, style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 10)),
    ]);
  }
}
class _VertDiv extends StatelessWidget {
  final bool d; const _VertDiv(this.d);
  @override Widget build(BuildContext context) => Container(width: 1, height: 36, color: C.border(d));
}
class _StatCard extends StatelessWidget {
  final String label, value; final Color color;
  const _StatCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: C.txMutD, fontSize: 11)),
    ]),
  );
}

// ─── SEARCH PAGE ────────────────────────────────────────────────────────────
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override State<SearchPage> createState() => _SearchState();
}
class _SearchState extends State<SearchPage> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  final _c = TextEditingController();
  List<OmdbMovie> _results = [];
  bool _searching = false;
  final List<String> _history = [];

  void _search(String q) {
    if (q.isEmpty) { setState(() { _searching = false; _results = []; }); return; }
    setState(() { _searching = true; _results = MovieDatabase.search(q); });
  }

  void _addToHistory(String q) {
    if (q.isNotEmpty && !_history.contains(q)) {
      setState(() { _history.insert(0, q); if (_history.length > 6) _history.removeLast(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d  = context.watch<ThemeService>().isDark;
    final ms = context.watch<MovieService>();
    return Scaffold(
      backgroundColor: C.bg(d),
      body: SafeArea(
        child: EdgeHapticScroll(
          child: CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _c,
                  onChanged: _search,
                  onSubmitted: (q) { _addToHistory(q); _search(q); },
                  style: TextStyle(color: d ? C.txPrimD : C.txPrimL),
                  decoration: InputDecoration(
                      hintText: 'Search Hollywood, Bollywood, South…',
                      hintStyle: TextStyle(color: d ? C.txMutD : C.txMutL),
                      prefixIcon: const Icon(Icons.search_rounded, color: C.gold, size: 20),
                      suffixIcon: _searching
                          ? IconButton(
                          icon: Icon(Icons.close_rounded, color: d ? C.txSecD : C.txSecL),
                          onPressed: () { _c.clear(); _search(''); })
                          : null),
                ),
              ),
            ),
            if (!_searching) ...[
              if (_history.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Row(children: [
                      Text('Recent', style: TextStyle(
                          color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 16)),
                      const Spacer(),
                      TextButton(
                          onPressed: () => setState(() => _history.clear()),
                          child: const Text('Clear', style: TextStyle(color: C.rose, fontSize: 12))),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(spacing: 8, runSpacing: 8, children: _history.map((t) => GestureDetector(
                        onTap: () { _c.text = t; _search(t); },
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                                color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: C.border(d))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.history_rounded, size: 13, color: d ? C.txMutD : C.txMutL),
                              const SizedBox(width: 6),
                              Text(t, style: TextStyle(color: d ? C.txPrimD : C.txPrimL, fontSize: 13)),
                            ])))).toList()),
                  ),
                ),
              ],
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text('Popular Searches', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    'RRR', 'Nolan', 'SRK', 'Vijay', 'Prabhas', 'Avengers',
                    'Horror', 'Sci-Fi', 'Bollywood', 'Tollywood', 'Animated', 'Thriller'
                  ].map((t) => GestureDetector(
                      onTap: () { _c.text = t; _search(t); },
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: C.border(d))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.trending_up_rounded, size: 13, color: C.gold),
                            const SizedBox(width: 6),
                            Text(t, style: TextStyle(color: d ? C.txPrimD : C.txPrimL, fontSize: 13)),
                          ])))).toList()),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 14),
                sliver: SliverToBoxAdapter(
                  child: Text('Discover', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              _buildSearchListSliver([...ms.nowPlaying, ...ms.trending]),
            ] else ...[
              if (_results.isEmpty)
                SliverFillRemaining(child: _empty(d))
              else
                _buildSearchListSliver(_results),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchListSliver(List<OmdbMovie> movies) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
            (ctx, i) => _SearchTile(movie: movies[i]).animate().fadeIn(delay: (i * 30).ms),
        childCount: movies.length,
      ),
    ),
  );

  Widget _empty(bool d) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.search_off_rounded, color: C.txMutD, size: 52),
    const SizedBox(height: 14),
    Text('No results for "${_c.text}"',
        style: TextStyle(color: d ? C.txSecD : C.txSecL)),
  ]));
}

class _SearchTile extends StatelessWidget {
  final OmdbMovie movie;
  const _SearchTile({required this.movie});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return PressableScale(
      onTap: () => _toDetail(context, movie),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.border(d))),
        child: Row(children: [
          Hero(
            tag: 'poster-${movie.imdbId}',
            child: ClipRRect(borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(imageUrl: movie.posterUrl, width: 54, height: 76, fit: BoxFit.cover,
                    fadeInDuration: 200.ms, memCacheHeight: 152,
                    placeholder: (_, __) => const ShimmerBox(width: 54, height: 76, radius: 10),
                    errorWidget: (_, __, ___) => Container(width: 54, height: 76, color: C.card(d),
                        child: const Icon(Icons.movie_rounded, color: C.gold)))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(movie.title, style: TextStyle(
                color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(movie.genres.take(2).join(' · '),
                style: TextStyle(color: d ? C.txMutD : C.txMutL, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              RatingBadge(movie.rating, small: true),
              const SizedBox(width: 8),
              Text(movie.year, style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12)),
              if (movie.hasTrailer) ...[
                const SizedBox(width: 8),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: C.rose.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('▶ Trailer',
                        style: TextStyle(color: C.rose, fontSize: 10, fontWeight: FontWeight.w600))),
              ],
            ]),
          ])),
          Icon(Icons.chevron_right_rounded, color: d ? C.txMutD : C.txMutL, size: 18),
        ]),
      ),
    );
  }
}

// ─── OFFERS PAGE ────────────────────────────────────────────────────────────
class OffersPage extends StatelessWidget {
  const OffersPage({super.key});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Scaffold(
      backgroundColor: C.bg(d),
      appBar: AppBar(backgroundColor: C.bg(d), title: Text('Offers & Coupons',
          style: TextStyle(color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: OffersData.all.length,
        itemBuilder: (ctx, i) =>
            _OfferCard(offer: OffersData.all[i]).animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.1),
      ),
    );
  }
}

class _OfferCard extends StatefulWidget {
  final Map<String, dynamic> offer;
  const _OfferCard({required this.offer});
  @override State<_OfferCard> createState() => _OfferCardState();
}
class _OfferCardState extends State<_OfferCard> {
  bool _copied = false;
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    final o = widget.offer;
    final c = o['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: c.withOpacity(0.08), blurRadius: 20)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: c.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(o['icon'] as IconData, color: c, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o['title'].toString(), style: TextStyle(
                color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 3),
            Text(o['desc'].toString(), style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.withOpacity(0.3))),
              child: Text(o['code'].toString(), style: TextStyle(
                  color: c, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2))),
          const SizedBox(width: 12),
          PressableScale(
            onTap: () {
              Clipboard.setData(ClipboardData(text: o['code'].toString()));
              setState(() => _copied = true);
              Future.delayed(2.seconds, () { if (mounted) setState(() => _copied = false); });
              _showSnack(context, 'Code "${o['code']}" copied!', o['color'] as Color);
            },
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    gradient: _copied ? C.gradGreen : LinearGradient(colors: [c, c]),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(_copied ? 'Copied!' : 'Copy',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ])),
          ),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Expires', style: TextStyle(color: C.txMutD, fontSize: 10)),
            Text(o['expiry'].toString(),
                style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ]),
    );
  }
}

// ─── THEATER SELECT PAGE ────────────────────────────────────────────────────
class TheaterSelectPage extends StatefulWidget {
  final OmdbMovie movie;
  const TheaterSelectPage({super.key, required this.movie});
  @override State<TheaterSelectPage> createState() => _TheaterSelectState();
}
class _TheaterSelectState extends State<TheaterSelectPage> {
  late List<Theater> _theaters;
  late List<DateTime> _dates;
  int _dateIdx = 0;

  @override void initState() {
    super.initState();
    _theaters = TheaterData.getForMovie(widget.movie);
    _dates    = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Scaffold(
      backgroundColor: C.bg(d),
      appBar: AppBar(backgroundColor: C.bg(d), title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.movie.title, style: TextStyle(
            color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 16),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('Select Date & Theater', style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12)),
      ])),
      body: EdgeHapticScroll(
        child: Column(children: [
          _DatePicker(dates: _dates, selected: _dateIdx,
              onSelect: (i) => setState(() => _dateIdx = i), isDark: d),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _theaters.length,
            itemBuilder: (ctx, i) => _TheaterCard(
                theater: _theaters[i], movie: widget.movie, date: _dates[_dateIdx])
                .animate().fadeIn(delay: (i * 80).ms),
          )),
        ]),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final List<DateTime> dates; final int selected;
  final ValueChanged<int> onSelect; final bool isDark;
  const _DatePicker({required this.dates, required this.selected, required this.onSelect, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    height: 92,
    decoration: BoxDecoration(
        color: isDark ? C.surf2Dark : Colors.white,
        border: Border(bottom: BorderSide(color: C.border(isDark)))),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: dates.length,
      itemBuilder: (_, i) {
        final dt = dates[i]; final sel = i == selected;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: 200.ms, width: 58, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
                gradient: sel ? C.gradGold : null,
                color: sel ? null : (isDark ? C.cardDark : const Color(0xFFF1F5FF)),
                borderRadius: BorderRadius.circular(14),
                boxShadow: sel ? [BoxShadow(color: C.gold.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))] : null),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(DateFormat('EEE').format(dt).toUpperCase(), style: TextStyle(
                  color: sel ? Colors.black : (isDark ? C.txMutD : C.txSecL),
                  fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(DateFormat('d').format(dt), style: TextStyle(
                  color: sel ? Colors.black : (isDark ? C.txPrimD : C.txPrimL),
                  fontSize: 20, fontWeight: FontWeight.w900)),
              Text(DateFormat('MMM').format(dt), style: TextStyle(
                  color: sel ? Colors.black.withOpacity(0.7) : (isDark ? C.txMutD : C.txSecL),
                  fontSize: 10)),
            ]),
          ),
        );
      },
    ),
  );
}

class _TheaterCard extends StatelessWidget {
  final Theater theater; final OmdbMovie movie; final DateTime date;
  const _TheaterCard({required this.theater, required this.movie, required this.date});
  @override
  Widget build(BuildContext context) {
    final d     = context.watch<ThemeService>().isDark;
    final shows = TheaterData.getShowtimesForDate(theater, date);
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.border(d)),
          boxShadow: d ? null : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(gradient: C.gradGold, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.theaters_rounded, color: Colors.black, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(theater.name, style: TextStyle(
                color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 15)),
            Text(theater.address, style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12)),
          ])),
          Row(children: [
            const Icon(Icons.star_rounded, color: C.gold, size: 14),
            const SizedBox(width: 3),
            Text(theater.rating.toStringAsFixed(1),
                style: const TextStyle(color: C.gold, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: theater.amenities.map((a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: C.cyan.withOpacity(0.08), borderRadius: BorderRadius.circular(6),
                border: Border.all(color: C.cyan.withOpacity(0.25))),
            child: Text(a, style: const TextStyle(color: C.cyan, fontSize: 10, fontWeight: FontWeight.w600)))).toList()),
        if (shows.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: shows.take(8).map((st) => PressableScale(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SeatSelectionPage(
                      movie: movie, theater: theater, showtime: st, date: date))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: d ? C.surf2Dark : const Color(0xFFF1F5FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: st.fillPct > 0.8
                        ? C.rose.withOpacity(0.6)
                        : st.fillPct > 0.5 ? C.orange.withOpacity(0.5) : C.border(d))),
                child: Column(children: [
                  Text(st.formatTime(context), style: TextStyle(
                      color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 14)),
                  Text('${st.format} · ${st.language}',
                      style: TextStyle(color: d ? C.txMutD : C.txSecL, fontSize: 10)),
                  const SizedBox(height: 4),
                  ClipRRect(borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                          value: st.fillPct, minHeight: 3,
                          backgroundColor: d ? C.borderDark : C.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              st.fillPct > 0.8 ? C.rose : st.fillPct > 0.5 ? C.orange : C.green))),
                  if (st.available < 15)
                    Text('${st.available} left',
                        style: const TextStyle(color: C.rose, fontSize: 9, fontWeight: FontWeight.w700)),
                ]),
              ))).toList()),
        ] else
          Padding(padding: const EdgeInsets.only(top: 10),
              child: Text('No shows today', style: TextStyle(color: d ? C.txMutD : C.txSecL, fontSize: 13))),
      ]),
    );
  }
}

// ─── SEAT SELECTION PAGE ────────────────────────────────────────────────────
class SeatSelectionPage extends StatefulWidget {
  final OmdbMovie movie; final Theater theater; final Showtime showtime; final DateTime date;
  const SeatSelectionPage({super.key, required this.movie, required this.theater, required this.showtime, required this.date});
  @override State<SeatSelectionPage> createState() => _SeatSelState();
}
class _SeatSelState extends State<SeatSelectionPage> with TickerProviderStateMixin {
  final Set<String> _sel = {};
  late List<List<SeatStatus>> _seats;
  double _total = 0;
  late AnimationController _scr, _sa;

  @override void initState() {
    super.initState();
    _seats = List.generate(
        widget.showtime.seats.length,
            (r) => List<SeatStatus>.from(widget.showtime.seats[r]));
    _scr = AnimationController(vsync: this, duration: 800.ms)..forward();
    _sa  = AnimationController(vsync: this, duration: 1000.ms);
    _scr.forward().then((_) => _sa.forward());
  }
  @override void dispose() { _scr.dispose(); _sa.dispose(); super.dispose(); }

  SeatTier _tier(int r) => r < 3 ? SeatTier.regular : r < 6 ? SeatTier.premium : SeatTier.recliner;

  void _tap(int r, int c, List<String> globallyBooked) {
    final key = '${String.fromCharCode(65 + r)}${c + 1}';
    if (globallyBooked.contains(key)) return;
    setState(() {
      if (_seats[r][c] == SeatStatus.available) {
        _seats[r][c] = SeatStatus.selected; _sel.add(key);
      } else if (_seats[r][c] == SeatStatus.selected) {
        _seats[r][c] = SeatStatus.available; _sel.remove(key);
      }
      _total = _sel.fold(0, (s, k) {
        final r2 = k.codeUnitAt(0) - 65;
        return s + (widget.showtime.prices[_tier(r2)] ?? 0);
      });
    });
  }

  Color _seatColor(SeatStatus s, int r, bool d, bool isGloballyBooked) {
    if (isGloballyBooked || s == SeatStatus.booked) return C.rose.withOpacity(0.55);
    if (s == SeatStatus.selected) return C.gold;
    if (_tier(r) == SeatTier.recliner) return C.purple.withOpacity(0.4);
    if (_tier(r) == SeatTier.premium)  return C.cyan.withOpacity(0.4);
    return d ? C.borderDark : C.txMutL;
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Scaffold(
      backgroundColor: C.bg(d),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings')
            .where('showtimeId', isEqualTo: widget.showtime.id).snapshots(),
        builder: (context, snapshot) {
          final globallyBooked = <String>[];
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              globallyBooked.addAll(List<String>.from(doc['seats'] ?? []));
            }
          }
          return SafeArea(child: Column(children: [
            _header(d),
            Expanded(child: SingleChildScrollView(child: Column(children: [
              _screenAnimation(),
              _legend(d),
              _seatsGrid(d, globallyBooked),
              const SizedBox(height: 20),
            ]))),
            _footer(d),
          ]));
        },
      ),
    );
  }

  Widget _header(bool d) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      PressableScale(
          onTap: () => Navigator.pop(context),
          child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: C.surf(d), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border(d))),
              child: Icon(Icons.arrow_back_ios_rounded, size: 16, color: d ? C.txPrimD : C.txPrimL))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.movie.title, style: TextStyle(
            color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 16),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${DateFormat('EEE dd MMM').format(widget.date)} · ${widget.showtime.formatTime(context)} · ${widget.showtime.format}',
            style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12)),
      ])),
    ]),
  );

  Widget _screenAnimation() => AnimatedBuilder(
    animation: _scr,
    builder: (_, __) => Padding(padding: const EdgeInsets.symmetric(vertical: 20),
      child: Transform.scale(
        scale: CurvedAnimation(parent: _scr, curve: Curves.easeOutBack).value.clamp(0.0, 1.5).toDouble(),
        child: Column(children: [
          Container(
              width: MediaQuery.of(context).size.width * 0.65, height: 7,
              decoration: BoxDecoration(
                  gradient: C.gradGold,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  boxShadow: [BoxShadow(color: C.gold.withOpacity(0.7), blurRadius: 22, spreadRadius: 4)])),
          const SizedBox(height: 6),
          const Text('SCREEN', style: TextStyle(
              color: C.txMutD, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 4)),
        ]),
      ),
    ),
  );

  Widget _legend(bool d) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _LegendDot('Regular',  d ? C.borderDark : C.txMutL, '₹${widget.showtime.prices[SeatTier.regular]?.toInt()}'),
      _LegendDot('Premium',  C.cyan.withOpacity(0.4),     '₹${widget.showtime.prices[SeatTier.premium]?.toInt()}'),
      _LegendDot('Recliner', C.purple.withOpacity(0.4),   '₹${widget.showtime.prices[SeatTier.recliner]?.toInt()}'),
      _LegendDot('Booked',   C.rose.withOpacity(0.55),    null),
      _LegendDot('Selected', C.gold,                      null),
    ]),
  );

  Widget _seatsGrid(bool d, List<String> globallyBooked) {
    final sw = MediaQuery.of(context).size.width;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _sa, curve: Curves.easeIn),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Column(children: List.generate(_seats.length, (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 20, child: Text(String.fromCharCode(65 + r),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _rowColor(r), fontSize: 10, fontWeight: FontWeight.w700))),
              const SizedBox(width: 4),
              ...List.generate(_seats[r].length, (c) {
                final gap = c == _seats[r].length ~/ 2;
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  if (gap) const SizedBox(width: 16),
                  _seatWidget(r, c, d, sw, globallyBooked),
                ]);
              }),
              const SizedBox(width: 4),
              SizedBox(width: 20, child: Text(String.fromCharCode(65 + r),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _rowColor(r), fontSize: 10, fontWeight: FontWeight.w700))),
            ]),
          ))),
        ),
      ),
    );
  }

  Color _rowColor(int r) => r >= 6 ? C.purple : r >= 3 ? C.cyan : C.txMutD;

  Widget _seatWidget(int r, int c, bool d, double sw, List<String> globallyBooked) {
    final key            = '${String.fromCharCode(65 + r)}${c + 1}';
    final isGlobalBooked = globallyBooked.contains(key);
    final s   = isGlobalBooked ? SeatStatus.booked : _seats[r][c];
    final isR = r >= 6;
    final w   = sw < 360 ? 18.0 : sw < 420 ? 21.0 : 24.0;
    final col = _seatColor(s, r, d, isGlobalBooked);
    final sel = s == SeatStatus.selected;
    return GestureDetector(
      onTap: (s != SeatStatus.booked && !isGlobalBooked) ? () => _tap(r, c, globallyBooked) : null,
      child: AnimatedContainer(
          duration: 140.ms, width: w, height: w, margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: col, borderRadius: BorderRadius.circular(isR ? 7 : 4),
              border: sel ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5) : null,
              boxShadow: sel ? [BoxShadow(color: C.gold.withOpacity(0.7), blurRadius: 10)] : null),
          child: sel ? Icon(Icons.check_rounded, color: Colors.black, size: w * 0.5) : null),
    );
  }

  Widget _footer(bool d) => Container(
    padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom > 0 ? 24 : 20),
    decoration: BoxDecoration(
        color: d ? C.surf2Dark : Colors.white,
        border: Border(top: BorderSide(color: C.border(d)))),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('${_sel.length} seat${_sel.length != 1 ? 's' : ''} selected',
            style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12)),
        Text('₹${_total.toInt()}',
            style: const TextStyle(color: C.gold, fontSize: 24, fontWeight: FontWeight.w900)),
      ])),
      const SizedBox(width: 16),
      Expanded(child: GoldBtn(
          label: 'Continue', icon: Icons.arrow_forward_ios_rounded,
          onTap: _sel.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SnackPage(
                  movie: widget.movie, theater: widget.theater, showtime: widget.showtime,
                  date: widget.date, seats: _sel.toList(), seatAmount: _total))))),
    ]),
  );
}

class _LegendDot extends StatelessWidget {
  final String label; final Color color; final String? price;
  const _LegendDot(this.label, this.color, this.price);
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: C.txMutD, fontSize: 9, fontWeight: FontWeight.w600)),
    if (price != null) Text(price!, style: const TextStyle(color: C.txMutD, fontSize: 9)),
  ]);
}

// ─── SNACK PAGE ─────────────────────────────────────────────────────────────
class SnackPage extends StatefulWidget {
  final OmdbMovie movie; final Theater theater; final Showtime showtime;
  final DateTime date; final List<String> seats; final double seatAmount;
  const SnackPage({super.key, required this.movie, required this.theater, required this.showtime,
    required this.date, required this.seats, required this.seatAmount});
  @override State<SnackPage> createState() => _SnackState();
}
class _SnackState extends State<SnackPage> {
  final _snacks = SnackData.all;
  double get _tot => _snacks.fold(0, (s, n) => s + n.price * n.qty);
  String _cat = 'All';
  static const _cats = ['All', 'Popcorn', 'Drinks', 'Sides', 'Combo'];

  @override
  Widget build(BuildContext context) {
    final d    = context.watch<ThemeService>().isDark;
    final filt = _cat == 'All' ? _snacks : _snacks.where((s) => s.category == _cat).toList();
    return Scaffold(
      backgroundColor: C.bg(d),
      appBar: AppBar(backgroundColor: C.bg(d), title: const Text('Snacks & Drinks'),
          actions: [TextButton(
              onPressed: _go,
              child: Text('Skip', style: TextStyle(color: d ? C.txSecD : C.txSecL, fontWeight: FontWeight.w600)))]),
      body: EdgeHapticScroll(
        child: Column(children: [
          SizedBox(height: 44, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _cats.length,
            itemBuilder: (_, i) {
              final c = _cats[i]; final sel = c == _cat;
              return GestureDetector(
                  onTap: () => setState(() => _cat = c),
                  child: AnimatedContainer(
                      duration: 200.ms, margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                          gradient: sel ? C.gradGold : null,
                          color: sel ? null : (d ? C.surf2Dark : C.cardLight),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? C.gold : C.border(d))),
                      child: Text(c, style: TextStyle(
                          color: sel ? Colors.black : (d ? C.txSecD : C.txSecL),
                          fontWeight: FontWeight.w600, fontSize: 12))));
            },
          )),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: filt.length,
            itemBuilder: (_, i) => _SnackTile(snack: filt[i], onChange: () => setState(() {}))
                .animate().fadeIn(delay: (i * 50).ms),
          )),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
                color: d ? C.surf2Dark : Colors.white,
                border: Border(top: BorderSide(color: C.border(d)))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Snacks: ₹${_tot.toInt()}', style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12)),
                Text('Total: ₹${(widget.seatAmount + _tot).toInt()}',
                    style: const TextStyle(color: C.gold, fontSize: 20, fontWeight: FontWeight.w900)),
              ])),
              SizedBox(width: 160, child: GoldBtn(label: 'Checkout', onTap: _go)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _go() => Navigator.push(context, MaterialPageRoute(
      builder: (_) => CheckoutPage(
          movie: widget.movie, theater: widget.theater, showtime: widget.showtime,
          date: widget.date, seats: widget.seats, seatAmount: widget.seatAmount,
          snacks: _snacks.where((s) => s.qty > 0).toList())));
}

class _SnackTile extends StatelessWidget {
  final SnackItem snack; final VoidCallback onChange;
  const _SnackTile({required this.snack, required this.onChange});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border(d))),
      child: Row(children: [
        Container(width: 52, height: 52,
            decoration: BoxDecoration(color: C.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(snack.emoji, style: const TextStyle(fontSize: 28)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(snack.name, style: TextStyle(
              color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w700, fontSize: 14)),
          Text('₹${snack.price.toInt()}', style: const TextStyle(
              color: C.gold, fontWeight: FontWeight.w800, fontSize: 14)),
        ])),
        Container(
          decoration: BoxDecoration(
              color: d ? C.surf2Dark : C.surf2Light, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.border(d))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                icon: const Icon(Icons.remove_rounded, size: 16),
                color: d ? C.txSecD : C.txSecL,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: snack.qty > 0 ? () { snack.qty--; onChange(); } : null),
            AnimatedSwitcher(duration: 200.ms, child: Text('${snack.qty}',
                key: ValueKey(snack.qty), style: TextStyle(
                    color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 15))),
            IconButton(
                icon: const Icon(Icons.add_rounded, size: 16), color: C.gold,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () { snack.qty++; onChange(); }),
          ]),
        ),
      ]),
    );
  }
}

// ─── CHECKOUT PAGE ──────────────────────────────────────────────────────────
class CheckoutPage extends StatefulWidget {
  final OmdbMovie movie; final Theater theater; final Showtime showtime;
  final DateTime date; final List<String> seats; final double seatAmount;
  final List<SnackItem> snacks;
  const CheckoutPage({super.key, required this.movie, required this.theater, required this.showtime,
    required this.date, required this.seats, required this.seatAmount, this.snacks = const []});
  @override State<CheckoutPage> createState() => _CheckoutState();
}
class _CheckoutState extends State<CheckoutPage> {
  PaymentMethod _pm = PaymentMethod.upi;
  final _pCtrl = TextEditingController();
  double _disc = 0;
  bool _proc = false;

  double get _snackTot => widget.snacks.fold(0, (s, n) => s + n.price * n.qty);
  double get _final => ((widget.seatAmount + _snackTot) - _disc).clamp(0.0, double.infinity);

  @override void dispose() { _pCtrl.dispose(); super.dispose(); }

  void _applyPromo() {
    final v = _pCtrl.text.toUpperCase();
    double d = 0;
    if (v == 'CINEMA50')       d = 50;
    else if (v == 'IMAX100')   d = 100;
    else if (v == 'FIRSTSHOW') d = widget.seatAmount * 0.15;
    setState(() => _disc = d);
    _showSnack(context,
        d > 0 ? '🎉 Discount applied!' : 'Invalid code. Try CINEMA50.',
        d > 0 ? C.green : C.rose);
  }

  Future<void> _pay() async {
    setState(() => _proc = true);
    await Future.delayed(2.seconds);
    if (!mounted) return;
    final b = Booking(
        id: 'CN${Random().nextInt(900000) + 100000}',
        movie: widget.movie, theater: widget.theater,
        showtime: widget.showtime, seats: widget.seats,
        total: _final, bookedAt: DateTime.now(),
        payment: _pm, snacks: widget.snacks);
    context.read<UserService>().addBooking(b);
    setState(() => _proc = false);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ConfirmationPage(booking: b)));
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return Scaffold(
      backgroundColor: C.bg(d),
      appBar: AppBar(backgroundColor: C.bg(d), title: const Text('Checkout')),
      body: _proc ? _loading(d) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _summary(d), const SizedBox(height: 16),
          _promo(d), const SizedBox(height: 24),
          _paymentMethods(d), const SizedBox(height: 28),
          GoldBtn(label: 'Pay ₹${_final.toInt()}', onTap: _pay),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _loading(bool d) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80,
        decoration: BoxDecoration(
            color: C.gold.withOpacity(0.1), shape: BoxShape.circle,
            border: Border.all(color: C.gold.withOpacity(0.3))),
        child: const Center(child: CircularProgressIndicator(color: C.gold, strokeWidth: 2))),
    const SizedBox(height: 24),
    Text('Processing Payment…', style: TextStyle(
        color: d ? C.txSecD : C.txSecL, fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Text("Please don't go back", style: TextStyle(color: d ? C.txMutD : C.txMutL, fontSize: 13)),
  ]));

  Widget _summary(bool d) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
        color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.border(d))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.receipt_long_rounded, color: C.gold, size: 18),
        const SizedBox(width: 8),
        Text('Order Summary', style: TextStyle(
            color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
      const SizedBox(height: 16),
      _row(d, 'Movie',   widget.movie.title),
      _row(d, 'Date',    DateFormat('EEE, dd MMM yyyy').format(widget.date)),
      _row(d, 'Time',    widget.showtime.formatTime(context)),
      _row(d, 'Venue',   widget.theater.name),
      _row(d, 'Seats',   widget.seats.join(', ')),
      _row(d, 'Tickets', '₹${widget.seatAmount.toInt()}'),
      if (widget.snacks.isNotEmpty) ...[
        Divider(color: C.border(d), height: 20),
        ...widget.snacks.map((s) => _row(d, '${s.emoji} ${s.name} ×${s.qty}', '₹${(s.price * s.qty).toInt()}')),
      ],
      if (_disc > 0) _row(d, '🏷 Promo', '−₹${_disc.toInt()}', C.green),
      Divider(color: C.border(d), height: 20),
      Row(children: [
        Text('Total', style: TextStyle(
            color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 17)),
        const Spacer(),
        Text('₹${_final.toInt()}',
            style: const TextStyle(color: C.gold, fontWeight: FontWeight.w900, fontSize: 22)),
      ]),
    ]),
  );

  Widget _row(bool d, String l, String v, [Color? vc]) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(l, style: TextStyle(color: d ? C.txMutD : C.txMutL, fontSize: 13)),
      const SizedBox(width: 8), const Spacer(),
      Flexible(child: Text(v, textAlign: TextAlign.end,
          style: TextStyle(color: vc ?? (d ? C.txSecD : C.txSecL), fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 2)),
    ]),
  );

  Widget _promo(bool d) => Container(
    decoration: BoxDecoration(
        color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border(d))),
    child: Row(children: [
      const SizedBox(width: 14),
      const Icon(Icons.local_offer_rounded, color: C.gold, size: 18),
      const SizedBox(width: 10),
      Expanded(child: TextField(
          controller: _pCtrl,
          style: TextStyle(color: d ? C.txPrimD : C.txPrimL, fontSize: 14),
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
              hintText: 'Promo code (CINEMA50 / IMAX100)',
              border: InputBorder.none, fillColor: Colors.transparent, filled: false))),
      TextButton(
          onPressed: _applyPromo,
          child: const Text('APPLY', style: TextStyle(color: C.gold, fontWeight: FontWeight.w800, fontSize: 13))),
    ]),
  );

  Widget _paymentMethods(bool d) {
    final methods = {
      PaymentMethod.upi:       ('UPI / BHIM',          Icons.payment_rounded),
      PaymentMethod.card:      ('Credit / Debit Card',  Icons.credit_card_rounded),
      PaymentMethod.googlePay: ('Google Pay',           Icons.g_mobiledata_rounded),
      PaymentMethod.phonePe:   ('PhonePe',              Icons.phone_android_rounded),
      PaymentMethod.paytm:     ('Paytm',                Icons.account_balance_wallet_rounded),
      PaymentMethod.wallet:    ('CinemaNow Wallet',      Icons.wallet_rounded),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Payment Method', style: TextStyle(
          color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 17)),
      const SizedBox(height: 12),
      ...methods.entries.map((e) {
        final sel = _pm == e.key;
        return PressableScale(
          onTap: () => setState(() => _pm = e.key),
          child: AnimatedContainer(
            duration: 200.ms, margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                gradient: sel ? LinearGradient(colors: [C.gold.withOpacity(0.1), Colors.transparent]) : null,
                color: sel ? null : (d ? C.cardDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? C.gold : C.border(d), width: sel ? 1.5 : 1),
                boxShadow: sel ? [BoxShadow(color: C.gold.withOpacity(0.15), blurRadius: 10)] : null),
            child: Row(children: [
              Icon(e.value.$2, color: sel ? C.gold : (d ? C.txSecD : C.txSecL), size: 20),
              const SizedBox(width: 12),
              Text(e.value.$1, style: TextStyle(
                  color: sel ? C.gold : (d ? C.txPrimD : C.txPrimL),
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
              const Spacer(),
              if (sel) const Icon(Icons.check_circle_rounded, color: C.gold, size: 20),
            ]),
          ),
        );
      }),
    ]);
  }
}

//  CONFIRMATION PAGE

class ConfirmationPage extends StatefulWidget {
  final Booking booking;
  const ConfirmationPage({super.key, required this.booking});
  @override State<ConfirmationPage> createState() => _ConfirmState();
}
class _ConfirmState extends State<ConfirmationPage> with TickerProviderStateMixin {
  late ConfettiController _cf;
  late AnimationController _scale;

  @override void initState() {
    super.initState();
    _cf    = ConfettiController(duration: 4.seconds)..play();
    _scale = AnimationController(vsync: this, duration: 700.ms);
    Future.delayed(300.ms, () => _scale.forward());
  }
  @override void dispose() { _cf.dispose(); _scale.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final d = context.watch<ThemeService>().isDark;
    return Scaffold(
      backgroundColor: C.bg(d),
      body: Stack(children: [
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 24),
            ScaleTransition(
                scale: CurvedAnimation(parent: _scale, curve: Curves.elasticOut),
                child: Container(
                    width: 92, height: 92,
                    decoration: BoxDecoration(
                        color: C.green.withOpacity(0.12), shape: BoxShape.circle,
                        border: Border.all(color: C.green.withOpacity(0.4), width: 2.5)),
                    child: const Icon(Icons.check_rounded, color: C.green, size: 52))),
            const SizedBox(height: 20),
            Text('Booking Confirmed! 🎉', style: TextStyle(
                color: d ? C.txPrimD : C.txPrimL, fontSize: 26, fontWeight: FontWeight.w900))
                .animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 8),
            Text('Your QR code is ready. Show it at the counter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 14, height: 1.5))
                .animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 32),
            _ticket(b, d).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlineBtn(label: '📥 Download',
                  onTap: () => _showSnack(context, 'Ticket saved!', C.green))),
              const SizedBox(width: 12),
              Expanded(child: OutlineBtn(label: '🔗 Share',
                  onTap: () => Share.share(
                      'I just booked ${b.movie.title} at ${b.theater.name}! 🎬 Code: ${b.id}'))),
            ]).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 16),
            GoldBtn(
                label: 'Back to Home',
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst))
                .animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 30),
          ]),
        )),
        Align(alignment: Alignment.topCenter, child: ConfettiWidget(
            confettiController: _cf,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [C.gold, C.cyan, C.rose, C.green, C.purple])),
      ]),
    );
  }


  Widget _ticket(Booking b, bool d) => Container(
    decoration: BoxDecoration(
        color: d ? C.cardDark : Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.border(d)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(d ? 0.15 : 0.08), blurRadius: 30, spreadRadius: 2)]),
    child: Column(children: [
      Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [C.gold.withOpacity(0.12), C.cyan.withOpacity(0.06)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: b.movie.posterUrl, width: 80, height: 112, fit: BoxFit.cover,
                    fadeInDuration: 200.ms,
                    errorWidget: (_, __, ___) => Container(width: 80, height: 112, color: C.card(d)))),
            const SizedBox(height: 12),
            Text(b.movie.title, style: TextStyle(
                color: d ? C.txPrimD : C.txPrimL, fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(DateFormat('EEEE, MMMM dd, yyyy').format(b.showtime.time),
                style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 13)),
            const SizedBox(height: 4),
            Text(b.showtime.formatTime(context),
                style: const TextStyle(color: C.gold, fontSize: 24, fontWeight: FontWeight.w900)),
          ])),
      _dashed(d),
      Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        _ticketRow(d, Icons.theaters_rounded, 'Theater', b.theater.name),
        _ticketRow(d, Icons.chair_outlined, 'Seats', b.seats.join(', ')),
        _ticketRow(d, Icons.currency_rupee_rounded, 'Paid', '₹${b.total.toInt()}'),
        const SizedBox(height: 20),
        Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: d ? C.surf2Dark : C.surf2Light, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              QrImageView(
                  data: b.id, version: QrVersions.auto, size: 140,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: d ? C.txPrimD : Colors.black),
                  dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square, color: d ? C.txPrimD : Colors.black)),
              const SizedBox(height: 12),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(gradient: C.gradGold, borderRadius: BorderRadius.circular(8)),
                  child: Text(b.id, style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2))),
            ])),
      ])),
    ]),
  );

  Widget _ticketRow(bool d, IconData icon, String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, color: d ? C.txMutD : C.txMutL, size: 16),
      const SizedBox(width: 8),
      Text('$l:', style: TextStyle(color: d ? C.txMutD : C.txMutL, fontSize: 13)),
      const SizedBox(width: 6), const Spacer(),
      Expanded(child: Text(v, textAlign: TextAlign.end,
          style: TextStyle(color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w700, fontSize: 13))),
    ]),
  );

  Widget _dashed(bool d) => SizedBox(height: 28, child: Stack(children: [
    Positioned(left: 0, right: 0, top: 12,
        child: Row(children: List.generate(40, (_) => Expanded(child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 1, color: C.border(d)))))),
    Positioned(left: -14, top: 4, child: CircleAvatar(radius: 12, backgroundColor: C.bg(d))),
    Positioned(right: -14, top: 4, child: CircleAvatar(radius: 12, backgroundColor: C.bg(d))),
  ]));
}



//  TICKETS PAGE

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});
  @override build(BuildContext context) {
    final d=context.watch<ThemeService>().isDark;
    final bks=context.watch<UserService>().user?.bookings??[];
    return Scaffold(backgroundColor:C.bg(d),
        appBar:AppBar(backgroundColor:C.bg(d), title:Text('My Tickets', style:TextStyle(color:d?C.txPrimD:C.txPrimL, fontWeight:FontWeight.w800))),
        body:EdgeHapticScroll(
          child: bks.isEmpty?_empty(d):ListView.builder(padding:const EdgeInsets.all(16), itemCount:bks.length,
              itemBuilder:(ctx,i){ final b=bks[i];
              return PressableScale(onTap:()=>Navigator.push(ctx,MaterialPageRoute(builder:(_)=>ConfirmationPage(booking:b))),
                  child:Container(margin:const EdgeInsets.only(bottom:14), decoration:BoxDecoration(color:d?C.cardDark:Colors.white,
                      borderRadius:BorderRadius.circular(18), border:Border.all(color:C.border(d))),
                      child:Row(children:[
                        ClipRRect(borderRadius:const BorderRadius.only(topLeft:Radius.circular(18),bottomLeft:Radius.circular(18)),
                            child:CachedNetworkImage(imageUrl:b.movie.posterUrl, width:80, height:110, fit:BoxFit.cover,
                                fadeInDuration:200.ms,
                                errorWidget:(_,__,___)=>Container(width:80,height:110,color:C.card(d)))),
                        Expanded(child:Padding(padding:const EdgeInsets.all(14), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                          Text(b.movie.title, style:TextStyle(color:d?C.txPrimD:C.txPrimL, fontWeight:FontWeight.w800, fontSize:15), maxLines:1, overflow:TextOverflow.ellipsis),
                          const SizedBox(height:4),
                          Text(b.theater.name, style:TextStyle(color:d?C.txSecD:C.txSecL, fontSize:12)),
                          const SizedBox(height:4),
                          Text('${DateFormat('dd MMM yyyy').format(b.showtime.time)} · ${b.showtime.formatTime(context)}',
                              style:TextStyle(color:d?C.txMutD:C.txMutL, fontSize:12)),
                          const SizedBox(height:8),
                          Row(children:[Icon(Icons.chair_outlined, size:13, color:d?C.txMutD:C.txMutL), const SizedBox(width:4),
                            Text(b.seats.join(', '), style:TextStyle(color:d?C.txSecD:C.txSecL, fontSize:12)),
                            const Spacer(), Text('₹${b.total.toInt()}', style:const TextStyle(color:C.gold, fontWeight:FontWeight.w900, fontSize:15))]),
                        ]))),
                      ])).animate().fadeIn(delay:(i*60).ms));
              }),
        ));
  }
  Widget _empty(bool d) => Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[
    Container(padding:const EdgeInsets.all(24), decoration:BoxDecoration(color:d?C.cardDark:C.cardLight, shape:BoxShape.circle),
        child:Icon(Icons.local_activity_outlined, color:d?C.txMutD:C.txMutL, size:52)),
    const SizedBox(height:20),
    Text('No bookings yet', style:TextStyle(color:d?C.txPrimD:C.txPrimL, fontSize:18, fontWeight:FontWeight.w700)),
    const SizedBox(height:8),
    Text('Book your first movie to see tickets here.', textAlign:TextAlign.center, style:TextStyle(color:d?C.txSecD:C.txSecL, height:1.5)),
  ]));
}


//  PROFILE PAGE

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  Color _tc(String t) => switch(t){'Platinum'=>const Color(0xFF8AB4F8),'Gold'=>C.gold,'Silver'=>const Color(0xFFB0C0D6),_=>const Color(0xFFCD7F32)};

  @override build(BuildContext context) {
    final d=context.watch<ThemeService>().isDark; final us=context.watch<UserService>(); final u=us.user;
    if(u==null) return Scaffold(backgroundColor:C.bg(d), body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[
      const CircularProgressIndicator(color:C.gold, strokeWidth:2), const SizedBox(height:24),
      Text('Fetching your profile…', style:TextStyle(color:d?C.txSecD:C.txSecL)),
      const SizedBox(height:32),
      GoldBtn(label:'Retry', onTap:()=>context.read<UserService>().reloadUser(), height:40, fullWidth:false),
      const SizedBox(height:12),
      TextButton(onPressed:()=>context.read<UserService>().signOut(), child:const Text('Sign Out', style:TextStyle(color:C.rose))),
    ])));
    final tc=_tc(u.tier);
    return Scaffold(backgroundColor:C.bg(d), body:EdgeHapticScroll(
      child: CustomScrollView(slivers:[
        SliverToBoxAdapter(child:Stack(children:[
          Container(height:220, decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[tc.withOpacity(0.2), C.bg(d)]))),
          Padding(padding:const EdgeInsets.fromLTRB(20,60,20,0), child:Column(children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
              Text('Profile', style:TextStyle(color:d?C.txPrimD:C.txPrimL, fontSize:22, fontWeight:FontWeight.w900)),
              GestureDetector(onTap:()=>context.read<ThemeService>().toggle(),
                  child:Container(padding:const EdgeInsets.all(9), decoration:BoxDecoration(color:C.surf(d), borderRadius:BorderRadius.circular(12), border:Border.all(color:C.border(d))),
                      child:Icon(d?Icons.light_mode_rounded:Icons.dark_mode_rounded, size:18, color:d?C.txSecD:C.txSecL))),
            ]),
            const SizedBox(height:20),
            Row(children:[
              Container(width:64, height:64, decoration:BoxDecoration(shape:BoxShape.circle, gradient:LinearGradient(colors:[tc,tc.withOpacity(0.5)]), boxShadow:[BoxShadow(color:tc.withOpacity(0.4), blurRadius:16)]),
                  child:Center(child:Text(u.displayName.isNotEmpty?u.displayName[0].toUpperCase():'U', style:const TextStyle(color:Colors.white, fontSize:28, fontWeight:FontWeight.w900)))),
              const SizedBox(width:16),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                Text(u.displayName, style:TextStyle(color:d?C.txPrimD:C.txPrimL, fontSize:20, fontWeight:FontWeight.w800)),
                Text(u.email, style:TextStyle(color:d?C.txSecD:C.txSecL, fontSize:13)),
                const SizedBox(height:6),
                Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                    decoration:BoxDecoration(color:tc.withOpacity(0.15), borderRadius:BorderRadius.circular(20), border:Border.all(color:tc.withOpacity(0.3))),
                    child:Row(mainAxisSize:MainAxisSize.min, children:[Icon(Icons.workspace_premium_rounded, color:tc, size:13), const SizedBox(width:5),
                      Text('${u.tier} · ${u.points} pts', style:TextStyle(color:tc, fontWeight:FontWeight.w700, fontSize:12))])),
              ])),
            ]),
            const SizedBox(height:20),
            Row(children:[
              _sb('Bookings','${u.bookings.length}',Icons.confirmation_number_rounded,C.gold,d),
              _sb('Wishlist','${context.watch<WishlistService>().ids.length}',Icons.bookmark_rounded,C.cyan,d),
              _sb('Points','${u.points}',Icons.stars_rounded,C.rose,d),
            ]).animate().fadeIn(delay:200.ms),
          ])),
        ])),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,8,16,40), child:Column(children:[
          _Sec(isDark:d, title:'ACCOUNT', tiles:[
            _T('Edit Profile',Icons.person_outline_rounded,C.gold,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const EditProfilePage()))),
            _T('Payment Methods',Icons.credit_card_rounded,C.cyan,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const PaymentMethodsPage()))),
            _T('Notifications',Icons.notifications_outlined,C.orange,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const NotificationsPage()))),
            _T('Offers & Coupons',Icons.local_offer_rounded,C.green,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OffersPage()))),
          ]),
          const SizedBox(height:16),
          _Sec(isDark:d, title:'ACTIVITY', tiles:[
            _T('Booking History',Icons.history_rounded,C.gold,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const TicketsPage()))),
            _T('My Wishlist',Icons.bookmark_outline_rounded,C.cyan,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const WatchlistPage()))),
            _T('My Reviews',Icons.rate_review_outlined,C.rose,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MyReviewsPage()))),
          ]),
          const SizedBox(height:16),
          _Sec(isDark:d, title:'SETTINGS', tiles:[
            _T(d?'Light Mode':'Dark Mode',d?Icons.light_mode_rounded:Icons.dark_mode_rounded,C.purple,()=>context.read<ThemeService>().toggle()),
            _T('Language Preference',Icons.language_rounded,C.indigo,(){}),
            _T('Help & Support',Icons.help_outline_rounded,C.txMutD,(){}),
          ]),
          const SizedBox(height:28),
          PressableScale(onTap:(){context.read<UserService>().signOut(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const AuthGate()),(_)=>false);},
              child:Container(padding:const EdgeInsets.all(16),
                  decoration:BoxDecoration(color:C.rose.withOpacity(0.08), borderRadius:BorderRadius.circular(14), border:Border.all(color:C.rose.withOpacity(0.3))),
                  child:const Row(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(Icons.logout_rounded, color:C.rose, size:20), SizedBox(width:10),
                    Text('Sign Out', style:TextStyle(color:C.rose, fontWeight:FontWeight.w800, fontSize:16))]))),
        ]))),
      ]),
    ));
  }

  Widget _sb(String l, String v, IconData icon, Color c, bool d) => Expanded(child:Container(margin:const EdgeInsets.symmetric(horizontal:4),
      padding:const EdgeInsets.symmetric(vertical:14),
      decoration:BoxDecoration(color:d?C.cardDark:Colors.white, borderRadius:BorderRadius.circular(14), border:Border.all(color:C.border(d))),
      child:Column(children:[Icon(icon, color:c, size:20), const SizedBox(height:4),
        Text(v, style:TextStyle(color:d?C.txPrimD:C.txPrimL, fontSize:18, fontWeight:FontWeight.w900)),
        Text(l, style:const TextStyle(color:C.txMutD, fontSize:11))])));
}

class _Sec extends StatelessWidget {
  final bool isDark; final String title; final List<_T> tiles;
  const _Sec({required this.isDark, required this.title, required this.tiles});
  @override build(BuildContext context) => Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
    Padding(padding:const EdgeInsets.only(left:4,bottom:8),
        child:Text(title, style:TextStyle(color:isDark?C.txSecD:C.txSecL, fontSize:11, fontWeight:FontWeight.w800, letterSpacing:1.2))),
    Container(decoration:BoxDecoration(color:isDark?C.cardDark:Colors.white, borderRadius:BorderRadius.circular(16), border:Border.all(color:C.border(isDark))),
        child:Column(children:tiles.asMap().entries.map((e){ final t=e.value; final last=e.key==tiles.length-1;
        return Column(children:[ListTile(
            leading:Container(width:36, height:36, decoration:BoxDecoration(color:t.color.withOpacity(0.12), borderRadius:BorderRadius.circular(10)),
                child:Icon(t.icon, color:t.color, size:18)),
            title:Text(t.label, style:TextStyle(color:isDark?C.txPrimD:C.txPrimL, fontWeight:FontWeight.w500, fontSize:14)),
            trailing:Icon(Icons.chevron_right_rounded, color:isDark?C.txMutD:C.txMutL, size:18),
            onTap:() {
              t.onTap();
            }),
          if(!last) Divider(indent:58, height:1, color:C.border(isDark))]);}).toList())),
  ]);
}

class _T { final String label; final IconData icon; final Color color; final VoidCallback onTap;
const _T(this.label, this.icon, this.color, this.onTap); }

// ─── MINOR PAGES ───────────────────────────────────────────────────────────
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override State<EditProfilePage> createState() => _EPState();
}
class _EPState extends State<EditProfilePage> {
  late TextEditingController _nCtrl, _eCtrl; bool _load=false; String? _img;
  @override void initState() { super.initState(); final u=context.read<UserService>().user!; _nCtrl=TextEditingController(text:u.displayName); _eCtrl=TextEditingController(text:u.email); }
  @override void dispose() { _nCtrl.dispose(); _eCtrl.dispose(); super.dispose(); }
  @override build(BuildContext context) {
    final d=context.watch<ThemeService>().isDark; final u=context.read<UserService>().user!;
    return Scaffold(backgroundColor:C.bg(d), appBar:AppBar(backgroundColor:C.bg(d), title:const Text('Edit Profile')),
        body:SingleChildScrollView(padding:const EdgeInsets.all(24), child:Column(children:[
          Stack(children:[
            Container(width:100, height:100, decoration:BoxDecoration(shape:BoxShape.circle, color:C.gold.withOpacity(0.2), border:Border.all(color:C.gold,width:2)),
                child:ClipOval(child:_img!=null?Image.file(File(_img!),fit:BoxFit.cover):Center(child:Text(u.displayName[0].toUpperCase(), style:const TextStyle(fontSize:40, fontWeight:FontWeight.bold, color:C.gold))))),
            Positioned(bottom:0, right:0, child:GestureDetector(onTap:()async{final p=await ImagePicker().pickImage(source:ImageSource.gallery);if(p!=null)setState(()=>_img=p.path);},
                child:Container(padding:const EdgeInsets.all(6), decoration:const BoxDecoration(color:C.gold, shape:BoxShape.circle),
                    child:const Icon(Icons.camera_alt_rounded, size:18, color:Colors.black)))),
          ]),
          const SizedBox(height:32),
          _fld(context,'DISPLAY NAME',_nCtrl,Icons.badge_outlined),
          const SizedBox(height:18),
          _fld(context,'EMAIL ADDRESS',_eCtrl,Icons.email_outlined, type:TextInputType.emailAddress),
          const SizedBox(height:40),
          _load?const _Loader():GoldBtn(label:'Save Changes', onTap:()async{
            setState(()=>_load=true);
            final e=await context.read<UserService>().updateProfile(name:_nCtrl.text.trim(),email:_eCtrl.text.trim());
            if(!mounted) return; setState(()=>_load=false);
            if(e==null){_showSnack(context,'Profile updated! ✨',C.green);Navigator.pop(context);}
            else _showSnack(context,e,C.rose);}),
        ])));
  }
}

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});
  @override build(BuildContext context) {
    final d=context.watch<ThemeService>().isDark;
    return Scaffold(backgroundColor:C.bg(d), appBar:AppBar(backgroundColor:C.bg(d), title:const Text('Payment Methods')),
        body:ListView(padding:const EdgeInsets.all(20), children:[
          _mt(context,'•••• •••• •••• 4242',Icons.credit_card_rounded,'Visa',true),
          const SizedBox(height:12), _mt(context,'user@upi',Icons.account_balance_wallet_rounded,'UPI',false),
          const SizedBox(height:32), GoldBtn(label:'Add New Method', icon:Icons.add_rounded, onTap:(){}),
        ]));
  }
  Widget _mt(BuildContext ctx, String v, IconData icon, String type, bool prim) {
    final d=ctx.watch<ThemeService>().isDark;
    return Container(padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(color:C.card(d), borderRadius:BorderRadius.circular(16), border:Border.all(color:prim?C.gold:C.border(d))),
        child:Row(children:[Icon(icon, color:prim?C.gold:C.tx(d,muted:true)),
          const SizedBox(width:16),
          Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
            Text(type, style:TextStyle(fontSize:11, color:C.tx(d,muted:true), fontWeight:FontWeight.w800)),
            Text(v, style:TextStyle(fontSize:15, fontWeight:FontWeight.w700, color:C.tx(d)))]),
          const Spacer(),
          if(prim) Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
              decoration:BoxDecoration(color:C.gold.withOpacity(0.15), borderRadius:BorderRadius.circular(6)),
              child:const Text('DEFAULT', style:TextStyle(color:C.gold, fontSize:10, fontWeight:FontWeight.w800)))]));
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override build(BuildContext context) {
    final d=context.watch<ThemeService>().isDark;
    return Scaffold(backgroundColor:C.bg(d), appBar:AppBar(backgroundColor:C.bg(d), title:const Text('Notifications')),
        body:ListView(padding:const EdgeInsets.all(16), children:[
          _nt(context,'Booking Confirmed!','Your tickets for Spider-Man are ready.','2h ago',Icons.confirmation_number_rounded,C.green),
          _nt(context,'New Movie Alert!','Stree 2 is trending! Book now.','1d ago',Icons.movie_filter_rounded,C.gold),
          _nt(context,'Offer Unlocked!','Use CINEMA50 to get ₹50 off!','2d ago',Icons.local_offer_rounded,C.purple),
          _nt(context,'Watchlist Update','Kalki 2898 AD is now showing!','3d ago',Icons.bookmark_rounded,C.rose),
        ]));
  }
  Widget _nt(BuildContext ctx, String title, String body, String time, IconData icon, Color c) {
    final d=ctx.watch<ThemeService>().isDark;
    return Container(margin:const EdgeInsets.only(bottom:12), padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(color:C.card(d), borderRadius:BorderRadius.circular(16), border:Border.all(color:C.border(d))),
        child:Row(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:c.withOpacity(0.1), shape:BoxShape.circle), child:Icon(icon, color:c, size:20)),
          const SizedBox(width:16),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[Text(title, style:TextStyle(fontWeight:FontWeight.w800, fontSize:14, color:C.tx(d))), Text(time, style:TextStyle(color:C.tx(d,muted:true), fontSize:11))]),
            const SizedBox(height:4), Text(body, style:TextStyle(color:C.tx(d,sec:true), fontSize:13))])),
        ]));
  }
}

class MyReviewsPage extends StatelessWidget {
  const MyReviewsPage({super.key});
  @override build(BuildContext context) {
    final d=context.watch<ThemeService>().isDark;
    return Scaffold(backgroundColor:C.bg(d), appBar:AppBar(backgroundColor:C.bg(d), title:const Text('My Reviews')),
        body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[
          Icon(Icons.rate_review_outlined, size:64, color:C.tx(d,muted:true)), const SizedBox(height:16),
          Text('No reviews yet', style:TextStyle(fontSize:18, fontWeight:FontWeight.w700, color:C.tx(d))),
          Text('Review movies you have watched!', style:TextStyle(color:C.tx(d,sec:true)))])));
  }
}

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});
  @override build(BuildContext context) {
    final d=context.watch<ThemeService>().isDark; final ws=context.watch<WishlistService>(); final ms=context.watch<MovieService>();
    final all=[...ms.nowPlaying,...ms.trending,...ms.bollywoodNew,...ms.hollywoodNew,...ms.tollywoodNew,...ms.topRated,...ms.bollywoodClassic,...ms.hollywoodClassic,...ms.tollywoodClassic];
    final movies=all.where((m)=>ws.has(m.imdbId)).toSet().toList();
    return Scaffold(backgroundColor:C.bg(d),
        appBar:AppBar(backgroundColor:C.bg(d), title:Text('My Wishlist', style:TextStyle(color:d?C.txPrimD:C.txPrimL, fontWeight:FontWeight.w800))),
        body:EdgeHapticScroll(
          child: movies.isEmpty?Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[
            const Icon(Icons.bookmark_border_rounded, color:C.txMutD, size:64), const SizedBox(height:16),
            Text('Wishlist is empty', style:TextStyle(color:d?C.txPrimD:C.txPrimL, fontSize:18, fontWeight:FontWeight.w700)), const SizedBox(height:8),
            Text('Tap the bookmark icon on any movie.', style:TextStyle(color:d?C.txSecD:C.txSecL))]))
              :GridView.builder(padding:const EdgeInsets.all(16),
              gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, childAspectRatio:0.6, crossAxisSpacing:12, mainAxisSpacing:16),
              itemCount:movies.length, itemBuilder:(_,i)=>_GridCard(movie:movies[i]).animate().fadeIn(delay:(i*50).ms)),
        ));
  }
}

// ─── HELPERS ───────────────────────────────────────────────────────────────
void _toDetail(BuildContext ctx, OmdbMovie m) {
  Navigator.push(ctx, MaterialPageRoute(builder: (_) => MovieDetailPage(movie: m)));
}
String _fmtNum(int n) { if(n>=1000000) return '${(n/1000000).toStringAsFixed(1)}M'; if(n>=1000) return '${(n/1000).toStringAsFixed(1)}K'; return '$n'; }
void _showSnack(BuildContext ctx, String msg, Color c) => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content:Text(msg, style:const TextStyle(fontWeight:FontWeight.w600)), backgroundColor:c,
    behavior:SnackBarBehavior.floating, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)), margin:const EdgeInsets.all(16)));