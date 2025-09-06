import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/file_storage/domain/entities/file_category.dart';

void main() {
  group('FileCategory', () {
    final testCategory = FileCategory(
      id: 'cat_123',
      name: 'Documents',
      description: 'Business documents and files',
      color: '#3498db',
      icon: 'document',
      createdBy: 'user_123',
      createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      isSystem: false,
      parentCategoryId: 'cat_parent',
    );

    group('constructor', () {
      test('should create FileCategory with all required properties', () {
        expect(testCategory.id, equals('cat_123'));
        expect(testCategory.name, equals('Documents'));
        expect(testCategory.description, equals('Business documents and files'));
        expect(testCategory.color, equals('#3498db'));
        expect(testCategory.icon, equals('document'));
        expect(testCategory.createdBy, equals('user_123'));
        expect(testCategory.createdAt, equals(DateTime.parse('2024-01-15T10:30:00Z')));
        expect(testCategory.isSystem, isFalse);
        expect(testCategory.parentCategoryId, equals('cat_parent'));
      });

      test('should create FileCategory with default values', () {
        final minimalCategory = FileCategory(
          id: 'cat_456',
          name: 'Photos',
          createdBy: 'user_456',
          createdAt: DateTime.parse('2024-01-16T11:00:00Z'),
        );

        expect(minimalCategory.description, isNull);
        expect(minimalCategory.color, equals('#666666')); // Default gray color
        expect(minimalCategory.icon, equals('folder')); // Default icon
        expect(minimalCategory.isSystem, isFalse);
        expect(minimalCategory.parentCategoryId, isNull);
      });

      test('should create system FileCategory', () {
        final systemCategory = FileCategory(
          id: 'sys_123',
          name: 'System Files',
          createdBy: 'system',
          createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
          isSystem: true,
        );

        expect(systemCategory.isSystem, isTrue);
        expect(systemCategory.isUserCreated, isFalse);
      });
    });

    group('CategoryType enum', () {
      test('should convert from string value', () {
        expect(CategoryType.fromString('documents'), equals(CategoryType.documents));
        expect(CategoryType.fromString('images'), equals(CategoryType.images));
        expect(CategoryType.fromString('videos'), equals(CategoryType.videos));
        expect(CategoryType.fromString('audio'), equals(CategoryType.audio));
        expect(CategoryType.fromString('archives'), equals(CategoryType.archives));
        expect(CategoryType.fromString('custom'), equals(CategoryType.custom));
        expect(CategoryType.fromString('invalid'), equals(CategoryType.custom));
      });

      test('should have default colors for each type', () {
        expect(CategoryType.documents.defaultColor, equals('#2196F3'));
        expect(CategoryType.images.defaultColor, equals('#4CAF50'));
        expect(CategoryType.videos.defaultColor, equals('#FF9800'));
        expect(CategoryType.audio.defaultColor, equals('#9C27B0'));
        expect(CategoryType.archives.defaultColor, equals('#795548'));
        expect(CategoryType.custom.defaultColor, equals('#666666'));
      });

      test('should have default icons for each type', () {
        expect(CategoryType.documents.defaultIcon, equals('document-text'));
        expect(CategoryType.images.defaultIcon, equals('image'));
        expect(CategoryType.videos.defaultIcon, equals('play-circle'));
        expect(CategoryType.audio.defaultIcon, equals('musical-notes'));
        expect(CategoryType.archives.defaultIcon, equals('archive'));
        expect(CategoryType.custom.defaultIcon, equals('folder'));
      });
    });

    group('computed properties', () {
      test('should determine category type from name', () {
        final docCategory = testCategory.copyWith(name: 'Documents');
        expect(docCategory.categoryType, equals(CategoryType.documents));

        final imageCategory = testCategory.copyWith(name: 'Pictures');
        expect(imageCategory.categoryType, equals(CategoryType.images));

        final videoCategory = testCategory.copyWith(name: 'Videos');
        expect(videoCategory.categoryType, equals(CategoryType.videos));

        final audioCategory = testCategory.copyWith(name: 'Music');
        expect(audioCategory.categoryType, equals(CategoryType.audio));

        final archiveCategory = testCategory.copyWith(name: 'Archives');
        expect(archiveCategory.categoryType, equals(CategoryType.archives));

        final customCategory = testCategory.copyWith(name: 'Custom Category');
        expect(customCategory.categoryType, equals(CategoryType.custom));
      });

      test('should check if category is user created', () {
        expect(testCategory.isUserCreated, isTrue);

        final systemCategory = testCategory.copyWith(isSystem: true);
        expect(systemCategory.isUserCreated, isFalse);
      });

      test('should check if category is root level', () {
        expect(testCategory.isRootLevel, isFalse);

        final rootCategory = testCategory.copyWith(clearParent: true);
        expect(rootCategory.isRootLevel, isTrue);
      });

      test('should get display color', () {
        // Should use custom color if provided
        expect(testCategory.displayColor, equals('#3498db'));

        // Should use default color for category type if no custom color
        final categoryNoColor = testCategory.copyWith(color: '#666666');
        expect(categoryNoColor.displayColor, equals(CategoryType.documents.defaultColor));
      });

      test('should get display icon', () {
        // Should use custom icon if provided
        expect(testCategory.displayIcon, equals('document'));

        // Should use default icon for category type if no custom icon
        final categoryNoIcon = testCategory.copyWith(icon: 'folder');
        expect(categoryNoIcon.displayIcon, equals(CategoryType.documents.defaultIcon));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedCategory = testCategory.copyWith(
          name: 'Updated Documents',
          color: '#e74c3c',
        );

        expect(updatedCategory.id, equals(testCategory.id));
        expect(updatedCategory.name, equals('Updated Documents'));
        expect(updatedCategory.color, equals('#e74c3c'));
        expect(updatedCategory.description, equals(testCategory.description));
      });

      test('should preserve original values when no updates provided', () {
        final copiedCategory = testCategory.copyWith();

        expect(copiedCategory, equals(testCategory));
        expect(copiedCategory.hashCode, equals(testCategory.hashCode));
      });

      test('should handle clearing parent category', () {
        final rootCategory = testCategory.copyWith(clearParent: true);

        expect(rootCategory.parentCategoryId, isNull);
        expect(rootCategory.isRootLevel, isTrue);
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final otherCategory = FileCategory(
          id: 'cat_123',
          name: 'Documents',
          description: 'Business documents and files',
          color: '#3498db',
          icon: 'document',
          createdBy: 'user_123',
          createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
          isSystem: false,
          parentCategoryId: 'cat_parent',
        );

        expect(testCategory, equals(otherCategory));
        expect(testCategory.hashCode, equals(otherCategory.hashCode));
      });

      test('should not be equal when properties differ', () {
        final differentCategory = testCategory.copyWith(name: 'Different Name');

        expect(testCategory, isNot(equals(differentCategory)));
        expect(testCategory.hashCode, isNot(equals(differentCategory.hashCode)));
      });
    });
  });

  group('FileCategoryTree', () {
    final rootCategories = [
      FileCategory(
        id: 'root_1',
        name: 'Documents',
        createdBy: 'admin',
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      ),
      FileCategory(
        id: 'root_2',
        name: 'Media',
        createdBy: 'admin',
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      ),
    ];

    final subCategories = [
      FileCategory(
        id: 'sub_1',
        name: 'Business Docs',
        parentCategoryId: 'root_1',
        createdBy: 'admin',
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      ),
      FileCategory(
        id: 'sub_2',
        name: 'Personal Docs',
        parentCategoryId: 'root_1',
        createdBy: 'admin',
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      ),
      FileCategory(
        id: 'sub_3',
        name: 'Images',
        parentCategoryId: 'root_2',
        createdBy: 'admin',
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      ),
    ];

    final deepCategory = FileCategory(
      id: 'deep_1',
      name: 'Contracts',
      parentCategoryId: 'sub_1',
      createdBy: 'admin',
      createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
    );

    final allCategories = [...rootCategories, ...subCategories, deepCategory];
    final categoryTree = FileCategoryTree(allCategories);

    group('constructor', () {
      test('should create FileCategoryTree with list of categories', () {
        expect(categoryTree.categories.length, equals(6));
      });
    });

    group('tree operations', () {
      test('should get root categories', () {
        final roots = categoryTree.rootCategories;
        expect(roots.length, equals(2));
        expect(roots.map((c) => c.id), containsAll(['root_1', 'root_2']));
      });

      test('should get children of specific category', () {
        final docChildren = categoryTree.getChildren('root_1');
        expect(docChildren.length, equals(2));
        expect(docChildren.map((c) => c.id), containsAll(['sub_1', 'sub_2']));

        final businessChildren = categoryTree.getChildren('sub_1');
        expect(businessChildren.length, equals(1));
        expect(businessChildren.first.id, equals('deep_1'));
      });

      test('should get all descendants of a category', () {
        final allDescendants = categoryTree.getAllDescendants('root_1');
        expect(allDescendants.length, equals(3)); // sub_1, sub_2, deep_1
        expect(allDescendants.map((c) => c.id), containsAll(['sub_1', 'sub_2', 'deep_1']));
      });

      test('should get parent of a category', () {
        final parent = categoryTree.getParent('sub_1');
        expect(parent, isNotNull);
        expect(parent!.id, equals('root_1'));

        final noParent = categoryTree.getParent('root_1');
        expect(noParent, isNull);
      });

      test('should get path to root', () {
        final path = categoryTree.getPathToRoot('deep_1');
        expect(path.length, equals(3));
        expect(path.map((c) => c.id), equals(['deep_1', 'sub_1', 'root_1']));

        final rootPath = categoryTree.getPathToRoot('root_1');
        expect(rootPath.length, equals(1));
        expect(rootPath.first.id, equals('root_1'));
      });

      test('should check if category is ancestor of another', () {
        expect(categoryTree.isAncestor('root_1', 'deep_1'), isTrue);
        expect(categoryTree.isAncestor('sub_1', 'deep_1'), isTrue);
        expect(categoryTree.isAncestor('root_2', 'deep_1'), isFalse);
        expect(categoryTree.isAncestor('deep_1', 'root_1'), isFalse);
      });

      test('should get depth of a category', () {
        expect(categoryTree.getDepth('root_1'), equals(0));
        expect(categoryTree.getDepth('sub_1'), equals(1));
        expect(categoryTree.getDepth('deep_1'), equals(2));
      });
    });

    group('tree manipulation', () {
      test('should add new category', () {
        final newCategory = FileCategory(
          id: 'new_cat',
          name: 'New Category',
          parentCategoryId: 'root_1',
          createdBy: 'user',
          createdAt: DateTime.now(),
        );

        final updatedTree = categoryTree.addCategory(newCategory);
        expect(updatedTree.categories.length, equals(7));
        expect(updatedTree.getChildren('root_1').length, equals(3));
      });

      test('should remove category and its descendants', () {
        final updatedTree = categoryTree.removeCategory('sub_1');
        expect(updatedTree.categories.length, equals(4)); // Removes sub_1 and deep_1
        expect(updatedTree.getChildren('root_1').length, equals(1));
        expect(updatedTree.findById('deep_1'), isNull);
      });

      test('should move category to new parent', () {
        final updatedTree = categoryTree.moveCategory('sub_2', 'root_2');
        final movedCategory = updatedTree.findById('sub_2');
        expect(movedCategory?.parentCategoryId, equals('root_2'));
        expect(updatedTree.getChildren('root_1').length, equals(1));
        expect(updatedTree.getChildren('root_2').length, equals(2));
      });

      test('should update category', () {
        final updatedCategory = subCategories.first.copyWith(
          name: 'Updated Business Docs',
          color: '#ff0000',
        );

        final updatedTree = categoryTree.updateCategory(updatedCategory);
        final found = updatedTree.findById('sub_1');
        expect(found?.name, equals('Updated Business Docs'));
        expect(found?.color, equals('#ff0000'));
      });
    });

    group('search and filtering', () {
      test('should find category by ID', () {
        final found = categoryTree.findById('sub_1');
        expect(found, isNotNull);
        expect(found!.name, equals('Business Docs'));

        final notFound = categoryTree.findById('nonexistent');
        expect(notFound, isNull);
      });

      test('should search categories by name', () {
        final results = categoryTree.searchByName('docs');
        expect(results.length, equals(2)); // Business Docs, Personal Docs
        expect(results.map((c) => c.id), containsAll(['sub_1', 'sub_2']));
      });

      test('should filter categories by type', () {
        // Add some typed categories
        final imageCategory = FileCategory(
          id: 'img_cat',
          name: 'Photos',
          createdBy: 'user',
          createdAt: DateTime.now(),
        );

        final treeWithImages = categoryTree.addCategory(imageCategory);
        final imageCategories = treeWithImages.getCategoriesByType(CategoryType.images);
        expect(imageCategories.length, greaterThan(0));
      });

      test('should get user created categories', () {
        final userCategories = categoryTree.getUserCreatedCategories();
        expect(userCategories.length, equals(6)); // All test categories are user-created
        expect(userCategories.every((c) => c.isUserCreated), isTrue);
      });
    });
  });
}