import 'package:flutter/material.dart';
import '../layouts/constants.dart';

const adminRowStyle = TextStyle(
  color: AppColors.darkBrown,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

class AdminColumn {
  final int flex;
  final String text;
  final Color? color;
  final FontWeight? fontWeight;

  const AdminColumn({
    required this.flex,
    required this.text,
    this.color,
    this.fontWeight,
  });
}

class AdminColHeader extends StatelessWidget {
  final String text;
  final int flex;

  const AdminColHeader(this.text, {super.key, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.darkBrown,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AdminActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double width;

  const AdminActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 34,
      child: ElevatedButton(
        onPressed: onPressed ?? () {},
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.darkBrown,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class AdminThumbnail extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;

  const AdminThumbnail({
    super.key,
    this.imageUrl,
    this.fallbackIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, color: AppColors.mediumBrown, size: 22),
              )
            : Icon(fallbackIcon, color: AppColors.mediumBrown, size: 22),
      ),
    );
  }
}

class AdminAvatar extends StatelessWidget {
  final String? imageUrl;

  const AdminAvatar({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mediumBrown, width: 1.5),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_outline,
                  color: AppColors.mediumBrown,
                  size: 22,
                ),
              )
            : const Icon(
                Icons.person_outline,
                color: AppColors.mediumBrown,
                size: 22,
              ),
      ),
    );
  }
}

class DetailActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double width;

  const DetailActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.darkBrown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.4),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const DetailRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ),
        Expanded(
          child: Text(value ?? '-',
              style: const TextStyle(color: AppColors.darkBrown, fontSize: 15)),
        ),
      ],
    );
  }
}

class StarRating extends StatelessWidget {
  final int rating;

  const StarRating(this.rating, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 14,
          color: const Color(0xFFE8A838),
        ),
      ),
    );
  }
}

class AdminListRow extends StatelessWidget {
  final Widget? leading;
  final List<AdminColumn> columns;
  final List<Widget> actions;

  const AdminListRow({
    super.key,
    this.leading,
    required this.columns,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          ...columns.map((col) => Expanded(
                flex: col.flex,
                child: Text(
                  col.text,
                  style: adminRowStyle.copyWith(
                    color: col.color,
                    fontWeight: col.fontWeight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                actions[i],
              ],
            ],
          ),
        ],
      ),
    );
  }
}
