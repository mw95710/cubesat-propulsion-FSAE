//
//  Connect4.cpp
//
//
//  Created by Michael Wang on 12/26/16.
//
//

#include "Connect4.hpp"

using namespace std;
using std::setw;

// enum state
enum State {won, lost, interim, draw};
State st = interim;

// AI struct
struct AI {
    std::vector<int> choices;
    std::vector<int> ranking;
};

// Node struct for Tree Search
// root Node has NULL for parent
// leaf node has NULL for children
struct Node {
    int value = 0;  // heuristic value| won: value = 1; lost: value = -1; draw: value = 0;
    int column;                   // column number
    Node* parent = NULL;          // parent Node
    std::vector<Node*> children;  // array of children Nodes
};

std::vector<int> coords(2); // vector storing coordinates of location

// function declarations
void             printGrid(std::vector<std::vector<int> >& grid);
std::vector<int> drop(std::vector<std::vector<int> >& grid, int choice, int col);
State            check(std::vector<std::vector<int> >& grid, int row, int col);
void             twoPlayerMode(std::vector<std::vector<int> >& grid);
void             computerMode(std::vector<std::vector<int> >& grid, std::function<int(std::vector<std::vector<int> >&)> computer);
int              randomizer(std::vector<std::vector<int> >& grid);
int              bruteForce(std::vector<std::vector<int> >& grid);
int              MonteCarloTreeSearch(std::vector<std::vector<int> >& grid1);
void             destroyTree(Node* n); //
Node*            addNode(Node* parent, int col); //
Node*            mcts(std::vector<std::vector<int> >& grid, Node* root); //
void             backPropagate(Node* leaf, int leafvalue); //
std::vector<int> determineComputerChoice(std::vector<std::vector<int> >& grid);



int main() {
    srand(time(NULL)); // initialize pseudorandom seed
    
    // user defined board grid
    int rows, columns;
    cout << "Please enter the number of rows for the board (usually 6): ";
    cin >> rows;
    cin.ignore();
    cout << "Please enter the number of columns for the board (usually 7): ";
    cin >> columns;
    cin.ignore();
    
    // initialize the grid with blanks
    // blanks = 2; 'o' = 0; 'x' = 1;
    // x's go first
    typedef std::vector< std::vector<int> > matrix;
    matrix grid(rows, std::vector<int>(columns));
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
            grid[i][j] = 2;
        }
    }
    
    // let the user pick the mode of the game
    int choice;
    cout << "Please choose the mode for the game." << endl;
    cout << "Enter 1 for Randomizer Mode" << endl;
    cout << "Enter 2 for Brute Force Mode" << endl;
    cout << "Enter 3 for Monte Carlo Tree Search Mode" << endl;
    cout << "Enter 4 for Two-Player Mode: ";
    cin >> choice;
    cin.ignore();
    switch(choice) {
        case 1 :
            computerMode(grid, randomizer);
            break;
        case 2 :
            computerMode(grid, bruteForce);
            break;
        case 3 :
            computerMode(grid, MonteCarloTreeSearch);
            break;
        case 4 :
            twoPlayerMode(grid);
            break;
    }
    
    return 0;
}

// this function displays the current grid on the terminal
void printGrid(std::vector<std::vector<int> >& grid) {
    int columns = grid[0].size();
    int rows = grid.size();
    int count = 1;
    
    cout << endl;
    for (int i = 0; i < rows; i++) {
        cout << count ;
        count++;
        for (int j = 0; j < columns; j++) {
            int state = grid[i][j];
            cout << setw(2);
            
            switch(state) {
                case 0 :
                    cout << 'o';
                    break;
                case 1 :
                    cout << 'x';
                    break;
                case 2 :
                    cout << ' ';
                    break;
            }
        }
        cout << endl;
    }
    
    cout << ' ';
    for (int i = 1; i < columns + 1; i++) {
        cout << setw(2) << i;
    }
    cout << '\n' << endl;
}

