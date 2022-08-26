class Button {
  float x, y, z, sx, sy, sz;
  int radius, r, g, b, s_size;
  String s = null;
  
  Button(float x, float y, float z, int radius) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.radius = radius;
  }
  
  Button(float x, float y, float z, int radius, int r, int g, int b) {
    this(x, y, z, radius);
    this.r = r;
    this.g = g;
    this.b = b;
  }
  
  Button(float x, float y, float z, int radius, int r, int g, int b, String s, float sx, float sy, float sz, int s_size) {
    this(x, y, z, radius, r, g, b);
    this.s = s;
    this.sx = sx;
    this.sy = sy;
    this.sz = sz;
    this.s_size = s_size;
  }
  
  void display() {
    translate(x, y, z);
    if (overButton()){
      fill(0.5*r, 0.5*g, 0.5*b);
    } else {
      fill(r, g, b);
    }
    sphere(radius);
    if (s != null) {
      fill(0);
      textSize(s_size);
      text(s, sx, sy, sz);
    }
    translate(-x, -y, -z);
  }
  
  boolean overButton() {
    return ((mouseX - x - tomove)*(mouseX - x - tomove) + (mouseY - y)*(mouseY - y) <= this.radius*this.radius);
  } //<>//
}


class SettingsButton extends Button {
    
  SettingsButton(float x, float y, float z, int radius, int r, int g, int b) {
    super(x, y, z, radius, r, g, b);
  }
  
  void display() {
    super.display();
    translate(x, y, z+radius);
    drawGear(10, 5);
    translate(-x, -y, -z-radius);
  }
  
  void drawGear(int radio, float teethHeight) { 
    strokeWeight(2);
    int numberOfTeeth=8;
    float teethAngle = TWO_PI/numberOfTeeth;
    float teethWidth = sin(teethAngle/2)*radio; 
    float lineY = cos(teethAngle/2)*radio+teethHeight;
    fill(0);
    noStroke();
    for (int i=0; i<numberOfTeeth; i++)
    {  
      rotate(teethAngle);     
      quad(-3*teethWidth/3, -lineY+teethHeight, teethWidth, -lineY+teethHeight, teethWidth/2, -lineY,-3*teethWidth/4, -lineY);
    }
    stroke(0);
    ellipse(0, 0, 2*(-lineY+teethHeight*0.65), 2*(-lineY+teethHeight*0.65)) ;
    if (overButton()){
      fill(0.5*r, 0.5*g, 0.5*b);
    } else {
      fill(r, g, b);
    }
    ellipse(0, 0, radio*1.85/2, radio*1.85/2);//Shaft
    noStroke();
  }
  
}


class SoundButton extends Button {
  
  SoundButton(float x, float y, float z, int radius, int r, int g, int b){
    super(x, y, z, radius, r, g, b);
  }
  
  void display() {
    super.display();
    translate(-3, -2, 0);
    drawSound();
    translate(3, 3, 0);
  }
  
  void drawSound() {
    //pushMatrix();
    translate(-20, 0, 50);
    fill(0);
    strokeWeight(8);
    rect(soundX - 10 - tomove*1.33, soundY - 2, 8, 8);
    float x1 = soundX - 2 - tomove*1.33;
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
    translate(20, 0, -50);
    //popMatrix();
  }
}


class NGButton extends Button {
    
  NGButton(float x, float y, float z, int radius, int r, int g, int b) {
    super(x, y, z, radius, r, g, b);
  }
  
  void display(){
    super.display();
    translate(0, 0, 50);
    drawNG(x, y, 17, 5);
    translate(0, 0, -50);
  }
  
  void drawNG(float xx, float yy, float radius_ng, float size){
    stroke(0);
    strokeWeight(4.5);
    noFill();
    arc(xx, yy, radius_ng, radius_ng, -PI, -QUARTER_PI*0.8);
    arc(xx, yy+2, radius_ng, radius_ng, PI*0.1, PI*0.8);
    fill(0);
    strokeWeight(1);
    float y2 = yy+size-1;
    triangle(xx+radius_ng/2-size-1, y2, xx+radius_ng/2+size-1, y2, xx+radius_ng/2-1, y2-size);
    float y1 = yy-size+4;
    triangle(xx-radius_ng/2-size, y1, xx-radius_ng/2+size, y1, xx-radius_ng/2, y1+size);
  }
}
  
