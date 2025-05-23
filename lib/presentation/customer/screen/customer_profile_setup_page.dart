import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/address_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';

class CustomerProfileSetupPage extends StatefulWidget {
  const CustomerProfileSetupPage({
    super.key,
    required this.forUpdate,
    this.profile,
    this.name,
  });

  final bool forUpdate;
  final Profile? profile;
  final String? name;

  @override
  State<CustomerProfileSetupPage> createState() =>
      _CustomerProfileSetupPageState();
}

class _CustomerProfileSetupPageState extends State<CustomerProfileSetupPage> {
  int _currentStep = 0;
  final _name = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _gstNumber = TextEditingController();
  final _houseFlatNumber = TextEditingController();
  final _panNumber = TextEditingController();
  final _streetNumber = TextEditingController();
  final _pinCode = TextEditingController();
  final _cityName = TextEditingController();
  late bool _isExportSelected = true;
  late bool _isDomesticSelected = false;
  AuthRepository auth = AuthRepository();
  String? _customerType;
  DateTime? _lastPressed;

  // Error texts for each field
  String? _nameError;
  String? _phoneNumberError;
  String? _gstNumberError;
  String? _panNumberError;
  String? _houseFlatNumberError;
  String? _streetNumberError;
  String? _cityNameError;
  String? _pinCodeError;

  @override
  void initState() {
    super.initState();

    if (!widget.forUpdate) {
      _name.text = (widget.name ?? LocalDbHelper.getProfile()?.name)!;
    }

    // Initialize fields with passed arguments if updating
    if (widget.forUpdate && widget.profile != null) {
      _name.text = widget.profile!.name ?? '';
      _phoneNumber.text = widget.profile!.mobile.toString();
      _gstNumber.text = widget.profile!.gstNo ?? '';
      _panNumber.text = widget.profile!.panNo ?? '';
      if (widget.profile!.address != null &&
          widget.profile!.address!.isNotEmpty) {
        var address = widget.profile!.address![0];
        _houseFlatNumber.text = address.houseNo ?? '';
        _streetNumber.text = address.streetName ?? '';
        _cityName.text = address.city ?? '';
        _pinCode.text = address.pincode ?? '';
      }
      _isExportSelected = widget.profile!.customerType == 'Export';
      _isDomesticSelected = widget.profile!.customerType == 'Domestic';
    } else {
      // Set default customer type to Export
      _isExportSelected = true;
      _isDomesticSelected = false;
    }
    _customerType = _isExportSelected ? 'Export' : 'Domestic';
  }

  Future<void> _saveUserProfile(context) async {
    if (!mounted) return;

    // Construct the address object with only changed values
    Address? addressDetails;
    if (_houseFlatNumber.text.isNotEmpty ||
        _streetNumber.text.isNotEmpty ||
        _cityName.text.isNotEmpty ||
        _pinCode.text.isNotEmpty) {
      addressDetails = Address(
        houseNo:
            _houseFlatNumber.text.isNotEmpty ? _houseFlatNumber.text : null,
        streetName: _streetNumber.text.isNotEmpty ? _streetNumber.text : null,
        city: _cityName.text.isNotEmpty ? _cityName.text : null,
        pincode: _pinCode.text.isNotEmpty ? _pinCode.text : null,
      );
    }

    try {
      final response = await auth.updateUserDetails(
        name: _name.text.isNotEmpty ? _name.text : widget.name,
        number: _phoneNumber.text.isNotEmpty ? _phoneNumber.text : null,
        customerType: _customerType,
        gstNo: _gstNumber.text.isNotEmpty ? _gstNumber.text : null,
        panNo: _panNumber.text.isNotEmpty ? _panNumber.text : null,
        address: addressDetails,
      );

      if (response['message'] == "Item updated successfully") {
        if (!mounted) return;

        Profile updatedProfile = Profile.fromJson(response["data"]);

        await LocalDbHelper.saveProfile(updatedProfile);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response['message'])));