// this function drops the 'x' or 'o' down the specified column in the grid
// returns error message if there is no space and ask for user
// 'o': choice = 0; 'x': choice = 1;
// col starts counting from 1
std::vector<int> drop(std::vector<std::vector<int> >& grid, int c, int column) {
    int choice = c;
    int col = column;
    int columns = grid[0].size();
    int rows = grid.size();
    int check = 0;
    std::vector<int> coord(2); // coordinate of the final placement
    
    while (check < 3) {
        check = 0;
        // check for bounds on choice
        if (choice != 0 && choice != 1) {
            check = 0;
            cout << "Warning. Please choose 0 for 'o' and 1 for 'x': ";
            cin >> choice;
            cin.ignore();
        } else {
            check++;
        }
        
        // check for bounds on col
        if (col < 1 || col > columns) {
            check = 0;
            cout << "Warning. Please choose between " << 1 << " and " << columns << " for column number: ";
            cin >> col;
            cin.ignore();
        } else {
            check++;
        }
        
        // check if that column has already filled up
        if (grid[0][col-1] != 2) {
            check = 0;
            cout << "Warning. The chosen column is filled up. Please choose another column: ";
            cin >> col;
            cin.ignore();
        } else {
            check++;
        }
    }
    
    for (int i = 0; i < rows; i++) {
        if (grid[i][col-1] != 2) {
            grid[i-1][col-1] = choice;
            coord[0] = i-1;
            coord[1] = col-1;
            return coord;
        }
    }
    grid[rows-1][col-1] = choice;
    coord[0] = rows-1;
    coord[1] = col-1;
    return coord;
}

// this function checks if the most recent move results in a win, lost, interim, and draw.
// returns the state of the grid
// r and c starts at 0
State check(std::vector<std::vector<int> >& grid, int r, int c) {
    int columns = grid[0].size();
    int rows = grid.size();
    int choice = grid[r][c];
    int count = 0;
    int minimum = min(r,c);
    int maximum = max(r,c);
    
    // checks entire row
    for (int i = 0; i < columns; i++) {
        if (grid[r][i] == choice) {
            count++;
        } else {
            count = 0;
        }
        
        if (count == 4) {
            return won;
        }
    }
    
    // checks entire column
    count = 0;
    for (int i = 0; i < rows; i++) {
        if (grid[i][c] == choice) {
            count++;
        } else {
            count = 0;
        }
        
        if (count == 4) {
            return won;
        }
    }
    
    // checks negative diagonal
    count = 0;
    int i = 0;
    while ((r-minimum+i) <= (rows-1) && (c-minimum+i) <= (columns-1)) {
        if (grid[r-minimum+i][c-minimum+i] == choice) {
            count++;
        } else {
            count = 0;
        }
        
        if (count == 4) {
            return won;
        }
        i++;
    }
    
    // checks positive diagonal
    count = 0;
    i = 0;
    while ((r+min(c,rows-1-r)-i) >= 0 && (c-min(c,rows-1-r)+i) <= (columns-1)) {
        if (grid[r+min(c,rows-1-r)-i][c-min(c,rows-1-r)+i] == choice) {
            count++;
        } else {
            count = 0;
        }
        
        if (count == 4) {
            return won;
        }
        i++;
    }
    
    return interim;
}

