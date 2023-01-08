package engine;

import engine.board.BoardManager;
import engine.events.InputController;
import imgui.ImGui;
import imgui.ImGuiViewport;
import imgui.ImVec2;
import imgui.flag.ImGuiInputTextFlags;
import imgui.flag.ImGuiWindowFlags;
import imgui.type.ImBoolean;
import imgui.type.ImString;

import java.util.Stack;

public class Main extends Window {
	public String version = "0.1.1";
	public Stack<SCENE> sceneStack;
	public ImGuiViewport mainViewport;
	private boolean showTextBoxName = false;
	private ImString newBoardName = new ImString();
	
	public enum SCENE {
		MAIN_MENU,
		BOARD_LIST,
		SETTINGS,
		IN_BOARD
	}
	
	public static void main(String[] args) {
		new Main().launch();
	}
	
	@Override
	protected void preRun() {
		BoardManager.addBoard("Test");
		BoardManager.addBoard("Lol");
		BoardManager.addBoard("DAVID!");
		
		sceneStack = new Stack<>();
		sceneStack.push(SCENE.MAIN_MENU);

//		Theme.printInverse();
	}
	
	@Override
	public void process() {
		mainViewport = ImGui.getMainViewport();
		ImGui.setNextWindowPos(mainViewport.getPosX(), mainViewport.getPosY());
		ImGui.setNextWindowSize(mainViewport.getSizeX(), mainViewport.getSizeY());
		
		switch (sceneStack.peek()) {
			case MAIN_MENU -> showMainMenu();
			case BOARD_LIST -> showBoardList();
			case SETTINGS -> showSettings();
			case IN_BOARD -> showBoard();
		}
		
		if (InputController.wasKeyPressed(KEY_ESCAPE) && sceneStack.size() > 0) {
			sceneStack.pop();
			if (sceneStack.isEmpty())
				sceneStack.push(SCENE.MAIN_MENU);
		}
	}
	
	// ==========================================[ Main Menu ]==========================================
	private void showMainMenu() {
		if (fullSizeWindow("Main Menu")) {
			// Title
			ImGui.pushFont(titleFont);
			ImGui.setCursorPos((mainViewport.getSizeX() / 2) - (ImGui.calcTextSize("L.C.S.").x / 2), 50);
			ImGui.text("L.C.S.");
			ImGui.popFont();
			
			// New Board
			ImGui.setCursorPos(100, 200);
			if (paddedButton("New Board", 15, 10))
				showTextBoxName = true;
			
			if (showTextBoxName) {
				ImGui.sameLine();
				ImGui.setNextItemWidth(300);
				if (ImGui.inputText("##newboardname", newBoardName, ImGuiInputTextFlags.EnterReturnsTrue) && !newBoardName.isEmpty()) {
					BoardManager.newBoard(newBoardName.get());
					newBoardName.clear();
					addScene(SCENE.IN_BOARD);
					showTextBoxName = false;
				}
				ImGui.sameLine();
				if (paddedButton("Create", 15, 10) && !newBoardName.isEmpty()) {
					BoardManager.newBoard(newBoardName.get());
					newBoardName.clear();
					addScene(SCENE.IN_BOARD);
					showTextBoxName = false;
				}
				ImGui.sameLine();
				if (paddedButton("Cancel", 15, 10)) {
					newBoardName.clear();
					showTextBoxName = false;
				}
			}
			
			// Open Board
			ImGui.setCursorPos(100, 250);
			if (paddedButton("Open Board", 15, 10))
				addScene(SCENE.BOARD_LIST);
			
			// Settings
			ImGui.setCursorPos(100, 300);
			if (paddedButton("Settings", 15, 10))
				addScene(SCENE.SETTINGS);
			
			// Quit
			ImGui.setCursorPos(100, 350);
			if (paddedButton("Quit", 15, 10))
				quit();
			
			// Version
			ImGui.setCursorPos(mainViewport.getSizeX() - 100, mainViewport.getSizeY() - 50);
			ImGui.text("V - " + version);
			
			ImGui.end();
		}
	}
	
	// ==========================================[ Board List ]==========================================
	private void showBoardList() {
		if (fullSizeWindow("Board List")) {
			ImGui.text("Boards:");
			if (ImGui.beginListBox("##Boards")) {
				for (int i = 0; i < BoardManager.getSize(); i++) {
					if (ImGui.selectable(BoardManager.get(i), false)) {
						addScene(SCENE.IN_BOARD);
						BoardManager.select(i);
					}
					ImGui.separator();
				}
				ImGui.endListBox();
			}
			ImGui.end();
		}
	}
	
	// ==========================================[ Settings ]==========================================
	private void showSettings() {
		if (fullSizeWindow("Board List")) {
			
			ImGui.text("Bright Mode: ");
			ImGui.sameLine();
			ImGui.checkbox("##brightmode", Settings.brightMode);
			ImGui.sameLine();
			ImGui.text("(F12)");
			
			ImGui.separator();
			ImGui.text("Full Screen:");
			ImGui.sameLine();
			ImGui.checkbox("##fullscreen", Settings.fullscreen);
			ImGui.sameLine();
			ImGui.text("(F11)");
			
			ImGui.separator();
			ImGui.text("V-Sync:");
			ImGui.sameLine();
			ImGui.checkbox("##vsync", Settings.vsync);
			
			ImGui.separator();
			ImGui.text("Resolution:");
			ImGui.sameLine();
			ImGui.setNextItemWidth(100);
			ImGui.inputInt("##resolution", Settings.resolution);
			
			ImGui.separator();
			ImGui.text("Font Size:");
			ImGui.sameLine();
			ImGui.setNextItemWidth(100);
			ImGui.inputInt("##fontsize", Settings.fontSize);
			ImGui.sameLine();
			ImGui.text("(Not Implemented Yet)");
			
			ImGui.setCursorPos(mainViewport.getSizeX() - 200, mainViewport.getSizeY() - 50);
			if (ImGui.button("Apply Settings"))
				updateSettings();
			
			ImGui.end();
		}
	}
	
	// ==========================================[ Board ]==========================================
	private void showBoard() {
		if (fullSizeWindow("In Board")) {
			BoardManager.drawBoard();
			ImGui.end();
		}
	}
	
	private void addScene(SCENE scene) {
		if (sceneStack.size() < 10)
			sceneStack.push(scene);
	}
	
	private boolean fullSizeWindow(final String title) {
		return ImGui.begin(title, new ImBoolean(true), ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoSavedSettings);
	}
	
	private boolean paddedButton(String label, int padX, int padY) {
		ImVec2 textSize = ImGui.calcTextSize(label);
		return ImGui.button(label, textSize.x + padX, textSize.y + padY);
	}
}
