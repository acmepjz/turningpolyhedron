#pragma once

#include <string>
#include <vector>

class SimpleMenu {
public:
	SimpleMenu();
	int MenuLoop() const;
public:
	std::string title;
	std::vector<std::string> item;
	int listIndex;
	
	int itemWidth, itemHeight;
	int minColumn;
	int fontSize;

	int defaultButton, cancelButton, closeButton;
};
