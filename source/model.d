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
    private string openFilename = null;

    void addListener(ModelUpdateListener listener) {
        listeners ~= listener;
    }

    string getOpenFilename() {
        return openFilename;
    }

    ToDoItem getItemAt(int prio) {
        if (prio < 1 || prio > items.length) return null;
        return items[prio - 1];
    }

    ulong itemCount() {
        return items.length;
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

    void openFromJson(string filename) {
        import std.json;
        import std.file;
        import std.algorithm;
        JSONValue j = parseJSON(readText(filename));
        JSONValue[] itemsArray = j["items"].array();
        items = [];
        foreach (JSONValue itemObj; itemsArray) {
            ToDoItem item = new ToDoItem(
                itemObj["text"].str,
                itemObj["priority"].get!int,
                itemObj["checked"].boolean
            );
            items ~= item;
        }
        openFilename = filename;
        sort!((a, b) => a.priority < b.priority)(items);
        normalizePrio();
        notifyListeners();
    }

    void saveToJson(string filename) {
        import std.json;
        import std.file;
        JSONValue j = JSONValue();
        JSONValue[] itemObjs;
        foreach (item; items) {
            JSONValue itemObj = JSONValue();
            itemObj["text"] = JSONValue(item.text);
            itemObj["priority"] = JSONValue(item.priority);
            itemObj["checked"] = JSONValue(item.checked);
            itemObjs ~= itemObj;
        }
        j["items"] = JSONValue(itemObjs);
        write(filename, toJSON(j, true));
        openFilename = filename;
    }

    void clear() {
        items = [];
        openFilename = null;
        notifyListeners();
    }

    private void normalizePrio() {
        int prio = 1;
        foreach (item; items) {
            item.priority = prio++;
        }
    }

    public void notifyListeners() {
        foreach (l; listeners) l.itemsUpdated(this.items);
    }
}