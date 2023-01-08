package engine;

import imgui.ImVec2;

public class Bounds {
	public int x, y, w, h;
	
	public Bounds(int x, int y, int w, int h) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}
	
	public Bounds() {
		this.x = this.y = 0;
		this.w = this.h = 0;
	}
	
	public void moveBy(ImVec2 offset) {
		this.x += offset.x;
		this.y += offset.y;
	}
	
	public void moveTo(ImVec2 pos) {
		this.x = (int) pos.x;
		this.y = (int) pos.y;
	}
	
	public void set(ImVec2 pos) {
		this.x = (int) pos.x;
		this.y = (int) pos.y;
	}
	
	public final ImVec2 pos() {
		return new ImVec2(x, y);
	}
	
	public final ImVec2 size() {
		return new ImVec2(w, h);
	}
}
