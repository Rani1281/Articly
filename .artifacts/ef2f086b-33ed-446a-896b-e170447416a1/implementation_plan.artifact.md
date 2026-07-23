# Fix redundant "Deleted successfully" snackbar

The user is experiencing a bug where the "Deleted the item successfully!" snackbar appears whenever they interact with the tool bar in `SavedWebpageCard`, even when they are not deleting anything.

## Problem Analysis

The root cause is a combination of shared state and over-broad logic in `SavedWebpageCard`:

1.  **Shared Command State**: `SavedItemViewModel.deleteItemCommand` pulls from `SavedItemsProvider.deleteCommand`. This is a single, shared instance in the provider.
2.  **State Persistence**: Once an item is deleted, `deleteCommand.completed` remains `true` for the rest of the app session (until another deletion starts).
3.  **Trigger-Happy Listener**: `SavedWebpageCard` adds a listener `_checkDeletion` to its `SavedItemViewModel`.
4.  **Interaction Trigger**: Clicking the tool bar (e.g., to expand/collapse) calls `viewModel.toggleExpand()`, which calls `notifyListeners()`.
5.  **Faulty Condition**: `_checkDeletion` runs whenever the view model notifies. It checks `if (cmd.completed && !showedSuccessMessage)`. Since `cmd.completed` is true from a previous deletion and `showedSuccessMessage` is initialized to `false` for every new card instance (or before the first interaction), the snackbar shows up.

## Proposed Changes

### [Component] Website Displaying

#### [MODIFY] [saved_item_card.dart](file:///C:/flutterApps/articly/lib/presentation/website_displaying/widgets/saved_item_card.dart)

- Add a private boolean `_isDeleting` to `_SavedWebpageCardState` to track if a deletion was actually initiated by this specific card instance.
- Update the "Delete" button's `onPressed` to set `_isDeleting = true`.
- Modify `_checkDeletion` to only show the snackbar if `_isDeleting` is `true`.
- Implement `didUpdateWidget` to correctly update the listener if the `viewModel` instance changes (important because `HomePage` creates a new `SavedItemViewModel` on every rebuild).

## Verification Plan

### Manual Verification
- Run the app and delete an item. Verify the "Deleted the item successfully!" snackbar appears.
- Click on the tool bar (expand/collapse) of another item. Verify the snackbar **does not** appear.
- Perform various interactions (edit, copy) and ensure no unexpected snackbars show up.
