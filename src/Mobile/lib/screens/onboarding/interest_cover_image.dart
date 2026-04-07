import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

String? interestCoverImageUrl(String englishName) => _coverUrls[englishName];

IconData interestFallbackIcon(String englishName) =>
    _fallbackIcons[englishName] ?? Icons.interests_rounded;

const _coverUrls = {
  'Sports':
      'https://images.unsplash.com/photo-1574629810360-7ed2a40d51fd?auto=format&fit=crop&w=600&q=80',
  'Fitness':
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=600&q=80',
  'Hiking':
      'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=600&q=80',
  'Coffee':
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=600&q=80',
  'Food':
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=600&q=80',
  'Cooking':
      'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=600&q=80',
  'Music':
      'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=600&q=80',
  'Concerts':
      'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=600&q=80',
  'Art':
      'https://images.unsplash.com/photo-1541961017774-22349e4a1262?auto=format&fit=crop&w=600&q=80',
  'Photography':
      'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=600&q=80',
  'Travel':
      'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=600&q=80',
  'Books':
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=600&q=80',
  'Movies':
      'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=600&q=80',
  'Gaming':
      'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=600&q=80',
  'Tech':
      'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=600&q=80',
  'Business':
      'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=600&q=80',
  'Meditation':
      'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=600&q=80',
  'Yoga':
      'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
  'Dancing':
      'https://images.unsplash.com/photo-1504609813445-a2c0879818f8?auto=format&fit=crop&w=600&q=80',
  'Languages':
      'https://images.unsplash.com/photo-1546412414-8035e1776c9f?auto=format&fit=crop&w=600&q=80',
  'Volunteering':
      'https://images.unsplash.com/photo-1593113598334-c288d2baa6c6?auto=format&fit=crop&w=600&q=80',
  'Nature':
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=600&q=80',
  'Animals':
      'https://images.unsplash.com/photo-1450778869180-f41aed341629?auto=format&fit=crop&w=600&q=80',
  'Outdoor':
      'https://images.unsplash.com/photo-1478131143081-80f9f7d078a7?auto=format&fit=crop&w=600&q=80',
};

final _fallbackIcons = <String, IconData>{
  'Sports': Icons.sports_soccer_rounded,
  'Fitness': Icons.fitness_center_rounded,
  'Hiking': Icons.hiking_rounded,
  'Coffee': Icons.local_cafe_rounded,
  'Food': Icons.restaurant_rounded,
  'Cooking': Icons.restaurant_menu_rounded,
  'Music': Icons.music_note_rounded,
  'Concerts': Icons.mic_rounded,
  'Art': Icons.palette_rounded,
  'Photography': Icons.photo_camera_rounded,
  'Travel': Icons.flight_rounded,
  'Books': Icons.menu_book_rounded,
  'Movies': Icons.movie_rounded,
  'Gaming': Icons.sports_esports_rounded,
  'Tech': Icons.computer_rounded,
  'Business': Icons.business_center_rounded,
  'Meditation': Icons.self_improvement_rounded,
  'Yoga': Icons.accessibility_new_rounded,
  'Dancing': Icons.nightlife_rounded,
  'Languages': Icons.translate_rounded,
  'Volunteering': Icons.volunteer_activism_rounded,
  'Nature': Icons.park_rounded,
  'Animals': Icons.pets_rounded,
  'Outdoor': Icons.terrain_rounded,
};

class InterestCoverPhoto extends StatelessWidget {
  const InterestCoverPhoto({
    super.key,
    required this.nameKey,
    this.height = 64,
    this.selected = false,
  });

  final String nameKey;
  final double height;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final url = interestCoverImageUrl(nameKey);
    final icon = interestFallbackIcon(nameKey);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: url == null
            ? _fallback(icon, selected)
            : Image.network(
                url,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => _fallback(icon, selected),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.purple50,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.purple500,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _fallback(IconData icon, bool selected) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [
                  AppColors.purple400.withValues(alpha: 0.35),
                  AppColors.purple600.withValues(alpha: 0.45),
                ]
              : [
                  AppColors.purple100.withValues(alpha: 0.9),
                  AppColors.purple50,
                ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 30,
        color: selected ? AppColors.purple700 : AppColors.purple600,
      ),
    );
  }
}