// this function implements the two player mode
void twoPlayerMode(std::vector<std::vector<int> >& grid) {
    int choice;
    int otherChoice;
    int count = 0;
    int move;
    int drawChecker;
    bool xo = true;
    while (xo) {
        cout << "Please choose 1 for x or 0 for o. x will go first: ";
        cin >> choice;
        cin.ignore(); xo = false;
        if (choice != 0 && choice != 1) {
            xo = true;
        }
    }
    
    if (choice == 1) {
        otherChoice = 0;
    } else {
        otherChoice = 1;
    }
    
    printGrid(grid);
    
    while (st == interim) {
        // check for draw
        drawChecker = 0;
        for (int i = 0; i < grid[0].size(); i++) {
            if (grid[0][i] != 2) drawChecker++;
        }
        if (drawChecker == grid[0].size()) {st = draw; break;}
        
        if (count == 0 && choice == 0) {
            // user 2 turn
            cout << "Player 2 please choose your next move: ";
            cin >> move;
            cin.ignore();
            coords = drop(grid, otherChoice, move);
            printGrid(grid);
            st = check(grid, coords[0], coords[1]);
            if (st != interim) {st = lost; break;}
            count++;
        }
        
        // user 1 turn
        cout << "Player 1 please choose your next move: ";
        cin >> move;
        cin.ignore();
        coords = drop(grid, choice, move);
        printGrid(grid);
        st = check(grid, coords[0], coords[1]);
        if (st != interim) {break;}
        // check for draw
        drawChecker = 0;
        for (int i = 0; i < grid[0].size(); i++) {
            if (grid[0][i] != 2) drawChecker++;
        }
        if (drawChecker == grid[0].size()) {st = draw; break;}
        
        // user 2 turn
        cout << "Player 2 please choose your next move: ";
        cin >> move;
        cin.ignore();
        coords = drop(grid, otherChoice, move);
        printGrid(grid);
        st = check(grid, coords[0], coords[1]);
        if (st != interim) {st = lost; break;}
    }
    
    switch(st) {
        case won :
            cout << "Player 1 Won!!!" << '\n' << endl;
            break;
        case lost :
            cout << "Player 2 Won!!!" << '\n' << endl;
            break;
        case draw :
            cout << "Draw." << '\n' << endl;
            break;
        case interim :
            break;
    }
}

// this function generates a random move
int randomizer(std::vector<std::vector<int> >& grid) {
    int randomIndex;
    std::vector<int> randomChoices;
    // available random choices
    for (int i = 0; i < grid[0].size(); i++) {
        if (grid[0][i] == 2) {randomChoices.push_back(i+1);}
    }
    randomIndex = rand()%(randomChoices.size());
    return randomChoices[randomIndex];
}

// this function implements the brute force mode
// hard code pinrciples to narrow down choices, randomly chooses the remaining choices
int bruteForce(std::vector<std::vector<int> >& grid1) {
    std::vector<std::vector<int> > grid = grid1;
    int index;
    State st;
    // available choices
    struct AI AI_Info;
    AI_Info.choices.clear();
    AI_Info.ranking.clear();
    for (int i = 0; i < grid[0].size(); i++) {
        if (grid[0][i] == 2) {
            AI_Info.choices.push_back(i+1);
            AI_Info.ranking.push_back(1);
        }
    }
    
    std::vector<int> choices(2);
    int humanChoice, computerChoice;
    choices = determineComputerChoice(grid);
    computerChoice = choices[0];
    humanChoice = choices[1];
    
    
    // brute force algorithm
    for (int i = 0; i < AI_Info.choices.size(); i++) {
        /*
        if (grid[1][AI_Info.choices[i] ] == 2) {
            // check if this computer move sets up the human player for a win
            coords = drop(grid, computerChoice, AI_Info.choices[i]);
            grid[coords[0]][coords[1] ] = 2; // reset grid to blank
            grid[coords[0]-1][coords[1] ] = humanChoice; // set human move
            st = check(grid, coords[0]-1, coords[1]);
            grid[coords[0]-1][coords[1] ] = 2; // reset grid to blank
            if (st == won) {
                AI_Info.ranking[i] = 0;
            }
        }
        */
        
        // check winning moves for human
        coords = drop(grid, humanChoice, AI_Info.choices[i]);
        st = check(grid, coords[0], coords[1]);
        grid[coords[0]][coords[1]] = 2; // reset grid to blank
        if (st == won) {
            AI_Info.ranking[i] = std::numeric_limits<int>::max() - 1;
        }
        
        // check winning moves for computer (one move ahead)
        coords = drop(grid, computerChoice, AI_Info.choices[i]);
        st = check(grid, coords[0], coords[1]);
        grid[coords[0]][coords[1]] = 2; // reset grid to blank
        if (st == won) {
            AI_Info.ranking[i] = std::numeric_limits<int>::max();
        }
    }
    
    // narrow down choices vector by maximizing the ranking vector (getting rid of smaller rankings)
    int max = *max_element(AI_Info.ranking.begin(), AI_Info.ranking.end());
    for (int i = AI_Info.choices.size()-1; i >= 0; i--) {
        if (AI_Info.ranking[i] < max) {
            AI_Info.choices.erase(AI_Info.choices.begin()+i);
            AI_Info.ranking.erase(AI_Info.ranking.begin()+i);
        }
    }
    
    // choices vector is narrowed down at this point
    // randomly chooses from the choices vector
    index = rand()%(AI_Info.choices.size());
    return AI_Info.choices[index];
}

