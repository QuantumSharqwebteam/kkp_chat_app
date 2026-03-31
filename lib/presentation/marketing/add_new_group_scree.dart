// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/agent.dart';

import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:provider/provider.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddNewGroupScreen extends StatefulWidget {
  const AddNewGroupScreen({super.key});

  @override
  State<AddNewGroupScreen> createState() => _AddNewGroupScreenState();
}

class _AddNewGroupScreenState extends State<AddNewGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<String> selectedMembers = [];
  List<String> selectedAdmins = [];
  String? _groupImageUrl;
  File? _selectedImageFile;
  bool isLoading = false;
  bool isUploading = false;
  List<Agent> agents = [];
  String? loggedInUserEmail;
  String? loggedInUserName;

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupNameField(),
            const SizedBox(height: 16),
            _buildGroupDescriptionField(),
            const SizedBox(height: 16),
            _buildGroupImageField(),
            const SizedBox(height: 16),
            _buildMembersSection(),
            const SizedBox(height: 16),
            _buildAdminsSection(),
            const SizedBox(height: 24),
            _buildCreateButton(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupNameField() {
    return TextFormField(
      controller: _groupNameController,
      decoration: InputDecoration(
        labelText: 'Group Name',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGroupDescriptionField() {
    return TextFormField(
      controller: _groupDescriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Group Description',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGroupImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Group Image', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[100],
            ),
            child: Stack(
              children: [
                Center(
                  child: _selectedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImageFile!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to select an image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
                if (isUploading)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_selectedImageFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Image selected',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedImageFile = null;
                      _groupImageUrl = null;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Select Members'),
              ),
              items: agents.map((agent) {
                final name = agent.name;
                final email = agent.email;
                final isSelected = selectedMembers.contains(email);
                return DropdownMenuItem<String>(
                  value: email,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    child: Row(
                      children: [
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        if (!isSelected)
                          const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style:
                                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(email, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedMembers.remove(email);
                      } else {
                        selectedMembers.add(email);
                      }
                    });
                  },
                );
              }).toList(),
              onChanged: (String? value) {},
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (selectedMembers.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedMembers.map((email) {
              final matchingAgent = agents.where((agent) => agent.email == email);
              final name =
                  matchingAgent.isNotEmpty ? matchingAgent.first.name : email.split('@').first;
              return Chip(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                label: Text(name),
                deleteIcon: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.close, size: 18),
                ),
                onDeleted: () => setState(() => selectedMembers.remove(email)),
              );
            }).toList(),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No members selected', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildAdminsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Select Admins'),
              ),
              items: [
                // Add other users (excluding logged-in user)
                ...agents.where((agent) => agent.email != loggedInUserEmail).map((agent) {
                  final name = agent.name;
                  final email = agent.email;
                  final isSelected = selectedAdmins.contains(email);
                  return DropdownMenuItem<String>(
                    value: email,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          if (!isSelected)
                            const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style:
                                        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(email,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedAdmins.remove(email);
                        } else {
                          selectedAdmins.add(email);
                        }
                      });
                    },
                  );
                }),
              ],
              onChanged: (String? value) {},
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Always show the logged-in user as an admin
            if (loggedInUserEmail != null)
              Chip(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                label: Text(loggedInUserName ?? 'You'),
                avatar: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, size: 16, color: Colors.white),
                ),
                onDeleted: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You cannot remove yourself as admin')),
                  );
                },
              ),
            // Show other selected admins
            ...selectedAdmins.where((email) => email != loggedInUserEmail).map((email) {
              final matchingAgent = agents.where((agent) => agent.email == email);
              final name =
                  matchingAgent.isNotEmpty ? matchingAgent.first.name : email.split('@').first;
              return Chip(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                label: Text(name),
                deleteIcon: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.close, size: 18),
                ),
                onDeleted: () => setState(() => selectedAdmins.remove(email)),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isLoading ? const Color(0xff007A75).withOpacity(0.5) : const Color(0xff007A75),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: isLoading ? null : _createGroup,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              isLoading ? 'Creating...' : 'Create Group',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageFile == null) return;

    setState(() => isUploading = true);
    try {
      final s3Service = S3UploadService();
      final imageUrl = await s3Service.uploadFile(_selectedImageFile!);
      if (imageUrl != null) {
        setState(() {
          _groupImageUrl = imageUrl;
          isUploading = false;
        });
      } else {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchAgents() async {
    if (agents.isNotEmpty) return;
    setState(() => isLoading = true);

    // Get logged-in user info
    loggedInUserEmail = LocalDbHelper.getEmail();
    loggedInUserName = LocalDbHelper.getName();

    // Add logged-in user as admin by default
    if (loggedInUserEmail != null && !selectedAdmins.contains(loggedInUserEmail!)) {
      selectedAdmins.add(loggedInUserEmail!);
    }

    try {
      agents = await AuthApi().getAgent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch agents: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    if (selectedAdmins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one admin')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    final success = await groupProvider.createGroup(
      groupName: _groupNameController.text,
      groupDescription: _groupDescriptionController.text,
      admins: selectedAdmins,
      members: selectedMembers,
      groupImage: _groupImageUrl ?? '',
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create group')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }
}
