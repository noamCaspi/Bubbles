import processing.serial.*; //<>// //<>// //<>//
import processing.sound.*;
import java.util.Iterator;
import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;
import javax.swing.JFrame;

int tomove = 350;
float inByte = 0;
float bmpVal;
float bmpInit = -1;

float FWradius = 0;
float FWspeed = 1;
float FWx, FWy;

float settingsX, settingsY, soundX, soundY, infoX, infoY, newGameX, newGameY, playAgainX, playAgainY, exitX, exitY;

float duration = -1;
int power = -1;
int wellDone = 0;
int drawFW = 0;
int FWColor;

int x = 40;           // X position
int y = 80;           // Y position
int columns = 15;     // Number of tile columns
int rows = 14;        // Number of tile rows
int tilewidth = 40;   // Visual width of a tile
int rowheight = 40;   // Height of a row
int radius = 20;      // Bubble collision radius
int width1 = 0;
int height1 = 0;      // Height, gets calculated

// Number of different colors
int bubblecolors = 2;

// Game states
int init = 0;
int ready = 1;
int shootbubble = 2;
int removecluster = 3;
int gameover = 4;
int win = 5;

int gamestate = init;

int turncounter = 0;
int rowoffset = 0;
int animationstate = 0;

int[] wellDoneColor = {0, 0, 0};


int[][][] neighborsoffsets = {{{1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {-1, -1}, {0, -1}},
  {{1, 0}, {1, 1}, {0, 1}, {-1, 0}, {0, -1}, {1, -1}}};

int[][] colors = {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 153, 255}, {255, 255, 255}};
String[] successMsgs = {"Well Done!", "  Great!  ", "Good Job!", "Excellent!"};
String successMsg;
String audioName = "music.wav";
String WDsound = "wellDone.wav";

boolean showcluster = false;
boolean firstRowShifted = false;
boolean settings = true;
boolean instructions = false;
boolean sound = true;

ArrayList<Tile> cluster = new ArrayList<Tile>();
ArrayList<ArrayList<Tile>> floatingclusters = new ArrayList<ArrayList<Tile>>();

SoundFile file, WDfile, winFile;

HScrollbar hs1, hs2, hs3;
float scrolly = 0.015;

Button ok_but, thanks_but, settings_but, sound_but, info_but, ng_but, pa_but, exit_but;

Serial myPort;
Tile[][] tiles = new Tile[columns][rows];
Player player = new Player();
StopWatchTimer timer = new StopWatchTimer();
PFont bubbleFont;
PShape group;


void update() {
  if (gamestate == shootbubble) {
    // Bubble is moving
    stateShootBubble();
  } else if (gamestate == removecluster) {
    // Remove cluster and drop tiles
    stateRemoveCluster(0.03);
  }
}

void setGameState(int newgamestate) {
  gamestate = newgamestate;
  animationstate = 0;
}


void stateShootBubble() {
  // Move the bubble in the direction of the mouse
  player.bubble.x += 10 * Math.cos(degToRad(player.bubble.angle));
  player.bubble.y -= 10 * Math.sin(degToRad(player.bubble.angle));

  // Handle left and right collisions with the level
  if (player.bubble.x < x + tilewidth/4) {
    player.bubble.angle = 180 - player.bubble.angle;
    player.bubble.x = x + tilewidth/4;
  } else if (player.bubble.x + tilewidth/2 > x-tilewidth/4 + 650) {
    player.bubble.angle = 180 - player.bubble.angle;
    player.bubble.x = x-tilewidth/4 + 650 - tilewidth/2;
  }
  // Collisions with the top of the level
  if (player.bubble.y <= y) {
    // Top collision
    player.bubble.y = y;
    snapBubble();
    return;
  }
  // Collisions with other tiles
  for (int i=0; i<columns; i++) {
    for (int j=0; j<rows; j++) {
      Tile tile = tiles[i][j];
      // Skip empty tiles
      if (tile.type < 0) {
        continue;
      }
      // Check for intersections
      int tilex = getTileX(i, j);
      int tiley = getTileY(j);
      if (circleIntersection(player.bubble.x, player.bubble.y, radius, tilex, tiley, radius)) {
        // Intersection with a level bubble
        snapBubble();
        return;
      }
    }
  }
}

