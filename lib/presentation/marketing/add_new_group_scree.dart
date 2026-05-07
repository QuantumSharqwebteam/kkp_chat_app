// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:provider/provider.dart';

class AddNewGroupScreen extends StatefulWidget {
  const AddNewGroupScreen({super.key});

  @override
  State<AddNewGroupScreen> createState() => _AddNewGroupScreenState();
}

class _AddNewGroupScreenState extends State<AddNewGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();

  List<String> selectedMembers = [];
  List<String> selectedAdmins = [];
  String? _groupImageUrl;
  bool _isAgentsLoading = false;
  bool _isCreating = false;
  List<Agent> agents = [];
  String? loggedInUserEmail;
  String? loggedInUserName;

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchAgents() async {
    if (agents.isNotEmpty) return;
    setState(() => _isAgentsLoading = true);

    loggedInUserEmail = LocalDbHelper.getEmail();
    loggedInUserName = LocalDbHelper.getName();

    if (loggedInUserEmail != null && !selectedAdmins.contains(loggedInUserEmail!)) {
      selectedAdmins.add(loggedInUserEmail!);
    }

    try {
      agents = await AuthApi().getAgent();
    } catch (e) {
      if (mounted) _showSnackBar('Failed to fetch agents: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAgentsLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
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

  String _initialsFor(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _nameForEmail(String email) {
    try {
      return agents.firstWhere((a) => a.email == email).name;
    } catch (_) {
      return email.split('@').first;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create New Group',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildSelectorCard(
              title: 'Members',
              icon: Icons.group_rounded,
              selectedEmails: selectedMembers,
              isLoading: _isAgentsLoading,
              onTap: _isAgentsLoading ? null : _showMemberSelector,
              emptyLabel: 'No members selected yet',
              onRemove: (email) => setState(() => selectedMembers.remove(email)),
            ),
            const SizedBox(height: 16),
            _buildSelectorCard(
              title: 'Admins',
              icon: Icons.admin_panel_settings_rounded,
              selectedEmails: selectedAdmins,
              isLoading: _isAgentsLoading,
              onTap: _isAgentsLoading ? null : _showAdminSelector,
              emptyLabel: 'No additional admins selected',
              lockedEmail: loggedInUserEmail,
              lockedLabel: loggedInUserName,
              onRemove: (email) {
                if (email == loggedInUserEmail) {
                  _showSnackBar('You cannot remove yourself as admin', isError: true);
                } else {
                  setState(() => selectedAdmins.remove(email));
                }
              },
            ),
            const SizedBox(height: 28),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  // ─── Basic info card ─────────────────────────────────────────────────────────

  Widget _buildBasicInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Group Name', Icons.group_work_rounded, required: true),
          const SizedBox(height: 8),
          TextField(
            controller: _groupNameController,
            style: const TextStyle(fontSize: 14, color: AppColors.black2E2E2E),
            decoration: _inputDeco('Enter group name'),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Description', Icons.description_rounded),
          const SizedBox(height: 8),
          TextField(
            controller: _groupDescriptionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: AppColors.black2E2E2E),
            decoration: _inputDeco('Enter group description (optional)'),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, IconData icon, {bool required = false}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.grey525252,
          ),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: AppColors.redF11515, fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
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

  // ─── Selector card ───────────────────────────────────────────────────────────

  Widget _buildSelectorCard({
    required String title,
    required IconData icon,
    required List<String> selectedEmails,
    required bool isLoading,
    required VoidCallback? onTap,
    required String emptyLabel,
    required void Function(String) onRemove,
    String? lockedEmail,
    String? lockedLabel,
  }) {
    final displayCount =
        selectedEmails.where((e) => e != lockedEmail).length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDCEBFF,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: AppColors.blue, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.black2E2E2E,
                      ),
                    ),
                    if (displayCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDCEBFF,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$displayCount',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLoading ? AppColors.greyD9D9D9 : AppColors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.add, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        isLoading ? 'Loading...' : 'Select',
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
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.greyE5E7EB),
          const SizedBox(height: 12),
          // Selected chips or empty state
          if (selectedEmails.isEmpty && lockedEmail == null)
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.greyAAAAAA, size: 15),
                const SizedBox(width: 6),
                Text(
                  emptyLabel,
                  style: const TextStyle(color: AppColors.greyAAAAAA, fontSize: 13),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (lockedEmail != null)
                  _chip(
                    email: lockedEmail,
                    name: lockedLabel ?? _nameForEmail(lockedEmail),
                    locked: true,
                    onRemove: () => onRemove(lockedEmail),
                  ),
                ...selectedEmails
                    .where((e) => e != lockedEmail)
                    .map((email) => _chip(
                          email: email,
                          name: _nameForEmail(email),
                          locked: false,
                          onRemove: () => onRemove(email),
                        )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String email,
    required String name,
    required bool locked,
    required VoidCallback onRemove,
  }) {
    final initials = _initialsFor(name);
    final color = locked ? AppColors.green22C55E : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              initials,
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: locked
                ? Icon(Icons.lock_rounded, size: 11, color: color.withValues(alpha: 0.6))
                : Icon(Icons.close_rounded, size: 13, color: color.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  // ─── Create button ────────────────────────────────────────────────────────────

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _isCreating ? null : _createGroup,
        child: _isCreating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_add_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Create Group',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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

  // ─── Sheet launchers ──────────────────────────────────────────────────────────

  void _showMemberSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AgentSelectorSheet(
        title: 'Select Members',
        icon: Icons.group_rounded,
        agents: agents,
        initialSelected: List.from(selectedMembers),
        onDone: (selected) => setState(() => selectedMembers = selected),
      ),
    );
  }

  void _showAdminSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AgentSelectorSheet(
        title: 'Select Admins',
        icon: Icons.admin_panel_settings_rounded,
        agents: agents.where((a) => a.email != loggedInUserEmail).toList(),
        initialSelected:
            selectedAdmins.where((e) => e != loggedInUserEmail).toList(),
        onDone: (selected) => setState(() {
          selectedAdmins = [
            if (loggedInUserEmail != null) loggedInUserEmail!,
            ...selected,
          ];
        }),
      ),
    );
  }

  // ─── Create group ─────────────────────────────────────────────────────────────

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter a group name', isError: true);
      return;
    }
    if (selectedMembers.isEmpty) {
      _showSnackBar('Please select at least one member', isError: true);
      return;
    }
    if (selectedAdmins.isEmpty) {
      _showSnackBar('Please select at least one admin', isError: true);
      return;
    }

    setState(() => _isCreating = true);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    final success = await groupProvider.createGroup(
      groupName: _groupNameController.text.trim(),
      groupDescription: _groupDescriptionController.text.trim(),
      admins: selectedAdmins,
      members: selectedMembers,
      groupImage: _groupImageUrl ?? '',
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (success) {
      _showSnackBar('Group created successfully!');
      Navigator.pop(context);
    } else {
      _showSnackBar('Failed to create group', isError: true);
    }
  }
}

