// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/group_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GroupDescriptionScreen extends StatefulWidget {
  final String groupId;
  final GroupModel group;

  const GroupDescriptionScreen({
    super.key,
    required this.groupId,
    required this.group,
  });

  @override
  State<GroupDescriptionScreen> createState() => _GroupDescriptionScreenState();
}

class _GroupDescriptionScreenState extends State<GroupDescriptionScreen> {
  late GroupModel _group;
  bool _isEditing = false;
  bool _isLoading = false;
  File? _selectedImageFile;
  String? _newImageUrl;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _groupNameController.text = _group.groupName;
    _groupDescriptionController.text = _group.groupDescription;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Group' : 'Group Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _selectedImageFile = null;
                  _newImageUrl = null;
                  _groupNameController.text = _group.groupName;
                  _groupDescriptionController.text = _group.groupDescription;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: Platform.isAndroid,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, right: 16, left: 16, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupImageSection(),
                    const SizedBox(height: 20),
                    _buildGroupNameSection(),
                    const SizedBox(height: 20),
                    _buildGroupDescriptionSection(),
                    const SizedBox(height: 20),
                    _buildGroupInfoSection(),
                    const SizedBox(height: 20),
                    _buildAdminsSection(),
                    const SizedBox(height: 20),
                    _buildMembersSection(),
                    const SizedBox(height: 20),
                    if (_isEditing) _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGroupImageSection() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipOval(
                child: _selectedImageFile != null
                    ? Image.file(
                        _selectedImageFile!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      )
                    : (_group.groupImage.isNotEmpty
                        ? Image.network(
                            _group.groupImage,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.group, size: 60, color: Colors.grey);
                            },
                          )
                        : const Icon(Icons.group, size: 60, color: Colors.grey)),
              ),
            ),
          ),
          if (_isEditing && _selectedImageFile == null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              ),
            ),
          if (_isLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Group Name',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _isEditing
            ? TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              )
            : Text(
                _group.groupName,
                style: const TextStyle(fontSize: 16),
              ),
      ],
    );
  }

  Widget _buildGroupDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Group Description',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _isEditing
            ? TextField(
                controller: _groupDescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              )
            : Text(
                _group.groupDescription.isNotEmpty ? _group.groupDescription : 'No description',
                style: const TextStyle(fontSize: 16),
              ),
      ],
    );
  }

  Widget _buildGroupInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Group Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Created', _formatDate(_group.createdAt)),
              const SizedBox(height: 8),
              _buildInfoRow('Last Activity', _formatDate(_group.lastActivity)),
              const SizedBox(height: 8),
              _buildInfoRow('Total Members', '${_group.members.length + _group.admins.length}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Admins',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_isEditing)
              TextButton(
                onPressed: _showAddAdminDialog,
                child: const Text('Add Admin'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _group.admins.map((adminEmail) {
              // Find admin details from members list (if available)
              final admin = _group.members.firstWhere(
                (member) => member == adminEmail,
                orElse: () => adminEmail,
              );

              final isCurrentUser = adminEmail == LocalDbHelper.getEmail();
              final name = admin.split('@').first;

              return Chip(
                label: Text(name),
                avatar: isCurrentUser
                    ? const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, size: 16, color: Colors.white),
                      )
                    : null,
                deleteIcon: _isEditing && !isCurrentUser ? const Icon(Icons.close, size: 18) : null,
                onDeleted: _isEditing && !isCurrentUser ? () => _removeAdmin(adminEmail) : null,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Members',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_isEditing)
              TextButton(
                onPressed: _showAddMemberDialog,
                child: const Text('Add Member'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _group.members.map((memberEmail) {
              // Check if member is also an admin
              final isAdmin = _group.admins.contains(memberEmail);
              final isCurrentUser = memberEmail == LocalDbHelper.getEmail();

              final name = memberEmail.split('@').first;

              return Chip(
                label: Text(name),
                avatar: isAdmin
                    ? const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.star, size: 16, color: Colors.white),
                      )
                    : (isCurrentUser
                        ? const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.person, size: 16, color: Colors.white),
                          )
                        : null),
                deleteIcon: _isEditing ? const Icon(Icons.close, size: 18) : null,
                onDeleted: _isEditing ? () => _removeMember(memberEmail) : null,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _showDeleteConfirmation,
          child: const Text('Delete Group'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
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

    setState(() => _isLoading = true);
    try {
      final s3Service = S3UploadService();
      final imageUrl = await s3Service.uploadFile(_selectedImageFile!);
      if (imageUrl != null) {
        setState(() {
          _newImageUrl = imageUrl;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: ${e.toString()}')),
      );
    }
  }

  Future<void> _showAddAdminDialog() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final agentEmail = LocalDbHelper.getEmail();
    final customers = await ChatRepository().fetchAssignedCustomerList(agentEmail ?? "");

    // Filter out users who are already admins
    final availableUsers = customers.where((customer) {
      final email = customer['email']?.toString() ?? '';
      return !_group.admins.contains(email) && !_group.members.contains(email);
    }).toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available users to add as admin')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Admin'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableUsers.length,
              itemBuilder: (context, index) {
                final user = availableUsers[index];
                final name = user['name'] ?? '';
                final email = user['email']?.toString() ?? '';

                return ListTile(
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final success = await groupProvider.addAdmin(
                        groupId: widget.groupId,
                        email: email,
                      );

                      if (success) {
                        // Update local group data
                        setState(() {
                          _group = _group.copyWith(
                            admins: [..._group.admins, email],
                          );
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to add admin')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddMemberDialog() async {
    Provider.of<GroupProvider>(context, listen: false);
    final agentEmail = LocalDbHelper.getEmail();
    final customers = await ChatRepository().fetchAssignedCustomerList(agentEmail ?? "");

    // Filter out users who are already members or admins
    final availableUsers = customers.where((customer) {
      final email = customer['email']?.toString() ?? '';
      return !_group.admins.contains(email) && !_group.members.contains(email);
    }).toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available users to add as member')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Member'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableUsers.length,
              itemBuilder: (context, index) {
                final user = availableUsers[index];
                final name = user['name'] ?? '';
                final email = user['email']?.toString() ?? '';

                return ListTile(
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      // For adding members, we need to use a different approach
                      // since there's no direct API method in GroupProvider
                      // This is a placeholder - you'll need to implement the API call
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Adding members will be implemented in the next update')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeAdmin(String email) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: const Text('Are you sure you want to remove this user as admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      final success = await groupProvider.removeAdmin(
        groupId: widget.groupId,
        email: email,
      );

      if (success) {
        setState(() {
          _group = _group.copyWith(
            admins: _group.admins.where((admin) => admin != email).toList(),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove admin')),
        );
      }
    }
  }

  Future<void> _removeMember(String email) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      final success = await groupProvider.removeMember(
        groupId: widget.groupId,
        email: email,
      );

      if (success) {
        setState(() {
          _group = _group.copyWith(
            members: _group.members.where((member) => member != email).toList(),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove member')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content:
            const Text('Are you sure you want to delete this group? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final success = await groupProvider.deleteGroup(widget.groupId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate group was deleted
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete group')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final updatedGroupName = _groupNameController.text.trim();
    final updatedGroupDescription = _groupDescriptionController.text.trim();
    final updatedImageUrl = _newImageUrl ?? _group.groupImage;

    try {
      final success = await groupProvider.updateGroup(
        id: widget.groupId,
        groupName: updatedGroupName != _group.groupName ? updatedGroupName : null,
        groupDescription:
            updatedGroupDescription != _group.groupDescription ? updatedGroupDescription : null,
        groupImage: updatedImageUrl != _group.groupImage ? updatedImageUrl : null,
      );

      if (success) {
        // Update local state with the new values
        setState(() {
          _group = _group.copyWith(
            groupName: updatedGroupName,
            groupDescription: updatedGroupDescription,
            groupImage: updatedImageUrl,
          );
          _isEditing = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update group')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
