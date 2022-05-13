class Tile {
  float x, y;
  int type, shift, velocity, alpha;
  boolean removed, processed;
  PShape s;

  Tile(float x, float y, int type, int shift) {
    this.x = x;
    this.y = y;
    this.type = type;
    this.removed = false;
    this.shift = shift;
    this.velocity = 0;
    this.alpha = 1;
    this.processed = false;
  };

  void addToGroup() {
    s = createShape(SPHERE, tilewidth/2);
    float tilex = getTileX((int)x, (int)y);
    float tiley = getTileY((int)y);
    s.translate(tilex, tiley, 0);
    s.setFill(color(colors[type][0], colors[type][1], colors[type][2]));
    s.setStroke(false);
    group.addChild(s);
  }

  void removeFromGroup() {
    int ind = group.getChildIndex(s);
    if (ind < 0 || group.getChild(ind) == null) {
      return;
    }
    group.removeChild(ind);
  }
}
