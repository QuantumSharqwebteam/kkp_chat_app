import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/data/models/agent.dart';

class TransferAgentScreen extends StatefulWidget {
  const TransferAgentScreen({super.key});

  @override
  State<TransferAgentScreen> createState() => _TransferAgentScreenState();
}

class _TransferAgentScreenState extends State<TransferAgentScreen> {
  List<Agent> _agentsList = [];
  bool _isLoading = true;
  final AuthApi _auth = AuthApi();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyE5E7EB,
      appBar: AppBar(
        backgroundColor: AppColors.greyE5E7EB,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Image.asset(
                  'assets/images/transfer.png',
                  height: 200,
                  width: 200,
                ),
              ), // Add your illustration here

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _agentsList.isEmpty
                      ? const Text("No agents available")
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _agentsList.map((agent) {
                            return _agentButton(agent);
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _agentButton(Agent agent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.blue, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        onPressed: () {
          debugPrint("Selected: ${agent.name}");
        },
        child: Text(
          agent.name,
          style: const TextStyle(
              fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
