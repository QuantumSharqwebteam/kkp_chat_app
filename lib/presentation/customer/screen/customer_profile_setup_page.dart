import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:indian_pincode_validator/indian_pincode_validator.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/address_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
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
  String? _completePhoneNumber;
  String? _countryCode;
  bool _isSavingProfile = false;

  // Error texts for each field
  String? _nameError;
  String? _phoneNumberError;
  String? _houseFlatNumberError;
  String? _streetNumberError;
  String? _cityNameError;
  String? _pinCodeError;
  String? _gstNumberError;
  String? _panNumberError;

  bool _isValidPinCode(String pinCode) {
    // Fast format check; full validation is done via package on submit.
    return IndianPinCodeValidator.isValidFormat(pinCode);
  }

  bool _isValidCityName(String city) {
    // Allows alphabetic city names with spaces/dot/hyphen/apostrophe separators.
    return RegExp(r"^[A-Za-z]+(?:[ .'-][A-Za-z]+)*$").hasMatch(city);
  }

  bool _isSameCity(String inputCity, String pinCity) {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r"[^a-z]"), "");
    return normalize(inputCity) == normalize(pinCity);
  }

  @override
  void initState() {
    super.initState();

    if (!widget.forUpdate) {
      _name.text = (widget.name ?? LocalDbHelper.getProfile()?.name)!;
    }

    // Initialize fields with passed arguments if updating
    if (widget.forUpdate && widget.profile != null) {
      _name.text = widget.profile!.name ?? '';

      // Parse the phone number for international field
      String phoneStr = widget.profile!.mobile.toString();
      if (phoneStr.startsWith('+')) {
        _completePhoneNumber = phoneStr;
        // Extract country code and phone number
        if (phoneStr.startsWith('+91')) {
          _countryCode = '+91';
          _phoneNumber.text = phoneStr.substring(3);
        } else {
          // For other countries, you might need more sophisticated parsing
          _phoneNumber.text = phoneStr;
        }
      } else {
        _phoneNumber.text = phoneStr;
        _countryCode = '+91'; // Default to India
        _completePhoneNumber = '+91$phoneStr';
      }

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
      _countryCode = '+91'; // Default to India
    }
    _customerType = _isExportSelected ? 'Export' : 'Domestic';
  }

  Future<void> _saveUserProfile() async {
    if (!mounted) return;

    if (_pinCode.text.isNotEmpty && !_isValidPinCode(_pinCode.text.trim())) {
      setState(() {
        _pinCodeError = 'Please enter a valid Indian PIN code';
        _isSavingProfile = false;
      });
      return;
    }

    if (_cityName.text.isNotEmpty && !_isValidCityName(_cityName.text.trim())) {
      setState(() {
        _cityNameError = 'Please enter a valid city name';
        _isSavingProfile = false;
      });
      return;
    }

    if (_pinCode.text.isNotEmpty) {
      final pinValidationResult = await IndianPinCodeValidator.validate(
        _pinCode.text.trim(),
      );

      if (!pinValidationResult.isValid) {
        setState(() {
          _pinCodeError =
              pinValidationResult.message ?? 'Please enter a valid Indian PIN code';
          _isSavingProfile = false;
        });
        return;
      }

      final enteredCity = _cityName.text.trim();
      final pinCity = (pinValidationResult.city ?? '').trim();
      if (enteredCity.isNotEmpty && pinCity.isNotEmpty && !_isSameCity(enteredCity, pinCity)) {
        setState(() {
          _cityNameError = 'City does not match the selected PIN code';
          _isSavingProfile = false;
        });
        return;
      }
    }

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
        number: _completePhoneNumber ?? _phoneNumber.text,
        customerType: _customerType,
        gstNo: _gstNumber.text.isNotEmpty ? _gstNumber.text : null,
        panNo: _panNumber.text.isNotEmpty ? _panNumber.text : null,
        address: addressDetails,
      );

      if (response['message'] == "Item updated successfully") {
        if (!mounted) return;

        Profile updatedProfile = Profile.fromJson(response["data"]);

        await LocalDbHelper.saveProfile(updatedProfile);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .profileDetailsUpdatedSuccessfully)));

        // Return the updated profile and image URL to the previous screen
        if (widget.forUpdate) {
          Navigator.pop(context, updatedProfile);
        } else {
          Navigator.pushReplacementNamed(context, CustomerRoutes.customerHost);
        }
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response[AppLocalizations.of(context)!.message])));
      }
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        print(e.toString());
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
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
                title: Text(AppLocalizations.of(context)!.updateProfile),
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
                    text: AppLocalizations.of(context)!.back,
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
                  isLoading: _currentStep == getSteps(context).length - 1 &&
                      _isSavingProfile,
                  onPressed: _isSavingProfile
                      ? null
                      : () async {
                          if (widget.forUpdate || validateStep()) {
                            if (_currentStep < getSteps(context).length - 1) {
                              setState(() {
                                _currentStep++;
                              });
                            } else {
                              if (!_isDataChanged()) {
                                Navigator.pop(context);
                              } else {
                                setState(() {
                                  _isSavingProfile = true;
                                });
                                // Give UI one frame so button loader is visible immediately.
                                await Future<void>.delayed(Duration.zero);
                                if (!mounted) return;
                                await _saveUserProfile();
                              }
                            }
                          }
                        },
                  // Keep button behavior unchanged apart from loading state.
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
                    content: Text(
                        AppLocalizations.of(context)!.pressBackAgainToExit),
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
                    content: Text(
                        AppLocalizations.of(context)!.pressBackAgainToExit),
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
                  AppLocalizations.of(context)!.someBasicInformation,
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
                    AppLocalizations.of(context)!.name,
                    style: AppTextStyles.black14_600,
                  ),
                  CustomTextField(
                    controller: _name,
                    height: 50,
                    keyboardType: TextInputType.name,
                    hintText: AppLocalizations.of(context)!.enterYourName,
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
                  AppLocalizations.of(context)!.someBasicInformation,
                  style: AppTextStyles.black22_600,
                ),
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.customerType,
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
                                // Clear GST and PAN errors when switching to Export
                                if (_isExportSelected) {
                                  _gstNumberError = null;
                                  _panNumberError = null;
                                }
                              });
                            },
                          ),
                          Text(
                            AppLocalizations.of(context)!.export,
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
                                // Clear GST and PAN errors when switching to Export
                                if (_isExportSelected) {
                                  _gstNumberError = null;
                                  _panNumberError = null;
                                }
                              });
                            },
                          ),
                          Text(
                            AppLocalizations.of(context)!.domestic,
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
                    AppLocalizations.of(context)!.mobileNumber,
                    style: AppTextStyles.black14_600,
                  ),
                  IntlPhoneField(
                    controller: _phoneNumber,
                    decoration: InputDecoration(
                      hintText:
                          AppLocalizations.of(context)!.enterYourMobileNumber,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(),
                      ),
                      errorText: widget.forUpdate ? null : _phoneNumberError,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                    ),
                    initialCountryCode:
                        _countryCode?.replaceAll('+', '') ?? 'IN',
                    onChanged: (phone) {
                      _completePhoneNumber = phone.completeNumber;
                      _countryCode = phone.countryCode;
                      if (_currentStep < getSteps(context).length - 1) {
                        setState(() {
                          _phoneNumberError = null; // Clear error on change
                        });
                      }
                    },
                    onCountryChanged: (country) {
                      _countryCode = '+${country.dialCode}';
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return 'Mobile number is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.gstNumber,
                        style: AppTextStyles.black14_600,
                      ),
                      if (_isDomesticSelected)
                        Text(
                          ' *',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      if (_isExportSelected)
                        Text(
                          ' (Optional)',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                  CustomTextField(
                    controller: _gstNumber,
                    height: 50,
                    hintText: AppLocalizations.of(context)!.enterGSTNo,
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
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.panNumber,
                        style: AppTextStyles.black14_600,
                      ),
                      if (_isDomesticSelected)
                        Text(
                          ' *',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      if (_isExportSelected)
                        Text(
                          ' (Optional)',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                  CustomTextField(
                    controller: _panNumber,
                    height: 50,
                    hintText: AppLocalizations.of(context)!.enterPANNo,
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
              AppLocalizations.of(context)!.someBasicInformation,
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
                      AppLocalizations.of(context)!.houseFlatNo,
                      style: AppTextStyles.black14_600,
                    ),
                    CustomTextField(
                      controller: _houseFlatNumber,
                      height: 50,
                      hintText: AppLocalizations.of(context)!.enterHouseFlatNo,
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
                      AppLocalizations.of(context)!.streetName,
                      style: AppTextStyles.black14_600,
                    ),
                    CustomTextField(
                      controller: _streetNumber,
                      height: 50,
                      hintText: AppLocalizations.of(context)!.enterStreetName,
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
                      AppLocalizations.of(context)!.cityName,
                      style: AppTextStyles.black14_600,
                    ),
                    CustomTextField(
                      controller: _cityName,
                      height: 50,
                      hintText: AppLocalizations.of(context)!.enterCityName,
                      errorText: _cityNameError,
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        final city = value.trim();
                        if (city.isEmpty || _isValidCityName(city)) {
                          setState(() {
                            _cityNameError = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.pinCode,
                      style: AppTextStyles.black14_600,
                    ),
                    CustomTextField(
                      controller: _pinCode,
                      height: 50,
                      maxLength: 6,
                      hintText: AppLocalizations.of(context)!.enterPincode,
                      errorText: _pinCodeError,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final pinCode = value.trim();
                        if (pinCode.isEmpty ||
                            (pinCode.length == 6 &&
                                _isValidPinCode(pinCode))) {
                          setState(() {
                            _pinCodeError = null;
                          });
                        }
                      },
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
        setState(() {
          _nameError = null;
        });
      }
    } else if (_currentStep == 1) {
      // Phone number validation
      if (_phoneNumber.text.isEmpty) {
        setState(() {
          _phoneNumberError = 'Mobile number is required';
        });
        isValid = false;
      } else {
        setState(() {
          _phoneNumberError = null;
        });
      }

      // GST validation - mandatory for domestic, optional for export
      if (_isDomesticSelected && _gstNumber.text.isEmpty) {
        setState(() {
          _gstNumberError = 'GST number is required for domestic customers';
        });
        isValid = false;
      } else {
        setState(() {
          _gstNumberError = null;
        });
      }

      // PAN validation - mandatory for domestic, optional for export
      if (_isDomesticSelected && _panNumber.text.isEmpty) {
        setState(() {
          _panNumberError = 'PAN number is required for domestic customers';
        });
        isValid = false;
      } else {
        setState(() {
          _panNumberError = null;
        });
      }

      // Customer type validation
      if (_customerType == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.validationError),
            content:
                Text(AppLocalizations.of(context)!.pleaseSelectCustomerType),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.ok),
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
        setState(() {
          _houseFlatNumberError = null;
        });
      }

      if (_streetNumber.text.isEmpty) {
        setState(() {
          _streetNumberError = 'Street name is required';
        });
        isValid = false;
      } else {
        setState(() {
          _streetNumberError = null;
        });
      }

      if (_cityName.text.isEmpty) {
        setState(() {
          _cityNameError = 'City name is required';
        });
        isValid = false;
      } else if (!_isValidCityName(_cityName.text.trim())) {
        setState(() {
          _cityNameError = 'Please enter a valid city name';
        });
        isValid = false;
      } else {
        setState(() {
          _cityNameError = null;
        });
      }

      if (_pinCode.text.isEmpty) {
        setState(() {
          _pinCodeError = 'Pin code is required';
        });
        isValid = false;
      } else if (!_isValidPinCode(_pinCode.text.trim())) {
        setState(() {
          _pinCodeError = 'Please enter a valid Indian PIN code';
        });
        isValid = false;
      } else {
        setState(() {
          _pinCodeError = null;
        });
      }
    }

    return isValid;
  }

  bool _isDataChanged() {
    String currentPhone = _completePhoneNumber ?? _phoneNumber.text;
    String originalPhone = widget.profile?.mobile.toString() ?? '';

    return _name.text != widget.profile?.name ||
        currentPhone != originalPhone ||
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
