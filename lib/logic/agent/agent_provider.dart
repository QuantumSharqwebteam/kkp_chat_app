import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
import 'package:kkpchatapp/data/models/agent.dart';

class AgentProvider extends ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  List<Agent> _agents = [];
  bool _isLoading = false;

  List<Agent> get agents => _agents;
  bool get isLoading => _isLoading;

  Future<void> fetchAgents() async {
    if (!ConnectivityService.instance.isOnline) {
      debugPrint('📴 [AgentProvider] Offline — skipping fetch'
          '${_agents.isNotEmpty ? " (${_agents.length} agents in memory)" : ""}');
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      final agents = await _authApi.getAgent();
      _agents = agents;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching agents: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addAgent(
      {required Map<String, dynamic> body}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authApi.addAgent(body: body);
      if (response['message'] == "User signed up successfully") {
        await fetchAgents(); // Refresh the agent list after adding
      } else {
        _isLoading = false;
        notifyListeners();
      }
      return response;
    } catch (e) {
      debugPrint("Error adding agent: $e");
      _isLoading = false;
      notifyListeners();
      return {
        "status": 500,
        "message": "An error occurred while adding the agent"
      };
    }
  }

  Future<Map<String, dynamic>> assignAgentToList(
      {required String email}) async {
    try {
      final response = await _authApi.assignAgent(email: email);
      if (response["status"] == 200) {
        await fetchAgents(); // Refresh the agent list after assigning
      }
      return response;
    } catch (e) {
      debugPrint("Error assigning agent: $e");
      return {
        "status": 500,
        "message": "An error occurred while assigning the agent"
      };
    }
  }

  Future<Map<String, dynamic>> deleteAgent({required String email}) async {
    try {
      final response = await _authApi.deleteAgent(email);
      if (response["status"] == 200) {
        await fetchAgents(); // Refresh the agent list after deleting
      }
      return response;
    } catch (e) {
      debugPrint("Error deleting agent: $e");
      return {
        "status": 500,
        "message": "An error occurred while deleting the agent"
      };
    }
  }
}
