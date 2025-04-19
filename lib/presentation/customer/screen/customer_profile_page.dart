import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/local_storage/local_db_helper.dart';
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
  Profile? profile;
  bool _isExportSelected = false;
  bool _isDomesticSelected = false;
  String? profileImageUrl = "";
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
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    profile = await auth.getUserInfo();
    if (profile != null) {
      LocalDbHelper.saveProfile(profile!);
      profileImageUrl = profile?.profileUrl;
      _updateProfileFields(profile!);
    }
  }

  void _updateProfileFields(Profile profile) {
    setState(() {
      _name.text = profile.name ?? '';
      _email.text = profile.email ?? '';
      _number.text = profile.mobile.toString();
      _gstNo.text = profile.gstNo ?? '';
      _panNo.text = profile.panNo ?? '';
      if (profileImageUrl != profile.profileUrl) {
        profileImageUrl = profile.profileUrl;
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(70),
                  child: profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: profileImageUrl!,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        )
                      : Image.asset(
                          'assets/images/profile_avataar.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                ),
                Text(
                  _name.text.isNotEmpty ? _name.text : 'No Name',
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
                      _buildCustomerTypeSelection(),
                      _buildTextField('Full Name', _name),
                      _buildTextField('Email', _email),
                      _buildTextField('Mobile Number', _number),
                      _buildTextField('GST Number', _gstNo, maxLength: 15),
                      _buildTextField('PAN Number', _panNo, maxLength: 10),
                      _buildTextField('House No.', _houseNo),
                      _buildTextField('Street Name', _streetName),
                      _buildTextField('City', _city),
                      _buildTextField('Pincode', _pincode),
                      SizedBox(height: 20),
                      Center(
                        child: CustomButton(
                          text: 'Edit',
                          onPressed: () async {
                            // Construct the Profile object with current data
                            final profile = Profile(
                              profileUrl: profileImageUrl,
                              name: _name.text,
                              email: _email.text,
                              mobile: int.tryParse(_number.text) ?? 0,
                              gstNo: _gstNo.text,
                              panNo: _panNo.text,
                              customerType:
                                  _isExportSelected ? 'Export' : 'Domestic',
                              address: [
                                Address(
                                  houseNo: _houseNo.text,
                                  streetName: _streetName.text,
                                  city: _city.text,
                                  pincode: _pincode.text,
                                ),
                              ],
                            );

                            // Navigate to the setup page with the Profile object
                            final updatedProfile = await Navigator.pushNamed(
                              context,
                              CustomerRoutes.customerProfileSetup,
                              arguments: {
                                "forUpdate": true,
                                "profile": profile,
                              },
                            ) as Profile?;

                            if (updatedProfile != null) {
                              _updateProfileFields(updatedProfile);
                            }
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
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          child: Text('Customer Type', style: AppTextStyles.black16_600),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCheckbox('Export', _isExportSelected),
            _buildCheckbox('Domestic', _isDomesticSelected),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value) {
    return Row(
      children: [
        Checkbox(
          visualDensity: VisualDensity.compact,
          value: value,
          activeColor: AppColors.blue,
          onChanged: null, // Disable manual changes
        ),
        Text(label, style: AppTextStyles.black14_600),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.black14_600),
          CustomTextField(
            controller: controller,
            hintText: controller.text,
            hintStyle: AppTextStyles.black16_500,
            readOnly: true,
            height: 40,
            maxLength: maxLength,
          ),
        ],
      ),
    );
  }
}
