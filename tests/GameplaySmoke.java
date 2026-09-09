package org.portmaster.ashworld;
import com.badlogic.gdx.*;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
public class GameplaySmoke extends Main {
 int frame,play,previous=-1; long started=System.nanoTime(); boolean reached;
 public static void main(String[] args) throws Exception { new Lwjgl3Application(new GameplaySmoke(),configuration()); }
 void key(int code,boolean down) {if(down)Gdx.input.getInputProcessor().keyDown(code);else Gdx.input.getInputProcessor().keyUp(code);}
 @Override public void render() {
  frame++;
  if(frame>180) {
   if(frame%90==0) {key(Input.Keys.X,true);key(Input.Keys.Z,true);if(GameState==26 || GameState==22 || GameState==21)key(Input.Keys.ESCAPE,true);}
   if(frame%90==3) {key(Input.Keys.X,false);key(Input.Keys.Z,false);key(Input.Keys.ESCAPE,false);}
  }
  if(GameState==6) {
   reached=true;play++;
   if(play==1)key(Input.Keys.RIGHT,true);
   if(play==120)key(Input.Keys.RIGHT,false);
  }
  super.render();
  java.nio.IntBuffer viewport=com.badlogic.gdx.utils.BufferUtils.newIntBuffer(4);
  Gdx.gl20.glGetIntegerv(com.badlogic.gdx.graphics.GL20.GL_VIEWPORT,viewport);
  if(viewport.get(0)!=layout.x || viewport.get(1)!=layout.y || viewport.get(2)!=layout.width || viewport.get(3)!=layout.height)
   throw new IllegalStateException("Viewport lost: "+viewport.get(0)+","+viewport.get(1)+","+viewport.get(2)+","+viewport.get(3));
  if(physicalGraphics.getWidth()!=Integer.getInteger("ashworld.width",640) || physicalGraphics.getHeight()!=Integer.getInteger("ashworld.height",480))throw new IllegalStateException("Game changed display mode");
  if(GameState!=previous){System.out.println("STATE "+frame+" "+GameState);previous=GameState;}
  if(frame%600==0)capture(System.getProperty("ashworld.output")+"/frame"+frame+".png");
  if(play>=300 || frame>=9000) {
   capture(System.getProperty("ashworld.output")+"/final.png");
   if(!reached || play<300)throw new IllegalStateException("Gameplay not reached");
   double seconds=(System.nanoTime()-started)/1e9;
   if(seconds<(frame-2)/60.0)throw new IllegalStateException("Frame cap exceeded");
   if(Boolean.getBoolean("ashworld.testSave")) {
    activePlayer.SaveGame(PROFILEID);activePlayer.LoadGame(PROFILEID,false);
    if(activePlayer.mySaveGame==null || !activePlayer.mySaveGame.isCorrectVersion())throw new IllegalStateException("Save readback failed");
    System.out.println("SAVE_READBACK_OK");
   }
   System.out.println("GAMEPLAY_OK frames="+frame+" play="+play+" seconds="+seconds);Gdx.app.exit();
  }
 }
}
