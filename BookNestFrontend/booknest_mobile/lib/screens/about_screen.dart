import 'package:flutter/material.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'ABOUT US',
      showBackButton: true,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo / naziv
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.darkBrown,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.menu_book_rounded,
                            color: AppColors.pageBg, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          'BookNest',
                          style: TextStyle(
                            color: AppColors.pageBg,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'World of your stories!',
                          style: TextStyle(
                            color: AppColors.pageBg.withValues(alpha: 0.8),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _InfoCard(
                    icon: Icons.info_outline,
                    title: 'About BookNest',
                    content:
                        'BookNest is your digital home for books and literary events. '
                        'Discover new titles, explore categories, purchase books, '
                        'and reserve seats at events — all in one place.',
                  ),

                  const SizedBox(height: 14),

                  _InfoCard(
                    icon: Icons.email_outlined,
                    title: 'Contact',
                    content: 'booknest@gmail.com',
                  ),

                  const SizedBox(height: 14),

                  _InfoCard(
                    icon: Icons.smartphone_outlined,
                    title: 'Version',
                    content: '1.0.0',
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Copyright — uvijek na dnu
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              '©2026 BookNest. All rights reserved.',
              style: TextStyle(
                color: AppColors.darkBrown.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBrown.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.darkBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.darkBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: AppColors.darkBrown.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
