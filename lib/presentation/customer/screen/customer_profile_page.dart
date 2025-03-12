import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  bool _isExportSelected = false;
  bool _isDomesticSelected = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _number = TextEditingController();
  final _gstNo = TextEditingController();
  final _panNo = TextEditingController();
  final _address = TextEditingController();
  final _materialType = TextEditingController();
  final _materialDescription = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                CircleAvatar(
                  radius: 55,
                  backgroundImage:
                      AssetImage('assets/images/profile_avataar.png'),
                ),
                Text(
                  'John',
                  style: AppTextStyles.black28_600,
                ),
                Text(
                  'Customer',
                  style:
                      AppTextStyles.black16_600.copyWith(color: Colors.black54),
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
                            color: Colors.black.withValues(alpha: 0.74),
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
                        child:
                            Text('Full Name', style: AppTextStyles.black14_600),
                      ),
                      CustomTextField(
                        controller: _name,
                        hintText: 'Enter Name',
                        height: 40,
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 5,
                        ),
                        child: Text('Email', style: AppTextStyles.black14_600),
                      ),
                      CustomTextField(
                        controller: _email,
                        hintText: 'Enter Email',
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
                        height: 40,
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 5,
                        ),
                        child:
                            Text('Address', style: AppTextStyles.black14_600),
                      ),
                      CustomTextField(
                        controller: _address,
                        hintText: 'Enter Address',
                        height: 40,
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 5,
                        ),
                        child: Text('Material Type',
                            style: AppTextStyles.black14_600),
                      ),
                      CustomTextField(
                        controller: _materialType,
                        hintText: 'Enter Material Type',
                        height: 40,
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 5,
                        ),
                        child: Text('Material Description',
                            style: AppTextStyles.black14_600),
                      ),
                      CustomTextField(
                        controller: _materialDescription,
                        hintText: 'Enter Material Description',
                        height: 120,
                        minLines: 2,
                        maxLines: 7,
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: CustomButton(
                          text: 'Update',
                          onPressed: () {},
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
