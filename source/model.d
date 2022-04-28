module model;

class ToDoItem {
	string text;
	int priority;
	bool checked;
	this(string text, int priority, bool checked) {
		this.text = text;
		this.priority = priority;
		this.checked = checked;
	}
}

interface ModelUpdateListener {
    void itemsUpdated(ToDoItem[] items);

    static ModelUpdateListener of(void delegate(ToDoItem[]) dg) {
        return new class ModelUpdateListener {
            void itemsUpdated(ToDoItem[] items) {
                dg(items);
            }
        };
    }
}

class ToDoModel {
    private ToDoItem[] items;
    private ModelUpdateListener[] listeners;

    void addListener(ModelUpdateListener listener) {
        listeners ~= listener;
    }

    void addItem(string text) {
        addItem(new ToDoItem(text, 1_000_000, false));
    }

    void addItem(ToDoItem item) {
        items ~= item;
        normalizePrio();
        notifyListeners();
    }

    void removeItem(int prio) {
        import std.algorithm;
        size_t idx = prio - 1; // Assume prio is normalized to start at 1.
        items = items.remove(idx);
        normalizePrio();
        notifyListeners();
    }

    bool canIncrement(ToDoItem item) {
        return item.priority > 1;
    }

    void incrementPriority(ToDoItem item) {
        size_t idx = item.priority - 1;
        if (idx == 0) return;
        ToDoItem higher = items[idx - 1];
        item.priority -= 1;
        higher.priority += 1;
        items[idx - 1] = item;
        items[idx] = higher;
        notifyListeners();
    }

    bool canDecrement(ToDoItem item) {
        return item.priority < items.length;
    }

    void decrementPriority(ToDoItem item) {
        size_t idx = item.priority - 1;
        if (idx + 1 >= items.length) return;
        ToDoItem lower = items[idx + 1];
        item.priority += 1;
        lower.priority -= 1;
        items[idx + 1] = item;
        items[idx] = lower;
        notifyListeners();
    }

    private void normalizePrio() {
        int prio = 1;
        foreach (item; items) {
            item.priority = prio++;
        }
    }

    private void notifyListeners() {
        foreach (l; listeners) l.itemsUpdated(this.items);
    }
}