void stateRemoveCluster(float dt) {
  if (animationstate == 0) {
    resetRemoved();
    // Mark the tiles as removed
    for (int i=0; i<cluster.size(); i++) {
      cluster.get(i).removed = true;
    }
    // Find floating clusters
    floatingclusters = findFloatingClusters();
    if (floatingclusters.size() > 0) {
      // Setup drop animation
      for (int i=0; i<floatingclusters.size(); i++) {
        for (int j=0; j<floatingclusters.get(i).size(); j++) {
          Tile tile = floatingclusters.get(i).get(j);
          tile.shift = 1;
          //tile.velocity = player.bubble.dropspeed;
        }
      }
    }
    animationstate = 1;
  }
  // Pop bubbles
  boolean tilesleft = false;
  for (int i=0; i<cluster.size(); i++) {
    Tile tile = cluster.get(i);

    if (tile.type >= 0) {
      tilesleft = true;
      tile.type = -1;
      tile.removeFromGroup();
    }
  }

  // Drop bubbles
  for (int i=0; i<floatingclusters.size(); i++) {
    for (int j=0; j<floatingclusters.get(i).size(); j++) {
      Tile tile = floatingclusters.get(i).get(j);
      if (tile.type >= 0) {
        tilesleft = true;
        // Accelerate dropped tiles
        //tile.velocity += dt * 700;
        //tile.shift += dt;// * tile.velocity;
        // Alpha animation
        //tile.alpha -= dt * 8;
        //if (tile.alpha < 0) {
          tile.alpha = 0;
        //}
        // Check if the bubbles are past the bottom of the level
        if (tile.alpha == 0 || (tile.y * rowheight + tile.shift > (rows - 1) * rowheight + tilewidth)) {
        //if ((tile.y * rowheight + tile.shift > (rows - 1) * rowheight + tilewidth)) {
          tile.type = -1;
          tile.shift = 0;
          tile.alpha = 1;
          tile.removeFromGroup();
        }
      }
    }
  }
  if (!tilesleft) {
    nextBubble();
    // Check for game over
    boolean tilefound = false;
    for (int i=0; i<columns; i++) {
      for (int j=0; j<rows; j++) {
        if (tiles[i][j].type != -1) {
          tilefound = true;
          break;
        }
      }
    }
    if (tilefound) {
      setGameState(ready);
    } else {
      setGameState(win);
      timer.stop();
      file.stop();
      if (sound) {
        winFile.loop();
      }
    }
  }
}


void snapBubble() {
  // Get the grid position
  float centerx = player.bubble.x;// + tilewidth/2;
  float centery = player.bubble.y;// + tilewidth/2;
  int[] gridpos = getGridPosition(centerx, centery);

  // Make sure the grid position is valid
  gridpos[0] = min(columns-1,max(0, gridpos[0]));
  gridpos[1] = min(rows - 1, max(0, gridpos[1]));

  // Check if the tile is empty
  boolean addtile = false;
  if (tiles[gridpos[0]][gridpos[1]].type != -1) {
    if (tiles[gridpos[0]-1][gridpos[1]-1].type == -1) {
      gridpos[0] -= 1;
      gridpos[1] -= 1;
      addtile = true;
    } else if (tiles[gridpos[0]-1][gridpos[1]+1].type == -1) {
      gridpos[0] -= 1;
      gridpos[1] +=1;
      addtile = true;
    } else {
      // Tile is not empty, shift the new tile downwards
      for (int newrow=gridpos[1]+1; newrow<rows; newrow++) {
        if (tiles[gridpos[0]][newrow].type == -1) {
          gridpos[1] = newrow;
          addtile = true;
          break;
        }
      }
    }
  } else {
    addtile = true;
  }

  // Add the tile to the grid
  if (addtile) {
    // Hide the player bubble
    player.bubble.visible = false;
    // Set the tile
    tiles[gridpos[0]][gridpos[1]].type = player.bubble.tiletype;
    tiles[gridpos[0]][gridpos[1]].addToGroup();

    // Check for game over
    if (checkGameOver()) {
      return;
    }
    // Find clusters
    cluster = findCluster(gridpos[0], gridpos[1], true, true, false);
    if (cluster.size() >= 3) {
      wellDone = 50;
      int clr = randRange(0, 6);
      successMsg = successMsgs[randRange(0, 3)];
      for (int i = 0; i < 3; i++)
        wellDoneColor[i] = colors[clr][i];
      setGameState(removecluster);
      WDfile.play();
      return;
    }
  }

  // No clusters found
  turncounter++;
  if (turncounter >= 5) {
    // Add a row of bubbles
    turncounter = 0;
    rowoffset = (rowoffset + 1) % 2;
    firstRowShifted = !firstRowShifted;
    addBubbles();
    if (checkGameOver()) {
      return;
    }
  }
  nextBubble();
  setGameState(ready);
}


