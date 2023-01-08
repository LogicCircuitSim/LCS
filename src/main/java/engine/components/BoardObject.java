package engine.components;

import engine.Bounds;
import imgui.ImColor;
import imgui.ImGui;
import imgui.ImVec2;
import imgui.flag.ImGuiCol;

public class BoardObject {
	public static Bounds canvasBounds = new Bounds();
	
	public static void setCanvasBounds(ImVec2 start, ImVec2 size) {
		canvasBounds = new Bounds((int) start.x, (int) start.y, (int) size.x, (int) size.y);
	}
	
	public static void setOffset(ImVec2 offset) {
		canvasBounds.moveTo(offset);
	}
	
	public Bounds bounds;
	
	public void drawRect(int x_, int y_, int width_, int height_) {
		float x = x_ + canvasBounds.x;
		float y = y_ + canvasBounds.y;
		float w = x_ + width_ + canvasBounds.x;
		float h = y_ + height_ + canvasBounds.y;
		ImGui.getWindowDrawList().addRectFilled(x, y, w, h,
				ImColor.rgba(.2f, .2f, .2f, 1), 5);
		ImGui.getWindowDrawList().addRect(x, y, w, h,
				ImColor.rgba(ImGui.getStyle().getColor(ImGuiCol.Text)), 5);
	}
	
	public void drawRect(Bounds b) {
		drawRect(b.x, b.y, b.w, b.h);
	}
	
	public void drawMe() {
		drawRect(this.bounds);
	}
	
	public void moveTo(ImVec2 pos) {
		this.bounds.moveTo(pos);
	}
	public void moveBy(ImVec2 pos) {
		this.bounds.moveBy(pos);
	}
	
}