// this function implements a computer mode against the player
void computerMode(std::vector<std::vector<int> >& grid1, std::function<int(std::vector<std::vector<int> >&)> computer) {
    std::vector<std::vector<int> > grid = grid1;
    int choice;
    int otherChoice;
    int count = 0;
    int move;
    int drawChecker;
    bool xo = true;
    while (xo) {
        cout << "Please choose 1 for x or 0 for o. x will go first: ";
        cin >> choice;
        cin.ignore(); xo = false;
        if (choice != 0 && choice != 1) {
            xo = true;
        }
    }
    
    if (choice == 1) {
        otherChoice = 0;
    } else {
        otherChoice = 1;
    }
    
    printGrid(grid);
    
    while (st == interim) {
        // check for draw
        drawChecker = 0;
        for (int i = 0; i < grid[0].size(); i++) {
            if (grid[0][i] != 2) drawChecker++;
        }
        if (drawChecker == grid[0].size()) {st = draw; break;}
        
        if (count == 0 && choice == 1) {
            // user turn
            cout << "Please choose your next move: ";
            cin >> move;
            cin.ignore();
            coords = drop(grid, choice, move);
            printGrid(grid);
            st = check(grid, coords[0], coords[1]);
            if (st != interim) {break;}
            count++;
        }
        
        // computer turn
        coords = drop(grid, otherChoice, computer(grid));
        printGrid(grid);
        st = check(grid, coords[0], coords[1]);
        if (st != interim) {st = lost; break;}
        // check for draw
        drawChecker = 0;
        for (int i = 0; i < grid[0].size(); i++) {
            if (grid[0][i] != 2) drawChecker++;
        }
        if (drawChecker == grid[0].size()) {st = draw; break;}
        
        // user turn
        cout << "Please choose your next move: ";
        cin >> move;
        cin.ignore();
        coords = drop(grid, choice, move);
        printGrid(grid);
        st = check(grid, coords[0], coords[1]);
    }
    
    switch(st) {
        case won :
            cout << "You Won!!!" << '\n' << endl;
            break;
        case lost :
            cout << "Game Over. You Lost." << '\n' << endl;
            break;
        case draw :
            cout << "Draw." << '\n' << endl;
            break;
        case interim :
            break;
    }
}

