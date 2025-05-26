import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/chat_service.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';

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
      List<Agent> filteredAgents = agents
          .where((agent) => _assignedAgentEmails.contains(agent.email))
          .toList();

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyE5E7EB,
      appBar: AppBar(
        backgroundColor: AppColors.greyE5E7EB,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _agentsList.isEmpty
              ? const Center(child: Text("No agents available"))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _agentsList.length + 1, // +1 for the image section
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildTransferImage();
                    }
                    final agent = _agentsList[index - 1];
                    return _agentButton(agent);
                  },
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
    return GestureDetector(
      onTap: () => _transferCustomerToAgent(agent.email),
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
            ],
          ),
        ),
      ),
    );
  }
}
