import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/models/address_model.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';
import 'package:kkp_chat_app/data/repositories/auth_repository.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final AuthRepository auth = AuthRepository();
  late Future<Profile> profileData;
  bool _isExportSelected = false;
  bool _isDomesticSelected = false;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _gstNo = TextEditingController();
  final TextEditingController _panNo = TextEditingController();
  final TextEditingController _houseNo = TextEditingController();
  final TextEditingController _streetName = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _pincode = TextEditingController();

  @override
  void initState() {
    super.initState();
    profileData = _loadUserInfo();
  }

  Future<Profile> _loadUserInfo() async {
    try {
      final profile = await auth.getUserInfo();
      if (mounted) {
        setState(() {
          _name.text = profile.name ?? '';
          _email.text = profile.email ?? '';
          _number.text = profile.mobile.toString();
          _gstNo.text = profile.gstNo ?? '';
          _panNo.text = profile.panNo ?? '';
          if (profile.address?.isNotEmpty == true) {
            final address = profile.address![0];
            _houseNo.text = address.houseNo ?? '';
            _streetName.text = address.streetName ?? '';
            _city.text = address.city ?? '';
            _pincode.text = address.pincode ?? '';
          }
          _isExportSelected = profile.customerType == 'Export';
          _isDomesticSelected = profile.customerType == 'Domestic';
        });
      }
      return profile;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return Profile(); // Return a default Profile object
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FutureBuilder<Profile>(
            future: profileData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data == null) {
                return Text('No data available');
              } else {
                final profile = snapshot.data!;
                final Address address = profile.address?.isNotEmpty == true
                    ? profile.address![0]
                    : Address();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      CircleAvatar(
                        radius: 55,
                        backgroundImage:
                            AssetImage('assets/images/profile_avataar.png'),
                      ),
                      Text(
                        profile.name ?? 'No Name',
                        style: AppTextStyles.black28_600,
                      ),
                      Text(
                        'Customer',
                        style: AppTextStyles.black16_600
                            .copyWith(color: Colors.black54),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: Utils().width(context) * 0.9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 5,
                              ),
                              child: Text(
                                'Customer Type',
                                style: AppTextStyles.black16_600.copyWith(
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      visualDensity: VisualDensity.compact,
                                      value: _isExportSelected,
                                      activeColor: AppColors.blue,
                                      onChanged: (value) {
                                        setState(() {
                                          _isExportSelected = value!;
                                          if (_isExportSelected) {
                                            _isDomesticSelected = false;
                                          }
                                        });
                                      },
                                    ),
                                    Text(
                                      'Export',
                                      style: AppTextStyles.black14_600,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _isDomesticSelected,
                                      visualDensity: VisualDensity.compact,
                                      activeColor: AppColors.blue,
                                      onChanged: (value) {
                                        setState(() {
                                          _isDomesticSelected = value!;
                                          if (_isDomesticSelected) {
                                            _isExportSelected = false;
                                          }
                                        });
                                      },
                                    ),
                                    Text(
                                      'Domestic',
                                      style: AppTextStyles.black14_600,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 5,
                              ),
                              child: Text('Full Name',
                                  style: AppTextStyles.black14_600),
                            ),
                            CustomTextField(
                              controller: _name,
                              hintText: 'Enter Name',
                              readOnly: true,
                              keyboardType: TextInputType.name,
                              height: 40,
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 5,
                              ),
                              child: Text('Email',
                                  style: AppTextStyles.black14_600),
                            ),
                            CustomTextField(
                              controller: _email,
                              hintText: 'Enter Email',
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                              height: 40,
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 5,
                              ),
                              child: Text('Mobile Number',
                                  style: AppTextStyles.black14_600),
                            ),
                            CustomTextField(
                              controller: _number,
                              height: 40,
                              hintText: 'Enter Mobile Number',
                              keyboardType: TextInputType.phone,
                              readOnly: true,
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 5,
                              ),
                              child: Text('GST Number',
                                  style: AppTextStyles.black14_600),
                            ),
                            CustomTextField(
                              controller: _gstNo,
                              hintText: 'Enter GST Number',
                              keyboardType: TextInputType.text,
                              maxLength: 15,
                              readOnly: true,
                              height: 40,
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 5,
                              ),
                              child: Text('PAN Number',
                                  style: AppTextStyles.black14_600),
                            ),
                            CustomTextField(
                              controller: _panNo,
                              hintText: 'Enter PAN Number',
                              keyboardType: TextInputType.text,
                              maxLength: 10,
                              readOnly: true,
                              height: 40,
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 5,
                              ),
                              child: Text('Address',
                                  style: AppTextStyles.black14_600),
                            ),
                            CustomTextField(
                              controller: _houseNo,
                              hintText: 'Enter House No',
                              readOnly: true,
                              height: 40,
                            ),
                            CustomTextField(
                              controller: _streetName,
                              hintText: 'Enter Street Name',
                              readOnly: true,
                              height: 40,
                            ),
                            CustomTextField(
                              controller: _city,
                              hintText: 'Enter City',
                              readOnly: true,
                              height: 40,
                            ),
                            CustomTextField(
                              controller: _pincode,
                              hintText: 'Enter Pincode',
                              readOnly: true,
                              height: 40,
                            ),
                            SizedBox(height: 20),
                            Center(
                              child: CustomButton(
                                text: 'Edit',
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    CustomerRoutes.customerProfileSetup,
                                    arguments: {
                                      "forUpdate": true,
                                      "name": _name.text,
                                      "email": _email.text,
                                      "number": _number.text,
                                      "gstNo": _gstNo.text,
                                      "panNo": _panNo.text,
                                      "houseNo": _houseNo.text,
                                      "streetName": _streetName.text,
                                      "city": _city.text,
                                      "pincode": _pincode.text,
                                      "isExportSelected": _isExportSelected,
                                      "isDomesticSelected": _isDomesticSelected,
                                    },
                                  );
                                },
                                height: 45,
                                elevation: 5,
                                width: Utils().width(context) * 0.5,
                                fontSize: 16,
                                backgroundColor: AppColors.bluePrimary,
                              ),
                            ),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