// this function implements Monte Carlo Tree Search during runtime against human player
// able to specify the time allotted for search
// use latin hypercube sampling vs. Monte Carlo sampling
////////// MCTS becomes better (game tree is more explored) as the game progresses (in progress)////////////
// returns the column number with the highest heuristic value
int MonteCarloTreeSearch(std::vector<std::vector<int> >& grid) {
    const unsigned long int BRANCHES = 50000; // number of branches of searching (Monte Carlo sample size)
    std::vector<std::vector<int> > grid1 = grid;
    std::vector<std::vector<int> > tempgrid = grid;
    int index;
    int max;
    int rows = grid.size();
    int columns = grid[0].size();
    std::vector<Node*> leaves;
    std::vector<int> c;
    int col;
    State st = interim;
    int choice;
    Node* tempchild;
    
    std::vector<int> choices(2);
    int humanChoice, computerChoice;
    choices = determineComputerChoice(grid1);
    computerChoice = choices[0];
    humanChoice = choices[1];
    
    
    // available choices
    struct AI info;
    info.choices.clear();
    info.ranking.clear();
    for (int i = 0; i < grid1[0].size(); i++) {
        if (grid1[0][i] == 2) {
            info.choices.push_back(i+1);   // stores currently avaiable choices
            info.ranking.push_back(0);     // stores the MCTS heuristic values for the respective choices
        }
    }
    
    leaves.clear();
    for (int j = 0; j < info.choices.size(); j++) {
        leaves.push_back(new Node);
        leaves[j]->column = info.choices[j];
        // Monte Carlo Tree Search Algorithm
        for (int i = 0; i < BRANCHES; i++) {
            tempchild = mcts(grid1, leaves[j]);
            backPropagate(tempchild, tempchild->value);
        }
    }
    
    // brute force algorithm
    for (int i = 0; i < info.choices.size(); i++) {
        // check winning moves for human
        c = drop(tempgrid, humanChoice, info.choices[i]);
        st = check(tempgrid, c[0], c[1]);
        tempgrid[c[0]][c[1]] = 2; // reset grid to blank
        c.clear();
        if (st == won) {
            for (int i = 0; i < leaves.size(); i++) {
                // delete the entire tree
                destroyTree(leaves[i]);
            }
            return info.choices[i];
        }
        st = interim;
    }
    
    cout << "Monte Carlo Tree Search Mode: " << endl;
    cout << "Heuristics: |";
    for (int i = 0; i < leaves.size(); i++) {
        cout << leaves[i]->value << '|';
    }
    cout << endl;
    cout << "Column Numbers: |";
    for (int i = 0; i < leaves.size(); i++) {
        cout << leaves[i]->column << '|';
    }
    cout << endl;
    
    // the column number of the highest heuristic value will be chosen (leads to higher probability of winning)
    max = std::numeric_limits<int>::min(); // initialize max
    for (int i = 0; i < leaves.size(); i++) {
        if (leaves[i]->value > max) {
            max = leaves[i]->value;
            index = i;
        }
    }
    
    choice = leaves[index]->column;
    
    for (int i = 0; i < leaves.size(); i++) {
        // delete the entire tree
        destroyTree(leaves[i]);
    }
    
    return choice;
}

// this function recursively deletes the entire tree from memory
// argument is the root of the tree to be deleted
void destroyTree(Node* n) {
    if (n->children.size() != 0) {
        for (int i = 0; i < n->children.size(); i++) {
            destroyTree(n->children[i]);
        }
    }
    delete n;
}

// this function adds a children node to the parent node
// this returns the child address
// if child node of the specified column already exists, that child node will be returned
Node* addNode(Node* parent, int col) {
    for (int i = 0; i < parent->children.size(); i++) {
        if (parent->children[i]->column == col) {return parent->children[i];}
    }
    
    //std::unique_ptr<Node> child(new Node);
    Node* child = new Node;
    child->column = col;
    child->parent = parent;
    parent->children.push_back(child);
    return child;
}

