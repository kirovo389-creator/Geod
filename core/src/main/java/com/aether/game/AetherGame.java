package com.aether.game;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.PerspectiveCamera;
import com.badlogic.gdx.graphics.VertexAttributes;
import com.badlogic.gdx.graphics.g3d.*;
import com.badlogic.gdx.graphics.g3d.attributes.ColorAttribute;
import com.badlogic.gdx.graphics.g3d.utils.ModelBuilder;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector3;
import java.util.ArrayList;
import java.util.List;

public class AetherGame extends ApplicationAdapter {
    private PerspectiveCamera camera;
    private ModelBatch modelBatch;
    private SpriteBatch uiBatch;
    private BitmapFont font;
    private final List<ModelInstance> world = new ArrayList<>();
    private final List<Vector3> crystals = new ArrayList<>();
    private final Vector3 player = new Vector3(0, 1.6f, 7);
    private float yaw = 180f, pitch = -8f, moveX, moveY, lookX;
    private boolean started = false, jumping = false;
    private float jumpVelocity = 0;
    private int collected = 0;
    private long touchMove = -1, touchLook = -1;
    private int moveStartX, moveStartY, lookStartX;
    private ModelBuilder builder;

    @Override public void create() {
        Gdx.graphics.setContinuousRendering(true);
        camera = new PerspectiveCamera(67, Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        camera.near = 0.1f; camera.far = 180f;
        modelBatch = new ModelBatch();
        uiBatch = new SpriteBatch();
        font = new BitmapFont();
        font.getData().setScale(1.35f);
        builder = new ModelBuilder();
        buildWorld();
        Gdx.input.setInputProcessor(new InputAdapter() {
            @Override public boolean touchDown(int x, int y, int pointer, int button) {
                if (!started) { started = true; return true; }
                if (x > Gdx.graphics.getWidth() - 170 && y > Gdx.graphics.getHeight() - 150) {
                    jumping = true; jumpVelocity = 6.2f; return true;
                }
                if (x < Gdx.graphics.getWidth() * 0.42f) {
                    touchMove = pointer; moveStartX = x; moveStartY = y; moveX = moveY = 0;
                } else { touchLook = pointer; lookStartX = x; }
                return true;
            }
            @Override public boolean touchDragged(int x, int y, int pointer) {
                if (pointer == touchMove) {
                    moveX = MathUtils.clamp((x - moveStartX) / 65f, -1, 1);
                    moveY = MathUtils.clamp((moveStartY - y) / 65f, -1, 1);
                } else if (pointer == touchLook) {
                    yaw -= (x - lookStartX) * 0.28f; lookStartX = x;
                }
                return true;
            }
            @Override public boolean touchUp(int x, int y, int pointer, int button) {
                if (pointer == touchMove) { touchMove = -1; moveX = moveY = 0; }
                if (pointer == touchLook) touchLook = -1;
                return true;
            }
            @Override public boolean keyDown(int keycode) {
                if (keycode == Input.Keys.ENTER || keycode == Input.Keys.SPACE) {
                    if (!started) started = true; else if (player.y <= 1.61f) { jumpVelocity = 6.2f; }
                    return true;
                }
                return false;
            }
        });
    }

    private void addBox(float x,float y,float z,float sx,float sy,float sz,Color color) {
        Model m = builder.createBox(sx,sy,sz,
            new Material(ColorAttribute.createDiffuse(color)),
            VertexAttributes.Usage.Position | VertexAttributes.Usage.Normal);
        ModelInstance i = new ModelInstance(m); i.transform.setToTranslation(x,y,z); world.add(i);
    }
    private void addSphere(float x,float y,float z,float size,Color color) {
        Model m = builder.createSphere(size,size,size,12,10,
            new Material(ColorAttribute.createDiffuse(color)),
            VertexAttributes.Usage.Position | VertexAttributes.Usage.Normal);
        ModelInstance i = new ModelInstance(m); i.transform.setToTranslation(x,y,z); world.add(i);
    }
    private void buildWorld() {
        // Floating island and grassy plateau
        addBox(0,-1.3f,0,25,2.2f,25,new Color(.24f,.19f,.16f,1));
        addBox(0,-.12f,0,24.5f,.45f,24.5f,new Color(.23f,.48f,.28f,1));
        // Path stones
        for(int n=0;n<8;n++) addBox(0,.14f,-n*1.7f,2.5f,.12f,1.25f,new Color(.48f,.49f,.43f,1));
        // Ruins
        addBox(-5,1.2f,-5,.5f,3.1f,.5f,new Color(.55f,.53f,.46f,1));
        addBox(-2.5f,1.2f,-5,.5f,3.1f,.5f,new Color(.55f,.53f,.46f,1));
        addBox(-3.75f,2.8f,-5,3.1f,.45f,.5f,new Color(.63f,.58f,.46f,1));
        addBox(5,.9f,-4,.45f,2.4f,.45f,new Color(.55f,.53f,.46f,1));
        addBox(7,.9f,-4,.45f,2.4f,.45f,new Color(.55f,.53f,.46f,1));
        addBox(6,2.05f,-4,2.4f,.4f,.45f,new Color(.63f,.58f,.46f,1));
        // Low-poly trees
        for(int n=0;n<9;n++){
            float x = (n%3)*6-6, z = (n/3)*6-6;
            addBox(x,.65f,z,.28f,1.4f,.28f,new Color(.36f,.22f,.12f,1));
            addSphere(x,1.8f,z,1.5f,new Color(.12f,.38f,.23f,1));
        }
        // Eight collectible glowing-looking crystals
        float[][] positions={{-7,.85f,-2},{-5,.85f,4},{-1,.85f,-7},{3,.85f,-5},{7,.85f,1},{5,.85f,7},{0,.85f,5},{-8,.85f,7}};
        for(float[] p:positions) { crystals.add(new Vector3(p[0],p[1],p[2])); addSphere(p[0],p[1],p[2],.72f,new Color(.25f,.86f,1f,1)); }
    }

    @Override public void render() {
        float dt = Math.min(Gdx.graphics.getDeltaTime(), .04f);
        Gdx.gl.glViewport(0,0,Gdx.graphics.getWidth(),Gdx.graphics.getHeight());
        Gdx.gl.glClearColor(.39f,.68f,.88f,1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT | GL20.GL_DEPTH_BUFFER_BIT);
        Gdx.gl.glEnable(GL20.GL_DEPTH_TEST);
        if(started) {
            float keyboardX = (Gdx.input.isKeyPressed(Input.Keys.D)?1:0)-(Gdx.input.isKeyPressed(Input.Keys.A)?1:0);
            float keyboardY = (Gdx.input.isKeyPressed(Input.Keys.W)?1:0)-(Gdx.input.isKeyPressed(Input.Keys.S)?1:0);
            float mx = moveX + keyboardX, my = moveY + keyboardY;
            float radians = yaw * MathUtils.degreesToRadians;
            player.x += (MathUtils.cos(radians)*mx + MathUtils.sin(radians)*my)*4.0f*dt;
            player.z += (MathUtils.sin(radians)*mx - MathUtils.cos(radians)*my)*4.0f*dt;
            player.x = MathUtils.clamp(player.x,-11,11); player.z = MathUtils.clamp(player.z,-11,11);
            if(jumpVelocity != 0 || player.y > 1.6f) {
                player.y += jumpVelocity*dt; jumpVelocity -= 14f*dt;
                if(player.y < 1.6f) { player.y=1.6f; jumpVelocity=0; }
            }
            for(int n=0;n<crystals.size();n++){
                Vector3 c=crystals.get(n);
                if(c.dst(player.x,player.y,player.z)<1.5f){
                    crystals.remove(n);
                    // hide collected crystal by removing nearest world sphere instance
                    for(int j=world.size()-1;j>=0;j--) {
                        ModelInstance inst=world.get(j);
                        Vector3 pos=inst.transform.getTranslation(new Vector3());
                        if(Math.abs(pos.x-c.x)<.01f && Math.abs(pos.y-c.y)<.01f && Math.abs(pos.z-c.z)<.01f){world.remove(j);break;}
                    }
                    collected++; break;
                }
            }
        }
        float r=yaw*MathUtils.degreesToRadians;
        camera.position.set(player.x,player.y,player.z);
        camera.direction.set(MathUtils.sin(r)*MathUtils.cos(pitch*MathUtils.degreesToRadians),
            MathUtils.sin(pitch*MathUtils.degreesToRadians),MathUtils.cos(r)*MathUtils.cos(pitch*MathUtils.degreesToRadians)).nor();
        camera.up.set(Vector3.Y); camera.update();
        modelBatch.begin(camera);
        for(ModelInstance instance:world) modelBatch.render(instance);
        modelBatch.end();
        uiBatch.begin();
        font.setColor(Color.WHITE);
        if(!started){
            font.draw(uiBatch,"AETHER: ОСКОЛКИ НЕБА",Gdx.graphics.getWidth()/2f-155,Gdx.graphics.getHeight()*.68f);
            font.draw(uiBatch,"Коснись экрана, чтобы начать",Gdx.graphics.getWidth()/2f-150,Gdx.graphics.getHeight()*.55f);
        } else {
            font.draw(uiBatch,"Кристаллы: "+collected+" / 8",24,Gdx.graphics.getHeight()-24);
            font.draw(uiBatch,"Движение: левая сторона   Обзор: правая сторона",24,36);
            font.draw(uiBatch,"ПРЫЖОК",Gdx.graphics.getWidth()-135,65);
            if(collected==8) font.draw(uiBatch,"Все кристаллы собраны!",Gdx.graphics.getWidth()/2f-110,Gdx.graphics.getHeight()-24);
        }
        uiBatch.end();
    }

    @Override public void resize(int width,int height) {
        if(camera!=null){camera.viewportWidth=width;camera.viewportHeight=height;camera.update();}
    }
    @Override public void dispose() {
        if(modelBatch!=null) modelBatch.dispose();
        if(uiBatch!=null) uiBatch.dispose();
        if(font!=null) font.dispose();
        for(ModelInstance instance:world) instance.model.dispose();
    }
}