boolean checkGameOver() {
  // Check for game over
  for (int i=0; i< columns; i++) {
    // Check if there are bubbles in the bottom row
    if (tiles[i][rows-1].type != -1) {
      // Game over
      nextBubble();
      setGameState(gameover);
      timer.stop();
      return true;
    }
  }
  return false;
}

void addBubbles() {
  // Move the rows downwards
  for (int i=0; i<columns; i++) {
    for (int j=0; j<rows-1; j++) {
      tiles[i][rows-1-j].type = tiles[i][rows-1-j-1].type;
    }
  }
  // Add a new row of bubbles at the top
  for (int i=0; i<columns; i++) {
    // Add random, existing, colors
    tiles[i][0].type = getExistingColor();
  }
  groupTiles();
}

ArrayList<Integer> findColors() {
  ArrayList<Integer> foundcolors = new ArrayList<>();
  boolean[] colortable = new boolean[bubblecolors];
  for (var i=0; i<bubblecolors; i++) {
    colortable[i] = false;
  }
  // Check all tiles
  for (int i=0; i<columns; i++) {
    for (int j=0; j<rows; j++) {
      Tile tile = tiles[i][j];
      if (tile.type >= 0) {
        if (!colortable[tile.type]) {
          colortable[tile.type] = true;
          foundcolors.add(tile.type);
        }
      }
    }
  }
  return foundcolors;
}

// Find cluster at the specified tile location
ArrayList<Tile> findCluster(int tx, int ty, boolean matchtype, boolean reset, boolean skipremoved) {
  // Reset the processed flags
  if (reset) {
    resetProcessed();
  }
  // Get the target tile. Tile coord must be valid.
  Tile targettile = tiles[tx][ty];

  // Initialize the toprocess array with the specified tile
  ArrayList<Tile> toprocess = new ArrayList<Tile>();
  toprocess.add(targettile);
  targettile.processed = true;
  ArrayList<Tile> foundcluster = new ArrayList<Tile>();

  while (toprocess.size() > 0) {
    // Pop the last element from the array
    Tile currenttile = toprocess.get(toprocess.size()-1);
    toprocess.remove(toprocess.size()-1);

    // Skip processed and empty tiles
    if (currenttile.type == -1) {
      continue;
    }

    // Skip tiles with the removed flag
    if (skipremoved && currenttile.removed) {
      continue;
    }

    // Check if current tile has the right type, if matchtype is true
    if (!matchtype || (currenttile.type == targettile.type)) {
      // Add current tile to the cluster
      foundcluster.add(currenttile);

      // Get the neighbors of the current tile
      ArrayList<Tile> neighbors = getNeighbors(currenttile);

      // Check the type of each neighbor
      for (int i=0; i<neighbors.size(); i++) {
        if (!neighbors.get(i).processed) {
          // Add the neighbor to the toprocess array
          toprocess.add(neighbors.get(i));
          neighbors.get(i).processed = true;
        }
      }
    }
  }
  // Return the found cluster
  return foundcluster;
}


// Find floating clusters
ArrayList<ArrayList<Tile>> findFloatingClusters() {
  // Reset the processed flags
  resetProcessed();
  ArrayList<ArrayList<Tile>> foundclusters = new ArrayList<ArrayList<Tile>>();
  // Check all tiles
  for (int i=0; i<columns; i++) {
    for (int j=0; j<rows; j++) {
      Tile tile = tiles[i][j];
      if (!tile.processed) {
        // Find all attached tiles
        ArrayList<Tile> foundcluster = findCluster(i, j, false, false, true);
        // There must be a tile in the cluster
        if (foundcluster.size() <= 0) {
          continue;
        }
        // Check if the cluster is floating
        boolean floating = true;
        for (int k=0; k<foundcluster.size(); k++) {
          if (foundcluster.get(k).y == 0) {
            // Tile is attached to the roof
            floating = false;
            break;
          }
        }
        if (floating) {
          // Found a floating cluster
          foundclusters.add(foundcluster);
        }
      }
    }
  }
  return foundclusters;
}


// Reset the processed flags
void resetProcessed() {
  for (int i=0; i<columns; i++) {
    for (int j=0; j<rows; j++) {
      tiles[i][j].processed = false;
    }
  }
}

// Reset the removed flags
void resetRemoved() {
  for (int i=0; i<columns; i++) {
    for (int j=0; j<rows; j++) {
      tiles[i][j].removed = false;
    }
  }
}

