import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/l10n/app_localizations.dart';

class ChatRequest extends StatefulWidget {
  const ChatRequest({super.key});

  @override
  State<ChatRequest> createState() => _ChatRequestState();
}

class _ChatRequestState extends State<ChatRequest> {
  final Color pink = const Color(0xffFF67CE);

  bool _loadingDoctors = true;
  bool _sending = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> doctors = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? selectedDoctor;

  @override
  void initState() {
    super.initState();
    _loadDoctorsFiltered();
  }

  // ✅ Load approved doctors but hide those that already approved patient request
  Future<void> _loadDoctorsFiltered() async {
    setState(() => _loadingDoctors = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        doctors = [];
        return;
      }

      // 1) Approved doctors
      final doctorSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('approved', isEqualTo: true)
          .get();

      // 2) Patient approved requests -> doctorIds
      final approvedReqSnap = await FirebaseFirestore.instance
          .collection('chatRequests')
          .where('patientId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved') // ✅ doctor approved
          .get();

      final Set<String> approvedDoctorIds = approvedReqSnap.docs
          .map((d) => (d.data()['doctorId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      // 3) Filter doctors
      doctors = doctorSnap.docs
          .where((doc) => !approvedDoctorIds.contains(doc.id))
          .toList();
    } catch (_) {
      doctors = [];
    } finally {
      if (mounted) {
        setState(() {
          _loadingDoctors = false;
        });
      }
    }
  }

  String _fullName(Map<String, dynamic> d) {
    final fn = (d['firstName'] ?? '').toString().trim();
    final ln = (d['lastName'] ?? '').toString().trim();
    final name = "$fn $ln".trim();
    return name.isEmpty ? "Doctor" : name; // fallback (not shown often)
  }

  Widget _profileRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              "$label:",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: pink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: const Color(0xff333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getPatientData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  void _showLoadingDialog() {
    final t = AppLocalizations.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              t?.sendingRequest ?? "Sending request...",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ).show();
  }

  void _showSuccessDialog() {
    final t = AppLocalizations.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: t?.successTitle ?? "Success",
      desc: t?.requestSentSuccessfully ?? "Request sent successfully!",
      btnOkOnPress: () {},
      btnOkText: t?.ok ?? "OK",
    ).show();
  }

  void _showErrorDialog(String msg) {
    final t = AppLocalizations.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: t?.errorTitle ?? "Error",
      desc: msg,
      btnOkOnPress: () {},
      btnOkText: t?.ok ?? "OK",
    ).show();
  }

  Future<void> _sendChatRequest() async {
    final t = AppLocalizations.of(context);

    if (selectedDoctor == null) {
      _showErrorDialog(t?.pleaseSelectDoctorFirst ?? "Please select a doctor first.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_sending) return;
    setState(() => _sending = true);

    _showLoadingDialog();

    try {
      final patientData = await _getPatientData(user.uid);
      if (patientData == null) {
        if (!mounted) return;
        Navigator.pop(context);
        _showErrorDialog(t?.patientDataNotFound ?? "Patient data not found.");
        return;
      }

      final doctorData = selectedDoctor!.data();
      final doctorId = selectedDoctor!.id;
      final doctorName = _fullName(doctorData);

      // ✅ Prevent duplicate pending OR approved request (both)
      final existing = await FirebaseFirestore.instance
          .collection('chatRequests')
          .where('patientId', isEqualTo: user.uid)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', whereIn: ['pending', 'approved'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        _showErrorDialog(t?.alreadyRequestedDoctor ?? "You already requested this doctor.");
        return;
      }

      final patientName = _fullName(patientData);
      final patientEmail = (patientData['email'] ?? user.email ?? '').toString().trim();

      // ✅ Save request record
      await FirebaseFirestore.instance.collection('chatRequests').add({
        "patientId": user.uid,
        "patientName": patientName,
        "patientEmail": patientEmail,
        "doctorId": doctorId,
        "doctorName": doctorName,
        "doctorEmail": (doctorData['email'] ?? '').toString().trim(),
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      _showSuccessDialog();

      setState(() {
        selectedDoctor = null;
      });

      await _loadDoctorsFiltered();
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog(t?.failedToSendRequest ?? "Failed to send request.");
    } finally {
      if (mounted) setState(() => _sending = false);
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
                color: pink,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: pink, width: 2),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: pink, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Image.asset("assets/images/notification.png", width: 373, height: 249),

              Text(
                t?.chatARequest ?? "Chat Request",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: pink,
                ),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.approvedDoctors ?? "Approved Doctors",
                  style: GoogleFonts.poppins(
                    color: pink,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (_loadingDoctors)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: CircularProgressIndicator(),
                )
              else if (doctors.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    t?.noDoctorsAvailable ?? "No doctors available right now.",
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedDoctor?.id,
                  hint: Text(
                    t?.selectDoctor ?? "Select Doctor",
                    style: GoogleFonts.poppins(color: pink),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: pink, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: pink, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: pink, width: 2),
                    ),
                  ),
                  icon: Icon(Icons.arrow_drop_down_circle_outlined, color: pink),
                  items: doctors.map((doc) {
                    final data = doc.data();
                    final name = _fullName(data);
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: pink,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final found = doctors.firstWhere((element) => element.id == id);
                    setState(() => selectedDoctor = found);
                  },
                ),

              const SizedBox(height: 20),

              if (selectedDoctor != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: pink, width: 2),
                  ),
                  child: Builder(builder: (_) {
                    final d = selectedDoctor!.data();
                    final img = (d['profileImagePath'] ?? '').toString().trim();

                    final experienceVal = (d['experience'] ?? '').toString().trim();
                    final experienceText = experienceVal.isEmpty
                        ? ""
                        : "${experienceVal} ${t?.years ?? "years"}";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage: img.isNotEmpty
                                  ? NetworkImage(img)
                                  : const AssetImage("assets/images/profileblue.png")
                              as ImageProvider,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _fullName(d),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: pink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _profileRow(t?.email ?? "Email", (d['email'] ?? '').toString()),
                        _profileRow(t?.age ?? "Age", (d['age'] ?? '').toString()),
                        _profileRow(t?.experience ?? "Experience", experienceText),
                        _profileRow(
                          t?.specialization ?? "Specialization",
                          (d['specialization'] ?? '').toString(),
                        ),
                        _profileRow(
                          t?.qualifications ?? "Qualifications",
                          (d['qualification'] ?? '').toString(),
                        ),
                        _profileRow(
                          t?.description ?? "Description",
                          (d['description'] ?? '').toString(),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_sending || doctors.isEmpty) ? null : _sendChatRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t?.request ?? "Request",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}