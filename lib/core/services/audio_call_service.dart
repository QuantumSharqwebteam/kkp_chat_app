// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'socket_service.dart';

// import 'package:flutter/foundation.dart';

// class AudioCallService {
//   static final AudioCallService _instance = AudioCallService._internal();
//   factory AudioCallService() => _instance;

//   final SocketService _socketService = SocketService();

//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;
//   MediaStream? _remoteStream;

//   final List<RTCIceCandidate> _iceCandidates = [];
//   bool _remoteDescriptionSet = false;

//   AudioCallService._internal() {
//     _socketService.onIncomingCall(_handleIncomingCall);
//     _socketService.onCallAnswered(_handleCallAnswered);
//     _socketService.onCallTerminated(_handleCallTerminated);
//     _socketService.onSignalCandidate(_handleSignalCandidate);
//   }

//   Future<void> initiateCall(
//       String targetId, String senderId, String senderName) async {
//     try {
//       debugPrint('📞 Initiating call to $targetId');
//       await _createPeerConnection();

//       _localStream = await _getUserMedia();
//       _localStream!.getTracks().forEach((track) {
//         _peerConnection!.addTrack(track, _localStream!);
//       });

//       final offer = await _peerConnection!.createOffer({
//         'offerToReceiveAudio': true,
//       });
//       await _peerConnection!.setLocalDescription(offer);

//       _socketService.initiateCall(
//         targetId: targetId,
//         signalData: offer.toMap(),
//         senderId: senderId,
//         senderName: senderName,
//       );
//       debugPrint('📢 Offer sent to $targetId');

//       // ✅ Ensure speaker is on
//       await Helper.setSpeakerphoneOn(true);
//     } catch (e) {
//       debugPrint('⚠️ Error initiating call: $e');
//     }
//   }

//   Future<void> answerCall(String callerId, dynamic signalData) async {
//     try {
//       debugPrint('📞 Answering call from $callerId');
//       await _createPeerConnection();

//       _localStream = await _getUserMedia();
//       _localStream!.getTracks().forEach((track) {
//         _peerConnection!.addTrack(track, _localStream!);
//       });

//       RTCSessionDescription offer = RTCSessionDescription(
//         signalData['sdp'],
//         signalData['type'],
//       );
//       await _peerConnection!.setRemoteDescription(offer);
//       _remoteDescriptionSet = true;

//       final answer = await _peerConnection!.createAnswer({
//         'offerToReceiveAudio': true,
//       });
//       await _peerConnection!.setLocalDescription(answer);

//       _socketService.answerCall(
//         to: callerId,
//         signalData: answer.toMap(),
//       );
//       debugPrint('📢 Answer sent to $callerId');

//       // ✅ Ensure speaker is on
//       await Helper.setSpeakerphoneOn(true);
//     } catch (e) {
//       debugPrint('⚠️ Error answering call: $e');
//     }
//   }

//   Future<void> _createPeerConnection() async {
//     try {
//       _peerConnection = await createPeerConnection({
//         'iceServers': [
//           {
//             'urls': [
//               'stun:stun1.l.google.com:19302',
//               'stun:stun2.l.google.com:19302'
//             ]
//           }
//         ]
//       });

//       _peerConnection!.onTrack = (event) {
//         debugPrint('🎥 Remote track added');
//         if (event.track.kind == 'audio') {
//           _remoteStream = event.streams.first;
//           debugPrint('🔊 Remote audio stream assigned');

//           for (var track in _remoteStream!.getAudioTracks()) {
//             debugPrint('🎧 Remote audio track: ${track.id}');
//             debugPrint('🟢 enabled: ${track.enabled}');
//           }

//           // ✅ Ensure audio plays (especially important for iOS/Android)
//           // Attach remote stream to audio output
//           _remoteStream?.getAudioTracks().forEach((track) {
//             track.enabled = true;
//           });

//           // ✅ Enable speaker
//           Helper.setSpeakerphoneOn(true);
//         }
//       };

//       _peerConnection!.onIceCandidate = (candidate) async {
//         if (_remoteDescriptionSet) {
//           await _peerConnection!.addCandidate(candidate);
//           debugPrint('🧊 ICE candidate added directly');
//         } else {
//           _iceCandidates.add(candidate);
//           debugPrint('🧊 ICE candidate buffered');
//         }
//       };