// this function uses the Monte Carlo Tree Search Method to construct a branch from the root node to an end leaf node
// returns the address of the end leaf node
// assigns the appropriate heuristic value to the end leaf node
// won: value = 1; lost: value = -1; draw: value = 0;
Node* mcts(std::vector<std::vector<int> >& grid, Node* root) {
    State st = interim;
    Node* tempRoot = root;
    Node* tempChild;
    std::vector<std::vector<int> > currentGrid = grid;
    std::vector<int> coords(2);
    struct AI AI_Info;
    int index;
    int columns = currentGrid[0].size();
    int rows = currentGrid.size();
    int drawChecker;
    int col;
    
    std::vector<int> choices(2);
    int humanChoice, computerChoice;
    choices = determineComputerChoice(currentGrid);
    computerChoice = choices[0];
    humanChoice = choices[1];

    while(st == interim) {
        // check for draw
        drawChecker = 0;
        for (int i = 0; i < currentGrid[0].size(); i++) {
            if (currentGrid[0][i] != 2) drawChecker++;
        }
        if (drawChecker == currentGrid[0].size()) {st = draw; break;}
        
        // computer's choice
        AI_Info.choices.clear();
        for (int i = 0; i < currentGrid[0].size(); i++) {
            if (currentGrid[0][i] == 2) {
                AI_Info.choices.push_back(i+1);
            }
        }
        index = rand()%(AI_Info.choices.size());
        // drop the choice
        col = AI_Info.choices[index];
        for (int i = 0; i < rows; i++) {
            if (currentGrid[i][col-1] != 2) {
                currentGrid[i-1][col-1] = computerChoice;
                coords[0] = i-1;
                coords[1] = col-1;
            } else if (i == rows-1) {
                currentGrid[i][col-1] = computerChoice;
                coords[0] = i;
                coords[1] = col-1;
            }
        }
        tempChild = addNode(tempRoot , AI_Info.choices[index]);
        tempRoot = tempChild;
        st = check(currentGrid, coords[0], coords[1]);
        if (st != interim) { st = won; break;}
        // check for draw
        drawChecker = 0;
        for (int i = 0; i < currentGrid[0].size(); i++) {
            if (currentGrid[0][i] != 2) drawChecker++;
        }
        if (drawChecker == currentGrid[0].size()) {st = draw; break;}
        
        // human's choice
        AI_Info.choices.clear();
        for (int i = 0; i < currentGrid[0].size(); i++) {
            if (currentGrid[0][i] == 2) {
                AI_Info.choices.push_back(i+1);
            }
        }
        index = rand()%(AI_Info.choices.size());
        // drop the choice
        col = AI_Info.choices[index];
        for (int i = 0; i < rows; i++) {
            if (currentGrid[i][col-1] != 2) {
                currentGrid[i-1][col-1] = humanChoice;
                coords[0] = i-1;
                coords[1] = col-1;
            } else if (i == rows-1) {
                currentGrid[i][col-1] = humanChoice;
                coords[0] = i;
                coords[1] = col-1;
            }
        }
        tempChild = addNode(tempRoot , AI_Info.choices[index]);
        tempRoot = tempChild;
        st = check(currentGrid, coords[0], coords[1]);
        if (st != interim) { st = lost; break;}
    }
    
    //////////////////check if we have been to this particular leaf before //////////////////
    switch(st) {
        case won :
            tempChild->value = 1;
            break;
        case lost :
            tempChild->value = -1;
            break;
        case draw :
            tempChild->value = 0;
            break;
        case interim :
            break;
    }
    
    return tempChild;
}

// this function recursively back-propagates the leaf node's heuristic value throughout the tree
void backPropagate(Node* leaf, int leafvalue) {
    int l = leafvalue;
    if (leaf->parent != NULL) {
        switch(l) {
            case 1 :
                leaf->parent->value++;
                break;
            case -1 :
                leaf->parent->value--;
                break;
        }
        backPropagate(leaf->parent, l);
    }
}

// determines the computer's choice and human's choice based on current grid
// the next move is the computer's move
// choices = [computerChoice, humanChoice]
std::vector<int> determineComputerChoice(std::vector<std::vector<int> >& grid) {
    int computerChoice = 0;    // 'o': choice = 0; 'x': choice = 1;
    int humanChoice = 1;       // the choice of the human player
    int xcount = 0;
    int ocount = 0;
    std::vector<int> choices(2);
    
    // determine the computer's symbol from the current grid
    // the computer is x if for the current grid, x's = o's
    // the computer is o if for the current grid, x's > o's
    for (int i = 0; i < grid.size(); i++) {
        for (int j = 0; j < grid[0].size(); j++) {
            if (grid[i][j] == 0) {
                ocount++;
            } else if (grid[i][j] == 1) {
                xcount++;
            }
        }
    }
    if (xcount == ocount) {
        computerChoice = 1;
        humanChoice = 0;
    }
    
    choices[0] = computerChoice;
    choices[1] = humanChoice;
    
    return choices;
}

