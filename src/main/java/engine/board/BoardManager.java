package engine.board;

import java.util.ArrayList;

public class BoardManager {
	private static ArrayList<Board> boardList = new ArrayList<>();
	private static int selectedIndex = -1;
	
	public static void newBoard(final String name) {
		addBoard(name);
		select(getSize() - 1);
	}
	
	public static void addBoard(final String name) {
		boardList.add(new Board(name));
	}
	
	public static int getSize() {
		return boardList.size();
	}
	
	public static String get(int i) {
		return boardList.get(i).getName();
	}
	
	public static void select(int i) {
		selectedIndex = i;
	}
	
	public static void drawBoard() {
		boardList.get(selectedIndex).draw();
	}
}
