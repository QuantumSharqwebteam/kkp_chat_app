import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

class ToastWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDismiss;

  const ToastWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onDismiss,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );
    _progressController.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      _fadeController.reverse();
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 5,
            center: Alignment.centerLeft,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, top: 10, bottom: 5, right: 5),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: .3),
                    radius: 16,
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.grey525252,
                      child: Icon(
                        Icons.check,
                        color: AppColors.green22C55E,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.black10_500
                              .copyWith(decoration: TextDecoration.none),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.subtitle,
                          style: AppTextStyles.grey12_600
                              .copyWith(decoration: TextDecoration.none),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.bottomLeft,
                  child: ClipPath(
                    clipper: _DiagonalClipper(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.grey525252,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      height: 5,
                      width: MediaQuery.of(context).size.width *
                          0.8 *
                          _progressAnimation.value,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - 10, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_DiagonalClipper oldClipper) => true;
}
