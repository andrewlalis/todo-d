import model;
import std.stdio;

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
        
        Button removeButton = new Button(StockID.REMOVE);
        removeButton.addOnClicked(delegate(Button b) {
			todoModel.removeItem(item.priority);
        });
		this.packEnd(removeButton, false, false, 0);

		if (todoModel.canIncrement(item)) {
			Button upButton = new Button(StockID.GO_UP, delegate(Button b) {
				todoModel.incrementPriority(item);
			});
			this.packEnd(upButton, false, false, 0);
		}
		if (todoModel.canDecrement(item)) {
			Button downButton = new Button(StockID.GO_DOWN, delegate(Button b) {
				todoModel.decrementPriority(item);
			});
			this.packEnd(downButton, false, false, 0);
		}
        
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
	taskEntry = cast(Entry) builder.getObject("addTaskEntry");

	todoModel = new ToDoModel();
	import std.functional : toDelegate;
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
		row.add(widget);
		taskList.add(row);
	}
	taskList.showAll();
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
