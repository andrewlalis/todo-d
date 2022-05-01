import model;

import std.stdio;
import std.functional : toDelegate;

import gtk.MainWindow;
import gtk.Main;
import gtk.Builder;
import gtk.Application;
import gtk.ApplicationWindow;
import gtk.Entry;
import gtk.Box;
import gtk.ListBox;
import gtk.ListBoxRow;
import gtk.Label;
import gtk.CheckButton;
import gtk.ToggleButton;
import gtk.Button;
import gtk.Widget;

import gdk.Keymap;
import gdk.Keysyms : GdkKeysyms;
import gio.Resource;
import glib.Bytes;

class ToDoItemWidget : Box {
    this(ToDoItem item, ToDoModel todoModel) {
        super(GtkOrientation.HORIZONTAL, 5);
        CheckButton button = new CheckButton();
        button.setActive(item.checked);
        button.addOnToggled(delegate(ToggleButton b) {
			item.checked = b.getActive();
		});
        Label label = new Label(item.text);
        label.setLineWrap(true);
        label.setHalign(GtkAlign.START);
        label.setValign(GtkAlign.CENTER);
        this.packStart(button, false, false, 0);
        this.packEnd(label, true, true, 0);
    }
}

Entry taskEntry;
ListBox taskList;
ApplicationWindow window;

ToDoModel todoModel;

void main(string[] args) {
	Main.init(args);

	auto bytes = new Bytes(cast(ubyte[]) import("resources.gresource"));
	Resource.register(new Resource(bytes));

	Builder builder = new Builder();
	builder.addFromResource("/ui/todo-ui.glade");
	
	builder.addCallbackSymbol("onAddTask", &addTask);
	builder.addCallbackSymbol("onWindowDestroy", &onWindowDestroy);

	builder.addCallbackSymbol("onNewMenuActivated", &onNewMenuActivated);
	builder.addCallbackSymbol("onSaveMenuActivated", &onSaveMenuActivated);
	builder.addCallbackSymbol("onSaveAsMenuActivated", &onSaveAsMenuActivated);
	builder.addCallbackSymbol("onOpenMenuActivated", &onOpenMenuActivated);
	builder.addCallbackSymbol("onQuitMenuActivated", &onWindowDestroy);
	builder.connectSignals(null);

	taskList = cast(ListBox) builder.getObject("taskList");
	Widget listWidget = cast(Widget) taskList;
	listWidget.addOnKeyPress(toDelegate(&taskListKeyPressed));
	taskEntry = cast(Entry) builder.getObject("addTaskEntry");

	todoModel = new ToDoModel();
	todoModel.addListener(ModelUpdateListener.of(toDelegate(&itemsUpdated)));

	window = cast(ApplicationWindow) builder.getObject("window");
	window.showAll();
	Main.run();
}

void itemsUpdated(ToDoItem[] items) {
	taskList.removeAll();
	foreach (item; items) {
		auto widget = new ToDoItemWidget(item, todoModel);
		auto row = new ListBoxRow();
		row.setSelectable(true);
		row.setActivatable(false);
		row.add(widget);
		taskList.add(row);
	}
	taskList.showAll();
}

bool taskListKeyPressed(GdkEventKey* event, Widget w) {
	int idx = taskList.getSelectedRow().getIndex();
	int selectedPrio = idx + 1;
	ToDoItem selectedItem = todoModel.getItemAt(selectedPrio);
	if (selectedItem is null) return true;
	bool ctrlDown = (event.state & ModifierType.CONTROL_MASK) > 0;
	if (ctrlDown && event.keyval == GdkKeysyms.GDK_Up && todoModel.canIncrement(selectedItem)) {
		todoModel.incrementPriority(selectedItem);
		auto row = taskList.getRowAtIndex(idx - 1);
		taskList.selectRow(row);
		Widget rowWidget = cast(Widget) row;
		rowWidget.grabFocus();
	}
	if (ctrlDown && event.keyval == GdkKeysyms.GDK_Down && todoModel.canDecrement(selectedItem)) {
		todoModel.decrementPriority(selectedItem);
		auto row = taskList.getRowAtIndex(idx + 1);
		taskList.selectRow(row);
		Widget rowWidget = cast(Widget) row;
		rowWidget.grabFocus();
	}
	if (!ctrlDown && event.keyval == GdkKeysyms.GDK_Up && idx > 0) {
		auto row = taskList.getRowAtIndex(idx - 1);
		taskList.selectRow(row);
		Widget rowWidget = cast(Widget) row;
		rowWidget.grabFocus();
	}
	if (!ctrlDown && event.keyval == GdkKeysyms.GDK_Down && idx + 1 < todoModel.itemCount) {
		auto row = taskList.getRowAtIndex(idx + 1);
		taskList.selectRow(row);
		Widget rowWidget = cast(Widget) row;
		rowWidget.grabFocus();
	}
	if (event.keyval == GdkKeysyms.GDK_Delete) {
		todoModel.removeItem(selectedPrio);
	}
	if (event.keyval == GdkKeysyms.GDK_Return) {
		selectedItem.checked = !selectedItem.checked;
		todoModel.notifyListeners();
		auto row = taskList.getRowAtIndex(idx);
		taskList.selectRow(row);
		Widget rowWidget = cast(Widget) row;
		rowWidget.grabFocus();
	}
	return true;
}

extern (C) void addTask() {
	todoModel.addItem(taskEntry.getText());
	taskEntry.setText("");
}

extern (C) void onWindowDestroy() {
	Main.quit();
	if (todoModel.getOpenFilename() !is null) {
		todoModel.saveToJson(todoModel.getOpenFilename());
	}
}

extern (C) void onNewMenuActivated() {
	todoModel.clear();
}

extern (C) void onSaveMenuActivated() {
	if (todoModel.getOpenFilename() is null) {
		onSaveAsMenuActivated();
	} else {
		todoModel.saveToJson(todoModel.getOpenFilename());
	}
}

extern (C) void onSaveAsMenuActivated() {
	import gtk.FileChooserDialog;
	auto dialog = new FileChooserDialog(
		"Save As",
		window,
		FileChooserAction.SAVE
	);
	if (todoModel.getOpenFilename() !is null) {
		dialog.setFilename(todoModel.getOpenFilename());
	}
	int result = dialog.run();
	if (result == -5) {
		todoModel.saveToJson(dialog.getFilename());
	}
	dialog.close();
}

extern (C) void onOpenMenuActivated() {
	import gtk.FileChooserDialog;
	auto dialog = new FileChooserDialog(
		"Open",
		window,
		FileChooserAction.OPEN
	);
	int result = dialog.run();
	if (result == -5) {
		todoModel.openFromJson(dialog.getFilename());
	}
	dialog.close();
}
