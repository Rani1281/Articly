# Implementation Plan - Unit Tests for HomePageViewModel

Implement unit tests for `HomePageViewModel` in `test/presentation/website_displaying/view_models/home_page_view_model_test.dart` using `package:test`, `package:checks`, and `mocktail`.

## User Review Required

> [!IMPORTANT]
> I will be making several private methods in `HomePageViewModel` public to facilitate unit testing as requested. These include:
> - `loadData`
> - `sortItems`
> - `sortByCreationDate`
> - `sortByName`
> - `filterItems`

## Proposed Changes

### [Component Name]

#### [MODIFY] [home_page_view_model.dart](file:///C:/flutterApps/articly/lib/presentation/website_displaying/view_models/home_page_view_model.dart)
- Make private methods public: `loadData`, `sortItems`, `sortByCreationDate`, `sortByName`, `filterItems`.
- Add `@visibleForTesting` annotation if appropriate (though user asked to make them public "for now"). I'll stick to making them public as requested.

#### [MODIFY] [home_page_view_model_test.dart](file:///C:/flutterApps/articly/test/presentation/website_displaying/view_models/home_page_view_model_test.dart)
- Implement all test cases in the skeleton.
- Use `mocktail` to mock `SavedItemsProvider` and `SharedPreferencesService`.
- Use `package:checks` for assertions.

## Verification Plan

### Automated Tests
- Run the implemented unit tests using `flutter test test/presentation/website_displaying/view_models/home_page_view_model_test.dart`.
