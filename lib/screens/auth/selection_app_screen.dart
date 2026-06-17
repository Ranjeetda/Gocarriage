import 'package:flutter/material.dart';
import '../../resource/app_colors.dart';
import '../dialogBox/login_register_dialog.dart';
import '../model/grid_item.dart';

class SelectionAppScreen extends StatefulWidget {
  const SelectionAppScreen({Key? key}) : super(key: key);

  @override
  State<SelectionAppScreen> createState() => _SelectionAppScreenState();
}

class _SelectionAppScreenState extends State<SelectionAppScreen> {

  final List<GridItem> items = [
    GridItem("Customer", Icons.person),
    GridItem("Operator", Icons.support_agent),
    GridItem("Vehicle Owner", Icons.local_shipping),
    GridItem("Driver", Icons.person),
   /* GridItem("Fuel Station", Icons.local_gas_station),
    GridItem("Restaurant", Icons.restaurant),
    GridItem("Service", Icons.build),*/
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        centerTitle: true,
        title: const Text(
          'Select Your Account Type',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'CustomFont',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: serviceGrid(),
      ),
    );
  }

  /// 🔥 Vertical Grid View
  Widget serviceGrid() {
    return GridView.builder(
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,        // number of columns
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,      // square cards
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => LoginRegisterDialog(item.title),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 36,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
