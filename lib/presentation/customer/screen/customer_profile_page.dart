import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/address_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final AuthRepository _authRepository = AuthRepository();
  Profile? _profile;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _numberController = TextEditingController();
  final _gstNoController = TextEditingController();
  final _panNoController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final TextInputFormatter _panUpperCaseFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    final upperCaseText = newValue.text.toUpperCase();
    return newValue.copyWith(text: upperCaseText);
  });

  String _customerType = 'Export';
  String? _nameError;
  String? _mobileError;
  String? _gstError;
  String? _panError;
  String? _houseNoError;
  String? _streetError;
  String? _cityError;
  String? _pincodeError;

  bool _isValidFullName(String name) {
    return RegExp(r"^[A-Za-z]+(?:[ .'-][A-Za-z]+)*$").hasMatch(name);
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phoneNumber);
  }

  bool _isValidPanNumber(String panNumber) {
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(panNumber);
  }

  bool _isValidCityName(String city) {
    return RegExp(r"^[A-Za-z]+(?:[ .'-][A-Za-z]+)*$").hasMatch(city);
  }

  bool _isValidGstNumber(String gstNumber) {
    return RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$')
        .hasMatch(gstNumber.toUpperCase());
  }

  bool _validateInputs() {
    bool isValid = true;
    final name = _nameController.text.trim();
    final mobile = _numberController.text.trim();
    final gst = _gstNoController.text.trim().toUpperCase();
    final pan = _panNoController.text.trim().toUpperCase();
    final houseNo = _houseNoController.text.trim();
    final street = _streetNameController.text.trim();
    final city = _cityController.text.trim();
    final pincode = _pincodeController.text.trim();
    final isDomestic = _customerType == 'Domestic';

    setState(() {
      _nameError = null;
      _mobileError = null;
      _gstError = null;
      _panError = null;
      _houseNoError = null;
      _streetError = null;
      _cityError = null;
      _pincodeError = null;
    });

    if (name.isEmpty) {
      _nameError = 'Full name is required';
      isValid = false;
    } else if (!_isValidFullName(name)) {
      _nameError = 'Name should contain only alphabets';
      isValid = false;
    }

    if (mobile.isEmpty) {
      _mobileError = 'Mobile number is required';
      isValid = false;
    } else if (!_isValidPhoneNumber(mobile)) {
      _mobileError = 'Enter a valid 10-digit mobile number';
      isValid = false;
    }

    if (isDomestic && gst.isEmpty) {
      _gstError = 'GST number is required for domestic customers';
      isValid = false;
    } else if (gst.isNotEmpty && !_isValidGstNumber(gst)) {
      _gstError = 'Enter a valid 15-character GSTIN';
      isValid = false;
    }

    if (isDomestic && pan.isEmpty) {
      _panError = 'PAN number is required for domestic customers';
      isValid = false;
    } else if (pan.isNotEmpty && !_isValidPanNumber(pan)) {
      _panError = 'Enter valid PAN (ABCDE1234F)';
      isValid = false;
    }

    if (houseNo.isEmpty) {
      _houseNoError = 'House number is required';
      isValid = false;
    }

    if (street.isEmpty) {
      _streetError = 'Street name is required';
      isValid = false;
    }

    if (city.isEmpty) {
      _cityError = 'City is required';
      isValid = false;
    } else if (!_isValidCityName(city)) {
      _cityError = 'Please enter a valid city name';
      isValid = false;
    }

    if (pincode.isEmpty) {
      _pincodeError = 'Pincode is required';
      isValid = false;
    } else if (pincode.length != 6) {
      _pincodeError = 'Pincode must be exactly 6 digits';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
    }

    return isValid;
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userData = await _authRepository.getUserInfo();
    if (userData['message'] == "Session expired due to login on another device") {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    final profileData = Profile.fromJson(userData['message']);
    setState(() {
      _profile = profileData;
    });
    await LocalDbHelper.saveProfile(profileData);
    _populateControllers(profileData);
  }

  void _populateControllers(Profile profile) {
    _nameController.text = profile.name ?? '';
    _emailController.text = profile.email ?? '';
    _numberController.text = profile.mobile.toString();
    _gstNoController.text = profile.gstNo ?? '';
    _panNoController.text = profile.panNo ?? '';
    _customerType = profile.customerType ?? 'Export';

    if (profile.address?.isNotEmpty ?? false) {
      final address = profile.address!.first;
      _houseNoController.text = address.houseNo ?? '';
      _streetNameController.text = address.streetName ?? '';
      _cityController.text = address.city ?? '';
      _pincodeController.text = address.pincode ?? '';
    }
  }

  Future<void> _saveChanges() async {
    if (!_validateInputs()) {
      return;
    }

    final updatedProfile = Profile(
      name: _nameController.text.trim(),
      email: _emailController.text,
      mobile: int.tryParse(_numberController.text.trim()) ?? 0,
      gstNo: _gstNoController.text.trim().toUpperCase(),
      panNo: _panNoController.text.trim().toUpperCase(),
      customerType: _customerType,
      address: [
        Address(
          houseNo: _houseNoController.text.trim(),
          streetName: _streetNameController.text.trim(),
          city: _cityController.text.trim(),
          pincode: _pincodeController.text.trim(),
        ),
      ],
    );

    try {
      final response = await _authRepository.updateUserDetails(
        name: updatedProfile.name,
        number: _numberController.text.trim(),
        customerType: updatedProfile.customerType,
        gstNo: updatedProfile.gstNo,
        panNo: updatedProfile.panNo,
        address: updatedProfile.address?.first,
      );

      if (response['message'] == "Item updated successfully") {
        final newProfile = Profile.fromJson(response['data']);
        await LocalDbHelper.saveProfile(newProfile);
        setState(() {
          _profile = newProfile;
          _isEditing = false;
        });
        if (!mounted) return;
        Utils().showSuccessDialog(context, "Profile Updated!", true);
        await Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showError(response['message'] ?? "Update failed");
      }
    } catch (e) {
      _showError("Error: ${e.toString()}");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _gstNoController.dispose();
    _panNoController.dispose();
    _houseNoController.dispose();
    _streetNameController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 239, 243),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(
              _isEditing
                  ? AppLocalizations.of(context)!.cancel
                  : AppLocalizations.of(context)!.edit,
              style: const TextStyle(color: Colors.blue),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildHeader(),
              const SizedBox(height: 10),
              _buildSectionContainer([
                _section("Personal Details"),
                _input(
                  "Full Name *",
                  _nameController,
                  errorText: _nameError,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'-]")),
                  ],
                  onChanged: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty || _isValidFullName(trimmed)) {
                      setState(() => _nameError = null);
                    }
                  },
                ),
                _input("Email Address", _emailController, enabled: false),
                _input(
                  "Mobile No. *",
                  _numberController,
                  errorText: _mobileError,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty || _isValidPhoneNumber(trimmed)) {
                      setState(() => _mobileError = null);
                    }
                  },
                ),
              ]),
              const SizedBox(height: 10),
              _buildSectionContainer([
                _section("Business Details"),
                _input(
                  _customerType == 'Domestic' ? "Pan No. *" : "Pan No.",
                  _panNoController,
                  errorText: _panError,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(10),
                    _panUpperCaseFormatter,
                  ],
                  onChanged: (value) {
                    final trimmed = value.trim().toUpperCase();
                    if (trimmed.isEmpty || _isValidPanNumber(trimmed)) {
                      setState(() => _panError = null);
                    }
                  },
                ),
                _input(
                  _customerType == 'Domestic' ? "GST No. *" : "GST No.",
                  _gstNoController,
                  errorText: _gstError,
                  maxLength: 15,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(15),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return newValue.copyWith(text: newValue.text.toUpperCase());
                    }),
                  ],
                  onChanged: (value) {
                    final trimmed = value.trim().toUpperCase();
                    if (trimmed.isEmpty || _isValidGstNumber(trimmed)) {
                      setState(() => _gstError = null);
                    }
                  },
                ),
                _dropdown("Customer", ['Export', 'Domestic']),
              ]),
              const SizedBox(height: 16),
              _buildSectionContainer([
                _section("Address Details"),
                _input(
                  "House No. *",
                  _houseNoController,
                  errorText: _houseNoError,
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() => _houseNoError = null);
                    }
                  },
                ),
                _input(
                  "Street Name *",
                  _streetNameController,
                  errorText: _streetError,
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() => _streetError = null);
                    }
                  },
                ),
                _input(
                  "City *",
                  _cityController,
                  errorText: _cityError,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'-]")),
                  ],
                  onChanged: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty || _isValidCityName(trimmed)) {
                      setState(() => _cityError = null);
                    }
                  },
                ),
                _input(
                  "Pincode *",
                  _pincodeController,
                  errorText: _pincodeError,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty ||
                        trimmed.length == 6) {
                      setState(() => _pincodeError = null);
                    }
                  },
                ),
              ]),
              const SizedBox(height: 40),
              if (_isEditing) _buildSaveButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE0E0E0),
            child: Initicon(
              text: _profile?.name ?? '',
              size: 90,
            ),
          ),
          const SizedBox(height: 10),
          Text(_profile?.name ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(_profile?.email ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(children: children),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Icon(
            title == AppLocalizations.of(context)!.addressDetails
                ? Icons.location_on
                : title == AppLocalizations.of(context)!.businessDetails
                    ? Icons.badge
                    : Icons.person,
            size: 20,
            color: Colors.black54,
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    String? errorText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: _isEditing && enabled,
            style: const TextStyle(fontSize: 14),
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            onChanged: onChanged,
            decoration: InputDecoration(
              errorText: errorText,
              counterText: '',
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF1976D2)),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _customerType,
            items: options.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
            onChanged: _isEditing
                ? (val) => setState(() {
                      _customerType = val!;
                      if (_customerType == 'Export') {
                        _gstError = null;
                        _panError = null;
                      }
                    })
                : null,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bluePrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          onPressed: _saveChanges,
          child: Text(
            AppLocalizations.of(context)!.saveChanges,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}



 // bool _isExportSelected = false;
// if (_isEditing)
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.bluePrimary,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       elevation: 2,
//                     ),
//                     onPressed: () {
//                       final updatedProfile = Profile(
//                         profileUrl: profileImageUrl,
//                         name: _name.text,
//                         email: _email.text,
//                         mobile: int.tryParse(_number.text) ?? 0,
//                         gstNo: _gstNo.text,
//                         panNo: _panNo.text,
//                         customerType: _isExportSelected ? 'Export' : 'Domestic',
//                         address: [
//                           Address(
//                             houseNo: _houseNo.text,
//                             streetName: _streetName.text,
//                             city: _city.text,
//                             pincode: _pincode.text,
//                           ),
//                         ],
//                       );
//                       setState(() {
//                         profile = updatedProfile;
//                         _isEditing = false;
//                       });
//                     },
//                     child: const Text(
//                       'Save Changes',
//                       style: TextStyle(fontSize: 16, color: Colors.white),
//                     ),
//                   ),
//                 ),





  // Widget _buildCustomerTypeSelection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
  //         child: Text('Customer Type', style: AppTextStyles.black16_600),
  //       ),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: [
  //           _buildCheckbox('Export', _isExportSelected),
  //           _buildCheckbox('Domestic', _isDomesticSelected),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildCheckbox(String label, bool value) {
  //   return Row(
  //     children: [
  //       Checkbox(
  //         visualDensity: VisualDensity.compact,
  //         value: value,
  //         activeColor: AppColors.blue,
  //         onChanged: null,
  //       ),
  //       Text(label, style: AppTextStyles.black14_600),
  //     ],
  //   );
  // }




// import 'package:flutter/material.dart';
// import 'package:flutter_initicon/flutter_initicon.dart';
// import 'package:kkpchatapp/config/routes/customer_routes.dart';
// import 'package:kkpchatapp/config/theme/app_colors.dart';
// import 'package:kkpchatapp/config/theme/app_text_styles.dart';
// import 'package:kkpchatapp/core/utils/utils.dart';
// import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
// import 'package:kkpchatapp/data/models/address_model.dart';
// import 'package:kkpchatapp/data/models/profile_model.dart';
// import 'package:kkpchatapp/data/repositories/auth_repository.dart';
// import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
// import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
// import 'package:kkpchatapp/presentation/common_widgets/profile_details_field.dart';

// class CustomerProfilePage extends StatefulWidget {
//   const CustomerProfilePage({super.key});

//   @override
//   State<CustomerProfilePage> createState() => _CustomerProfilePageState();
// }

// class _CustomerProfilePageState extends State<CustomerProfilePage> {
//   final AuthRepository auth = AuthRepository();
//   Profile? profile;
//   bool _isExportSelected = false;
//   bool _isDomesticSelected = false;
//   String? profileImageUrl = "";
//   final TextEditingController _name = TextEditingController();
//   final TextEditingController _email = TextEditingController();
//   final TextEditingController _number = TextEditingController();
//   final TextEditingController _gstNo = TextEditingController();
//   final TextEditingController _panNo = TextEditingController();
//   final TextEditingController _houseNo = TextEditingController();
//   final TextEditingController _streetName = TextEditingController();
//   final TextEditingController _city = TextEditingController();
//   final TextEditingController _pincode = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserInfo();
//   }

//   Future<void> _loadUserInfo() async {
//     final Map<String, dynamic> userData = await auth.getUserInfo();
//     if (userData['message'] ==
//         "Session expired due to login on another device") {
//       if (mounted) {
//         Navigator.of(context)
//             .pushReplacement(MaterialPageRoute(builder: (context) {
//           return LoginPage();
//         }));
//       }
//     } else {
//       profile = Profile.fromJson(userData['message']);
//       if (profile != null) {
//         LocalDbHelper.saveProfile(profile!);
//         profileImageUrl = profile?.profileUrl;
//         _updateProfileFields(profile!);
//       }
//     }
//   }

//   void _updateProfileFields(Profile profile) {
//     setState(() {
//       _name.text = profile.name ?? '';
//       _email.text = profile.email ?? '';
//       _number.text = profile.mobile.toString();
//       _gstNo.text = profile.gstNo ?? '';
//       _panNo.text = profile.panNo ?? '';
//       if (profileImageUrl != profile.profileUrl) {
//         profileImageUrl = profile.profileUrl;
//       }
//       if (profile.address?.isNotEmpty == true) {
//         final address = profile.address![0];
//         _houseNo.text = address.houseNo ?? '';
//         _streetName.text = address.streetName ?? '';
//         _city.text = address.city ?? '';
//         _pincode.text = address.pincode ?? '';
//       }
//       _isExportSelected = profile.customerType == 'Export';
//       _isDomesticSelected = profile.customerType == 'Domestic';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 SizedBox(height: 10),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(70),
//                   child: Initicon(
//                     text: profile?.name ?? "",
//                     elevation: 10,
//                     size: 120,
//                   ),
//                 ),
//                 Text(
//                   _name.text.isNotEmpty ? _name.text : 'No Name',
//                   style: AppTextStyles.black28_600,
//                 ),
//                 // Text(
//                 //   'Customer',
//                 //   style:
//                 //       AppTextStyles.black16_600.copyWith(color: Colors.black54),
//                 // ),
//                 SizedBox(height: 10),
//                 SizedBox(
//                   width: Utils().width(context) * 0.9,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildCustomerTypeSelection(),
//                       ProfileDetailsField(
//                         icon: Icons.person,
//                         label: 'Full Name',
//                         value: _name.text,
//                       ),
//                       ProfileDetailsField(
//                         icon: Icons.email,
//                         label: 'Email',
//                         value: _email.text,
//                       ),
//                       ProfileDetailsField(
//                         icon: Icons.phone,
//                         label: 'Mobile Number',
//                         value: _number.text,
//                       ),
//                       ProfileDetailsField(
//                         icon: Icons.assignment,
//                         label: 'GST Number',
//                         value: _gstNo.text,
//                       ),
//                       ProfileDetailsField(
//                         icon: Icons.assignment_ind,
//                         label: 'PAN Number',
//                         value: _panNo.text,
//                       ),
//                       ProfileDetailsField(
//                         icon: Icons.home,
//                         label: 'House No.',
//                         value: _houseNo.text,
//                       ),
//                       ProfileDetailsField(
//                         icon: Icons.streetview,
//                         label: 'Street Name',
//                         value: _streetName.text,
//                       ),
//                       ProfileDetailsField(
//                         icon: Icons.location_city,
//                         label: 'City',
//                         value: _city.text,
//                       ),
//                       ProfileDetailsField(
//                         icon: Icons.markunread_mailbox,
//                         label: 'Pincode',
//                         value: _pincode.text,
//                       ),
//                       SizedBox(height: 20),
//                       Center(
//                         child: CustomButton(
//                           text: 'Edit',
//                           onPressed: () async {
//                             // Construct the Profile object with current data
//                             final profile = Profile(
//                               profileUrl: profileImageUrl,
//                               name: _name.text,
//                               email: _email.text,
//                               mobile: int.tryParse(_number.text) ?? 0,
//                               gstNo: _gstNo.text,
//                               panNo: _panNo.text,
//                               customerType:
//                                   _isExportSelected ? 'Export' : 'Domestic',
//                               address: [
//                                 Address(
//                                   houseNo: _houseNo.text,
//                                   streetName: _streetName.text,
//                                   city: _city.text,
//                                   pincode: _pincode.text,
//                                 ),
//                               ],
//                             );

//                             // Navigate to the setup page with the Profile object
//                             final updatedProfile = await Navigator.pushNamed(
//                               context,
//                               CustomerRoutes.customerProfileSetup,
//                               arguments: {
//                                 "forUpdate": true,
//                                 "profile": profile,
//                               },
//                             ) as Profile?;

//                             if (updatedProfile != null) {
//                               _updateProfileFields(updatedProfile);
//                             }
//                           },
//                           height: 45,
//                           elevation: 5,
//                           width: Utils().width(context) * 0.5,
//                           fontSize: 16,
//                           backgroundColor: AppColors.bluePrimary,
//                         ),
//                       ),
//                       SizedBox(height: 40),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomerTypeSelection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
//           child: Text('Customer Type', style: AppTextStyles.black16_600),
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _buildCheckbox('Export', _isExportSelected),
//             _buildCheckbox('Domestic', _isDomesticSelected),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildCheckbox(String label, bool value) {
//     return Row(
//       children: [
//         Checkbox(
//           visualDensity: VisualDensity.compact,
//           value: value,
//           activeColor: AppColors.blue,
//           onChanged: null, // Disable manual changes
//         ),
//         Text(label, style: AppTextStyles.black14_600),
//       ],
//     );
//   }

//   // Widget _buildTextField(String label, TextEditingController controller,
//   //     {int? maxLength}) {
//   //   return Padding(
//   //     padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
//   //     child: Column(
//   //       crossAxisAlignment: CrossAxisAlignment.start,
//   //       children: [
//   //         Text(label, style: AppTextStyles.black14_600),
//   //         CustomTextField(
//   //           controller: controller,
//   //           hintText: controller.text,
//   //           hintStyle: AppTextStyles.black16_500,
//   //           readOnly: true,
//   //           height: 40,
//   //           maxLength: maxLength,
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
// }
