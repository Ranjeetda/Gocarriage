import 'package:flutter/material.dart';

import '../../resource/app_colors.dart';
import '../../resource/step_progress_header.dart';

class QuickBookingScreen extends StatefulWidget {
  const QuickBookingScreen({super.key});

  @override
  State<QuickBookingScreen> createState() => _QuickBookingScreen();
}

class _QuickBookingScreen extends State<QuickBookingScreen> {

  int currentStep = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Quick Booking',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// STEP HEADER
            StepProgressHeader(currentStep: currentStep),

            const SizedBox(height: 20),

            /// STEP CONTENT
            if (currentStep == 1) buildStep1(),
            if (currentStep == 2) buildStep2(),
            if (currentStep == 3) buildStep3(),

            const SizedBox(height: 30),

            /// BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                if (currentStep > 1)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentStep--;
                      });
                    },
                    child: const Text("Back"),
                  ),

                ElevatedButton(
                  onPressed: () {

                    if (currentStep < 3) {
                      setState(() {
                        currentStep++;
                      });
                    }

                  },
                  child: Text(currentStep == 3 ? "Finish" : "Next"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

///////////////////////////////////////////////////////////
  /// STEP 1
///////////////////////////////////////////////////////////

  Widget buildStep1() {
    return Column(
      children:  [

        const SizedBox(height: 20),

        /// PICKUP + DELIVERY
        Row(
          children: const [
            Expanded(
              child: CustomField(
                label: "Pickup Location",
                hint: "Area name or pincode",
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: CustomField(
                label: "Delivery Location",
                hint: "Area name or pincode",
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        /// DATE + VEHICLES
        Row(
          children: const [
            Expanded(
              child: CustomField(
                label: "Booking Date & Time",
                hint: "dd/mm/yyyy",
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: CustomField(
                label: "No. of Vehicles",
                hint: "1",
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        /// MATERIAL TYPE
        const CustomField(
          label: "Material Type",
          hint: "Select material type",
        ),

        const SizedBox(height: 20),

        /// CARGO SPECIFICATION
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Cargo Specification",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.scale)
                  ],
                ),

                SizedBox(height: 12),

                CustomField(
                  label: "Weight",
                  hint: "Enter weight in KG",
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        /// VEHICLE TYPE
        Container(
          width: double.infinity,
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              Icon(Icons.local_shipping, size: 32),
              SizedBox(width: 12),
              Text(
                "Select Vehicle Type",
                style: TextStyle(fontSize: 16),
              )
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// ADVANCED INSTRUCTIONS
        ExpansionTile(
          title: const Text("Advanced Instructions"),
          children: [

            Row(
              children: const [
                Expanded(
                  child: CustomField(
                    label: "Loading Time (hrs)",
                    hint: "0",
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: CustomField(
                    label: "Unloading Time (hrs)",
                    hint: "0",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const CustomField(
              label: "Additional Notes",
              hint: "Special instructions...",
            ),

            const SizedBox(height: 10),
          ],
        ),

      ],
    );
  }

///////////////////////////////////////////////////////////
  /// STEP 2
///////////////////////////////////////////////////////////

  Widget buildStep2() {
    return Column(
      children: [

        /// MARKET PRICE RANGE
        _marketPriceSection(),

        const SizedBox(height: 10),
        _priceOfferSection(),
        const SizedBox(height: 10),
        _sendQuotationCard()
      ],
    );
  }

  Widget _marketPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Market Price Range",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Step 1 of 2"),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _priceBox(
                  title: "Min Price",
                  price: "₹1,000",
                  subtitle: "lowest listed",
                  color: Colors.red.shade50,
                  priceColor: Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _priceBox(
                  title: "Vehicles",
                  price: "2",
                  subtitle: "32 ft Container Truck",
                  color: Colors.orange.shade50,
                  priceColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _priceBox(
                  title: "Max Price",
                  price: "₹4,999",
                  subtitle: "highest listed",
                  color: Colors.green.shade50,
                  priceColor: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// Price Range Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.orange, Colors.green],
              ),
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("₹1,000"),
              Text("₹4,999"),
            ],
          )
        ],
      ),
    );
  }

  Widget _priceBox({
    required String title,
    required String price,
    required String subtitle,
    required Color color,
    required Color priceColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: priceColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _priceOfferSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Your Price Offer",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 20),

          const Text("Offered Price per Vehicle"),

          const SizedBox(height: 8),

          TextField(
            decoration: InputDecoration(
              hintText: "₹ e.g. 900",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text("Wait Time for Responses"),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time),
                SizedBox(width: 8),
                Text("6 hours"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _sendQuotationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Send Quotation",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.orange,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "Customer details will be added after vehicle owners respond to your offer.",
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Send Quotation to Owners",style: TextStyle(color: Colors.white),),
            ),
          )
        ],
      ),
    );
  }

///////////////////////////////////////////////////////////
  /// STEP 3
///////////////////////////////////////////////////////////

  Widget buildStep3() {
    return Column(
      children: const [

        Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 90,
        ),

        SizedBox(height: 20),

        Text(
          "Booking Confirmed!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10),

        Text("Your vehicle booking has been successfully completed.")
      ],
    );
  }
}


class CustomField extends StatelessWidget {

  final String label;
  final String hint;

  const CustomField({
    super.key,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(label),

        const SizedBox(height: 6),

        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}