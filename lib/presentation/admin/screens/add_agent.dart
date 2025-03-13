import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class AddAgent extends StatefulWidget {
  const AddAgent({super.key});

  @override
  State<AddAgent> createState() => _AddAgentState();
}

class _AddAgentState extends State<AddAgent> {
  final TextEditingController fullNameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController agentIdController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final List<String> roles = ["Select role", 'Admin', 'Agent'];

  String selectedRole = 'Select role';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.white,
            elevation: 10,
            surfaceTintColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  // Profile Upload Section
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(Icons.person,
                              size: 50, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child:
                              const Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Input Fields
                  Text("Full Name"),
                  CustomTextField(
                    controller: fullNameController,
                    hintText: 'Enter full name',
                    prefixIcon: const Icon(Icons.person),
                  ),
                  Text("Email Address"),
                  CustomTextField(
                    controller: emailController,
                    hintText: 'Enter email address',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  Text("Phone number"),
                  CustomTextField(
                    controller: phoneController,
                    hintText: 'Enter phone number',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  Text("Agent Id"),
                  CustomTextField(
                    controller: agentIdController,
                    hintText: 'Create Agent ID',
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  Text("Password"),
                  CustomTextField(
                    controller: passwordController,
                    hintText: 'Create Password',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  Text("Role"),

                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: roles
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) {
                      selectedRole = value!;
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Add Agent Button
                  CustomButton(
                    onPressed: () {
                      Utils().showSuccessDialog(context, "Added Sucessfully");
                    },
                    fontSize: 18,
                    backgroundColor: AppColors.blue00ABE9,
                    text: "Add Agent",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