// Get the neighbors of the specified tile
ArrayList<Tile> getNeighbors(Tile tile) {
  int tilerow = (int) (tile.y + rowoffset) % 2; // Even or odd row
  ArrayList<Tile> neighbors = new ArrayList<Tile>();

  // Get the neighbor offsets for the specified tile
  int[][] n = neighborsoffsets[tilerow];

  // Get the neighbors
  for (int i=0; i<n.length; i++) {
    // Neighbor coordinate
    int nx = (int) (tile.x + n[i][0]);
    int ny = (int) (tile.y + n[i][1]);

    // Make sure the tile is valid
    if (nx >= 0 && nx < columns && ny >= 0 && ny < rows) {
      neighbors.add(tiles[nx][ny]);
    }
  }

  return neighbors;
}

int getTileX(int column, int row) {
  int tilex = x + column * tilewidth + radius;
  // X offset for odd or even rows
  if ((row + rowoffset) % 2 != 0) {
    tilex += tilewidth/2;
  }
  return tilex;
}

int getTileY(int row) {
  int tiley = y + row * tilewidth + radius;
  return tiley;
}


int[] getGridPosition(float x2, float y2) {
  double gridy = Math.floor((y2 - y) / rowheight);

  // Check for offset
  int xoffset = 0;
  if ((firstRowShifted && gridy % 2 == 0) ||
    (!firstRowShifted && gridy % 2 != 0)) {
    xoffset = tilewidth / 2;
  }
  double gridx = Math.floor((x2 - xoffset - x) / tilewidth);
  int[] result = {(int) gridx, (int) gridy};

  return result;
}


// Start a new game
void newGame() {
  init_vals();
  createLevel();
  groupTiles();

  // Init the next bubble and set the current bubble
  nextBubble();
  nextBubble();
  setGameState(init);
}


// Create a random level
void createLevel() {
  // Create a level with random tiles
  for (int j=0; j<rows; j++) {
    int randomtile = randRange(0, bubblecolors-1);
    int count = 0;
    for (int i=0; i<columns; i++) {
      if (count >= 2) {
        // Change the random tile
        int newtile = randRange(0, bubblecolors-1);

        // Make sure the new tile is different from the previous tile
        if (newtile == randomtile) {
          newtile = (newtile + 1) % bubblecolors;
        }
        randomtile = newtile;
        count = 0;
      }
      count++;
      if (j < rows/2) {
        tiles[i][j].type = randomtile;
      } else {
        tiles[i][j].type = -1;
      }
    }
  }
}


void nextBubble() {
  // Set the current bubble
  player.tiletype = player.nextbubble.tiletype;
  player.bubble.tiletype = player.nextbubble.tiletype;
  player.bubble.x = player.x;
  player.bubble.y = player.y;
  player.bubble.visible = true;

  // Get a random type from the existing colors
  var nextcolor = getExistingColor();

  // Set the next bubble
  player.nextbubble.tiletype = nextcolor;
}

int getExistingColor() {
  ArrayList<Integer> existingcolors = findColors();

  var bubbletype = 0;
  if (existingcolors.size() > 0) {
    bubbletype = existingcolors.get(randRange(0, existingcolors.size()-1));
  }

  return bubbletype;
}


// Get a random int between low and high, inclusive
int randRange(int low, int high) {
  return (int) Math.floor(low + Math.random()*(high-low+1));
}

// Shoot the bubble
void shootBubble() {
  // Shoot the bubble in the direction of the mouse
  player.bubble.x = player.x;
  player.bubble.y = player.y;
  player.bubble.angle = player.angle;
  player.bubble.tiletype = player.tiletype;

  // Set the gamestate
  setGameState(shootbubble);
}

// Check if two circles intersect
boolean circleIntersection(float x1, float y1, int r1, int x2, int y2, int r2) {
  // Calculate the distance between the centers
  float dx = x1 - x2;
  float dy = y1 - y2;
  double len = Math.sqrt(dx * dx + dy * dy);

  if (len < r1 + r2) {
    // Circles intersect
    return true;
  }
  return false;
}

// Convert radians to degrees
double radToDeg(double angle) {
  return angle * (180 / Math.PI);
}

// Convert degrees to radians
double degToRad(double angle) {
  return angle * (Math.PI / 180);
}