// ─── Agent selector bottom sheet ─────────────────────────────────────────────

class _AgentSelectorSheet extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Agent> agents;
  final List<String> initialSelected;
  final void Function(List<String>) onDone;

  const _AgentSelectorSheet({
    required this.title,
    required this.icon,
    required this.agents,
    required this.initialSelected,
    required this.onDone,
  });

  @override
  State<_AgentSelectorSheet> createState() => _AgentSelectorSheetState();
}

class _AgentSelectorSheetState extends State<_AgentSelectorSheet> {
  late List<String> _selected;
  late List<Agent> _filtered;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _filtered = widget.agents;
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.agents
          : widget.agents
              .where((a) =>
                  a.name.toLowerCase().contains(q) ||
                  a.email.toLowerCase().contains(q))
              .toList();
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.78;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyD9D9D9,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDCEBFF,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: AppColors.blue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black2E2E2E,
                        ),
                      ),
                      Text(
                        '${_selected.length} selected',
                        style: const TextStyle(color: AppColors.grey7B7B7B, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onDone(_selected);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: const TextStyle(color: AppColors.greyAAAAAA, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.greyAAAAAA, size: 20),
                filled: true,
                fillColor: const Color(0xffF5F7FB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.greyE5E7EB),
          // Agent list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      _search.text.isEmpty ? 'No agents available' : 'No results found',
                      style: const TextStyle(color: AppColors.grey7B7B7B, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                      color: AppColors.greyE5E7EB,
                    ),
                    itemBuilder: (context, index) {
                      final agent = _filtered[index];
                      final isSelected = _selected.contains(agent.email);

                      return InkWell(
                        onTap: () => setState(() {
                          isSelected
                              ? _selected.remove(agent.email)
                              : _selected.add(agent.email);
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isSelected
                                    ? AppColors.blue.withValues(alpha: 0.12)
                                    : AppColors.backgroundDCEBFF,
                                child: Text(
                                  _initials(agent.name),
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.blue
                                        : AppColors.grey7B7B7B,
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
                                        color: isSelected
                                            ? AppColors.blue
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
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.blue
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.blue
                                        : AppColors.greyD9D9D9,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 15)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
