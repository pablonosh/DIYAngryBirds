import SimpleOpenNI.*;
import fisica.*;
import java.awt.*;

/** Setup Kinect **/
SimpleOpenNI context;
String gestureToRecognize = "RaiseHand";

/** Setup Physics World **/
FWorld world;         // all drawn shapes exist in this world.
FPoly temporaryShape; // the shape the user is currently drawing.

/** State **/
FBody lastSelectedBody;

// location tracking
long handStillSince;
PVector hand = null;
PVector lastHand = null;
PVector lastFinger;
ArrayList handPositions = new ArrayList();

void setup() {
  size(640,480);
  smooth();

  setupWorld();
  setupKinect();
}

void draw() {
  background(0);
  context.update();
  drawRGB();

 
  world.step();
  world.draw(this);

  // draw any half found shapes.
  if (temporaryShape != null) {
    temporaryShape.draw(this);
  }
  
   processUserInputs();
    
  lastHand = hand;
}

void processUserInputs() {
    Boolean isDrawingShape = false;
    Boolean hasSelectedShape = lastSelectedBody != null;
   if(lastHand != null && hand != null) {
    //  start drawing shape if hand still for 2 seconds
    if (handPositions.isEmpty() ) {  
      
      FBody b = world.getBody(hand.x,hand.y);
      
      if(b != null && !hasSelectedShape && handsBeenStillFor(lastHand, hand, 500)) {
        println("Selected Object: "+ b);
        // IF TOUCHING AN EXISTING OBJECT, RECORD OBJECT
        lastSelectedBody = b;
        lastFinger = hand;
        b.setFill(120, 120, 120);
      } 
      else if(lastSelectedBody != null && lastSelectedBody != b) {
        println("Moving  Object");

        // IF NEW OBJECT IS DIFFERENT TO OLD THEN OBJECT HAS BEEN MOVED
        float dx = (lastFinger.x-hand.x);
        float dy=  (lastFinger.y-hand.y);

        if(dx != 0 && dy != 0) {
          lastSelectedBody.setVelocity(-20*dx,-20*dy);
        }

        lastSelectedBody.setFill(120, 30, 90);
        lastSelectedBody=null;  
      } else if (!hasSelectedShape && handsBeenStillFor(lastHand, hand, 2000)){ 
      
        println("Creating new Object");
        isDrawingShape=true;
      } else if (hasSelectedShape){
         b.setFill(120, 120, 120);
      }
    }
 
  
    // if drawing a shape and still for 2 seconds then finish otherwise update.
    if(!handPositions.isEmpty()) {

      if(!handsBeenStillFor(lastHand, hand, 2000)) {
        println("Extending Object");
        isDrawingShape=true;
      } else {
        // ADD OBJECT TO WORLD
        println("Finished new Object");
        world.add(temporaryShape);
        temporaryShape = null;
        handPositions.clear();
      }
    }
    if (isDrawingShape) {
      // IF NOT SELECTING A BODY THEN BLANK AND CREATE NEW SHAPE
      println("Refreshing Object");
      handPositions.add(hand);
      temporaryShape = new FPoly();
      temporaryShape.setStrokeWeight(3);
      temporaryShape.setFill(120, 30, 90);
      temporaryShape.setDensity(10);
      temporaryShape.setRestitution(0);
      for (int i = 0; i < handPositions.size(); i++) {
        PVector p = (PVector) handPositions.get(i);
        temporaryShape.vertex(p.x,p.y);
      }
    }

  // draw hand ( go from red to green when drawing)
 if(isDrawingShape || hasSelectedShape) {
    fill(0,255,0,64);
    stroke(0,255,0);
  } else {
    fill(255,0,0,64);
    stroke(255,0,0);
  }  

  ellipse(hand.x, hand.y, 20, 20);
  }
}
void setupKinect() {
  context = new SimpleOpenNI(this);
  context.setMirror(false);
  if(context.enableDepth() == false)
  {
    println("Can't open the depthMap, maybe the camera is not connected!"); 
    exit();
    return;
  }

  // enable hands + gesture generation
  context.enableGesture();
  context.enableHands();
  context.enableRGB();
  context.setSmoothingHands(0.1);
  context.addGesture(gestureToRecognize);
}

void setupWorld() {
  Fisica.init(this);
  world = new FWorld();
  world.setGravity(0, 200);
  world.setEdges();
  world.setEdgesRestitution(0);
}

void drawRGB() {
  pushMatrix();
  scale(-1.0, 1.0); // draw mirrored
  image(context.rgbImage(),-context.rgbImage().width,0);
  popMatrix();
}


// -----------------------------------------------------------------
// hand events

void onUpdateHands(int handId,PVector pos,float time) {
 PVector tempHand = new PVector();
  context.convertRealWorldToProjective(pos, tempHand);
  hand = new PVector(640-tempHand.x, tempHand.y); // mirror
}

void onDestroyHands(int handId,float time) {
  hand=null;
  context.addGesture(gestureToRecognize);
}

// -----------------------------------------------------------------
// gesture events

void onRecognizeGesture(String strGesture, PVector idPosition, PVector endPosition) {
  println("onRecognizeGesture - strGesture: " + strGesture + ", idPosition: " + idPosition + ", endPosition:" + endPosition);
  context.removeGesture(gestureToRecognize); 
  context.startTrackingHands(endPosition);
}

boolean handsBeenStillFor(PVector oldHand, PVector newHand, int timeOut) {
  float dis = oldHand.dist(newHand);
  if(dis > 10.0 || handStillSince == 0) {
    // reset system timer
    handStillSince = System.currentTimeMillis();
    return false;
  } 
  else if (System.currentTimeMillis() - handStillSince > timeOut) { 
    handStillSince=0;
    return true;
  }
  return false;
}

void keyPressed() {
  if ( key=='c' ) {
    world.clear();
    setupWorld();
  }
}

