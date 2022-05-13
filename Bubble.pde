class Bubble {
  float x, y;
  double angle;
  int speed, dropspeed, tiletype;
  boolean visible;

  Bubble(float x, float y, double angle, int speed, int dropspeed, int tiletype, boolean visible) {
    this.x=x;
    this.y=y;
    this.angle=angle;
    this.speed=speed;
    this.dropspeed=dropspeed;
    this.tiletype=tiletype;
    this.visible=visible;
  }
}