//       _peerConnection!.onConnectionState = (state) {
//         debugPrint('🔌 Connection state: $state');
//         if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
//           debugPrint('⚠️ Peer connection failed');
//           _handleCallTerminated({});
//         }
//       };

//       debugPrint('🔗 Peer connection created');
//     } catch (e) {
//       debugPrint('⚠️ Error creating peer connection: $e');
//     }
//   }

//   Future<MediaStream> _getUserMedia() async {
//     try {
//       final Map<String, dynamic> mediaConstraints = {
//         'audio': {
//           'mandatory': {
//             'echoCancellation': 'true',
//             'googEchoCancellation': 'true',
//             'googEchoCancellation2': 'true',
//             'googNoiseSuppression': 'true',
//             'googDAEchoCancellation': 'true',
//           },
//           'optional': [],
//         },
//       };
//       MediaStream stream =
//           await navigator.mediaDevices.getUserMedia(mediaConstraints);
//       debugPrint('🎤 Local media stream obtained');
//       debugPrint('🔍 Local audio tracks: ${stream.getAudioTracks().length}');
//       return stream;
//     } catch (e) {
//       debugPrint('⚠️ Error getting user media: $e');
//       rethrow;
//     }
//   }

//   void _handleIncomingCall(Map<String, dynamic> data) {
//     try {
//       debugPrint('📞 Incoming call from ${data['from']}');
//       // Add further UI trigger or notification logic if needed
//     } catch (e) {
//       debugPrint('⚠️ Error handling incoming call: $e');
//     }
//   }

//   void _handleCallAnswered(Map<String, dynamic> data) async {
//     try {
//       final signalData = data['signalData'];
//       if (signalData == null) {
//         debugPrint('❌ signalData is null!');
//         return;
//       }

//       RTCSessionDescription answer = RTCSessionDescription(
//         signalData['sdp'],
//         signalData['type'],
//       );
//       await _peerConnection!.setRemoteDescription(answer);
//       _remoteDescriptionSet = true;
//       debugPrint('📢 Call answered, remote description set');

//       for (RTCIceCandidate candidate in _iceCandidates) {
//         await _peerConnection!.addCandidate(candidate);
//       }
//       _iceCandidates.clear();
//     } catch (e) {
//       debugPrint('⚠️ Error setting remote description: $e');
//     }
//   }

//   void _handleCallTerminated(Map<String, dynamic> data) {
//     try {
//       debugPrint('📞 Call terminated');
//       _peerConnection?.close();
//       _localStream?.dispose();
//       _remoteStream?.dispose();
//       _iceCandidates.clear();
//       _remoteDescriptionSet = false;
//       debugPrint('🔄 Resources disposed');
//     } catch (e) {
//       debugPrint('⚠️ Error handling call termination: $e');
//     }
//   }

//   void _handleSignalCandidate(Map<String, dynamic> data) {
//     try {
//       RTCIceCandidate candidate = RTCIceCandidate(
//         data['candidate']['candidate'],
//         data['candidate']['sdpMid'],
//         data['candidate']['sdpMLineIndex'],
//       );

//       if (_remoteDescriptionSet) {
//         _peerConnection!.addCandidate(candidate);
//         debugPrint('🧊 ICE candidate added directly');
//       } else {
//         _iceCandidates.add(candidate);
//         debugPrint('🧊 ICE candidate buffered');
//       }
//     } catch (e) {
//       debugPrint('⚠️ Error adding ICE candidate: $e');
//     }
//   }

//   void terminateCall(String targetId) {
//     try {
//       _socketService.terminateCall(targetId: targetId);
//       _handleCallTerminated({});
//       debugPrint('📞 Terminating call to $targetId');
//     } catch (e) {
//       debugPrint('⚠️ Error terminating call: $e');
//     }
//   }

//   void dispose() {
//     try {
//       _peerConnection?.close();
//       _localStream?.dispose();
//       _remoteStream?.dispose();
//       _iceCandidates.clear();
//       _remoteDescriptionSet = false;
//       debugPrint('🔄 AudioCallService disposed');
//     } catch (e) {
//       debugPrint('⚠️ Error disposing AudioCallService: $e');
//     }
//   }
// }
