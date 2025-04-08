import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/services/chat_service.dart';
import 'package:kkp_chat_app/data/models/agent.dart';

class TransferAgentScreen extends StatefulWidget {
  final String customerEmailId;
  const TransferAgentScreen({super.key, required this.customerEmailId});

  @override
  State<TransferAgentScreen> createState() => _TransferAgentScreenState();
}

class _TransferAgentScreenState extends State<TransferAgentScreen> {
  List<Agent> _agentsList = [];
  bool _isLoading = true;
  final AuthApi _auth = AuthApi();
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  Future<void> _fetchAgents() async {
    try {
      List<Agent> agents = await _auth.getAgent();
      if (mounted) {
        setState(() {
          _agentsList = agents;
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
          : Center(
              child: Column(
                children: [
                  _buildTransferImage(),
                  _agentsList.isEmpty
                      ? const Text("No agents available")
                      : Column(
                          children: _agentsList.map((agent) {
                            return _agentButton(agent);
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildTransferImage() {
    return Padding(
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
