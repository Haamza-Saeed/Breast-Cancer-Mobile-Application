import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/adminrootpage.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class AddADoctor extends StatefulWidget {
  const AddADoctor({super.key});

  @override
  State<AddADoctor> createState() => _AddADoctorState();
}

// ⚠️ Better to keep controllers inside State, but I’m keeping your structure.
final TextEditingController emailController = TextEditingController();
final TextEditingController nameController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

bool _obscurePassword = true;

class _AddADoctorState extends State<AddADoctor> {
  static const Color adminGreen = Color(0xff00EFAB);

  String selectedGender = "Female";
  final List<String> genders = ["Male", "Female", "Other"];

  // ✅ localized gender label
  String _genderLabel(AppLocalizations? t, String gender) {
    switch (gender) {
      case "Male":
        return t?.genderMale ?? "Male";
      case "Female":
        return t?.genderFemale ?? "Female";
      case "Other":
        return t?.genderOther ?? "Other";
      default:
        return gender;
    }
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
                color: adminGreen,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: adminGreen, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: adminGreen,
                      size: 18,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminRootPage()),
                      );
                    },
                  ),
                ),
              ),
              Image.asset("assets/images/addadoctor.png", width: 373, height: 249),

              Text(
                t?.addDoctorTitle ?? "Add Doctor",
                style: GoogleFonts.poppins(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: adminGreen,
                ),
              ),
              const SizedBox(height: 15),

              // Doctor Name
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.doctorNameLabel ?? "Doctor Name",
                  style: GoogleFonts.poppins(
                    color: adminGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: t?.enterDoctorName ?? "Enter doctor name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Gender
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.genderLabel ?? "Gender",
                  style: GoogleFonts.poppins(
                    color: adminGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: selectedGender,
                icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: adminGreen),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                ),
                items: genders.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(
                      _genderLabel(t, gender),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedGender = value);
                },
              ),
              const SizedBox(height: 15),

              // Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.email ?? "Email",
                  style: GoogleFonts.poppins(
                    color: adminGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: t?.enterEmail ?? "Enter email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.password ?? "Password",
                  style: GoogleFonts.poppins(
                    color: adminGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: t?.enterPassword ?? "Enter password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: adminGreen,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: adminGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Add button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t?.nameCannotBeEmpty ?? "Name cannot be empty")),
                      );
                      return;
                    }

                    if (emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t?.emailCannotBeEmpty ?? "Email cannot be empty")),
                      );
                      return;
                    }

                    if (passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t?.passwordCannotBeEmpty ?? "Password cannot be empty")),
                      );
                      return;
                    }

                    if (!emailController.text.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t?.emailMissingAt ?? "Your email does not contain @. Please include @.",
                          ),
                        ),
                      );
                      return;
                    }

                    if (passwordController.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t?.passwordTooShort ?? "Password can't be less than 8 characters",
                          ),
                        ),
                      );
                      return;
                    }

                    // TODO: your create-doctor logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: adminGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    t?.add ?? "Add",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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