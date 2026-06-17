import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/Utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../provider_service/add_car_provider.dart';
import '../../../provider_service/draft_vehicle_provider.dart';
import '../../../provider_service/file_upload_provider.dart';
import '../../../provider_service/vehicle_brands_provider.dart';
import '../../../provider_service/vehicle_documents_bulk_provider.dart';
import '../../../provider_service/vehicle_model_provider.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/pref_utils.dart';

class EditVehicleScreen extends StatefulWidget {
  String? mVehicleId;

  EditVehicleScreen(this.mVehicleId);

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  int step = 0;

  /// CONTROLLERS
  final regNo = TextEditingController();
  final regDate = TextEditingController();
  final vehicleCategoryController = TextEditingController();
  final city = TextEditingController();
  final payload = TextEditingController();
  final chassis = TextEditingController();
  final engine = TextEditingController();
  final insuranceCompany = TextEditingController();
  final policyNo = TextEditingController();
  bool isUpdate = false;
  bool isLoading = false;
  String? selectedColorName;
  Color? selectedColor;
  bool? selected;
  Map<String, dynamic>? setModel;
  bool _isModelSet = false;
  /// DROPDOWN VALUES
  String? brand,
      model,
      fuel,
      permit,
      status,
      service,
      roadTax,
      isNegotiable,
      selectedTaxPeriod,
      taxFrom,
      taxTo,
      lastPaidDate,
      fleetId,
      vehicleTypeId,vehicle_model_id;
  List<String> selectedPermitStates = [];
  bool _isFetched = false;

  /// FILES
  File? rc, fitness, permitDoc, insurance;
  String? rcUrl, fitnessUrl, permitDocUrl, insuranceUrl;

  /// DATE VALUES
  String? rcFrom, rcTo, fitFrom, fitTo, permitFrom, permitTo, insFrom, insTo;

  /// Lists
  List<PollutionCertificateModel> pollutionList = [PollutionCertificateModel()];

  /// Pollution
  void addPollution() {
    setState(() => pollutionList.add(PollutionCertificateModel()));
  }

