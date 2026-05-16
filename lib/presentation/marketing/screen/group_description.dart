// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/data/models/group_model.dart';
import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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
  bool _isAgentsLoading = false;
  String? _newImageUrl;
  String? role;
  List<Agent> _agents = [];
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? AppColors.redF11515 : AppColors.green22C55E,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _groupNameController.text = _group.groupName;
    _groupDescriptionController.text = _group.groupDescription;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeScreen());
  }

  Future<void> _initializeScreen() async {
    setState(() => _isAgentsLoading = true);
    try {
      final results = await Future.wait([
        LocalDbHelper.getUserType(),
        AuthApi().getAgent(),
      ]);
      if (!mounted) return;
      setState(() {
        role = results[0] as String?;
        _agents = results[1] as List<Agent>;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Unable to load available agents.', isError: true);
    } finally {
      if (mounted) setState(() => _isAgentsLoading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _group);
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(
          backgroundColor: AppColors.bluePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: Text(
            _isEditing ? 'Edit Group' : 'Group Details',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          actions: [
            if (!_isEditing)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  label: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _isEditing = false;
                    _newImageUrl = null;
                    _groupNameController.text = _group.groupName;
                    _groupDescriptionController.text = _group.groupDescription;
                  }),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              bottom: Platform.isAndroid,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isEditing) ...[
                      _buildHeroHeader(),
                      const SizedBox(height: 16),
                      _buildGroupInfoCard(),
                      const SizedBox(height: 16),
                    ] else ...[
                      _buildEditCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildAdminsSection(),
                    const SizedBox(height: 16),
                    _buildMembersSection(),
                    const SizedBox(height: 16),
                    if (_isEditing) _buildActionButtons(),
                  ],
                ),
              ),
            ),
            if (_isLoading) const FullScreenLoader(),
          ],
        ),
      ),
    );
  }

  // ─── Hero header ────────────────────────────────────────────────────────────

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bluePrimary, AppColors.blue4A76CD],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              _initialsFor(_group.groupName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _group.groupName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_group.groupDescription.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              _group.groupDescription,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderChip(
                  Icons.admin_panel_settings_rounded, '${_group.admins.length} Admins'),
              const SizedBox(width: 10),
              _buildHeaderChip(Icons.group_rounded, '${_group.members.length} Members'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Group info card (view mode) ────────────────────────────────────────────

  Widget _buildGroupInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Group Info', Icons.info_outline_rounded),
          const SizedBox(height: 14),
          _infoRow(
              Icons.calendar_today_rounded, 'Created', _formatDate(_group.createdAt.toLocal())),
          _divider(),
          _infoRow(Icons.access_time_rounded, 'Last Activity',
              _formatDate(_group.lastActivity.toLocal())),
          _divider(),
          _infoRow(
            Icons.people_alt_rounded,
            'Total Participants',
            '${_group.members.length + _group.admins.length} people',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.backgroundDCEBFF,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.blue, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.grey7B7B7B,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.black2E2E2E,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: AppColors.greyE5E7EB),
      );

  // ─── Edit card (edit mode) ──────────────────────────────────────────────────

  Widget _buildEditCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Group Name', Icons.group_work_rounded),
          const SizedBox(height: 8),
          TextField(
            controller: _groupNameController,
            style: const TextStyle(fontSize: 14, color: AppColors.black2E2E2E),
            decoration: _inputDecoration('Enter group name'),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Description', Icons.description_rounded),
          const SizedBox(height: 8),
          TextField(
            controller: _groupDescriptionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: AppColors.black2E2E2E),
            decoration: _inputDecoration('Enter group description'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.greyAAAAAA, fontSize: 13),
        filled: true,
        fillColor: const Color(0xffF5F7FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greyE5E7EB),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greyE5E7EB),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
      );

  // ─── Shared card / label helpers ─────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 15),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.grey525252,
          ),
        ),
      ],
    );
  }

  // ─── Action buttons (edit mode) ─────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _saveChanges,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.redF11515,
              side: BorderSide(color: AppColors.redF11515.withValues(alpha: 0.4)),
              backgroundColor: AppColors.redF11515.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _showDeleteConfirmation,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Delete Group',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── People helpers ──────────────────────────────────────────────────────────

  String _nameForEmail(String email) {
    try {
      return _agents.firstWhere((a) => a.email == email).name;
    } catch (_) {
      return email.split('@').first;
    }
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required int count,
    VoidCallback? onAdd,
    String? addLabel,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.backgroundDCEBFF,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.blue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.black2E2E2E,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDCEBFF,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    addLabel ?? 'Add',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonTile({
    required String email,
    bool showAdminBadge = false,
    bool canRemove = false,
    VoidCallback? onRemove,
  }) {
    final isCurrentUser = email == LocalDbHelper.getEmail();
    final name = _nameForEmail(email);
    final initials = _initialsFor(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5E7EB),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundDCEBFF,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.black2E2E2E,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      _badge('You', AppColors.blue),
                    ],
                    if (showAdminBadge) ...[
                      const SizedBox(width: 6),
                      _badge('Admin', AppColors.green22C55E),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(color: AppColors.grey7B7B7B, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppColors.redF11515,
                size: 20,
              ),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyListPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xffF5F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5E7EB),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.grey7B7B7B, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAdminsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Admins',
          icon: Icons.admin_panel_settings_rounded,
          count: _group.admins.length,
          onAdd: (_isEditing && role != "2") ? _showAddAdminDialog : null,
          addLabel: 'Add Admin',
        ),
        const SizedBox(height: 12),
        if (_group.admins.isEmpty)
          _buildEmptyListPlaceholder('No admins in this group')
        else
          ..._group.admins.map((email) => _buildPersonTile(
                email: email,
                canRemove: _isEditing && role != "2" && email != LocalDbHelper.getEmail(),
                onRemove: () => _removeAdmin(email),
              )),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Members',
          icon: Icons.group_rounded,
          count: _group.members.length,
          onAdd: (_isEditing && role != "2") ? _showAddMemberDialog : null,
          addLabel: 'Add Member',
        ),
        const SizedBox(height: 12),
        if (_group.members.isEmpty)
          _buildEmptyListPlaceholder('No members in this group')
        else
          ..._group.members.map((email) => _buildPersonTile(
                email: email,
                showAdminBadge: _group.admins.contains(email),
                canRemove: _isEditing && role != "2",
                onRemove: () => _removeMember(email),
              )),
      ],
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────

  Future<void> _showAddAdminDialog() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final existingEmails = {..._group.admins, ..._group.members};

    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(
        title: 'Add Admin',
        icon: Icons.admin_panel_settings_rounded,
        allAgents: _agents,
        existingEmails: existingEmails,
        isLoading: _isAgentsLoading,
        onAdd: (email) async {
          _setLoading(true);
          final success = await groupProvider.addAdmin(
            groupId: widget.groupId,
            email: email,
          );
          _setLoading(false);
          if (success) {
            setState(() {
              _group = _group.copyWith(admins: [..._group.admins, email]);
            });
            _showSnackBar('Admin added successfully');
          } else {
            _showSnackBar(
              groupProvider.errorMessage ?? 'Failed to add admin',
              isError: true,
            );
          }
          return success;
        },
      ),
    );
  }

  Future<void> _showAddMemberDialog() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final existingEmails = {..._group.members, ..._group.admins};

    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(
        title: 'Add Member',
        icon: Icons.group_add_rounded,
        allAgents: _agents,
        existingEmails: existingEmails,
        isLoading: _isAgentsLoading,
        onAdd: (email) async {
          _setLoading(true);
          final success = await groupProvider.addMember(
            groupId: widget.groupId,
            email: email,
          );
          _setLoading(false);
          if (success) {
            setState(() {
              _group = _group.copyWith(members: [..._group.members, email]);
            });
            _showSnackBar('Member added successfully');
          } else {
            _showSnackBar(
              groupProvider.errorMessage ?? 'Failed to add member',
              isError: true,
            );
          }
          return success;
        },
      ),
    );
  }

  Future<void> _removeAdmin(String email) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final name = _nameForEmail(email);
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        icon: Icons.admin_panel_settings_rounded,
        iconColor: AppColors.blue,
        title: 'Remove Admin',
        message: 'Remove $name as an admin? They will remain a group member.',
        confirmLabel: 'Remove',
        confirmColor: AppColors.redF11515,
      ),
    );

    if (shouldRemove == true) {
      _setLoading(true);
      final success = await groupProvider.removeAdmin(
        groupId: widget.groupId,
        email: email,
      );
      _setLoading(false);

      if (success) {
        setState(() {
          _group = _group.copyWith(
            admins: _group.admins.where((a) => a != email).toList(),
          );
        });
        _showSnackBar('Admin removed successfully');
      } else {
        _showSnackBar(
          groupProvider.errorMessage ?? 'Failed to remove admin',
          isError: true,
        );
      }
    }
  }

  Future<void> _removeMember(String email) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final name = _nameForEmail(email);
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        icon: Icons.group_rounded,
        iconColor: AppColors.blue,
        title: 'Remove Member',
        message: 'Remove $name from this group?',
        confirmLabel: 'Remove',
        confirmColor: AppColors.redF11515,
      ),
    );

    if (shouldRemove == true) {
      _setLoading(true);
      final success = await groupProvider.removeMember(
        groupId: widget.groupId,
        email: email,
      );
      _setLoading(false);

      if (success) {
        setState(() {
          _group = _group.copyWith(
            members: _group.members.where((m) => m != email).toList(),
          );
        });
        _showSnackBar('Member removed successfully');
      } else {
        _showSnackBar(
          groupProvider.errorMessage ?? 'Failed to remove member',
          isError: true,
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.redF11515,
        title: 'Delete Group',
        message: 'Permanently delete "${_group.groupName}"?\nThis action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.redF11515,
      ),
    );

    if (shouldDelete == true) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      _setLoading(true);
      final success = await groupProvider.deleteGroup(widget.groupId);
      _setLoading(false);

      if (success) {
        _showSnackBar('Group deleted successfully');
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
          groupProvider.errorMessage ?? 'Failed to delete group',
          isError: true,
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    _setLoading(true);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final updatedName = _groupNameController.text.trim();
    final updatedDesc = _groupDescriptionController.text.trim();
    final updatedImage = _newImageUrl ?? _group.groupImage;

    try {
      final success = await groupProvider.updateGroup(
        id: widget.groupId,
        groupName: updatedName != _group.groupName ? updatedName : null,
        groupDescription: updatedDesc != _group.groupDescription ? updatedDesc : null,
        groupImage: updatedImage != _group.groupImage ? updatedImage : null,
      );

      if (success) {
        setState(() {
          _group = _group.copyWith(
            groupName: updatedName,
            groupDescription: updatedDesc,
            groupImage: updatedImage,
          );
          _isEditing = false;
        });
        _setLoading(false);
        _showSnackBar('Group updated successfully');
      } else {
        _setLoading(false);
        _showSnackBar(
          groupProvider.errorMessage ?? 'Failed to update group',
          isError: true,
        );
      }
    } catch (e) {
      _setLoading(false);
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy  h:mm a').format(date);
  }
}

// ─── Confirm dialog ──────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.black2E2E2E,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.grey7B7B7B,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppColors.greyE5E7EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.grey7B7B7B,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add user dialog ─────────────────────────────────────────────────────────

class _AddUserDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Agent> allAgents;
  final Set<String> existingEmails;
  final bool isLoading;
  final Future<bool> Function(String email) onAdd;

  const _AddUserDialog({
    required this.title,
    required this.icon,
    required this.allAgents,
    required this.existingEmails,
    required this.isLoading,
    required this.onAdd,
  });

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  String? _loadingEmail;

  String _initials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get _allAlreadyAdded =>
      widget.allAgents.isNotEmpty &&
      widget.allAgents.every((a) => widget.existingEmails.contains(a.email));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(color: AppColors.blue),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          // "All added" banner
          if (_allAlreadyAdded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.backgroundDCEBFF,
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All users are already in this group',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Body
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: widget.isLoading && widget.allAgents.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.blue,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : widget.allAgents.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No users available',
                            style: TextStyle(color: AppColors.grey7B7B7B),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.allAgents.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 72,
                          endIndent: 16,
                          color: AppColors.greyE5E7EB,
                        ),
                        itemBuilder: (context, index) {
                          final agent = widget.allAgents[index];
                          final alreadyAdded = widget.existingEmails.contains(agent.email);
                          final isRowLoading = _loadingEmail == agent.email;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: alreadyAdded
                                      ? AppColors.greyE5E7EB
                                      : AppColors.backgroundDCEBFF,
                                  child: Text(
                                    _initials(agent.name),
                                    style: TextStyle(
                                      color: alreadyAdded ? AppColors.grey7B7B7B : AppColors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        agent.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: alreadyAdded
                                              ? AppColors.greyAAAAAA
                                              : AppColors.black2E2E2E,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        agent.email,
                                        style: const TextStyle(
                                          color: AppColors.grey7B7B7B,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  height: 32,
                                  child: alreadyAdded
                                      ? Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.greyF2F4F7,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.greyE5E7EB),
                                          ),
                                          child: const Text(
                                            'Added',
                                            style: TextStyle(
                                              color: AppColors.greyAAAAAA,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                      : isRowLoading
                                          ? const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: AppColors.blue,
                                                ),
                                              ),
                                            )
                                          : FilledButton(
                                              onPressed: _loadingEmail != null
                                                  ? null
                                                  : () async {
                                                      setState(() => _loadingEmail = agent.email);
                                                      final success =
                                                          await widget.onAdd(agent.email);
                                                      if (mounted) {
                                                        setState(() => _loadingEmail = null);
                                                        if (success) {
                                                          Navigator.pop(context);
                                                        }
                                                      }
                                                    },
                                              style: FilledButton.styleFrom(
                                                backgroundColor: AppColors.blue,
                                                disabledBackgroundColor: AppColors.greyD9D9D9,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Add',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
