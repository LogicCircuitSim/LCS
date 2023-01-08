package engine.board;

import engine.canvas.Canvas;
import imgui.ImGui;

public class Board {
	private String name;
	private Canvas canvas;
	
	public Board(String name) {
		this.name = name;
		this.canvas = new Canvas();
	}
	
	public String getName() {
		return this.name;
	}
	
	public void draw() {
		ImGui.text(String.format("Board Name: %s", this.name));
		canvas.draw();
	}
}
