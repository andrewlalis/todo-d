import std.stdio;

import model;
import view : setupUI;

import gtk.MainWindow;
import gtk.Main;

void main(string[] args) {
	Main.init(args);
	MainWindow window = new MainWindow("To-Do");
	window.setDefaultSize(300, 500);
	setupUI(window);
	window.showAll();
	Main.run();
}