        // Return the updated profile and image URL to the previous screen
        if (widget.forUpdate) {
          Navigator.pop(context, updatedProfile);
        } else {
          Navigator.pushReplacementNamed(context, CustomerRoutes.customerHost);
        }
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        print(e.toString());
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAndroid12orAbove =
        Platform.isAndroid && int.parse(Platform.version.split('.')[0]) > 12;

    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: widget.forUpdate
            ? AppBar(
                leading: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: Text('Update Profile'),
              )
            : null,
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
                CustomButton(
                  text: _currentStep == getSteps(context).length - 1
                      ? 'Finish'
                      : 'Next',
                  onPressed: () {
                    if (widget.forUpdate || validateStep()) {
                      if (_currentStep < getSteps(context).length - 1) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        if (!_isDataChanged()) {
                          Navigator.pop(context);
                        } else {
                          _saveUserProfile(context);
                        }
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
      ),
    );

    return isAndroid12orAbove
        ? PopScope(
            onPopInvoked: (_) {
              DateTime now = DateTime.now();
              if (_lastPressed == null ||
                  now.difference(_lastPressed!) > Duration(seconds: 2)) {
                _lastPressed = now;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Press back again to exit"),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                // Allow system navigation
                Navigator.pop(context);
              }
            },
            child: content,
          )
        : WillPopScope(
            onWillPop: () async {
              DateTime now = DateTime.now();
              if (_lastPressed == null ||
                  now.difference(_lastPressed!) > Duration(seconds: 2)) {
                _lastPressed = now;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Press back again to exit"),
                    duration: Duration(seconds: 2),
                  ),
                );
                return false; // Do not exit yet
              }
              return true; // Proceed to exit
            },
            child: content,
          );
  }

  List<Widget> getSteps(BuildContext context) {
    return [
      step_0(context),
      step_1(context),
      step_2(context),
    ];
  }

  Widget step_0(BuildContext context) {
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
                  SizedBox(height: 10),
                  Initicon(
                    text: (widget.name ?? LocalDbHelper.getProfile()?.name)!,
                    elevation: 10,
                    size: 140,
                  ),
                  SizedBox(height: 10),
                ],
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name',
                    style: AppTextStyles.black14_600,
                  ),
                  CustomTextField(
                    controller: _name,
                    height: 50,
                    keyboardType: TextInputType.name,
                    hintText: 'Enter your name',
                    errorText: widget.forUpdate ? null : _nameError,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
      ],
    );
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
                    maxLength: 10,
                    keyboardType: TextInputType.phone,
                    hintText: 'Enter your mobile number',
                    errorText: widget.forUpdate ? null : _phoneNumberError,
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
                    keyboardType: TextInputType.text,
                    maxLength: 15,
                    errorText: widget.forUpdate ? null : _gstNumberError,
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
                    keyboardType: TextInputType.text,
                    maxLength: 10,
                    errorText: widget.forUpdate ? null : _panNumberError,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
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
                      keyboardType: TextInputType.text,
                      errorText:
                          widget.forUpdate ? null : _houseFlatNumberError,
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
                      keyboardType: TextInputType.text,
                      errorText: widget.forUpdate ? null : _streetNumberError,
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
                      errorText: widget.forUpdate ? null : _cityNameError,
                      keyboardType: TextInputType.text,
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
                      maxLength: 6,
                      hintText: 'Enter Pincode',
                      errorText: widget.forUpdate ? null : _pinCodeError,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  bool validateStep() {
    bool isValid = true;

    if (_currentStep == 0) {
      if (_name.text.isEmpty) {
        setState(() {
          _nameError = 'Name is required';
        });
        isValid = false;
      } else {
        _nameError = null;
      }
    } else if (_currentStep == 1) {
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
    } else if (_currentStep == 2) {
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

  bool _isDataChanged() {
    return _name.text != widget.profile?.name ||
        _phoneNumber.text != widget.profile?.mobile.toString() ||
        _gstNumber.text != widget.profile?.gstNo ||
        _panNumber.text != widget.profile?.panNo ||
        _houseFlatNumber.text != widget.profile?.address?[0].houseNo ||
        _streetNumber.text != widget.profile?.address?[0].streetName ||
        _cityName.text != widget.profile?.address?[0].city ||
        _pinCode.text != widget.profile?.address?[0].pincode ||
        _isExportSelected != (widget.profile?.customerType == 'Export') ||
        _isDomesticSelected != (widget.profile?.customerType == 'Domestic');
  }
}
