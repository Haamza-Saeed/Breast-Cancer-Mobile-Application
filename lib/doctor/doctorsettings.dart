import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import 'package:project/doctor/doctorrootpage.dart';
import 'package:project/l10n/app_localizations.dart';
import 'package:project/services/locale_controller.dart';

class DoctorSettings extends StatefulWidget {
  const DoctorSettings({super.key});

  @override
  State<DoctorSettings> createState() => _DoctorSettingsState();
}

class _DoctorSettingsState extends State<DoctorSettings> {
  static const Color doctorBlue = Color(0xff00AEEF);

  bool isDarkMode = false;
  String selectedLanguage = 'English';
  bool _loading = true;

  // UI language names (keep as these)
  final List<String> languages = const ['English', 'Urdu'];

  String _languageFromCode(String code) => code == 'ur' ? 'Urdu' : 'English';
  String _codeFromLanguage(String lang) => lang == 'Urdu' ? 'ur' : 'en';

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final data = doc.data() ?? {};

      final bool dm = (data['darkMode'] ?? false) as bool;
      final String code = (data['languageCode'] ?? 'en').toString();

      if (!mounted) return;
      setState(() {
        isDarkMode = dm;
        selectedLanguage = _languageFromCode(code);
        _loading = false;
      });

      // ✅ Apply locale immediately on open
      LocaleController.setLocale(code);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
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

  Future<void> _saveLanguage(String lang) async {
    final code = _codeFromLanguage(lang);

    // ✅ save to firestore (per doctor)
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      "languageCode": code,
    }, SetOptions(merge: true));

    // ✅ apply instantly
    LocaleController.setLocale(code);

    if (!mounted) return;
    _showLanguageChangedDialog(lang);
  }

  Future<void> _saveDarkMode(bool value) async {
    setState(() => isDarkMode = value);

    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      "darkMode": value,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

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
                color: doctorBlue,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    border: Border.all(color: doctorBlue, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: doctorBlue,
                      size: 18,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorRootPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Image.asset("assets/images/settings.png",
                  width: 373, height: 249),
              Center(
                child: Text(
                  t?.settings ?? "Settings",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 27,
                    color: doctorBlue,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.changeLanguage ?? "Change Language",
                  style: GoogleFonts.poppins(
                    color: doctorBlue,
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
                      horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: doctorBlue, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: doctorBlue, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: doctorBlue, width: 2),
                  ),
                ),
                icon: const Icon(
                  Icons.arrow_drop_down_circle_outlined,
                  color: doctorBlue,
                ),
                dropdownColor: Colors.white,
                items: languages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(
                      language,
                      style: GoogleFonts.poppins(
                        color: doctorBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) async {
                  if (newValue == null) return;
                  setState(() => selectedLanguage = newValue);
                  await _saveLanguage(newValue);
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
                      color: doctorBlue,
                    ),
                  ),
                  Switch(
                    value: isDarkMode,
                    onChanged: (value) async {
                      await _saveDarkMode(value);
                    },
                    activeColor: doctorBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}