  void removePollution(int i) {
    setState(() => pollutionList.removeAt(i));
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<VehicleBrandsProvider>(
        context,
        listen: false,
      );
      await provider.fetchBrands();
    });
    if (widget.mVehicleId != null) {
      isUpdate = true;
      fleetId = widget.mVehicleId;
      fetchData();
    } else {
      isUpdate = false;
    }
  }

  Future<void> fetchData() async {
    if (_isFetched) return;
    _isFetched = true;

    final provider = Provider.of<DraftVehicleProvider>(context, listen: false);
    await provider.fetchDraftVehicle(widget.mVehicleId!);
    final data = provider.vehicleQutation;
    final providerVehicleBrand = Provider.of<VehicleBrandsProvider>(context, listen: false,);
    final vehicleModelProvider = Provider.of<VehicleModelProvider>(context, listen: false,);


    setState(() {
      regNo.text = data['vehicle_number'];
      regDate.text = Utils.formatDate(data['registered_date']);
      city.text = data['location']['current_city' ?? ""];
      payload.text = (data['payload']?.toString() ?? "").replaceAll(
        RegExp(r'\.00$'),
        "",
      );

      if (Utils.capitalize(data['status']) == 'Draft') {
        status = 'Inactive';
      } else {
        status = Utils.capitalize(data['status']);
      }
      chassis.text = data['chassis_number'] ?? "";
      engine.text = data['engine_number'] ?? "";
      city.text = data['rto'] ?? "";
      insuranceCompany.text = data['insurance_company'] ?? "";
      policyNo.text = data['insurance_policy_number'] ?? "";
      selectedColorName = data['color'] ?? "";
      providerVehicleBrand.setSelectedBrand(data['vehicleModel']?['brand']);
      vehicleModelProvider.fetchVehicleModel(data['vehicleModel']?['brand']);
      setModel=data['vehicleModel'];
      model=data['vehicleModel']['modal'];
      vehicleTypeId=data['VehicleType']?['id'].toString();
      vehicleCategoryController.text=data['vehicleModel']?['v_cat'];
      vehicle_model_id=data['vehicleModel']?['id'].toString();

      brand = providerVehicleBrand.selectedBrand;
      final docs = data['documents'];

      if (docs != null && docs is List && docs.isNotEmpty) {
        for (var item in docs) {
          if (item['document_type'] == 'rc_document') {
            rcFrom = item['valid_from'] ?? '';
            rcTo = item['valid_to'] ?? '';
            rcUrl = item['file_path'] ?? '';
          } else if (item['document_type'] == 'fitness_certificate') {
            fitFrom = item['valid_from'] ?? '';
            fitTo = item['valid_to'] ?? '';
            fitnessUrl = item['file_path'] ?? '';
          } else if (item['document_type'] == 'permit_document') {
            permitFrom = item['valid_from'] ?? '';
            permitTo = item['valid_to'] ?? '';
            permitDocUrl = item['file_path'] ?? '';
          } else if (item['document_type'] == 'insurance') {
            insFrom = item['valid_from'] ?? '';
            insTo = item['valid_to'] ?? '';
            insuranceUrl = item['file_path'] ?? '';
          }
        }
      }

      final pollution = data['pollutionCertificates'];

      if (pollution is List && pollution.isNotEmpty) {
        pollutionList.clear(); // optional safety

        for (int i = 0; i < pollution.length; i++) {
          final e = pollution[i];

          final model = PollutionCertificateModel(
            state: e['state'],
            fileUrl: e['file_upload'],
            validFrom:
                e['valid_from'] != null
                    ? DateTime.tryParse(e['valid_from'])
                    : null,
            validTo:
                e['valid_to'] != null ? DateTime.tryParse(e['valid_to']) : null,
          );

          pollutionList.add(model);

          // 🔍 Debug (optional)
          print("Index: $i → validTo: ${model.validTo}");
        }
      } else {
        pollutionList.clear();
        pollutionList.add(PollutionCertificateModel());
      }

      fuel = data['fuel_type'];
      if (data['permit_type'] != null &&
          data['permit_type'] == 'State Permit') {
        permit = 'State permit';
      } else if (data['permit_type'] != null &&
          data['permit_type'] == 'No Permit') {
        permit = 'No permit';
      }

      if (data['permit_states'] != null) {
        var permitStates = data['permit_states'];

        if (permitStates is String) {
          selectedPermitStates =
              permitStates
                  .replaceAll('[', '')
                  .replaceAll(']', '')
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
        } else if (permitStates is List) {
          selectedPermitStates = permitStates.map((e) => e.toString()).toList();
        }
      }

      selectedTaxPeriod =
          data['road_tax_paid_period'] == null
              ? null
              : Utils.capitalize(data['road_tax_paid_period']);
      if (selectedTaxPeriod != null) {
        selected = true;
      }
      lastPaidDate = data['tax_paid_date'] ?? null;
      isNegotiable = (data['is_negotiable'] ?? false) ? 'Yes' : 'No';
      roadTax = (data['road_tax_paid'] ?? false) ? 'Yes' : 'No';

      if (data['service_type']?.toString() == 'in_city') {
        service = 'Within City';
      } else {
        service = data['service_type']?.toString();
      }
    });

    print("Vehicle Number: ${data['vehicle_number']}");
  }

  /// ================= FUNCTIONS =================

  Future<void> pickFile(Function(File) onPicked, int position) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      File pickedFile = File(result.files.single.path!);
      onPicked(pickedFile);
      _fileUpload('vehicle-documents', pickedFile, 'Pollution', position);
    }
  }

  Future<DateTime?> pickDate() async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  /// ================= POLLUTION UI =================
  Widget buildPollutionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Pollution Certificate", style: TextStyle(fontSize: 18)),
              ElevatedButton(onPressed: addPollution, child: Text("Add More")),
            ],
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: pollutionList.length,
            itemBuilder: (context, index) {
              final item = pollutionList[index];
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Cert #${index + 1}"),
                      if (index != 0)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removePollution(index),
                        ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: item.state,
                    hint: const Text("Select State"),
                    items:
                        Utils.indiaStates.map((e) {
                          return DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          );
                        }).toList(),
                    onChanged: (v) {
                      setState(() {
                        item.state = v;
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),

                      // ✅ Rectangle border
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          8,
                        ), // small radius = rectangle look
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          pickFile((f) => setState(() => item.file = f), index);
                        },
                        child: Text("Upload"),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.file?.path.split('/').last ?? "No file",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          key: ValueKey(item.validFrom),
                          // ✅ IMPORTANT
                          initialValue:
                              item.validFrom == null
                                  ? ""
                                  : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(item.validFrom!),
                          onTap: () async {
                            var d = await pickDate();
                            if (d != null) {
                              setState(() {
                                item.validFrom = d;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: "Valid From",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          key: ValueKey(item.validTo),
                          // ✅ IMPORTANT
                          initialValue:
                              item.validTo == null
                                  ? ""
                                  : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(item.validTo!),
                          onTap: () async {
                            var d = await pickDate();
                            if (d != null) {
                              setState(() {
                                item.validTo = d;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: "Valid To",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 30),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// ================= STEP HEADER (UPDATED) =================
  Widget stepHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          stepItem("Basic Info", 0),
          stepItem("Vehicle Details", 1),
          stepItem("Documents", 2),
        ],
      ),
    );
  }

  Widget stepItem(String title, int index) {
    bool active = step == index;

    return Expanded(
      child: GestureDetector(
        onTap:
            () => setState(() {
              //step = index;
            }),
        // onTap: () => setState(() => step = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.teal,
            borderRadius: BorderRadius.circular(12),
            border: active ? Border.all(color: Colors.teal, width: 2) : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: active ? Colors.teal : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// ================= BODY =================
  Widget body() {
    switch (step) {
      case 0:
        return basicUI();
      case 1:
        return vehicleUI();
      case 2:
        return documentUI();
      default:
        return basicUI();
    }
  }

  /// White Background Card (for Basic Info)
  Widget cardWhite({required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Pure White Background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ), // Optional light border
      ),
      child: child,
    );
  }

  /// ================= BASIC =================
  Widget basicUI() {
    final vehicleModelProvider = Provider.of<VehicleModelProvider>(
      context,
      listen: false,
    );
    return cardWhite(
      child: Column(
        children: [
          card(
            child: Column(
              children: [
                vehicleField(regNo),
                gap(),
                dateField1("Registration Date", regDate),
                gap(),
                // Brand Dropdown
                Consumer<VehicleBrandsProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: provider.selectedBrand,
                          decoration: const InputDecoration(
                            labelText: "Vehicle Brand *",
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items:
                          provider.vehicleBrands.map((brand) {
                            return DropdownMenuItem<String>(
                              value: brand,
                              child: Text(brand),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              provider.setSelectedBrand(value);
                              brand=value;
                              vehicleModelProvider.fetchVehicleModel(value);
                            }
                          },
                        ),
                        SizedBox(height: 10),
                        Consumer<VehicleModelProvider>(
                          builder: (context, provider, _) {

                            if (provider.isLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            // ✅ RUN ONLY ONCE AFTER BUILD
                            if (!_isModelSet && setModel != null && provider.models.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                provider.setSelectedModelById(setModel?['id']);
                              });
                              _isModelSet = true;
                            }

                            return DropdownButtonFormField<Map<String, dynamic>>(
                              value: provider.models.any(
                                    (item) => item['id'] == provider.selectedModel?['id'],
                              )
                                  ? provider.selectedModel
                                  : null,

                              decoration: const InputDecoration(
                                labelText: "Select Model *",
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text("Select Model"),
                              isExpanded: true,

                              items: provider.models.map((item) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: item,
                                  child: Text(item['model']),
                                );
                              }).toList(),

                              onChanged: (value) {
                                provider.setSelectedModel(value);

                                vehicle_model_id = value?['id'].toString();
                                vehicleTypeId = value?['category_id'].toString();
                                model = value?['model'];
                                vehicleCategoryController.text = value?['v_cat'];
                                payload.text = value!['payload_capacity_kg'].toString();
                              },
                            );
                          },
                        )
                      ],
                    );
                  },
                ),
                gap(),
                text('Vehicle Category *'),
                field(vehicleCategoryController),
                text('Payload *'),
                field(payload),

                gap(),
                text("Service City *"),
                field(city),
                gap(),
                text("Status"),
                dropdown(
                  "Status",
                  ["Active", "Inactive", "Under Maintenance"],
                  status,
                  (v) => setState(() {
                    status = v;
                  }),
                ),
                gap(),
                radioRow(
                  "Service Type *",
                  ["Within City", "Outside City"],
                  service,
                  (v) => setState(() => service = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= Vehicle Details =================

  void _showMultiSelectStateBottomSheet() {
    List<String> tempSelected = List.from(selectedPermitStates);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.5, // ← Half Screen
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 20,
                  bottom: 20,
                ),
                child: Column(
                  children: [
                    Text(
                      "Select States",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Search Field
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search state...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        // Live search can be added later
                      },
                    ),
                    SizedBox(height: 12),

                    // States List
                    Expanded(
                      child: ListView.builder(
                        itemCount: Utils.indiaStates.length,
                        itemBuilder: (context, index) {
                          String state = Utils.indiaStates[index];
                          bool isSelected = tempSelected.contains(state);

                          return CheckboxListTile(
                            title: Text(state),
                            value: isSelected,
                            activeColor: Colors.teal,
                            onChanged: (bool? checked) {
                              setModalState(() {
                                if (checked == true) {
                                  tempSelected.add(state);
                                } else {
                                  tempSelected.remove(state);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedPermitStates = List.from(tempSelected);
                              });
                              Navigator.pop(context);
                            },
                            child: Text("Done"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget vehicleUI() {
    return cardWhite(
      child: Column(
        children: [
          card(
            child: Column(
              children: [
                dropdown(
                  "Permit Type *",
                  ["National permit", "State permit", "No permit"],
                  permit,
                  (v) {
                    setState(() {
                      permit = v;
                      if (v != "State permit") {
                        selectedPermitStates.clear();
                      }
                    });
                  },
                ),
                gap(),
                // === MULTI-SELECT SEARCHABLE STATES ===
                if (permit == "State permit") ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Select States *",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showMultiSelectStateBottomSheet(),
                    child: Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedPermitStates.isEmpty
                                  ? "Select States"
                                  : selectedPermitStates.join(", "),
                              style: TextStyle(
                                color:
                                    selectedPermitStates.isEmpty
                                        ? Colors.grey
                                        : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
                gap(),
                dropdown(
                  "Fuel Type *",
                  ["Diesel", "Petrol", "CNG", "Electric"],
                  fuel,
                  (v) => setState(() => fuel = v),
                ),
                gap(),
                text("Payload (kg) *"),
                field(payload),
                gap(),
                text("RTO / Registered State"),
                field(city),
                gap(),
                text("Chassis Number"),
                field(chassis),
                gap(),
                text("Engine Number"),
                field(engine),
                gap(),
                radioRow(
                  "Is Price Negotiable?",
                  ["Yes", "No"],
                  isNegotiable,
                  (v) => setState(() {
                    isNegotiable = v;
                  }),
                ),
                gap(),

                radioRow(
                  "Road Tax Paid?",
                  ["Yes", "No"],
                  roadTax,
                  (v) => setState(() {
                    roadTax = v;
                    // selectedTaxPeriod = null;
                  }),
                ),
                gap(),
                if (roadTax == 'Yes') ...[
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Tax Period",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children:
                        ["Monthly", "Half-Yearly", "Yearly", "Custom"].map((e) {
                          selected = selectedTaxPeriod == e;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedTaxPeriod = e;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      selected!
                                          ? Colors.teal.shade100
                                          : Colors.white,
                                  border: Border.all(
                                    color:
                                        selected! ? Colors.teal : Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    e,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],

                if (roadTax == 'Yes' && selectedTaxPeriod == "Custom") ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: date("From", taxFrom, (v) => taxFrom = v),
                      ),
                      gapW(),
                      Expanded(child: date("To", taxTo, (v) => taxTo = v)),
                    ],
                  ),
                ],
                if (roadTax == 'Yes' &&
                    selectedTaxPeriod != null &&
                    selectedTaxPeriod != "Custom") ...[
                  const SizedBox(height: 12),
                  date("Last Paid Date", lastPaidDate, (v) => lastPaidDate = v),
                ],
                buildColorPicker(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= Documents =================

  Widget documentUI() {
    return cardWhite(
      child: Column(
        children: [
          doc(
            "RC Document",
            (f) => rc = f,
            rcFrom,
            rcTo,
            (v) => rcFrom = v,
            (v) => rcTo = v,
          ),
          doc(
            "Fitness Certificate",
            (f) => fitness = f,
            fitFrom,
            fitTo,
            (v) => fitFrom = v,
            (v) => fitTo = v,
          ),
          doc(
            "Permit Document",
            (f) => permitDoc = f,
            permitFrom,
            permitTo,
            (v) => permitFrom = v,
            (v) => permitTo = v,
          ),
          card(
            child: Column(
              children: [
                text("Insurance Company"),
                field(insuranceCompany),
                gap(),
                text("Policy Number"),
                field(policyNo),
                gap(),
                upload(
                  fileType: 'Insurance',
                  file: insurance,
                  fileUrl: insuranceUrl,
                  onPick: (f) => setState(() => insurance = f),
                ),
                gap(),
                Row(
                  children: [
                    Expanded(child: date("From", insFrom, (v) => insFrom = v)),
                    gapW(),
                    Expanded(child: date("To", insTo, (v) => insTo = v)),
                  ],
                ),
                gap(),
                buildPollutionSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= COMMON UI =================
  Widget card({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget field(TextEditingController c) {
    return TextField(
      controller: c,
      decoration: InputDecoration(border: OutlineInputBorder()),
    );
  }

  Widget vehicleField(TextEditingController c) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        hintText: "Enter vehicle number (e.g. BR01AB1234)",
        labelText: "Vehicle Registration *",
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Vehicle number is required";
        }

        // Indian vehicle number format validation
        final RegExp vehicleRegex = RegExp(
          r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$',
        );

        if (!vehicleRegex.hasMatch(value.toUpperCase())) {
          return "Enter valid vehicle number (e.g. BR01AB1234)";
        }

        return null;
      },
    );
  }

  Widget text(String t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(t, style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget dropdown(
    String label,
    List<String> items,
    String? value,
    Function(String) onChange,
  ) {
    return DropdownButtonFormField(
      value: value,
      hint: Text(label),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChange(v as String),
      decoration: InputDecoration(border: OutlineInputBorder()),
    );
  }

  Widget radioRow(
    String label,
    List<String> options,
    String? group,
    Function(String) onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text(label),
        Row(
          children:
              options.map((e) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(e),
                    child: Container(
                      margin: EdgeInsets.all(4),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            group == e
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                          ),
                          SizedBox(width: 6),
                          Text(e, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget upload({
    required String fileType,
    required File? file,
    required String? fileUrl, // ✅ NEW
    required Function(File) onPick,
  }) {
    return GestureDetector(
      onTap: () async {
        FilePickerResult? r = await FilePicker.platform.pickFiles();
        if (r != null && r.files.single.path != null) {
          File pickedFile = File(r.files.single.path!);

          onPick(pickedFile); // update UI

          _fileUpload('vehicle-documents', pickedFile, fileType, 0);

          print("Picked File => $fileType");
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                file != null
                    ? file.path.split('/').last
                    : (fileUrl != null && fileUrl.isNotEmpty
                        ? fileUrl.split('/').last
                        : "Upload File"),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      (file != null || (fileUrl != null && fileUrl.isNotEmpty))
                          ? Colors.black
                          : Colors.grey,
                ),
              ),
            ),

            /// 👁️ Eye Icon
            if (file != null || (fileUrl != null && fileUrl.isNotEmpty))
              GestureDetector(
                onTap: () async {
                  if (file != null) {
                    // ✅ open local file
                    //openFile(file);
                  } else if (fileUrl != null) {
                    // ✅ open URL
                  }
                },
                child: const Icon(Icons.remove_red_eye, color: Colors.teal),
              ),
          ],
        ),
      ),
    );
  }

  /////////////////// Upload image /////////////////////////////////

  Future<void> _fileUpload(
    String folderName,
    File? fileName,
    String mType,
    int position,
  ) async {
    if (fileName == null) return;
    print("RanjeetTest============> callll uper _fileUpload ${"_fileUpload"}");

    showUploadingDialog(context);
    print("RanjeetTest============> callll _fileUpload ${"_fileUpload"}");

    final response = await Provider.of<FileUploadProvider>(
      context,
      listen: false,
    ).uploadFileOnServer(folder: folderName, mFile: fileName);

    if (!mounted) return;
    Navigator.pop(context);

    if (response != null && response['success'] == true) {
      final message = response['message'] ?? 'File uploaded successfully';
      final fileKey = response['data']?['key'];

      setState(() {
        if (mType == "Insurance") {
          insuranceUrl = fileKey;
        } else if (mType == "Permit Document") {
          permitDocUrl = fileKey;
        } else if (mType == "Fitness Certificate") {
          fitnessUrl = fileKey;
        } else if (mType == "RC Document") {
          rcUrl = fileKey;
        } else if (mType == "Pollution") {
          pollutionList[position].fileUrl = fileKey;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else {
      final message = response?['message'] ?? 'Upload failed';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> showUploadingDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  LinearProgressIndicator(minHeight: 8),
                  SizedBox(height: 16),
                  Text("Wait we are uploading your documents"),
                ],
              ),
            ),
          ),
    );
  }

  /////////////////////////////////////////////////////////////////

  Widget date(String label, String? value, Function(String) onPick) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: value ?? ""),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        DateTime? d = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );
        setState(() {
          if (d != null) onPick(DateFormat("yyyy-MM-dd").format(d));
        });
      },
    );
  }

  Widget dateField(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        DateTime? d = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );
        if (d != null) {
          c.text = DateFormat("yyyy-MM-dd").format(d);
        }
      },
    );
  }

  Widget dateField1(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        DateTime? d = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );
        if (d != null) {
          setState(() {
            rcFrom = DateFormat("yyyy-MM-dd").format(d);
          });
          c.text = DateFormat("yyyy-MM-dd").format(d);
        }
      },
    );
  }

  Widget doc(
    String title,
    Function(File) onPick,
    String? from,
    String? to,
    Function(String) setFrom,
    Function(String) setTo,
  ) {
    return card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text(title),
          if (title == 'RC Document')
            upload(
              fileType: 'RC Document',
              file: rc,
              fileUrl: rcUrl,
              onPick: (f) => setState(() => rc = f),
            ),
          if (title == 'Fitness Certificate')
            upload(
              fileType: 'Fitness Certificate',
              file: fitness,
              fileUrl: fitnessUrl,
              onPick: (f) => setState(() => fitness = f),
            ),
          if (title == 'Permit Document')
            upload(
              fileType: 'Permit Document',
              file: permitDoc,
              fileUrl: permitDocUrl,
              onPick: (f) => setState(() => permitDoc = f),
            ),
          gap(),
          Row(
            children: [
              Expanded(child: date("From", from, setFrom)),
              gapW(),
              Expanded(child: date("To", to, setTo)),
            ],
          ),
        ],
      ),
    );
  }

  // ================= IMPROVED COLOR PICKER =================
  Widget buildColorPicker() {
    List<VehicleColor> colorList = [
      VehicleColor("White", Colors.white),
      VehicleColor("Silver", Colors.grey.shade400),
      VehicleColor("Gray", Colors.grey),
      VehicleColor("Black", Colors.black),
      VehicleColor("Red", Colors.red),
      VehicleColor("Maroon", Colors.brown.shade700),
      VehicleColor("Blue", Colors.blue),
      VehicleColor("Navy", Colors.indigo.shade900),
      VehicleColor("Green", Colors.green),
      VehicleColor("Yellow", Colors.yellow),
      VehicleColor("Orange", Colors.orange),
      VehicleColor("Cream", Colors.yellow.shade100),
      VehicleColor("Brown", Colors.brown),
      VehicleColor("Sky Blue", Colors.lightBlue),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vehicle Color",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // Color Circles Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  colorList.map((item) {
                    bool isSelected = selectedColorName == item.name;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColorName = item.name;
                          selectedColor = item.color;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: item.color,
                              child:
                                  isSelected
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                      : null,
                              foregroundColor:
                                  item.color == Colors.white
                                      ? Colors.black
                                      : Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Selected Color Display
        if (selectedColorName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 12, backgroundColor: selectedColor),
                const SizedBox(width: 8),
                Text(
                  selectedColorName!,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColorName = null;
                      selectedColor = null;
                    });
                  },
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget gap() => SizedBox(height: 12);

  Widget gapW() => SizedBox(width: 10);

  /// ================= BUTTON =================
  Widget bottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (step > 0)
          ElevatedButton(
            onPressed: () => setState(() => step--),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: Text("Back", style: TextStyle(color: Colors.white)),
          ),
        ElevatedButton(
          onPressed: () {
            if (regNo.text.isEmpty) {
              Utils.showErrorMessage(context, 'Please enter registration no');
              return;
            } else if (regDate.text.isEmpty) {
              Utils.showErrorMessage(context, 'Please enter registration date');
              return;
            } else if (brand == null) {
              Utils.showErrorMessage(context, 'Please select brand');
              return;
            } else if (city.text.isEmpty) {
              Utils.showErrorMessage(context, 'Please enter your city');
              return;
            } else if (service == null) {
              Utils.showErrorMessage(context, 'Please select service type');
              return;
            }
            if (step < 2) {
              setState(() => step++);
            } else {
              submit();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
          child:
              (step == 2 && isLoading)
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                    step == 2 ? "Update Vehicle" : "Next",
                    style: const TextStyle(color: Colors.white),
                  ),
        ),
      ],
    );
  }

  /// ================= SUBMIT & PRINT ALL DATA =================

  Future<void> submit() async {
    final provider = Provider.of<AddCarProvider>(context, listen: false);

    try {
      setState(() => isLoading = true);

      final response = await provider.validateAddNewCar(
        isUpdate: isUpdate,
        vehicle_number: regNo.text.trim(),
        vehicle_type_id: vehicleTypeId,
        owner_id: PrefUtils.getUserId(),
        fleetId: fleetId,
        current_city: city.text.trim(),
        service_type: service == 'Within City' ? 'in_city' : service,
        status: 'Active',
        registered_date: regDate.text.trim(),
        rto: city.text.trim(),
        permit_type: permit ?? "No Permit",
        permit_states: selectedPermitStates.toString(),
        chassis_number: chassis.text.trim(),
        engine_number: engine.text.trim(),
        engine_no: engine.text.trim(),
        fuel_type: fuel,
        color: selectedColorName,
        payload: payload.text.trim(),
        is_negotiable: isNegotiable == 'Yes',
        road_tax_paid: roadTax == "Yes",
        road_tax_paid_period: selectedTaxPeriod,
        tax_paid_date: lastPaidDate,
        insurance_from_date: insFrom,
        insurance_upto: insTo,
        rc_validity_from_date: rcFrom,
        rc_validity_date: rcTo,
        fitness_validity_from_date: fitFrom,
        fitness_validity_date: fitTo,
        permit_from_date: permitFrom,
        permit_to_date: permitTo,
        pollution_validity_date:
            pollutionList.isEmpty
                ? ""
                : pollutionList[0].validTo != null
                ? DateFormat('yyyy-MM-dd').format(pollutionList[0].validTo!)
                : null,
        brand: brand,
        model: model,
        vehicle_model_id:vehicle_model_id,
        pollution_certificates: jsonEncode(
          pollutionList
              .map(
                (p) => {
                  "state": p.state,
                  "file_upload": p.fileUrl,
                  "valid_from":
                      p.validFrom != null
                          ? DateFormat('yyyy-MM-dd').format(p.validFrom!)
                          : null,
                  "valid_to":
                      p.validTo != null
                          ? DateFormat('yyyy-MM-dd').format(p.validTo!)
                          : null,
                },
              )
              .toList(),
        ),
        rcDocument: rcUrl,
        fitnessCertificate: fitnessUrl,
        permitDocument: permitDocUrl,
        insurance: insuranceUrl,
      );

      setState(() => isLoading = false);

      /// ✅ SAFE RESPONSE HANDLING
      final bool success = response?['success'] ?? false;
      final String message = response?['message'] ?? "Something went wrong";

      /// ✅ GET VEHICLE ID SAFELY
      if (success == true) {
        setState(() {
          isUpdate = true;
          fleetId = response?['data']?['id']?.toString();
        });
      } else {
        isUpdate = false;
      }

      /// ✅ SHOW SNACKBAR BASED ON API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      /// ✅ FLOW CONTROL
      if (success) {
        if (fleetId != null) {
          _documentUpload(response!['data']['id'].toString());
        } else {
          debugPrint("❌ Vehicle ID missing in response");
        }
      }
    } catch (e) {
      setState(() => isLoading = false);

      debugPrint("❌ Exception: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _documentUpload(String vehicleId) async {
    List<Map<String, dynamic>> documents = [];

    /// 🔹 Build documents list FIRST
    if (rc != null && rcUrl!.isNotEmpty) {
      documents.add({
        "document_type": "rc_document",
        "file_path": rcUrl,
        "original_filename": rc!.path,
        "file_type": "image/png",
        "valid_from": rcFrom,
        "valid_to": rcTo,
      });
    }

    if (fitness != null && fitnessUrl!.isNotEmpty) {
      documents.add({
        "document_type": "fitness_certificate",
        "file_path": fitnessUrl,
        "original_filename": fitness!.path,
        "file_type": "image/png",
        "valid_from": fitFrom,
        "valid_to": fitTo,
      });
    }

    if (permitDoc != null && permitDocUrl!.isNotEmpty) {
      documents.add({
        "document_type": "permit_document",
        "file_path": permitDocUrl,
        "original_filename": permitDoc!.path,
        "file_type": "image/png",
        "valid_from": permitFrom,
        "valid_to": permitTo,
      });
    }

    if (insurance != null && insuranceUrl!.isNotEmpty) {
      documents.add({
        "document_type": "insurance",
        "file_path": insuranceUrl,
        "original_filename": insurance!.path,
        "file_type": "image/png",
        "valid_from": insFrom,
        "valid_to": insTo,
        "company_name": insuranceCompany.text.trim(),
        "policy_number": policyNo.text.trim(),
      });
    }

    /// 🚨 Safety check
    if (documents.isEmpty) {
      print("⚠️ No documents to upload");
      Navigator.pop(context);
      return;
    }

    setState(() {
      isLoading = true;
    });
    final provider = Provider.of<VehicleDocumentsBulkProvider>(
      context,
      listen: false,
    );

    try {
      final response = await provider.validateVehicleBuckDocumentUpload(
        mVehicleId: vehicleId,
        documents: documents, // ✅ PASS HERE
      );
      setState(() {
        isLoading = false;
      });
      print("✅ FULL RESPONSE: $response");

      if (response != null && response['success'] == true) {
        print("🎉 Success: ${response['message']}");
        Navigator.pop(context);
      } else {
        print("⚠️ Failed: ${response?['message']}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("❌ ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Vehicle",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          stepHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: body(),
            ),
          ),
          Padding(padding: EdgeInsets.all(16), child: bottom()),
        ],
      ),
    );
  }
}

class PollutionCertificateModel {
  String? state;
  File? file;
  String? fileUrl;
  DateTime? validFrom;
  DateTime? validTo;

  PollutionCertificateModel({
    this.state,
    this.file,
    this.fileUrl,
    this.validFrom,
    this.validTo,
  });
}

class VehicleColor {
  final String name;
  final Color color;

  VehicleColor(this.name, this.color);
}
