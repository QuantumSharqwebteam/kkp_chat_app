import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/api/chat_service.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';

class TransferAgentScreen extends StatefulWidget {
  final String customerEmailId;
  const TransferAgentScreen({super.key, required this.customerEmailId});

  @override
  State<TransferAgentScreen> createState() => _TransferAgentScreenState();
}

class _TransferAgentScreenState extends State<TransferAgentScreen> {
  List<Agent> _agentsList = [];
  List<String> _assignedAgentEmails = [];
  bool _isLoading = true;
  bool _isTransferring = false;
  String? _transferringAgentEmail;
  final _repo = AuthRepository();
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _fetchAssignedAgentList();
  }

  Future<void> _fetchAgents() async {
    try {
      List<Agent> agents = await _repo.getAgent();
      // Filter agents to include only those in the assigned list
      List<Agent> filteredAgents =
          agents.where((agent) => _assignedAgentEmails.contains(agent.email)).toList();

      if (mounted) {
        setState(() {
          _agentsList = filteredAgents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching agents: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAssignedAgentList() async {
    try {
      List<String> assignedAgents = await _repo.fetchAssignedAgentList();
      setState(() {
        _assignedAgentEmails = assignedAgents;
      });
      _fetchAgents(); // Fetch agents after getting the assigned list
    } catch (e) {
      debugPrint("Error fetching assigned agent list: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _transferCustomerToAgent(String agentEmail) async {
    if (_isTransferring) return;

    if (mounted) {
      setState(() {
        _isTransferring = true;
        _transferringAgentEmail = agentEmail;
      });
    }

    try {
      bool success = await _chatService.transferCustomerToAgent(
        customerEmail: widget.customerEmailId,
        agentEmail: agentEmail,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer transferred to $agentEmail')),
        );
        Navigator.pop(context);
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to transfer customer')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTransferring = false;
          _transferringAgentEmail = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyE5E7EB,
      appBar: AppBar(
        backgroundColor: AppColors.greyE5E7EB,
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: Platform.isAndroid,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _agentsList.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context)!.noAgentsAvailable))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _agentsList.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildTransferImage();
                          }
                          final agent = _agentsList[index - 1];
                          return _agentButton(agent);
                        },
                      ),
          ),
          if (_isTransferring)
            const Positioned.fill(
              child: FullScreenLoader(
                color: Color(0xB3FFFFFF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransferImage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Stack(children: [
          Image.asset(
            'assets/images/oval.png',
            height: 250,
            width: 250,
          ),
          Positioned(
            bottom: 50,
            child: Image.asset(
              'assets/images/transfer.png',
              height: 250,
              width: 250,
            ),
          ),
          Positioned(
            top: 130,
            left: 70,
            child: Image.asset(
              'assets/images/cArrow.png',
              height: 30,
              width: 110,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _agentButton(Agent agent) {
    final isSubmittingThisAgent = _transferringAgentEmail == agent.email;

    return GestureDetector(
      onTap: _isTransferring ? null : () => _transferCustomerToAgent(agent.email),
      child: Container(
        width: double.maxFinite,
        margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.blue00ABE9, width: 2),
            borderRadius: BorderRadius.circular(5),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, -4),
                color: AppColors.blue00ABE9.withValues(alpha: 0.10),
              ),
              BoxShadow(
                spreadRadius: 2,
                blurRadius: 1,
                offset: Offset(0, 0),
                color: AppColors.blue00ABE9.withValues(alpha: 0),
              ),
              BoxShadow(
                spreadRadius: 4,
                blurRadius: 0,
                offset: Offset(0, 0),
                color: AppColors.blue00ABE9.withValues(alpha: 0.10),
              ),
            ]),
        child: Center(
          child: Column(
            children: [
              Text(
                agent.name,
                style: AppTextStyles.black18_600.copyWith(
                  color: AppColors.blue00ABE9,
                ),
              ),
              Text(
                agent.role,
                style: AppTextStyles.black12_400.copyWith(
                  color: AppColors.blue00ABE9,
                ),
              ),
              if (isSubmittingThisAgent) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.blue00ABE9,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
