import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class CustomerProfileSetupPage extends StatefulWidget {
  const CustomerProfileSetupPage({super.key});

  @override
  State<CustomerProfileSetupPage> createState() =>
      _CustomerProfileSetupPageState();
}

class _CustomerProfileSetupPageState extends State<CustomerProfileSetupPage> {
  int _currentStep = 0;
  final _phoneNumber = TextEditingController();
  bool _isExportSelected = false;
  bool _isDomesticSelected = false;

  List<Widget> getSteps(BuildContext context) {
    return [
      SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: Utils().width(context) * 0.7,
              child: Text(
                textAlign: TextAlign.center,
                'Some basic information to get you started.',
                style: AppTextStyles.black22_600,
              ),
            ),
            // widgets for step 1
            SizedBox(height: 16),
            SizedBox(
              width: Utils().width(context) * 0.9,
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Type',
                        style: AppTextStyles.black14_600,
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
                                    // Optionally, unselect "Domestic" if "Export" is selected
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
                                    // Optionally, unselect "Export" if "Domestic" is selected
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
                      )
                    ],
                  ),
                  SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mobile number',
                        style: AppTextStyles.black14_600,
                      ),
                      CustomTextField(
                        controller: _phoneNumber,
                        height: 50,
                        hintText: 'Enter your mobile number',
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GST number',
                        style: AppTextStyles.black14_600,
                      ),
                      CustomTextField(
                        controller: _phoneNumber,
                        height: 50,
                        hintText: 'Enter GST No.',
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAN number',
                        style: AppTextStyles.black14_600,
                      ),
                      CustomTextField(
                        controller: _phoneNumber,
                        height: 50,
                        hintText: 'Enter PAN No.',
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      Column(
        children: [
          SizedBox(
            width: Utils().width(context) * 0.7,
            child: Text(
              textAlign: TextAlign.center,
              'Some basic information to get you started.',
              style: AppTextStyles.black22_600,
            ),
          ),
          // Add your widgets for step 2 here
        ],
      ),
      Column(
        children: [
          SizedBox(
            width: Utils().width(context) * 0.7,
            child: Text(
              textAlign: TextAlign.center,
              'Some basic information to get you started.',
              style: AppTextStyles.black22_600,
            ),
          ),
          // Add your widgets for step 3 here
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            Image.asset(
              'assets/icons/app_logo.png',
              height: 200,
              width: Utils().width(context) * 0.7,
            ),
            SizedBox(height: 20),
            Expanded(
              child: getSteps(context)[_currentStep],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    CustomButton(
                      text: 'Back',
                      backgroundColor: Colors.white,
                      textColor: AppColors.blue,
                      width: Utils().width(context) * 0.4,
                      height: 50,
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                    ),
                  Spacer(),
                  CustomButton(
                    text: _currentStep == getSteps(context).length - 1
                        ? 'Finish'
                        : 'Next',
                    onPressed: () {
                      if (_currentStep < getSteps(context).length - 1) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Completed'),
                            content: Text('All steps completed!'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    backgroundColor: AppColors.blue,
                    width: Utils().width(context) * 0.4,
                    height: 50,
                  ),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     if (_currentStep < getSteps(context).length - 1) {
                  //       setState(() {
                  //         _currentStep++;
                  //       });
                  //     } else {
                  //       showDialog(
                  //         context: context,
                  //         builder: (context) => AlertDialog(
                  //           title: Text('Completed'),
                  //           content: Text('All steps completed!'),
                  //           actions: [
                  //             TextButton(
                  //               onPressed: () => Navigator.of(context).pop(),
                  //               child: Text('OK'),
                  //             ),
                  //           ],
                  //         ),
                  //       );
                  //     }
                  //   },
                  //   child: Text(_currentStep == getSteps(context).length - 1
                  //       ? 'Finish'
                  //       : 'Next'),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
