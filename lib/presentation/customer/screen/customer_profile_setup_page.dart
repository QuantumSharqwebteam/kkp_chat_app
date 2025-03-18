import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/models/address_model.dart';
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
  final _gstNumber = TextEditingController();
  final _houseFlatNumber = TextEditingController();
  final _panNumber = TextEditingController();
  final _streetNumber = TextEditingController();
  final _pinCode = TextEditingController();
  final _cityName = TextEditingController();
  bool _isExportSelected = false;
  bool _isDomesticSelected = false;
  AuthApi auth = AuthApi();
  String? _customerType;
  bool _isLoading = false;

  // Error texts for each field
  String? _phoneNumberError;
  String? _gstNumberError;
  String? _panNumberError;
  String? _houseFlatNumberError;
  String? _streetNumberError;
  String? _cityNameError;
  String? _pinCodeError;

  Future<void> _saveUserProfile(context) async {
    _isLoading = true;
    Address addressDetails = Address(
      city: _cityName.text,
      houseNo: _houseFlatNumber.text,
      pincode: _pinCode.text,
      streetName: _streetNumber.text,
    );
    try {
      final response = await auth.updateDetails(
        name: null,
        number: _phoneNumber.text,
        customerType: _customerType,
        gstNo: _gstNumber.text,
        panNo: _panNumber.text,
        address: addressDetails,
      );

      if (response['message'] == "Item updated successfully") {
        _isLoading = false;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response['message'])));
        Navigator.pushReplacementNamed(context, CustomerRoutes.customerHost);
      } else {
        _isLoading = false;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) {
        print(e.toString());
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
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
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: _currentStep == getSteps(context).length - 1
                          ? 'Finish'
                          : 'Next',
                      onPressed: () {
                        if (validateStep()) {
                          if (_currentStep < getSteps(context).length - 1) {
                            setState(() {
                              _currentStep++;
                            });
                          } else {
                            _saveUserProfile(context);
                          }
                        }
                      },
                      backgroundColor: AppColors.blue,
                      width: Utils().width(context) * 0.4,
                      height: 50,
                    ),
            ],
          ),
        ),
      ],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                Image.asset(
                  'assets/icons/app_logo.png',
                  height: 200,
                  width: Utils().width(context) * 0.7,
                ),
                SizedBox(height: 20),
                getSteps(context)[_currentStep],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> getSteps(BuildContext context) {
    return [
      step_1(context),
      step_2(context),
    ];
  }

  Widget step_1(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: Utils().width(context) * 0.9,
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
              SizedBox(height: 16),
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
                                _isDomesticSelected = !_isExportSelected;
                                _customerType =
                                    _isExportSelected ? 'Export' : 'Domestic';
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
                                _isExportSelected = !_isDomesticSelected;
                                _customerType =
                                    _isDomesticSelected ? 'Domestic' : 'Export';
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
                    errorText: _phoneNumberError,
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
                    controller: _gstNumber,
                    height: 50,
                    hintText: 'Enter GST No.',
                    errorText: _gstNumberError,
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
                    controller: _panNumber,
                    height: 50,
                    hintText: 'Enter PAN No.',
                    errorText: _panNumberError,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget step_2(BuildContext context) {
    return SingleChildScrollView(
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
          SizedBox(height: 16),
          SizedBox(
            width: Utils().width(context) * 0.9,
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'House/Flat No.',
                      style: AppTextStyles.black14_600,
                    ),
                    CustomTextField(
                      controller: _houseFlatNumber,
                      height: 50,
                      hintText: 'Enter house/flat no.',
                      errorText: _houseFlatNumberError,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Street Name',
                      style: AppTextStyles.black14_600,
                    ),
                    CustomTextField(
                      controller: _streetNumber,
                      height: 50,
                      hintText: 'Enter Street Name',
                      errorText: _streetNumberError,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'City Name',
                      style: AppTextStyles.black14_600,
                    ),
                    CustomTextField(
                      controller: _cityName,
                      height: 50,
                      hintText: 'Enter City Name',
                      errorText: _cityNameError,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pin Code',
                      style: AppTextStyles.black14_600,
                    ),
                    CustomTextField(
                      controller: _pinCode,
                      height: 50,
                      hintText: 'Enter Pincode',
                      errorText: _pinCodeError,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool validateStep() {
    bool isValid = true;

    if (_currentStep == 0) {
      if (_phoneNumber.text.isEmpty) {
        setState(() {
          _phoneNumberError = 'Mobile number is required';
        });
        isValid = false;
      } else {
        _phoneNumberError = null;
      }

      if (_gstNumber.text.isEmpty) {
        setState(() {
          _gstNumberError = 'GST number is required';
        });
        isValid = false;
      } else {
        _gstNumberError = null;
      }

      if (_panNumber.text.isEmpty) {
        setState(() {
          _panNumberError = 'PAN number is required';
        });
        isValid = false;
      } else {
        _panNumberError = null;
      }

      if (_customerType == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Validation Error'),
            content: Text('Please select a customer type.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        isValid = false;
      }
    } else if (_currentStep == 1) {
      if (_houseFlatNumber.text.isEmpty) {
        setState(() {
          _houseFlatNumberError = 'House/Flat number is required';
        });
        isValid = false;
      } else {
        _houseFlatNumberError = null;
      }

      if (_streetNumber.text.isEmpty) {
        setState(() {
          _streetNumberError = 'Street name is required';
        });
        isValid = false;
      } else {
        _streetNumberError = null;
      }

      if (_cityName.text.isEmpty) {
        setState(() {
          _cityNameError = 'City name is required';
        });
        isValid = false;
      } else {
        _cityNameError = null;
      }

      if (_pinCode.text.isEmpty) {
        setState(() {
          _pinCodeError = 'Pin code is required';
        });
        isValid = false;
      } else {
        _pinCodeError = null;
      }
    }

    return isValid;
  }
}