void groupTiles() {
  if (group != null) {
    for (int j=0; j<rows; j++) {
      for (int i=0; i<columns; i++) {
        Tile t = tiles[i][j];
        if (t.type < 0)
          continue;
        t.removeFromGroup();
      }
    }
  }

  group = createShape(GROUP);
  for (int j=0; j<rows; j++) {
    for (int i=0; i<columns; i++) {
      Tile t = tiles[i][j];
      if (t.type < 0)
        continue;
      t.addToGroup();
    }
  }
}

// Draw the bubble
void drawBubble(float x1, float y1, int index) {
  if (index < 0 || index >= bubblecolors)
    return;
  noStroke();
  lights();
  translate(x1, y1, 0);
  fill(colors[index][0], colors[index][1], colors[index][2]);
  sphere(tilewidth / 2);
  translate(-x1, -y1, 0);
}

// Render the game
void render() {
  // Draw the frame around the game
  noStroke();
  fill(255);
  rect(x-tilewidth/4, y-tilewidth/2, 650, 602, 28);
  shape(group);
  renderPlayer();
}

// Render the player bubble
void renderPlayer() {
  float centerx = player.x;
  float centery = player.y;

  // Draw the angle
  stroke(0);
  drawArrow((int)centerx, (int)centery, 2.5*tilewidth, (float) -player.angle);
  // Draw the next bubble
  drawBubble(player.nextbubble.x, player.nextbubble.y, player.nextbubble.tiletype);

  // Draw the bubble
  if (player.bubble.visible) {
    drawBubble(player.bubble.x, player.bubble.y, player.bubble.tiletype);
  }
}


void serialEvent( Serial myPort)
{
  String inString = myPort.readStringUntil('\n');
  int lbound = 20;
  int ubound = 160;
  if (inString!= null) {
    String[] nString = split(inString, ',');
    //convert to an int and map to the screen height:
    inByte = float(nString[0]);
    inByte = map(inByte, 0, 1023, lbound, ubound);
    if (bmpInit < 0) {
      bmpInit = float(nString[1]);
    } else {
      bmpVal = float(nString[1]) - bmpInit;
    }
  }
  // Get the mouse angle
  double mouseangle = inByte;
  // Convert range to 0, 360 degrees
  if (mouseangle < 0) {
    mouseangle = 180 + (180 + mouseangle);
  }

  if (mouseangle > 90 && mouseangle < 270) {
    if (mouseangle > ubound) {
      mouseangle = ubound;
    }
  } else {
    if (mouseangle < lbound || mouseangle >= 270) {
      mouseangle = lbound;
    }
  }
  player.angle = mouseangle;
}

void breath() {
  if (gamestate == ready) {
    gamestate = shootbubble;
    shootBubble();
  }
}

boolean pressureCheck2() {
  //if (bmpVal > power) {  // ######################################################################################################
  if (mousePressed) {
    if (timer.running) {
      float centerx = player.x;
      float centery = player.y;

      if (timer.getElapsedTime() >= duration*1000) {
        timer.stop();
        return true;
      }
      fillArrow(map(timer.getElapsedTime(), 0, duration*1000.0, 0, 2.5*tilewidth + 10), (int)centerx, (int)centery, 2.5*tilewidth, (float) -player.angle);
    } else {
      timer.start();
    }
  } else {
    timer.stop();
  }
  return false;
}

boolean pressureCheck() {
  if (bmpVal > power) {
    if (timer.running) {
      if (timer.second() >= duration) {
        timer.stop();
        return true;
      }
    } else {
      timer.start();
    }
  } else {
    timer.stop();
  }
  return false;
}

void instructionsScreen() {
  noStroke();
  fill(0, 153, 153);
  rect(x-tilewidth/4, y-tilewidth/2, 650, 602, 28);
  fill(0);
  textSize(70);
  translate(-20, 0, 0);
  text("Instructions", 170, y + 100);
  
  thanks_but.display();
  
  translate(-15, 0, 10);
  fill(0);
  textSize(17);
  String s = " Match at least three bubbles of the same color to pop them and clear\n them off the board. Mind your angles as you bounce bubbles off the wall\n to hit the hard-to-reach spots.\n In order to shot, blow the tube for the amount of time and force\n that you were instructed. In order to change the direction of the shot,\n turn the cannon. Keep on popping until you run out of bubbles!";
  text(s, 100, height/2-100);
  translate(35, 0, -10);
}


