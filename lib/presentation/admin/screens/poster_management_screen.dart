import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/poster_model.dart';
import 'package:kkpchatapp/data/repositories/poster_repository.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';

import 'package:cached_network_image/cached_network_image.dart';

class PosterManagementScreen extends StatefulWidget {
  const PosterManagementScreen({super.key});

  @override
  State<PosterManagementScreen> createState() => _PosterManagementScreenState();
}

class _PosterManagementScreenState extends State<PosterManagementScreen> {
  final PosterRepository _posterRepository = PosterRepository();
  final S3UploadService _s3UploadService = S3UploadService();
  List<PosterModel> _posters = [];
  File? _selectedImage;
  bool _isLoading = true;
  bool _isUploading = false; // Track uploading state

  @override
  void initState() {
    super.initState();
    _fetchPosters();
  }

  Future<void> _fetchPosters() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _posters = await _posterRepository.getPosters();
    } catch (e) {
      // Handle error, e.g., show a snackbar or dialog
      if (kDebugMode) {
        debugPrint("Failed to fetch Posters: ${e.toString()}");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadPoster() async {
    if (_selectedImage == null) {
      Utils().showSuccessDialog(context, AppLocalizations.of(context)!.uploadProductImage, false);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context); // Close dialog
        }
      });
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl = await _s3UploadService.uploadFile(_selectedImage!);
      if (imageUrl != null) {
        bool success = await _posterRepository.addPoster(imageUrl);
        if (success && mounted) {
          Utils().showSuccessDialog(context, "Poster uploaded successfully!", true);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context); // Close dialog
            }
          });
          _fetchPosters();
          _selectedImage = null;
        } else {
          if (mounted) {
            Utils().showSuccessDialog(context, "Failed to upload poster.", false);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Failed to upload  poster: $e");
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deletePoster(String posterId) async {
    try {
      bool success = await _posterRepository.deletePoster(posterId);
      if (success && mounted) {
        Utils().showSuccessDialog(context, "Poster deleted successfully!", true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context); // Close dialog
          }
        });
        _fetchPosters();
      } else {
        if (mounted) {
          Utils().showSuccessDialog(context, "Failed to delete poster.", false);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Failed to deleted poster: $e");
      }
    }
  }

  void _pickImage(File image) {
    setState(() {
      _selectedImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.posterAdsManagement,
          style: AppTextStyles.black15_500,
        ),
      ),
      body: _isUploading
          ? FullScreenLoader(
              color: Colors.white.withValues(alpha: 0.5),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildImagePickerContainer(context),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? _buildShimmerList()
                        : ListView.builder(
                            itemCount: _posters.length,
                            itemBuilder: (context, index) {
                              final poster = _posters[index];
                              return _buildPosterCard(poster);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePickerContainer(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: GestureDetector(
        onTap: () async {
          final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            _pickImage(File(pickedFile.path)); // Directly call the method
          }
        },
        child: Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: DottedBorder(
                  color: Colors.grey.withOpacity(0.67),
                  strokeWidth: 2,
                  dashPattern: const [6, 4],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  child: Center(
                    child: Container(
                      height: 180,
                      padding: const EdgeInsets.all(5),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_rounded,
                                    size: 50, color: Colors.grey),
                                Text(
                                  AppLocalizations.of(context)!.uploadProductImage,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              clipBehavior: Clip.antiAlias,
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.fitWidth,
                                height: 180,
                                width: double.infinity,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 10),
                child: CustomButton(
                  onPressed: _isUploading ? null : _uploadPoster,
                  text: AppLocalizations.of(context)!.uploadPoster,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosterCard(PosterModel poster) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: poster.mediaUrl,
                placeholder: (context, url) => Container(
                  height: 150,
                  color: Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  color: Colors.grey[300],
                ),
                fit: BoxFit.fill,
                height: 130,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomButton(
              textColor: Colors.white,
              text: AppLocalizations.of(context)!.deletePoster,
              onPressed: () => _deletePoster(poster.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.white,
      child: ListView.builder(
        itemCount: 5, // Number of shimmer placeholders
        itemBuilder: (context, index) {
          return Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 120,
                      color: Colors.white, // Shimmer placeholder color
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 40, // Adjust height to match your button
                    color: Colors.white, // Shimmer placeholder color
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
