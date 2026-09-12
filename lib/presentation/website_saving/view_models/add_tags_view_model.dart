import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:flutter/material.dart';

class AddTagsViewModel extends ChangeNotifier {
  AddTagsViewModel({
    required this.provider,
    List<String>? initialSelectedTagIds,
  }) : _selectedTagIds = List.from(initialSelectedTagIds ?? []) {
    provider.addListener(_onProviderChanged);
  }

  final UserProvider provider;
  final List<String> _selectedTagIds;
  String _searchQuery = '';

  List<String> get selectedTagIds => List.unmodifiable(_selectedTagIds);
  String get searchQuery => _searchQuery;

  bool isTagSelected(String tagId) => _selectedTagIds.contains(tagId);

  void toggleTag(String tagId) {
    if (_selectedTagIds.contains(tagId)) {
      _selectedTagIds.remove(tagId);
    } else {
      _selectedTagIds.add(tagId);
    }
    notifyListeners();
  }

  void selectTag(String tagId) {
    if (!_selectedTagIds.contains(tagId)) {
      _selectedTagIds.add(tagId);
      notifyListeners();
    }
  }

  void unselectTag(String tagId) {
    if (_selectedTagIds.remove(tagId)) {
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearchQuery() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Returns all tags from [provider] sorted alphabetically by name (case-insensitive).
  List<Tag> get sortedTags {
    final tags = provider.tags.values.toList();
    tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return tags;
  }

  /// Returns tags filtered by the normalized search query, sorted alphabetically.
  List<Tag> get filteredTags {
    final tags = sortedTags;
    final trimmed = _searchQuery.trim();
    if (trimmed.isEmpty) {
      return tags;
    }

    final normalizedQuery = Tag.normalize(trimmed);
    final lowerQuery = trimmed.toLowerCase();

    return tags.where((tag) {
      return tag.normalizeName().contains(normalizedQuery) ||
          tag.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  void _onProviderChanged() {
    // Retain existing tag selections, removing any that no longer exist
    _selectedTagIds.removeWhere((id) => !provider.tags.containsKey(id));
    notifyListeners();
  }

  @override
  void dispose() {
    provider.removeListener(_onProviderChanged);
    super.dispose();
  }
}
