import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/patient/rootpage.dart';
import 'package:project/services/user_settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

// ✅ locale controller
import 'package:project/services/locale_controller.dart';

// ✅ localization
import 'package:project/l10n/app_localizations.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _service = UserSettingsService();
  final String userDocId = FirebaseAuth.instance.currentUser!.uid;

  // UI language names (these are fine)
  final List<String> languages = const ['English', 'Urdu'];

  String _languageFromCode(String code) => code == 'ur' ? 'Urdu' : 'English';
  String _codeFromLanguage(String lang) => lang == 'Urdu' ? 'ur' : 'en';

  @override
  void initState() {
    super.initState();
    _service.ensureUserDoc(userDocId);
  }

  void _showLanguageChangedDialog(String lang) {
    final t = AppLocalizations.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: t?.languageUpdatedTitle ?? "Language Updated 🎉",
      desc: t?.languageUpdatedDesc(lang) ??
          "Your app language has been changed to $lang successfully!",
      btnOkText: t?.ok ?? "OK",
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context); // can be null if not ready

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset("assets/images/ribon.png", width: 24),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              t?.appTitle ?? "AI-Based Breast Cancer Detection App",
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: const Color(0xffFF67CE),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _service.streamUser(userDocId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading settings: ${snapshot.error}',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'User settings not found in Firestore.\nCheck the document id.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }

          final bool isDarkMode = (data['darkMode'] ?? false) as bool;
          final String languageCode = (data['languageCode'] ?? 'en') as String;
          final String selectedLanguage = _languageFromCode(languageCode);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xffFF67CE),
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xffFF67CE),
                          size: 18,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RootPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Image.asset(
                    "assets/images/settings.png",
                    width: 373,
                    height: 249,
                  ),
                  Center(
                    child: Text(
                      t?.settings ?? "Settings",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 27,
                        color: const Color(0xffFF67CE),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t?.changeLanguage ?? "Change Language",
                      style: GoogleFonts.poppins(
                        color: const Color(0xffFF67CE),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedLanguage,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xffFF67CE),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xffFF67CE),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xffFF67CE),
                          width: 2,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down_circle_outlined,
                      color: Color(0xffFF67CE),
                    ),
                    dropdownColor: Colors.white,
                    items: languages.map((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(
                          language,
                          style: GoogleFonts.poppins(
                            color: const Color(0xffFF67CE),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) async {
                      if (newValue == null) return;

                      final code = _codeFromLanguage(newValue);

                      // ✅ 1) Save preference to Firestore
                      await _service.updateLanguage(userDocId, code);

                      // ✅ 2) Apply instantly
                      LocaleController.setLocale(code);

                      if (!mounted) return;
                      _showLanguageChangedDialog(newValue);
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t?.darkMode ?? "Dark Mode",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xffFF67CE),
                        ),
                      ),
                      Switch(
                        value: isDarkMode,
                        onChanged: (value) async {
                          await _service.updateDarkMode(userDocId, value);
                        },
                        activeColor: const Color(0xffFF67CE),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
