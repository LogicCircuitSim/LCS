package engine.components;

import engine.Bounds;
import imgui.ImVec2;

public class AND extends Gate {
	
	public AND(int x, int y) {
		this.bounds = new Bounds(x, y, 100, 70);
	}
	
	public AND(ImVec2 pos) {
		this.bounds = new Bounds((int) pos.x, (int) pos.y, 100, 70);
	}
	
	public void show() {
		drawMe();
	}
	
}
