import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextInputFormatter _panUpperCaseFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    final upperCaseText = newValue.text.toUpperCase();
    return newValue.copyWith(text: upperCaseText);
  });
  late bool _isExportSelected = true;
  late bool _isDomesticSelected = false;
  AuthRepository auth = AuthRepository();
  String? _customerType;
  DateTime? _lastPressed;
  String? _completePhoneNumber;
  String _countryIsoCode = 'IN';
  int _phoneMinLength = 10; // ← FIX: dynamic min length based on country
  int _phoneMaxLength = 10; // ← FIX: dynamic max length based on country
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

  bool _isValidFullName(String name) {
    return RegExp(r"^[A-Za-z]+(?:[ .'-][A-Za-z]+)*$").hasMatch(name);
  }

  // ← FIX: now uses dynamic min/max length instead of hardcoded 10
  bool _isValidPhoneNumber(String phoneNumber) {
    if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) return false;
    return phoneNumber.length >= _phoneMinLength &&
        phoneNumber.length <= _phoneMaxLength;
  }

  bool _isValidPanNumber(String panNumber) {
    // PAN format: ABCDE1234F (5 letters + 4 digits + 1 letter)
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(panNumber.toUpperCase());
  }

  bool _isValidGstNumber(String gst) {
    // Indian GST format: 22AAAAA0000A1Z5
    // 2-digit state code (01-37) + 10-char PAN + 1 entity code + Z + 1 check char
    return RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$')
        .hasMatch(gst.toUpperCase());
  }

  Widget _requiredLabel(
    String label, {
    bool isRequired = true,
    String? optionalText,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.black14_600,
        ),
        if (isRequired)
          Text(
            ' *',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
        if (!isRequired && optionalText != null)
          Text(
            optionalText,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
      ],
    );
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
          _countryIsoCode = 'IN';
          _phoneMinLength = 10;
          _phoneMaxLength = 10;
          _phoneNumber.text = phoneStr.substring(3);
        } else {
          // For other countries, you might need more sophisticated parsing
          _phoneNumber.text = phoneStr;
        }
      } else {
        _phoneNumber.text = phoneStr;
// Default to India
        _countryIsoCode = 'IN';
        _phoneMinLength = 10;
        _phoneMaxLength = 10;
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
// Default to India
      _countryIsoCode = 'IN';
      _phoneMinLength = 10;
      _phoneMaxLength = 10;
    }
    _customerType = _isExportSelected ? 'Export' : 'Domestic';
  }

  Future<void> _saveUserProfile() async {
    if (!mounted) return;

    if (_pinCodeError != null || _cityNameError != null) {
      setState(() {
        _pinCodeError = null;
        _cityNameError = null;
      });
    }

    final trimmedPinCode = _pinCode.text.trim();
    final trimmedCityName = _cityName.text.trim();

    if (trimmedPinCode.isNotEmpty && !_isValidPinCode(trimmedPinCode)) {
      setState(() {
        _pinCodeError = 'Please enter a valid Indian PIN code';
        _isSavingProfile = false;
      });
      return;
    }

    if (trimmedCityName.isNotEmpty && !_isValidCityName(trimmedCityName)) {
      setState(() {
        _cityNameError = 'Please enter a valid city name';
        _isSavingProfile = false;
      });
      return;
    }

    if (trimmedPinCode.isNotEmpty) {
      final pinValidationResult = await IndianPinCodeValidator.validate(
        trimmedPinCode,
      );

      if (!pinValidationResult.isValid) {
        setState(() {
          _pinCodeError = pinValidationResult.message ??
              'Please enter a valid Indian PIN code';
          _isSavingProfile = false;
        });
        return;
      }
    }

    final trimmedName = _name.text.trim();
    final trimmedPhone = _phoneNumber.text.trim();
    final trimmedGst = _gstNumber.text.trim();
    final trimmedPan = _panNumber.text.trim().toUpperCase();

    // Construct the address object with only changed values
    final trimmedHouseFlat = _houseFlatNumber.text.trim();
    final trimmedStreet = _streetNumber.text.trim();
    Address? addressDetails;
    if (trimmedHouseFlat.isNotEmpty ||
        trimmedStreet.isNotEmpty ||
        trimmedCityName.isNotEmpty ||
        trimmedPinCode.isNotEmpty) {
      addressDetails = Address(
        houseNo: trimmedHouseFlat.isNotEmpty ? trimmedHouseFlat : null,
        streetName: trimmedStreet.isNotEmpty ? trimmedStreet : null,
        city: trimmedCityName.isNotEmpty ? trimmedCityName : null,
        pincode: trimmedPinCode.isNotEmpty ? trimmedPinCode : null,
      );
    }

    try {
      final response = await auth.updateUserDetails(
        name: trimmedName.isNotEmpty ? trimmedName : widget.name,
        number: _completePhoneNumber ?? trimmedPhone,
        customerType: _customerType,
        gstNo: trimmedGst.isNotEmpty ? trimmedGst : null,
        panNo: trimmedPan.isNotEmpty ? trimmedPan : null,
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
                          if (validateStep()) {
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
                  _requiredLabel(
                    AppLocalizations.of(context)!.name,
                  ),
                  CustomTextField(
                    controller: _name,
                    height: 50,
                    keyboardType: TextInputType.name,
                    hintText: AppLocalizations.of(context)!.enterYourName,
                    errorText: _nameError,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-z .'-]")),
                    ],
                    onChanged: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isEmpty || _isValidFullName(trimmed)) {
                        setState(() {
                          _nameError = null;
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
                  _requiredLabel(
                    AppLocalizations.of(context)!.mobileNumber,
                  ),
                  IntlPhoneField(
                    controller: _phoneNumber,
                    decoration: InputDecoration(
                      hintText:
                          AppLocalizations.of(context)!.enterYourMobileNumber,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(),
                      ),
                      errorText: _phoneNumberError,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                          _phoneMaxLength), // ← FIX: dynamic max length
                    ],
                    initialCountryCode: _countryIsoCode,
                    onChanged: (phone) {
                      _completePhoneNumber = phone.completeNumber;
                      if (_phoneNumberError != null) {
                        setState(() {
                          _phoneNumberError = null; // Clear error on change
                        });
                      }
                    },
                    onCountryChanged: (country) {
                      setState(() {
                        _countryIsoCode = country.code;
                        _phoneMinLength =
                            country.minLength; // ← FIX: update from country
                        _phoneMaxLength =
                            country.maxLength; // ← FIX: update from country
                        _phoneNumberError =
                            null; // Clear error when country changes
                      });
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return 'Mobile number is required';
                      }
                      if (!_isValidPhoneNumber(phone.number)) {
                        return 'Enter a valid mobile number ($_phoneMinLength-$_phoneMaxLength digits)';
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
                  _requiredLabel(
                    AppLocalizations.of(context)!.gstNumber,
                    isRequired: _isDomesticSelected,
                    optionalText: _isExportSelected ? ' (Optional)' : null,
                  ),
                  CustomTextField(
                    controller: _gstNumber,
                    height: 50,
                    hintText: AppLocalizations.of(context)!.enterGSTNo,
                    keyboardType: TextInputType.text,
                    maxLength: 15,
                    errorText: _gstNumberError,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(15),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.copyWith(
                            text: newValue.text.toUpperCase());
                      }),
                    ],
                    onChanged: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isEmpty || _isValidGstNumber(trimmed)) {
                        setState(() {
                          _gstNumberError = null;
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
                  _requiredLabel(
                    AppLocalizations.of(context)!.panNumber,
                    isRequired: _isDomesticSelected,
                    optionalText: _isExportSelected ? ' (Optional)' : null,
                  ),
                  CustomTextField(
                    controller: _panNumber,
                    height: 50,
                    hintText: AppLocalizations.of(context)!.enterPANNo,
                    keyboardType: TextInputType.text,
                    maxLength: 10,
                    errorText: _panNumberError,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(10),
                      _panUpperCaseFormatter,
                    ],
                    onChanged: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isEmpty || _isValidPanNumber(trimmed)) {
                        setState(() {
                          _panNumberError = null;
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
                    _requiredLabel(
                      AppLocalizations.of(context)!.houseFlatNo,
                    ),
                    CustomTextField(
                      controller: _houseFlatNumber,
                      height: 50,
                      hintText: AppLocalizations.of(context)!.enterHouseFlatNo,
                      keyboardType: TextInputType.text,
                      errorText: _houseFlatNumberError,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _requiredLabel(
                      AppLocalizations.of(context)!.streetName,
                    ),
                    CustomTextField(
                      controller: _streetNumber,
                      height: 50,
                      hintText: AppLocalizations.of(context)!.enterStreetName,
                      keyboardType: TextInputType.text,
                      errorText: _streetNumberError,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _requiredLabel(
                      AppLocalizations.of(context)!.cityName,
                    ),
                    CustomTextField(
                      controller: _cityName,
                      height: 50,
                      hintText: AppLocalizations.of(context)!.enterCityName,
                      errorText: _cityNameError,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r"[A-Za-z .'-]")),
                      ],
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
                    _requiredLabel(
                      AppLocalizations.of(context)!.pinCode,
                    ),
                    CustomTextField(
                      controller: _pinCode,
                      height: 50,
                      maxLength: 6,
                      hintText: AppLocalizations.of(context)!.enterPincode,
                      errorText: _pinCodeError,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (value) {
                        final pinCode = value.trim();
                        if (pinCode.isEmpty ||
                            (pinCode.length == 6 && _isValidPinCode(pinCode))) {
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
      final nameInput = _name.text.trim();
      if (nameInput.isEmpty) {
        setState(() {
          _nameError = 'Please provide the name';
        });
        isValid = false;
      } else if (!_isValidFullName(nameInput)) {
        setState(() {
          _nameError = 'Name should contain only alphabets';
        });
        isValid = false;
      } else if (!_isValidFullName(nameInput)) {
        setState(() {
          _nameError = 'Please enter a valid name';
        });
        isValid = false;
      } else {
        setState(() {
          _nameError = null;
        });
      }
    } else if (_currentStep == 1) {
      final phoneInput = _phoneNumber.text.trim();
      if (phoneInput.isEmpty) {
        setState(() {
          _phoneNumberError = 'Mobile number is required';
        });
        isValid = false;
      } else if (!_isValidPhoneNumber(phoneInput)) {
        // ← FIX: dynamic error message showing expected digit range
        setState(() {
          if (_phoneMinLength == _phoneMaxLength) {
            _phoneNumberError =
                'Enter a valid $_phoneMinLength-digit mobile number';
          } else {
            _phoneNumberError =
                'Enter a valid mobile number ($_phoneMinLength-$_phoneMaxLength digits)';
          }
        });
        isValid = false;
      } else {
        setState(() {
          _phoneNumberError = null;
        });
      }

      final gstInput = _gstNumber.text.trim();
      if (_isDomesticSelected && gstInput.isEmpty) {
        setState(() {
          _gstNumberError = 'GST number is required for domestic customers';
        });
        isValid = false;
      } else if (gstInput.isNotEmpty && !_isValidGstNumber(gstInput)) {
        setState(() {
          _gstNumberError = 'Enter valid GST (e.g. 22AAAAA0000A1Z5)';
        });
        isValid = false;
      } else {
        setState(() {
          _gstNumberError = null;
        });
      }

      final panInput = _panNumber.text.trim().toUpperCase();
      final panProvided = panInput.isNotEmpty;
      if (_isDomesticSelected && !panProvided) {
        setState(() {
          _panNumberError = 'PAN number is required for domestic customers';
        });
        isValid = false;
      } else if (panProvided && !_isValidPanNumber(panInput)) {
        setState(() {
          _panNumberError = 'Enter valid PAN (e.g. ABCDE1234F)';
        });
        isValid = false;
      } else {
        setState(() {
          _panNumberError = null;
        });
      }

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

      final cityInput = _cityName.text.trim();
      if (cityInput.isEmpty) {
        setState(() {
          _cityNameError = 'City name is required';
        });
        isValid = false;
      } else if (!_isValidCityName(cityInput)) {
        setState(() {
          _cityNameError = 'Please enter a valid city name';
        });
        isValid = false;
      } else {
        setState(() {
          _cityNameError = null;
        });
      }

      final pinInput = _pinCode.text.trim();
      if (pinInput.isEmpty) {
        setState(() {
          _pinCodeError = 'Pin code is required';
        });
        isValid = false;
      } else if (pinInput.length != 6) {
        setState(() {
          _pinCodeError = 'Pincode must be exactly 6 digits';
        });
      } else if (!_isValidPinCode(pinInput)) {
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