void settingsScreen() {
  translate(0, 0, 10);
  hs1.update();
  hs2.update();
  hs1.display();
  hs2.display();
  translate(0, 0, -10);
  duration = hs1.getTime(map(hs1.getPos(), 0, 220, 0.5, 5));
  power = (int) hs2.getPressure((int) map(hs2.getPos(), 0, 220, 50, 550));
  noStroke();

  fill(0, 153, 153);
  rect(x-tilewidth/4, y-tilewidth/2, 650, 602, 28);
  fill(0);
  translate(-20, 0, 0);
  textSize(70);
  text("settings", 240, y + 100);
  ok_but.display();
  
  translate(20, 0, 10);
  fill(0);
  textSize(20);
  text("Duration:", 100, height/2-25);
  text("0.5", 230, height/2-25);
  text("4.5", 500, height/2-25);
  text("Pressure:", 100, height/2+35);
  text("low", 230, height/2+35);
  text("high", 500, height/2+35);
  translate(0, 0, -10);
}

void settingsScreen2() {
  settingsScreen();
  translate(0, 0, 10);
  
  hs3.update();
  hs3.display();
  bubblecolors = hs3.getLevel(0);
  
  fill(0);
  textSize(20);
  text("Level:", 100, height/2+95);
  text("1", 230, height/2+95);
  text("7", 500, height/2+95);
  
  translate(0, 0, -10);
}


void drawSettingsBubbles() {
  translate(-tomove*1.33, 0, 0);
  noStroke();
  lights();
  pushMatrix();
  settings_but.display();
  sound_but.display();
  info_but.display();
  ng_but.display();
  popMatrix();
  translate(tomove*1.33, 0, 0);
}

void drawArrow(int cx, int cy, float len, float angle) {
  pushMatrix();
  translate(cx, cy);
  rotate(radians(angle));
  strokeWeight(8);
  line(0, 0, len, 0);
  fill(0);
  noStroke();
  triangle(len+10, 0, len-15, -15, len-15, 15);
  translate(-cx, -cy);
  popMatrix();
}

void fillArrow(float dur, int cx, int cy, float len, float angle) {
  pushMatrix();
  translate(cx, cy, 10);
  rotate(radians(angle));
  strokeWeight(8);
  stroke(0, 153, 153);
  fill(0, 153, 153);
  line(0, 0, dur, 0);
  stroke(100);
  fill(0, 153, 153);
  noStroke();
  if (dur >= len-15) {
    float dx = (dur - len - 10) / (25.0/15.0);
    fill(0, 153, 153);
    quad(len-15, -15, dur, dx, dur, -dx, len-15, 15 );
    fill(0, 153, 153);
  }
  translate(-cx, -cy, -10);
  popMatrix();
}

void drawSound() {
  pushMatrix();
  translate(0, 0, 500);
  fill(0);
  strokeWeight(8);
  rect(soundX - 10, soundY - 2, 8, 8);
  float x1 = soundX - 2;
  float y1 = soundY + 6;
  fill(0);
  noStroke();
  quad(x1, y1, x1, y1-8, x1+8, y1-16, x1+8, y1+8);
  strokeWeight(2);
  if (sound) {
    noFill();
    stroke(50);
    arc(x1+6, y1-4.5, tilewidth/3, tilewidth/3, -QUARTER_PI, QUARTER_PI);
    arc(x1+3, y1-4.5, tilewidth/3+15, tilewidth/3+15, -QUARTER_PI, QUARTER_PI);
    noStroke();
  }
  translate(0, 0, -500);
  popMatrix();
}


void fireWork() {
  noStroke();
  if (drawFW <= 0) {
      FWradius = 0;
      FWx = randRange(50, width-50);
      FWy = randRange(50, height-50);
      FWColor = randRange(0, 6);
      drawFW = 100;
    }
  if (drawFW > 0 && FWradius < 100) {
    float x2, y2;
    FWradius += FWspeed;

    for (float a = 0; a <= (2 * PI); a += QUARTER_PI) {
      x2 = cos(a) * FWradius  + FWx;
      y2 = sin(a) * FWradius  + FWy;
      fill(colors[FWColor][0], colors[FWColor][1], colors[FWColor][2]);
      translate(x2 - tomove, y2);
      sphere(5);
      translate(-x2 + tomove, -y2);
    }
    drawFW--;
  }
}


void drawEndButtons(String t, float x3, float y3) {
  noStroke();
  fill(0, 153, 153);
  rect(x-tilewidth/4, y-tilewidth/2, 650, 602, 28);
  fill(0);
  textSize(70);
  text(t, x3-20, y3);
  pa_but.display();
  exit_but.display();
  fill(0);
}

