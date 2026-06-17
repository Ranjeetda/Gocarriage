import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';
import '../../provider_service/help_support_provider.dart';
import '../../resource/Utils.dart';

class HelpSupportScreen extends StatefulWidget {
  String? title;

  HelpSupportScreen(this.title);

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _discriptionController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();


  Future<void> _submitHelpSupportUser() async {

    if (_formKey.currentState!.validate()) {
      if (_nameController.text.isEmpty) {
        Utils.showErrorMessage(context, 'Please enter your name.');
        return;
      }else if (_emailController.text.isEmpty) {
        Utils.showErrorMessage(context, 'Please enter you email');
        return;
      }else if (_phoneController.text.isEmpty) {
        Utils.showErrorMessage(context, 'Please enter your mobile no.');
        return;
      } else if (_discriptionController.text.isEmpty) {
        Utils.showErrorMessage(context, 'please enter a description');
        return;
      }
      setState(() {
        isLoading = true;
      });

      final response = await Provider.of<HelpSupportProvider>(context,
          listen: false)
          .sendHelpSupportRequestService(_nameController.text,_emailController.text,_phoneController.text,_discriptionController.text);

      setState(() {
        isLoading = false;
      });
      if (response['code'] == '200') {
        setState(() {
          String errorMessage = response['message'] ??'Help & Support in failed. Please try again.';
          Utils.showToast1(context, errorMessage);
          isLoading = false;
          Navigator.pop(context);
        });
      } else {
        setState(() {
          isLoading = false;
        });
        String errorMessage = response['message'] ??'Help & Support in failed. Please try again.';
        Utils.showErrorMessage(context, errorMessage);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.title!,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
          
                // Name Field
                TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
          
                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email ID',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Contact Number Field
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Enter your contact number',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
          
                const SizedBox(height: 16),
          
                // Message Field
                TextField(
                  controller: _discriptionController,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
          
                const SizedBox(height: 24),
          
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _submitHelpSupportUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor, // Match bg_btn_shape
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      "Submit",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'TitilliumWeb',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
