import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  // For now, we'll use placeholder data
  // In a real app, you'd integrate with image_picker and cloud storage
  final List<ProgressPhoto> _photos = [
    ProgressPhoto(
      id: '1',
      date: DateTime.now().subtract(const Duration(days: 30)),
      type: 'Front',
      description: 'Starting photo',
    ),
    ProgressPhoto(
      id: '2',
      date: DateTime.now().subtract(const Duration(days: 15)),
      type: 'Side',
      description: '2 week progress',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photos'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addPhoto,
            icon: const Icon(Icons.add_a_photo),
            tooltip: 'Add Photo',
          ),
        ],
      ),
      body: _photos.isEmpty ? _buildEmptyState() : _buildPhotoGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, size: 80, color: Colors.grey[400]),
            const SizedBox(height: AppDimensions.marginLarge),
            Text(
              'No Progress Photos Yet',
              style: AppTextStyles.headline2.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            Text(
              'Start tracking your fitness journey with progress photos. Take consistent photos to see your amazing transformation!',
              style: AppTextStyles.bodyText1.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            ElevatedButton.icon(
              onPressed: _addPhoto,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Your First Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tips card
          Card(
            color: AppColors.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.marginSmall),
                      Text(
                        'Photo Tips',
                        style: AppTextStyles.headline3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.marginSmall),
                  Text(
                    '• Take photos in the same lighting and pose\n'
                    '• Use the same background when possible\n'
                    '• Take photos at the same time of day\n'
                    '• Be consistent with your clothing',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.marginMedium),

          Text(
            'Your Photos (${_photos.length})',
            style: AppTextStyles.headline3.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineSmall?.color,
            ),
          ),

          const SizedBox(height: AppDimensions.marginMedium),

          // Photo grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppDimensions.marginMedium,
                mainAxisSpacing: AppDimensions.marginMedium,
                childAspectRatio: 0.75,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return _buildPhotoCard(photo);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(ProgressPhoto photo) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusMedium),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo, size: 40, color: AppColors.darkGray),
                    SizedBox(height: AppDimensions.marginSmall),
                    Text(
                      'Photo Placeholder',
                      style: TextStyle(color: AppColors.darkGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.type,
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(photo.date),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.darkGray,
                  ),
                ),
                if (photo.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    photo.description,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addPhoto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddPhotoSheet(),
    );
  }

  Widget _buildAddPhotoSheet() {
    final TextEditingController descriptionController = TextEditingController();
    String selectedType = 'Front';

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  'Add Progress Photo',
                  style: AppTextStyles.headline2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // Photo type selection
                Text(
                  'Photo Type',
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.marginSmall),
                Wrap(
                  spacing: 8,
                  children: ['Front', 'Side', 'Back'].map((type) {
                    final isSelected = selectedType == type;
                    return FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setSheetState(() {
                          selectedType = type;
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : null,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppDimensions.marginMedium),

                // Description
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g., "After 4 weeks of training"',
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement camera functionality
                          _showComingSoonSnackBar('Camera');
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.marginMedium),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement gallery functionality
                          _showComingSoonSnackBar('Gallery');
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('From Gallery'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.marginMedium),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoonSnackBar(String feature) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature functionality coming soon!'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class ProgressPhoto {
  final String id;
  final DateTime date;
  final String type; // Front, Side, Back
  final String description;
  final String? imagePath;

  ProgressPhoto({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    this.imagePath,
  });
}
