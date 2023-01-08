package engine.canvas;

import engine.KeyList;
import engine.components.AND;
import engine.components.BoardObject;
import engine.components.Component;
import engine.components.Gate;
import engine.events.InputController;
import imgui.*;
import imgui.flag.ImGuiButtonFlags;
import imgui.flag.ImGuiCol;
import imgui.flag.ImGuiMouseButton;
import imgui.flag.ImGuiPopupFlags;

import java.util.ArrayList;

public class Canvas {
	private final ImVec2 scrolling;
	private ArrayList<Gate> gates;
	private Gate draggedGate;
	
	public Canvas() {
		this.scrolling = new ImVec2();
		this.gates = new ArrayList<>();
		this.gates.add(new AND(200, 200));
	}
	
	public void draw() {
		ImGui.sameLine();
		ImGui.text(String.format("Offset: %4.1f | %4.1f", scrolling.x, scrolling.y));
		
		// Using InvisibleButton() as a convenience 1) it will advance the layout cursor and 2) allows us to use IsItemHovered()/IsItemActive()
		ImVec2 canvasStartPos = ImGui.getCursorScreenPos();    // ImDrawList API uses screen coordinates!
		ImVec2 canvasSize = ImGui.getContentRegionAvail();     // Resize canvas to what's available
		ImVec2 canvasEndPos = new ImVec2(canvasStartPos.x + canvasSize.x, canvasStartPos.y + canvasSize.y);
		BoardObject.setCanvasBounds(canvasStartPos, canvasSize);
		
		// Draw border and background color
		ImGuiIO io = ImGui.getIO();
		ImDrawList drawList = ImGui.getWindowDrawList();
		// This will catch our interactions
		ImGui.invisibleButton("canvas", canvasSize.x, canvasSize.y, ImGuiButtonFlags.MouseButtonLeft | ImGuiButtonFlags.MouseButtonRight | ImGuiButtonFlags.MouseButtonMiddle);
		boolean canvasIsHovered = ImGui.isItemHovered(); // Hovered
		boolean canvasIsHeld = ImGui.isItemActive();     // Held
		ImVec2 origin = new ImVec2(canvasStartPos.x + scrolling.x, canvasStartPos.y + scrolling.y); // Lock scrolled origin
		ImVec2 mousePosInCanvas = new ImVec2(io.getMousePos().x - origin.x, io.getMousePos().y - origin.y);
		
		// Add first and second point
		/*if (isHovered && !addingLine && ImGui.isMouseClicked(ImGuiMouseButton.Left)) {
			pointList.add(mousePosInCanvas);
			pointList.add(mousePosInCanvas);
			addingLine = true;
		}
		if (addingLine) {
			pointList.set(pointList.size() - 1, mousePosInCanvas);
			if (!ImGui.isMouseDown(ImGuiMouseButton.Left)) {
				addingLine = false;
			}
		}*/
		
		// Pan (we use a zero mouse threshold when there's no context menu)
		// You may decide to make that threshold dynamic based on whether the mouse is hovering something etc.
		if (canvasIsHeld && ImGui.isMouseDragging(ImGuiMouseButton.Middle, -1.0f)) {
			scrolling.x += io.getMouseDelta().x;
			scrolling.y += io.getMouseDelta().y;
		}
		BoardObject.setOffset(scrolling);
		
		if (InputController.wasKeyPressed(KeyList.KEY_C))
			scrolling.x = scrolling.y = 0;

//		if (ImGui.isMouseClicked(ImGuiMouseButton.Right))
		ImGui.openPopupOnItemClick("context", ImGuiPopupFlags.MouseButtonRight);
		
		drawList.pushClipRect(canvasStartPos.x, canvasStartPos.y, canvasEndPos.x, canvasEndPos.y, false);
		drawList.addRectFilled(canvasStartPos.x, canvasStartPos.y, canvasEndPos.x, canvasEndPos.y,
				ImColor.rgba(ImGui.getStyle().getColor(ImGuiCol.ChildBg)));
		
		float GRID_STEP = 64.0f;
		for (float x = fmodf(scrolling.x, GRID_STEP); x < canvasSize.x; x += GRID_STEP)
			drawList.addLine(canvasStartPos.x + x, canvasStartPos.y, canvasStartPos.x + x, canvasEndPos.y,
					ImColor.rgba(ImGui.getStyle().getColor(ImGuiCol.PopupBg)));
		for (float y = fmodf(scrolling.y, GRID_STEP); y < canvasSize.y; y += GRID_STEP)
			drawList.addLine(canvasStartPos.x, canvasStartPos.y + y, canvasEndPos.x, canvasStartPos.y + y,
					ImColor.rgba(ImGui.getStyle().getColor(ImGuiCol.PopupBg)));
		
		// TODO: Component Drawing here
		
		for (Gate gate : gates) {
			if (ImGui.isMouseHoveringRect(gate.bounds.x, gate.bounds.y, gate.bounds.w, gate.bounds.h)) {
				
				if (ImGui.isMouseDown(ImGuiMouseButton.Left) && draggedGate == null)
					draggedGate = gate;
				if (!ImGui.isMouseDown(ImGuiMouseButton.Left))
					draggedGate = null;
				
				if (ImGui.isMouseDragging(ImGuiMouseButton.Left, -1f) && draggedGate != null)
					gate.moveBy(io.getMouseDelta());
				
			}
			
			gate.show();
		}
		
		drawList.addRect(canvasStartPos.x, canvasStartPos.y, canvasEndPos.x, canvasEndPos.y,
				ImColor.rgba(ImGui.getStyle().getColor(ImGuiCol.Text)));
		drawList.popClipRect();
		
		
		if (ImGui.beginPopup("context")) {
			if (ImGui.menuItem("Add AND", "A", false, true)) {
				gates.add(new AND(mousePosInCanvas));
				ImGui.closeCurrentPopup();
			}
			if (ImGui.menuItem("Remove last", "", false, gates.size() > 0)) {
				gates.remove(gates.size() - 1);
				ImGui.closeCurrentPopup();
			}
			if (ImGui.menuItem("Remove all", "", false, gates.size() > 0)) {
				gates.clear();
				ImGui.closeCurrentPopup();
			}
			ImGui.endPopup();
		}
	}
	
	private float fmodf(float a, float b) {
		int result = (int) Math.floor(a / b);
		return a - result * b;
	}
}
