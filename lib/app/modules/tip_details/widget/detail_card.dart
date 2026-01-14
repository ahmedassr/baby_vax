import 'package:baby_vax/app/core/imports/import_manger.dart';

class DetailCard extends StatelessWidget {
  final String? title;
  final String? description;
  final String? image;

  const DetailCard({this.title, this.description, this.image, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tip Title
            AppText(
              text: title ?? "",
              maxLines: 5,
              style: AppTextStyles.headLineExtraSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            12.sbh,
            // Optional Image
            if (image?.isNotEmpty ?? false)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  image!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (image?.isNotEmpty ?? false) 16.sbh,
            AppText(
              text: description ?? "No description available.",
              maxLines: 30,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
