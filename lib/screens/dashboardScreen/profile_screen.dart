// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';

import '../../resource/app_colors.dart';

/// Local image paths you uploaded (keeps original local path as requested).
const String shot1 = '/mnt/data/Screenshot 2025-11-22 at 12.20.46 PM.png';
const String shot2 = '/mnt/data/Screenshot 2025-11-22 at 12.21.15 PM.png';
const String shot3 = '/mnt/data/Screenshot 2025-11-22 at 12.14.20 PM.png';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // expansion state for each panel
  final Map<String, bool> _expanded = {
    'personal': true,
    'contact': true,
    'address': true,
    'bank': false,
    'documents': false,
    'credentials': false,
  };

  // controllers with sample values (from the screenshots)
  final TextEditingController nameCtrl = TextEditingController(text: 'Manish');
  final TextEditingController emailCtrl =
  TextEditingController(text: 'manish@abc.com');
  final TextEditingController companyCtrl = TextEditingController();
  final TextEditingController contactNameCtrl =
  TextEditingController(text: 'Manish');
  final TextEditingController contactPhoneCtrl =
  TextEditingController(text: '9717586443');
  final TextEditingController addressCtrl = TextEditingController(
      text: 'Nyay Khand 3 indirapuram ghaziabad');
  final TextEditingController pinCtrl = TextEditingController(text: '201014');
  final TextEditingController cityCtrl =
  TextEditingController(text: 'ghaziabad');
  final TextEditingController ifscCtrl =
  TextEditingController(text: 'HDFC0000590');
  final TextEditingController bankNameCtrl =
  TextEditingController(text: 'hdfc');
  final TextEditingController accountCtrl =
  TextEditingController(text: '1023894392394');
  final TextEditingController branchCtrl =
  TextEditingController(text: 'indirapuram');
  final TextEditingController usernameCtrl =
  TextEditingController(text: '10082500801');
  final TextEditingController passwordCtrl =
  TextEditingController(text: 'LG#12epb');

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    companyCtrl.dispose();
    contactNameCtrl.dispose();
    contactPhoneCtrl.dispose();
    addressCtrl.dispose();
    pinCtrl.dispose();
    cityCtrl.dispose();
    ifscCtrl.dispose();
    bankNameCtrl.dispose();
    accountCtrl.dispose();
    branchCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Widget headerRow(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple.shade700),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Colors.deepPurple.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6F6F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // mobile-friendly paddings & sizes
    final EdgeInsets pagePadding =
    const EdgeInsets.symmetric(horizontal: 18, vertical: 14);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Profile',style: TextStyle(color: Colors.white),),
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        foregroundColor:Colors.white,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content scroll
            Padding(
              padding: EdgeInsets.only(
                  bottom: 90), // leave space for bottom button bar
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // PERSONAL INFO
                    Padding(
                      padding: pagePadding,
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ExpansionTile(
                          initiallyExpanded: _expanded['personal'] ?? true,
                          onExpansionChanged: (v) =>
                              setState(() => _expanded['personal'] = v),
                          leading: Icon(Icons.person,
                              color: Colors.deepPurple.shade700),
                          title: Text('Personal Information',
                              style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.bold)),
                          childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          children: [
                            labeledField(
                              'Operator Name *',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your name",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            labeledField(
                              'Email *',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your email",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            labeledField(
                              'Company Name (Optional)',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your company",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // CONTACT PERSON
                    Padding(
                      padding: pagePadding,
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ExpansionTile(
                          initiallyExpanded: _expanded['contact'] ?? true,
                          onExpansionChanged: (v) =>
                              setState(() => _expanded['contact'] = v),
                          leading:
                          Icon(Icons.phone, color: Colors.deepPurple.shade700),
                          title: Text('Contact Person',
                              style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.bold)),
                          childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          children: [
                            labeledField(
                              'Contact Person Name *',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your contact person name",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            labeledField(
                              'Contact Phone *',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your contact phone",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            labeledField(
                              'Contact Email (Optional)',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your contact email",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // ADDRESS INFORMATION
                    Padding(
                      padding: pagePadding,
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ExpansionTile(
                          initiallyExpanded: _expanded['address'] ?? true,
                          onExpansionChanged: (v) =>
                              setState(() => _expanded['address'] = v),
                          leading: Icon(Icons.location_on,
                              color: Colors.deepPurple.shade700),
                          title: Text('Address Information',
                              style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.bold)),
                          childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          children: [
                            labeledField(
                              'Address *',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your address",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: labeledField(
                                    'Pin Code *',
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {}); // refresh UI to show/hide clear button
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Enter your pin code",
                                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: labeledField(
                                    'City *',
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {}); // refresh UI to show/hide clear button
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Enter your city",
                                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    // DOCUMENTS (driving licence optional)
                    Padding(
                      padding: pagePadding,
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ExpansionTile(
                          initiallyExpanded: _expanded['documents'] ?? false,
                          onExpansionChanged: (v) =>
                              setState(() => _expanded['documents'] = v),
                          leading: Icon(Icons.insert_drive_file,
                              color: Colors.deepPurple.shade700),
                          title: Text('Government Documents',
                              style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.bold)),
                          childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          children: [
                            labeledField(
                              'PAN Number *',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your pan number",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              onPressed: () {
                                // pick file (left as exercise)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Choose file (stub)')),
                                );
                              },
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Upload Document'),
                            ),

                            SizedBox(height: 10,),
                            labeledField(
                              'Aadhar Number *',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your aadhar number",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              onPressed: () {
                                // pick file (left as exercise)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Choose file (stub)')),
                                );
                              },
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Upload Document'),
                            ),

                            SizedBox(height: 10,),
                            labeledField(
                              'GST Certificate (Optional)',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your gst certificate",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              onPressed: () {
                                // pick file (left as exercise)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Choose file (stub)')),
                                );
                              },
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Upload Document'),
                            ),

                            SizedBox(height: 10,),
                            labeledField(
                              'Driving Licence (Optional)',
                              TextField(
                                onChanged: (value) {
                                  setState(() {}); // refresh UI to show/hide clear button
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your driving Licence",
                                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              onPressed: () {
                                // pick file (left as exercise)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Choose file (stub)')),
                                );
                              },
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Upload Document'),
                            ),
                            SizedBox(height: 10,),
                          ],
                        ),
                      ),
                    ),

                    // BANK DETAILS
                    Padding(
                      padding: pagePadding,
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ExpansionTile(
                          initiallyExpanded: _expanded['bank'] ?? false,
                          onExpansionChanged: (v) =>
                              setState(() => _expanded['bank'] = v),
                          leading: Icon(Icons.account_balance,
                              color: Colors.deepPurple.shade700),
                          title: Text('Bank Details',
                              style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.bold)),
                          childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: labeledField(
                                    'IFSC Code *',
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {}); // refresh UI to show/hide clear button
                                      },
                                      decoration: InputDecoration(
                                        hintText: "IFSC Code",
                                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: labeledField(
                                    'Bank Name *',
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {}); // refresh UI to show/hide clear button
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Bank Name",
                                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: labeledField(
                                    'Account Number *',
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {}); // refresh UI to show/hide clear button
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Account Number",
                                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: labeledField(
                                    'Branch Address *',
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {}); // refresh UI to show/hide clear button
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Branch Address",
                                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    // Note section
                    Padding(
                      padding: pagePadding,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Note: Fields marked with * are required to complete your profile. Documents for PAN and Aadhar are mandatory. Optional documents (GST, Driving Licence) can be added later.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // bottom action bar (sticky)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, -2))
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.button_color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // small stub for "complete later"
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved for later')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Complete Later',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // small helper: attempt to show local image (if file exists), otherwise placeholder box
  Widget _buildPreviewThumb(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, height: 64, fit: BoxFit.cover),
        );
      } else {
        return _placeholderThumb();
      }
    } catch (_) {
      return _placeholderThumb();
    }
  }

  Widget _placeholderThumb() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(child: Icon(Icons.image_outlined, size: 28)),
    );
  }

  void _onSave() {
    // collect values and show (in a real app you would validate & send to server)
    final summary = '''
Name: ${nameCtrl.text}
Email: ${emailCtrl.text}
Contact: ${contactPhoneCtrl.text}
Address: ${addressCtrl.text}, ${cityCtrl.text} - ${pinCtrl.text}
Bank IFSC: ${ifscCtrl.text}, A/C: ${accountCtrl.text}
''';
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Profile Saved (demo)'),
        content: SingleChildScrollView(child: Text(summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
