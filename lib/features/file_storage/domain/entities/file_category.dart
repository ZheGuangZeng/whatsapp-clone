import 'package:equatable/equatable.dart';

/// Enum for category types with default colors and icons
enum CategoryType {
  documents('documents'),
  images('images'),
  videos('videos'),
  audio('audio'),
  archives('archives'),
  custom('custom');

  const CategoryType(this.value);
  final String value;

  static CategoryType fromString(String value) {
    return CategoryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CategoryType.custom,
    );
  }

  /// Default color for this category type
  String get defaultColor {
    switch (this) {
      case CategoryType.documents:
        return '#2196F3';
      case CategoryType.images:
        return '#4CAF50';
      case CategoryType.videos:
        return '#FF9800';
      case CategoryType.audio:
        return '#9C27B0';
      case CategoryType.archives:
        return '#795548';
      case CategoryType.custom:
        return '#666666';
    }
  }

  /// Default icon for this category type
  String get defaultIcon {
    switch (this) {
      case CategoryType.documents:
        return 'document-text';
      case CategoryType.images:
        return 'image';
      case CategoryType.videos:
        return 'play-circle';
      case CategoryType.audio:
        return 'musical-notes';
      case CategoryType.archives:
        return 'archive';
      case CategoryType.custom:
        return 'folder';
    }
  }
}

/// Domain entity representing a file category for organization
class FileCategory extends Equatable {
  const FileCategory({
    required this.id,
    required this.name,
    this.description,
    String? color,
    String? icon,
    required this.createdBy,
    required this.createdAt,
    this.isSystem = false,
    this.parentCategoryId,
  })  : color = color ?? '#666666',
        icon = icon ?? 'folder';

  /// Unique identifier for the category
  final String id;

  /// Name of the category
  final String name;

  /// Optional description
  final String? description;

  /// Color for the category (hex code)
  final String color;

  /// Icon name for the category
  final String icon;

  /// User ID who created this category
  final String createdBy;

  /// When this category was created
  final DateTime createdAt;

  /// Whether this is a system-defined category
  final bool isSystem;

  /// ID of parent category (null for root level)
  final String? parentCategoryId;

  /// Determine category type from name
  CategoryType get categoryType {
    final lowerName = name.toLowerCase();
    
    if (_containsAny(lowerName, ['document', 'docs', 'pdf', 'text', 'word'])) {
      return CategoryType.documents;
    } else if (_containsAny(lowerName, ['image', 'photo', 'picture', 'pic'])) {
      return CategoryType.images;
    } else if (_containsAny(lowerName, ['video', 'movie', 'film'])) {
      return CategoryType.videos;
    } else if (_containsAny(lowerName, ['audio', 'music', 'song', 'sound'])) {
      return CategoryType.audio;
    } else if (_containsAny(lowerName, ['archive', 'zip', 'compressed'])) {
      return CategoryType.archives;
    }
    
    return CategoryType.custom;
  }

  /// Helper method to check if string contains any of the given patterns
  bool _containsAny(String text, List<String> patterns) {
    return patterns.any((pattern) => text.contains(pattern));
  }

  /// Whether this category was created by a user
  bool get isUserCreated => !isSystem;

  /// Whether this is a root level category
  bool get isRootLevel => parentCategoryId == null;

  /// Get the display color (custom or default)
  String get displayColor {
    if (color != '#666666') {
      return color; // Custom color provided
    }
    return categoryType.defaultColor;
  }

  /// Get the display icon (custom or default)
  String get displayIcon {
    if (icon != 'folder') {
      return icon; // Custom icon provided
    }
    return categoryType.defaultIcon;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        color,
        icon,
        createdBy,
        createdAt,
        isSystem,
        parentCategoryId,
      ];

  /// Creates a copy of this category with updated fields
  FileCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    String? createdBy,
    DateTime? createdAt,
    bool? isSystem,
    String? parentCategoryId,
    bool clearParent = false,
  }) {
    return FileCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isSystem: isSystem ?? this.isSystem,
      parentCategoryId: clearParent ? null : (parentCategoryId ?? this.parentCategoryId),
    );
  }
}

/// A hierarchical collection of file categories
class FileCategoryTree extends Equatable {
  const FileCategoryTree(this.categories);

  /// List of all categories in this tree
  final List<FileCategory> categories;

  /// Get all root level categories
  List<FileCategory> get rootCategories =>
      categories.where((c) => c.isRootLevel).toList();

  /// Get children of a specific category
  List<FileCategory> getChildren(String categoryId) {
    return categories
        .where((c) => c.parentCategoryId == categoryId)
        .toList();
  }

  /// Get all descendants of a category (recursive)
  List<FileCategory> getAllDescendants(String categoryId) {
    final descendants = <FileCategory>[];
    final children = getChildren(categoryId);
    
    for (final child in children) {
      descendants.add(child);
      descendants.addAll(getAllDescendants(child.id));
    }
    
    return descendants;
  }

  /// Get parent of a category
  FileCategory? getParent(String categoryId) {
    final category = findById(categoryId);
    if (category?.parentCategoryId == null) return null;
    
    return findById(category!.parentCategoryId!);
  }

  /// Get path from category to root
  List<FileCategory> getPathToRoot(String categoryId) {
    final path = <FileCategory>[];
    FileCategory? current = findById(categoryId);
    
    while (current != null) {
      path.add(current);
      current = current.parentCategoryId != null
          ? findById(current.parentCategoryId!)
          : null;
    }
    
    return path;
  }

  /// Check if one category is ancestor of another
  bool isAncestor(String ancestorId, String descendantId) {
    final path = getPathToRoot(descendantId);
    return path.any((c) => c.id == ancestorId && c.id != descendantId);
  }

  /// Get depth of a category (0 for root)
  int getDepth(String categoryId) {
    return getPathToRoot(categoryId).length - 1;
  }

  /// Find category by ID
  FileCategory? findById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search categories by name (case insensitive, partial match)
  List<FileCategory> searchByName(String query) {
    final lowerQuery = query.toLowerCase();
    return categories
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get categories of a specific type
  List<FileCategory> getCategoriesByType(CategoryType type) {
    return categories
        .where((c) => c.categoryType == type)
        .toList();
  }

  /// Get all user-created categories
  List<FileCategory> getUserCreatedCategories() {
    return categories
        .where((c) => c.isUserCreated)
        .toList();
  }

  /// Add a new category to the tree
  FileCategoryTree addCategory(FileCategory category) {
    return FileCategoryTree([...categories, category]);
  }

  /// Remove a category and all its descendants
  FileCategoryTree removeCategory(String categoryId) {
    final toRemove = <String>{categoryId};
    toRemove.addAll(getAllDescendants(categoryId).map((c) => c.id));
    
    final filteredCategories = categories
        .where((c) => !toRemove.contains(c.id))
        .toList();
    
    return FileCategoryTree(filteredCategories);
  }

  /// Move a category to a new parent
  FileCategoryTree moveCategory(String categoryId, String? newParentId) {
    final updatedCategories = categories.map((c) {
      if (c.id == categoryId) {
        return c.copyWith(parentCategoryId: newParentId);
      }
      return c;
    }).toList();
    
    return FileCategoryTree(updatedCategories);
  }

  /// Update an existing category
  FileCategoryTree updateCategory(FileCategory updatedCategory) {
    final updatedCategories = categories.map((c) {
      if (c.id == updatedCategory.id) {
        return updatedCategory;
      }
      return c;
    }).toList();
    
    return FileCategoryTree(updatedCategories);
  }

  @override
  List<Object?> get props => [categories];
}