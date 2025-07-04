import 'package:kkpchatapp/data/api/poster_service.dart';
import 'package:kkpchatapp/data/models/poster_model.dart';

class PosterRepository {
  final PosterService _posterService = PosterService();

  /// Get all posters
  Future<List<PosterModel>> getPosters() async {
    return await _posterService.getAllPosters();
  }

  /// Add a new poster
  Future<bool> addPoster(String mediaUrl) async {
    return await _posterService.addPoster(mediaUrl);
  }

  /// Delete a poster by ID
  Future<bool> deletePoster(String posterId) async {
    return await _posterService.deletePoster(posterId);
  }
}
