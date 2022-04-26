module view;

import model;

import gtk.Box;
import gtk.ListBox;
import gtk.ListBoxRow;
import gtk.Label;
import gtk.CheckButton;
import gtk.Window;
import gtk.ScrolledWindow;
import gtk.Entry;
import gtk.Button;

// Yes, I use global items for my application.

ListBox todoList;
Entry todoEntry;

ToDoItem[] items = [];

void setupUI(Window w) {
    todoList = new ListBox();
    todoEntry = new Entry();

	auto vbox = new Box(GtkOrientation.VERTICAL, 5);

    todoList.setSelectionMode(GtkSelectionMode.NONE);

	vbox.packStart(new ScrolledWindow(todoList), true, true, 5);

    auto addBox = new Box(GtkOrientation.HORIZONTAL, 5);
    addBox.packStart(todoEntry, true, true, 0);
    Button addButton = new Button("Add");
    addButton.addOnClicked(delegate(Button b) {addItem();});
    addBox.packEnd(addButton, false, false, 0);
    vbox.packEnd(addBox, false, false, 0);

	w.add(vbox);
}

void addItem() {
    import std.algorithm;
    import std.string;
    string text = todoEntry.getText().strip;
    if (text.length == 0) return;
    int maxPrio = -1_000_000;
    foreach (item; items) {
        maxPrio = max(maxPrio, item.priority);
    }
    ToDoItem newItem = ToDoItem(text, maxPrio + 1);
    items ~= newItem;
    todoEntry.setText("");
    normalizePriorities();
    refreshList();
}

void normalizePriorities() {
    int prio = 1;
    foreach (item; items) {
        item.priority = prio++;
    }
}

void removeItem(int prio) {
    import std.algorithm;
    import std.array;
    ToDoItem[] newItems = items.filter!(item => item.priority != prio).array;
    items = newItems;
    normalizePriorities();
    refreshList();
}

void refreshList() {
    todoList.removeAll();
    foreach (item; items) {
        auto widget = new ToDoItemWidget(item);
        auto row = new ListBoxRow();
        row.add(widget);
		todoList.add(row);
	}
    todoList.showAll();
}

class ToDoItemWidget : Box {
    private ToDoItem item;

    this(ToDoItem item) {
        super(GtkOrientation.HORIZONTAL, 5);
        this.item = item;
        CheckButton button = new CheckButton();
        Label label = new Label(item.text);
        label.setLineWrap(true);
        label.setHalign(GtkAlign.START);
        label.setValign(GtkAlign.CENTER);
        this.packStart(button, false, false, 0);
        
        Button removeButton = new Button("Remove");
        removeButton.addOnClicked(delegate(Button b) {
            removeItem(item.priority);
        });
        this.packEnd(removeButton, false, false, 0);
        this.packEnd(label, true, true, 0);
    }
}