void init_vals() {
  inByte = 0;
  bmpInit = -1;
  FWradius = 0;
  FWspeed = 1;

  wellDone = 0;
  drawFW = 0;

  turncounter = 0;
  rowoffset = 0;
  animationstate = 0;
  showcluster = false;
  firstRowShifted = false;
  instructions = false;

  cluster = new ArrayList<Tile>();
  floatingclusters = new ArrayList<ArrayList<Tile>>();

  tiles = new Tile[columns][rows];
  player = new Player();
  timer = new StopWatchTimer();
  for (int i=0; i < columns; i++) {
    for (int j=0; j<rows; j++) {
      // Define a tile type and a shift parameter for animation
      tiles[i][j] = new Tile(i, j, 0, 0);
    }
  }

  // Init the player
  player.x = x + width1/2 - tilewidth/2 + 35;
  player.y = y + height1;
  player.angle = 90;
  player.tiletype = 0;
  player.nextbubble.x = player.x - 2 * tilewidth;
  player.nextbubble.y = player.y;
  
  turncounter = 0;
  rowoffset = 0;
}



void mousePressed() {
  if (ng_but.overButton()){
    if (sound && (gamestate == win)) {
      winFile.stop();
      file.loop();
    }
    gamestate = init;
    settings = true;
    instructions = false;
  } else if (gamestate == win || gamestate == gameover) {
    if (pa_but.overButton()) {
      gamestate = init;
      settings = true;
      winFile.stop();
      if (sound) {
        file.loop();
      }
      return;
    } else if (exit_but.overButton()) {
      exit();
    }
  }
  if (!settings && settings_but.overButton()) {
    settings = true;
    instructions = false;
  } else if (!instructions && info_but.overButton()) {
    instructions = true;
    settings = false;
  } else if (settings && ok_but.overButton()) {
    settings = false;
    if (gamestate == init) {
      newGame();
      gamestate = ready;
    }
  } else if (instructions && ok_but.overButton()) {
    instructions = false;
    if (gamestate == init) {
      settings = true;
    }
  } else if (sound_but.overButton()) {
    sound = !sound;
    if (sound) {
      if (gamestate == win) {
        winFile.loop();
      } else {
        file.loop();
      }
    } else {
      file.stop();
      winFile.stop();
    }
  }
}

void createButtons() {
  ok_but = new Button(350 + tilewidth/2, 560, 0, tilewidth, 255, 255, 255, "OK", -19, 12, 100, 28);
  thanks_but = new Button(350 + tilewidth/2, 560, 0, tilewidth, 255, 255, 255, "Thanks", -32, 8, 100, 20);
  settings_but = new SettingsButton(settingsX, settingsY, 0, tilewidth/2, 255, 255, 0);
  sound_but = new SoundButton(soundX, settingsY, 0, tilewidth/2, 0, 255, 0);
  info_but = new Button(infoX, settingsY, 0, tilewidth/2, 0, 153, 255, "?", -7-tomove*1.33, 12, 50, 36);
  ng_but = new NGButton(newGameX, newGameY, 0, tilewidth/2, 255, 0, 0);
  pa_but = new Button(playAgainX, playAgainY, 0, tilewidth, 255, 255, 255, " Play\nAgain", -24, -7, 200, 20);
  exit_but = new Button(exitX, exitY, 0, tilewidth, 255, 255, 255, "Exit", -18, 4, 200, 20);
}


void drawBackground() {
  translate(150, 100, 0);
  fill(255, 255, 255, 100);
  sphere(tilewidth*2);
  translate(-150, -100, 0);
  fill(255, 255, 255, 100);
  circle(300, 350, tilewidth*3);
  translate(130, 600, 0);
  fill(255, 255, 255, 100);
  sphere(tilewidth);
  translate(-130, -600, 0);
  translate(1000,0,0);
  translate(150, 100, 0);
  fill(255, 255, 255, 100);
  sphere(tilewidth*2);
  translate(-150, -100, 0);
  fill(255, 255, 255, 100);
  circle(300, 350, tilewidth*3);
  translate(130, 600, 0);
  fill(255, 255, 255, 100);
  sphere(tilewidth);
  translate(-130, -600, 0);
  translate(-1000,0,0);
}

void set_buttons_locations(){
  settingsX = x + tilewidth + tomove*1.33;
  settingsY = y - tilewidth*1.2;
  soundX = settingsX + tilewidth*1.5;
  soundY = settingsY;
  infoX = soundX + tilewidth*1.5;
  infoY = settingsY;
  newGameX = x + 630 + tomove*1.33;
  newGameY = settingsY;
}

