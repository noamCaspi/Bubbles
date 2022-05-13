class HScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  int loose;              // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;
  int r, g, b;
  int m, t;

  HScrollbar (float xp, float yp, int sw, int sh, int l, int r1, int g1, int b1, int t) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos + swidth/2 - sheight/2;

    sposMin = xpos + sheight;
    sposMax = xpos + swidth - sheight;
    //spos = sposMax;
    m = 8;
    this.t = t;

    spos = constrain(spos, sposMin, sposMax);
    newspos = spos;
    loose = l;
    r = r1;
    g = g1;
    b = b1;
    update();
  }

  HScrollbar (float xp, float yp, int sw, int sh, int l, int r1, int g1, int b1, int t, int m) {
    this(xp, yp, sw, sh, l, r1, g1, b1, t);
    this.m = m;
  }

  float getTime(float x) {
    float newVal = map(min(max(spos, sposMin), sposMax), sposMin, sposMax, 0, 8);
    return map(round(newVal), 0, 8, 0.5, 4.5);
  }

  float getPressure(float x) {
    float newVal = map(min(max(spos, sposMin), sposMax), sposMin, sposMax, 70, 4200);
    return map(round(newVal), 0, 8, 0.5, 4.5);
  }

  int getLevel(float x) {
    float newVal = map(min(max(spos, sposMin), sposMax), sposMin, sposMax, 1, 7);
    return round(newVal);//map(round(newVal), 0, 8, 0.5, 4.5);
  }

  void update() {
    if (overEvent()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2 - tomove, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 1) {
      spos = spos + (newspos-spos)/loose;
    }
  }

  float constrain(float val, float minv, float maxv) {
    float newVal = map(min(max(val, minv), maxv), minv, maxv, 0, m);
    //println(round(newVal));
    return map(round(newVal), 0, m, minv, maxv);
  }


  boolean overEvent() {
    if (mouseX - tomove > xpos && mouseX - tomove < xpos+swidth &&
      mouseY- tomove*scrolly > ypos && mouseY- tomove*scrolly < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  void display() {
    noStroke();

    beginShape();
    fill(255);
    vertex(xpos, ypos + tomove*scrolly);
    vertex(xpos, ypos + sheight + tomove*scrolly);
    fill(0);
    vertex(xpos + swidth, ypos + sheight + tomove*scrolly);
    vertex(xpos + swidth, ypos + tomove*scrolly);
    endShape();

    if (over || locked) {
      fill(0.5*r, 0.5*g, 0.5*b);
    } else {
      fill(r, g, b);
    }

    translate(spos, ypos+sheight/2 + tomove*scrolly, 0);
    sphere(tilewidth/2);
    if (t == 1) {
      translate(0, 0, 50);
      textSize(18);
      fill(0);
      text(Float.toString(this.getTime(0)), -14, 6);
      translate(0, 0, -50);
    } else if (t == 3) {
      translate(0, 0, 50);
      textSize(18);
      fill(0);
      text(this.getLevel(0), -7, 6);
      translate(0, 0, -50);
    }
    translate(-spos, -ypos-sheight/2 - tomove*scrolly, 0);
  }

  float getPos() {
    return (int)(spos - xpos) * ratio;
  }
}
