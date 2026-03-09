import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/poster_model.dart';
import 'package:kkpchatapp/data/repositories/poster_repository.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';

import 'dart:io';
import 'package:shimmer/shimmer.dart';

import 'package:cached_network_image/cached_network_image.dart';

// class PosterManagementScreen extends StatefulWidget {
//   const PosterManagementScreen({super.key});

//   @override
//   State<PosterManagementScreen> createState() => _PosterManagementScreenState();
// }

// class _PosterManagementScreenState extends State<PosterManagementScreen> {
//   final PosterRepository _posterRepository = PosterRepository();
//   final S3UploadService _s3UploadService = S3UploadService();
//   List<PosterModel> _posters = [];
//   File? _selectedImage;
//   bool _isLoading = true;
//   bool _isUploading = false; // Track uploading state

//   @override
//   void initState() {
//     super.initState();
//     _fetchPosters();
//   }

//   Future<void> _fetchPosters() async {
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       _posters = await _posterRepository.getPosters();
//     } catch (e) {
//       // Handle error, e.g., show a snackbar or dialog
//       if (kDebugMode) {
//         debugPrint("Failed to fetch Posters: ${e.toString()}");
//       }
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _uploadPoster() async {
//     if (_selectedImage == null) {
//       Utils().showSuccessDialog(context, AppLocalizations.of(context)!.uploadProductImage, false);
//       Future.delayed(const Duration(seconds: 1), () {
//         if (mounted) {
//           Navigator.pop(context); // Close dialog
//         }
//       });
//       return;
//     }

//     setState(() {
//       _isUploading = true;
//     });

//     try {
//       String? imageUrl = await _s3UploadService.uploadFile(_selectedImage!);
//       if (imageUrl != null) {
//         bool success = await _posterRepository.addPoster(imageUrl);
//         if (success && mounted) {
//           Utils().showSuccessDialog(context, "Poster uploaded successfully!", true);
//           Future.delayed(const Duration(seconds: 1), () {
//             if (mounted) {
//               Navigator.pop(context); // Close dialog
//             }
//           });
//           _fetchPosters();
//           _selectedImage = null;
//         } else {
//           if (mounted) {
//             Utils().showSuccessDialog(context, "Failed to upload poster.", false);
//           }
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         debugPrint("Failed to upload  poster: $e");
//       }
//     } finally {
//       setState(() {
//         _isUploading = false;
//       });
//     }
//   }

//   Future<void> _deletePoster(String posterId) async {
//     try {
//       bool success = await _posterRepository.deletePoster(posterId);
//       if (success && mounted) {
//         Utils().showSuccessDialog(context, "Poster deleted successfully!", true);
//         Future.delayed(const Duration(seconds: 2), () {
//           if (mounted) {
//             Navigator.pop(context); // Close dialog
//           }
//         });
//         _fetchPosters();
//       } else {
//         if (mounted) {
//           Utils().showSuccessDialog(context, "Failed to delete poster.", false);
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         debugPrint("Failed to deleted poster: $e");
//       }
//     }
//   }

//   void _pickImage(File image) {
//     setState(() {
//       _selectedImage = image;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           AppLocalizations.of(context)!.posterAdsManagement,
//           style: AppTextStyles.black15_500,
//         ),
//       ),
//       body: _isUploading
//           ? FullScreenLoader(
//               color: Colors.white.withValues(alpha: 0.5),
//             )
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   _buildImagePickerContainer(context),
//                   const SizedBox(height: 20),
//                   Expanded(
//                     child: _isLoading
//                         ? _buildShimmerList()
//                         : ListView.builder(
//                             itemCount: _posters.length,
//                             itemBuilder: (context, index) {
//                               final poster = _posters[index];
//                               return _buildPosterCard(poster);
//                             },
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildImagePickerContainer(BuildContext context) {
//     return SizedBox(
//       width: double.maxFinite,
//       child: GestureDetector(
//         onTap: () async {
//           final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//           if (pickedFile != null) {
//             _pickImage(File(pickedFile.path)); // Directly call the method
//           }
//         },
//         child: Card(
//           color: Colors.white,
//           surfaceTintColor: Colors.white,
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(10),
//                 child: DottedBorder(
//                   color: Colors.grey.withOpacity(0.67),
//                   strokeWidth: 2,
//                   dashPattern: const [6, 4],
//                   borderType: BorderType.RRect,
//                   radius: const Radius.circular(12),
//                   child: Center(
//                     child: Container(
//                       height: 180,
//                       padding: const EdgeInsets.all(5),
//                       child: _selectedImage == null
//                           ? Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Icon(Icons.cloud_upload_rounded,
//                                     size: 50, color: Colors.grey),
//                                 Text(
//                                   AppLocalizations.of(context)!.uploadProductImage,
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                               ],
//                             )
//                           : ClipRRect(
//                               clipBehavior: Clip.antiAlias,
//                               borderRadius: BorderRadius.circular(10),
//                               child: Image.file(
//                                 _selectedImage!,
//                                 fit: BoxFit.fitWidth,
//                                 height: 180,
//                                 width: double.infinity,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 10),
//                 child: CustomButton(
//                   onPressed: _isUploading ? null : _uploadPoster,
//                   text: AppLocalizations.of(context)!.uploadPoster,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPosterCard(PosterModel poster) {
//     return Card(
//       color: Colors.white,
//       surfaceTintColor: Colors.white,
//       elevation: 4,
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(4.0),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: CachedNetworkImage(
//                 imageUrl: poster.mediaUrl,
//                 placeholder: (context, url) => Container(
//                   height: 150,
//                   color: Colors.grey[300],
//                 ),
//                 errorWidget: (context, url, error) => Container(
//                   height: 150,
//                   color: Colors.grey[300],
//                 ),
//                 fit: BoxFit.fill,
//                 height: 130,
//                 width: double.infinity,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: CustomButton(
//               textColor: Colors.white,
//               text: AppLocalizations.of(context)!.deletePoster,
//               onPressed: () => _deletePoster(poster.id),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildShimmerList() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.white,
//       child: ListView.builder(
//         itemCount: 5, // Number of shimmer placeholders
//         itemBuilder: (context, index) {
//           return Card(
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(4.0),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Container(
//                       height: 120,
//                       color: Colors.white, // Shimmer placeholder color
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Container(
//                     height: 40, // Adjust height to match your button
//                     color: Colors.white, // Shimmer placeholder color
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

class PosterManagementScreen extends StatefulWidget {
  const PosterManagementScreen({super.key});

  @override
  State<PosterManagementScreen> createState() => _PosterManagementScreenState();
}

class _PosterManagementScreenState extends State<PosterManagementScreen> {
  final PosterRepository _posterRepository = PosterRepository();
  final S3UploadService _s3UploadService = S3UploadService();

  List<PosterModel> _posters = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosters();
  }

  /// Fetch posters from API
  Future<void> _fetchPosters() async {
    setState(() => _isLoading = true);

    try {
      _posters = await _posterRepository.getPosters();
    } catch (e) {
      debugPrint("Failed to fetch posters $e");
    }

    setState(() => _isLoading = false);
  }

  /// Delete poster
  Future<void> _deletePoster(String posterId) async {
    try {
      bool success = await _posterRepository.deletePoster(posterId);

      if (success && mounted) {
        Utils().showSuccessDialog(context, "Poster deleted successfully!", true);

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });

        _fetchPosters();
      } else {
        Utils().showSuccessDialog(context, "Failed to delete poster", false);
      }
    } catch (e) {
      debugPrint("Delete error $e");
    }
  }

  /// Open bottom sheet to upload poster
  void _openAddPosterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // transparent for rounded design
      builder: (_) => AddPosterBottomSheet(
        onUploadSuccess: _fetchPosters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.posterAdsManagement, style: AppTextStyles.black15_500),
      ),

      /// Floating action button
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue00ABE9,
        onPressed: _openAddPosterSheet,
        child: const Icon(Icons.add),
      ),

      body: _isLoading
          ? _buildShimmerGrid()
          : _posters.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchPosters,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posters.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final poster = _posters[index];
                      return _buildPosterCard(poster);
                    },
                  ),
                ),
    );
  }

  /// ===============================
  /// POLISHED POSTER TILE UI
  /// ===============================
  Widget _buildPosterCard(PosterModel poster) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        elevation: 4,
        shadowColor: Colors.black12,
        child: Stack(
          children: [
            /// Poster Image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: poster.mediaUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey[200],
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),

            /// Gradient overlay for better UI
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black26,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            /// 3-dot menu with background circle
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == "delete") {
                      _deletePoster(poster.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18),
                          SizedBox(width: 8),
                          Text("Delete"),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// EMPTY STATE
  /// ===============================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 120, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Posters Available",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap the + button to upload your first poster",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// SHIMMER LOADING GRID
  /// ===============================
  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class AddPosterBottomSheet extends StatefulWidget {
  final VoidCallback onUploadSuccess;

  const AddPosterBottomSheet({super.key, required this.onUploadSuccess});

  @override
  State<AddPosterBottomSheet> createState() => _AddPosterBottomSheetState();
}

class _AddPosterBottomSheetState extends State<AddPosterBottomSheet> {
  final S3UploadService _s3UploadService = S3UploadService();
  final PosterRepository _posterRepository = PosterRepository();

  File? _selectedImage;
  bool _isUploading = false;

  /// Pick image
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  /// Upload poster
  Future<void> _uploadPoster() async {
    if (_selectedImage == null) {
      Utils().showSuccessDialog(context, "Please select image", false);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = await _s3UploadService.uploadFile(_selectedImage!);

      if (imageUrl != null) {
        bool success = await _posterRepository.addPoster(imageUrl);

        if (success) {
          widget.onUploadSuccess();
          Navigator.pop(context);

          Utils().showSuccessDialog(context, "Poster uploaded successfully!", true);
          Future.delayed(const Duration(microseconds: 300), () {
            if (context.mounted) {
              Navigator.pop(context); // Close dialog
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Upload error $e");
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // ✅ prevents bottom gesture overlap
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Drag indicator
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Upload Poster",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 20),

            /// Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.cloud_upload_rounded, size: 48),
                          SizedBox(height: 10),
                          Text("Tap to select poster"),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            CustomButton(
              text: _isUploading ? "Uploading..." : "Upload Poster",
              onPressed: _isUploading ? null : _uploadPoster,
            ),
          ],
        ),
      ),
    );
  }
}