void setup() {
  size(710, 690, P3D);
  tomove = 0;
  bubbleFont = loadFont("ComicSansMS-120.vlw");
  textFont(bubbleFont);

  String path2 = sketchPath(WDsound);
  WDfile = new SoundFile(this, path2);

  String path = sketchPath(audioName);
  file = new SoundFile(this, path);
  file.loop();

  winFile = new SoundFile(this, sketchPath("winSound.wav"));

  wellDone = 0;
  ortho(-width/2, width/2, -height/2, height/2);
  hs1 = new HScrollbar(270, 690/2-30, 900/4, 16, 10, 255, 128, 0, 1);
  hs2 = new HScrollbar(270, 690/2+30, 900/4, 16, 16, 255, 128, 0, 2);
  hs3 = new HScrollbar(270, 690/2+90, 900/4, 16, 16, 255, 128, 0, 3, 6);
  settings = true;

  //myPort = new Serial (this, Serial.list()[0], 9600); // ######################################################################################################

  width1 = columns * tilewidth + tilewidth/2;
  height1 = (rows-1) * rowheight + tilewidth;
  
  settingsX = x + tilewidth/2;
  settingsY = y - tilewidth*1.2;
  soundX = settingsX + tilewidth*1.5;
  soundY = settingsY;
  infoX = soundX + tilewidth*1.5;
  infoY = settingsY;
  newGameX = x + 610;
  newGameY = settingsY;
  playAgainX = 250;
  playAgainY = 560;
  exitX = playAgainX + 210;
  exitY = playAgainY;

  newGame();
  createButtons();
}


void draw() {
  background(204, 229, 255);
  if (width > 900) {
    tomove = 350;
    drawBackground();
  } else {
    tomove = 0;
  }
  set_buttons_locations();
  
  ortho(-width/2, width/2, -height/2, height/2);
  translate(tomove, 0, 0);
  noStroke();
  lights();

  drawSettingsBubbles();
  
  switch(gamestate) {
    case 5: // win
      fireWork();
      drawEndButtons("Well Done!", 210, y + 260);
      return;
    case 0: //init
      if (instructions) {
        instructionsScreen();
      } else {
        settingsScreen2();
      }
      return;
    case 4: //gameover
      drawEndButtons("Good Try", 230, y + 260);
      return;
  }
  if (wellDone > 0) {
    textSize(38);
    drawText(successMsg, infoX + 2 * tilewidth - tomove*1.3, infoY + tilewidth/4);//width -200 - tomove*1.33, height - 200);
    fill(0);
    wellDone--;
  }
  if (settings) {
    settingsScreen();
  } else if (instructions) {
    instructionsScreen();
  } else {
    update();
    render();
    if (pressureCheck2()) {
      breath();
    }
  }
}


void drawText(String text, float x, float y) {
  fill(0);
  for (int i = -1; i < 2; i++) {
    text(text, x+i, y, 100);
    text(text, x, y+i, 100);
  }
  fill(wellDoneColor[0], wellDoneColor[1], wellDoneColor[2]);
  text(text, x, y, 100);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void mouseMoved() {
  // Get the mouse position
  int x = mouseX - tomove;
  int y = mouseY;

  // Get the mouse angle
  double mouseangle = radToDeg(Math.atan2((player.y+tilewidth/2) - y, x - (player.x+tilewidth/2)));

  // Convert range to 0, 360 degrees
  if (mouseangle < 0) {
    mouseangle = 180 + (180 + mouseangle);
  }

  // Restrict angle to 8, 172 degrees
  var lbound = 8;
  var ubound = 172;
  if (mouseangle > 90 && mouseangle < 270) {
    // Left
    if (mouseangle > ubound) {
      mouseangle = ubound;
    }
  } else {
    // Right
    if (mouseangle < lbound || mouseangle >= 270) {
      mouseangle = lbound;
    }
  }
  player.angle = mouseangle;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////



//void draw()
//{
//  background(255);  
//  int radio=12;
//  float teethHeight=0.48*radio; 
//  float centerPositionX=100;//2*width/3-radio-teethHeight/2;
//  float centerPositionY=100;//height/2;
//  drawGear(radio, centerPositionX, centerPositionY, teethHeight);
//}

//final int minNumberOfTeeth=3;
//final int maxNumberOfTeeth=40;

//void setup()
//{
//  size(1350, 690);  
//  frameRate(60);
//  textAlign(CENTER);
//  textSize(18);
//}
