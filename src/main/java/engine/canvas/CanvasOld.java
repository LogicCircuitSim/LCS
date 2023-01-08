package engine.canvas;

import engine.KeyList;
import engine.events.InputController;
import imgui.*;
import imgui.flag.ImGuiButtonFlags;
import imgui.flag.ImGuiCol;
import imgui.flag.ImGuiMouseButton;
import imgui.flag.ImGuiPopupFlags;

public class CanvasOld {
	private final ImVec2 scrolling = new ImVec2();
	
	public CanvasOld() {
	}
	
	public void draw() {
		ImGui.text(String.format("Offset: %4.1f | %4.1f", scrolling.x, scrolling.y));
		
		// Using InvisibleButton() as a convenience 1) it will advance the layout cursor and 2) allows us to use IsItemHovered()/IsItemActive()
		ImVec2 canvasStartPos = ImGui.getCursorScreenPos();      // ImDrawList API uses screen coordinates!
		ImVec2 canvasSize = ImGui.getContentRegionAvail();         // Resize canvas to what's available
		ImVec2 canvasEndPos = new ImVec2(canvasStartPos.x + canvasSize.x, canvasStartPos.y + canvasSize.y);
		
		// Draw border and background color
		ImGuiIO io = ImGui.getIO();
		ImDrawList drawList = ImGui.getWindowDrawList();
		// This will catch our interactions
		ImGui.invisibleButton("canvas", canvasSize.x, canvasSize.y,ImGuiButtonFlags.MouseButtonLeft | ImGuiButtonFlags.MouseButtonRight);
		boolean isHovered = ImGui.isItemHovered(); // Hovered
		boolean isActive = ImGui.isItemActive();   // Held
		ImVec2 origin = new ImVec2(canvasStartPos.x + scrolling.x, canvasStartPos.y + scrolling.y); // Lock scrolled origin
		ImVec2 mousePosInCanvas = new ImVec2(io.getMousePos().x - origin.x, io.getMousePos().y - origin.y);
		
		// Add first and second point
//			if (isHovered && !addingLine && ImGui.isMouseClicked(ImGuiMouseButton.Left)) {
//				pointList.add(mousePosInCanvas);
//				pointList.add(mousePosInCanvas);
//				addingLine = true;
//			}
//			if (addingLine) {
//				pointList.set(pointList.size() - 1, mousePosInCanvas);
//				if (!ImGui.isMouseDown(ImGuiMouseButton.Left)) {
//					addingLine = false;
//				}
//			}
		
		// Pan (we use a zero mouse threshold when there's no context menu)
		// You may decide to make that threshold dynamic based on whether the mouse is hovering something etc.
		float mouseThresholdForPan = -1.0f;
		if (isActive && ImGui.isMouseDragging(ImGuiMouseButton.Right, mouseThresholdForPan)) {
			scrolling.x += io.getMouseDelta().x;
			scrolling.y += io.getMouseDelta().y;
		}
		
		if (InputController.wasKeyPressed(KeyList.KEY_C)) {
			scrolling.x = scrolling.y = 0;
		}
		
		// Context menu (under default mouse threshold)
		ImVec2 dragDelta = ImGui.getMouseDragDelta(ImGuiMouseButton.Right);
		if (dragDelta.x == 0.0f && dragDelta.y == 0.0f) {
			ImGui.openPopupOnItemClick("context", ImGuiPopupFlags.MouseButtonRight);
		}
		
		// Draw grid + all lines in the canvas
		drawList.pushClipRect(canvasStartPos.x, canvasStartPos.y, canvasEndPos.x, canvasEndPos.y, false);
		float GRID_STEP = 64.0f;
		for (float x = fmodf(scrolling.x, GRID_STEP); x < canvasSize.x; x += GRID_STEP)
			drawList.addLine(canvasStartPos.x + x, canvasStartPos.y, canvasStartPos.x + x, canvasEndPos.y,
					ImColor.rgba(ImGui.getStyle().getColor(ImGuiCol.PopupBg)));
		for (float y = fmodf(scrolling.y, GRID_STEP); y < canvasSize.y; y += GRID_STEP)
			drawList.addLine(canvasStartPos.x, canvasStartPos.y + y, canvasEndPos.x, canvasStartPos.y + y,
					ImColor.rgba(ImGui.getStyle().getColor(ImGuiCol.PopupBg)));
				
		drawList.addRectFilled(canvasStartPos.x, canvasStartPos.y, canvasEndPos.x, canvasEndPos.y,
				ImColor.rgba(ImGui.getStyle().getColor(ImGuiCol.ChildBg)));
		drawList.addRect(canvasStartPos.x, canvasStartPos.y, canvasEndPos.x, canvasEndPos.y,
				ImColor.rgba(ImGui.getStyle().getColor(ImGuiCol.Text)));
		
		drawList.popClipRect();
		
		// Menu properties
//			if (ImGui.beginPopup("context")) {
//				if (ImGui.menuItem("Remove one", "", false, pointList.size() > 0)) {
//					pointList.remove(pointList.size() - 1);
//					pointList.remove(pointList.size() - 1);
//				}
//				if (ImGui.menuItem("Remove all", "", false, pointList.size() > 0)) {
//					pointList.clear();
//				}
//				ImGui.endPopup();
//			}
	}
	
	private float fmodf(float a, float b) {
		int result = (int) Math.floor(a / b);
		return a - result * b;
	}
}
