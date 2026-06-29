# Items Editing - Testing Plan:

Please write a unit/widget test files in dart to test the functionality of the following files while following the appropriate testing rules as described in the directory @.cursor\rules\testing/.

--- 

`saved_item_test.dart` - changes:
- change to include the attribute *id*

- `toFirestore(...)`:
	- if isEdit is false, always include *createAt* key in the map which its value is a FieldValue.serverTimestamp().

- `fromFirestore(...)`:
	- the *id* of the retured SavedItem is snapshot.id

---

`saved_items_repository_test.dart` - changes:
- `updateItem(...)`:
	- throws an exception "The user is not authenticated..." if the current user is null.
	- throws an exception "Can't proceed to updating the item..." if the item's id is null.

---

`saved_items_provider_test.dart` - changes:
- `edit(...)`:
	- initializes the edit commands fields correctly (running = true, error = null, completed = false), and notifies listeners.
	- calls _repo.updateItem()
	- if successful, changes the value of the map that corresponds to the id of the item. and finalizes the edit commands' fields correctly (running = false, error = null, completed = true) and notifies listeners.
	- if fails, does not change the items map and sets the edit commands' fields correctly (running = false, error = "Something went wrong. Please try again later", completed = false) and notifies listeners.

---

`saved_item_view_model_test.dart` - changes:
- correctly builds the SavedItemViewModel object by a SavedItem object (title, uri and notes equal to those of the passed currentItem)
- currentItem setter not only sets the currentItem, but also title, uri, and notes a new value based on it, and notifies listeners.


--- 

`saved_item_card_test.dart` - new:
- card builds correctly from a passed item:
- has title if non null, has the uri host if not null or empty, the right reading status.
- allow the expand the card from the bottom to see notes if they are not null or empty.
- clicking on the edit button leads to SaveWebpageScreen.
- displays new values after receiving a new item from SaveWebpageScreen.

---

`save_webpage_view_model_test.dart` - maybe change:
- delete *remindMe* tests.

--- 

`save_webpage_screen_test.dart` - changes:
- when given a SavedItem and isEdit = true, the fields of the page are prepopulated correctly: title, url, reading status, notes, remind me. If some of these values are null in the passed item, they will simply not be prepopulated.
- error snack bar (MySnackBar) show both on saving and editing errors.
- shows a loading spinner both on saving and editing events.
- returns the new created item when Navigator.pop() after saving completed.


After creating the tests, run them, and they fails because of a problem regarding themselves, fix them, but if it fails because of a problem withing the codebase itself so that it doesn't satisfy the conditions of the test, tell be about the problem, what causes it, and suggest a fix. Write the test under \test.
