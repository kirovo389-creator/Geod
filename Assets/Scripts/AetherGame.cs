using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public sealed class AetherGame : MonoBehaviour
{
    const int Total = 8;
    readonly List<Transform> crystals = new();
    CharacterController player;
    Transform playerRoot;
    Camera cam;
    Canvas canvas;
    GameObject menu;
    Text counter, message;
    bool started;
    int found;
    float yaw, pitch = -8, vertical;
    Vector2 move;
    int moveFinger = -1, lookFinger = -1;
    Vector2 moveOrigin, lookLast;
    bool jump;

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void Boot() { if (FindObjectOfType<AetherGame>() == null) new GameObject("AETHER").AddComponent<AetherGame>(); }

    void Awake()
    {
        Application.targetFrameRate = 60;
        Screen.orientation = ScreenOrientation.LandscapeLeft;
        RenderSettings.ambientLight = new Color(.6f,.72f,.9f);
        BuildWorld();
        BuildUI();
    }

    Material Mat(Color c, bool glow = false)
    {
        var s = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
        var m = new Material(s); m.color = c;
        if (glow) { m.EnableKeyword("_EMISSION"); m.SetColor("_EmissionColor", c * 1.6f); }
        return m;
    }
    GameObject Cube(string name, Vector3 p, Vector3 size, Color c)
    {
        var o = GameObject.CreatePrimitive(PrimitiveType.Cube); o.name=name; o.transform.SetParent(transform);
        o.transform.position=p; o.transform.localScale=size; o.GetComponent<Renderer>().material=Mat(c); return o;
    }
    void BuildWorld()
    {
        RenderSettings.skybox=null;
        var cg=new GameObject("AETHER Camera"); cam=cg.AddComponent<Camera>(); cam.tag="MainCamera";
        cam.clearFlags=CameraClearFlags.SolidColor; cam.backgroundColor=new Color(.5f,.75f,.94f); cam.fieldOfView=70;
        var light=new GameObject("Sun").AddComponent<Light>(); light.type=LightType.Directional; light.intensity=1.1f; light.shadows=LightShadows.None;
        light.transform.rotation=Quaternion.Euler(48,-32,0);
        Cube("Island",new Vector3(0,-1.2f,0),new Vector3(30,2,30),new Color(.18f,.45f,.29f));
        Cube("Island rock",new Vector3(0,-2.5f,0),new Vector3(23,1,23),new Color(.29f,.32f,.4f));
        Cube("Island rock lower",new Vector3(0,-3.3f,0),new Vector3(15,1,15),new Color(.18f,.21f,.3f));
        for(int i=0;i<7;i++) Cube("Stone path",new Vector3(0,-.05f,7-i*2.25f),new Vector3(3,.28f,1.7f),new Color(.45f,.49f,.56f));
        for(int i=0;i<12;i++){float a=Mathf.PI*2*i/12f; Cube("Pillar",new Vector3(Mathf.Cos(a)*11,.1f,Mathf.Sin(a)*11),new Vector3(.8f,2+(i%3)*.4f,.8f),new Color(.32f,.39f,.48f));}
        for(int i=0;i<Total;i++){
            float a=Mathf.PI*2*i/Total; var g=GameObject.CreatePrimitive(PrimitiveType.Capsule); g.name="Crystal";
            g.transform.SetParent(transform); g.transform.position=new Vector3(Mathf.Cos(a)*7,.55f,Mathf.Sin(a)*7);
            g.transform.localScale=new Vector3(.48f,.75f,.48f); g.GetComponent<Renderer>().material=Mat(new Color(.12f,.88f,1),true);
            Destroy(g.GetComponent<Collider>()); crystals.Add(g.transform);
        }
        for(int i=0;i<14;i++){float a=Mathf.PI*2*i/14f; Vector3 p=new(Mathf.Cos(a)*10,.3f,Mathf.Sin(a)*10);
            Cube("Tree trunk",p+Vector3.up*.8f,new Vector3(.35f,1.6f,.35f),new Color(.3f,.2f,.13f));
            var crown=Cube("Tree crown",p+Vector3.up*2,Vector3.one*1.5f,new Color(.13f,.43f+(i%3)*.07f,.31f)); crown.transform.rotation=Quaternion.Euler(0,a*Mathf.Rad2Deg,0);
        }
        for(int i=0;i<5;i++){float x=-23+i*11.5f,z=-27-(i%2)*8; Cube("Floating rock",new Vector3(x,-1,z),new Vector3(7,1,7),new Color(.22f,.38f,.42f)); Cube("Rock base",new Vector3(x,-2,z),new Vector3(4.5f,1.2f,4.5f),new Color(.25f,.28f,.38f));}
        var pg=new GameObject("Player"); playerRoot=pg.transform; playerRoot.position=new Vector3(0,-.18f,9);
        player=pg.AddComponent<CharacterController>(); player.height=1.8f; player.radius=.38f; player.center=new Vector3(0,.9f,0);
        cam.transform.SetParent(playerRoot,false); cam.transform.localPosition=new Vector3(0,1.48f,0);
    }
    void BuildUI()
    {
        var go=new GameObject("UI",typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster)); canvas=go.GetComponent<Canvas>(); canvas.renderMode=RenderMode.ScreenSpaceOverlay;
        var scaler=go.GetComponent<CanvasScaler>(); scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize; scaler.referenceResolution=new Vector2(1280,720);
        counter=Label(canvas.transform,"AETHER • ОСКОЛКИ НЕБА\nКристаллы: 0 / 8",26,new Color(.7f,.96f,1),new Vector2(24,-20),new Vector2(600,90),TextAnchor.UpperLeft);
        counter.rectTransform.anchorMin=counter.rectTransform.anchorMax=new Vector2(0,1); counter.rectTransform.pivot=new Vector2(0,1);
        message=Label(canvas.transform,"Собери все кристаллы древнего острова",19,Color.white,new Vector2(0,48),new Vector2(700,50),TextAnchor.MiddleCenter);
        message.rectTransform.anchorMin=message.rectTransform.anchorMax=new Vector2(.5f,0);
        MakeButton("JUMP",new Vector2(1,0),new Vector2(-85,105),new Vector2(130,90),()=>jump=true);
        MakeButton("TAKE",new Vector2(1,0),new Vector2(-220,65),new Vector2(120,65),Collect);
        menu=new GameObject("Main Menu",typeof(RectTransform),typeof(Image)); menu.transform.SetParent(canvas.transform,false);
        var mr=menu.GetComponent<RectTransform>(); mr.anchorMin=Vector2.zero; mr.anchorMax=Vector2.one; mr.offsetMin=mr.offsetMax=Vector2.zero;
        menu.GetComponent<Image>().color=new Color(.025f,.05f,.11f,.985f);
        Label(menu.transform,"AETHER",52,new Color(.5f,.9f,1),new Vector2(0,115),new Vector2(600,80),TextAnchor.MiddleCenter);
        Label(menu.transform,"ОСКОЛКИ НЕБА",24,new Color(.91f,.96f,1),new Vector2(0,62),new Vector2(600,50),TextAnchor.MiddleCenter);
        Label(menu.transform,"Исследуй древний остров в облаках\nи собери 8 светящихся кристаллов.",20,new Color(.71f,.81f,.91f),Vector2.zero,new Vector2(650,75),TextAnchor.MiddleCenter);
        MakeButton("ИГРАТЬ",new Vector2(.5f,.5f),new Vector2(0,-80),new Vector2(300,70),()=>{started=true;menu.SetActive(false);},menu.transform,new Color(.24f,.84f,.98f),new Color(.02f,.08f,.14f));
        Label(menu.transform,"Левая сторона — движение • правая — обзор\nJUMP — прыжок • TAKE — взять кристалл",15,new Color(.61f,.73f,.85f),new Vector2(0,-155),new Vector2(700,55),TextAnchor.MiddleCenter);
    }
    Text Label(Transform parent,string value,int size,Color color,Vector2 pos,Vector2 dims,TextAnchor align)
    {
        var g=new GameObject("Text",typeof(RectTransform),typeof(CanvasRenderer),typeof(Text)); g.transform.SetParent(parent,false);
        var r=g.GetComponent<RectTransform>(); r.anchorMin=r.anchorMax=new Vector2(.5f,.5f); r.pivot=new Vector2(.5f,.5f); r.anchoredPosition=pos;r.sizeDelta=dims;
        var t=g.GetComponent<Text>();t.font=Resources.GetBuiltinResource<Font>("Arial.ttf");t.text=value;t.fontSize=size;t.color=color;t.alignment=align;
        t.horizontalOverflow=HorizontalWrapMode.Wrap;t.verticalOverflow=VerticalWrapMode.Overflow;return t;
    }
    void MakeButton(string caption,Vector2 anchor,Vector2 pos,Vector2 dims,UnityEngine.Events.UnityAction action,Transform parent=null,Color? bg=null,Color? fg=null)
    {
        var g=new GameObject(caption,typeof(RectTransform),typeof(CanvasRenderer),typeof(Image),typeof(Button));g.transform.SetParent(parent??canvas.transform,false);
        var r=g.GetComponent<RectTransform>();r.anchorMin=r.anchorMax=anchor;r.pivot=new Vector2(.5f,.5f);r.anchoredPosition=pos;r.sizeDelta=dims;
        var image=g.GetComponent<Image>();image.color=bg??new Color(.12f,.25f,.38f,.92f);var b=g.GetComponent<Button>();b.targetGraphic=image;b.onClick.AddListener(action);
        var t=Label(g.transform,caption,caption=="ИГРАТЬ"?24:18,fg??Color.white,Vector2.zero,dims-Vector2.one*10,TextAnchor.MiddleCenter);
        t.rectTransform.anchorMin=Vector2.zero;t.rectTransform.anchorMax=Vector2.one;t.rectTransform.offsetMin=t.rectTransform.offsetMax=Vector2.zero;
    }
    void Update()
    {
        if(!started)return; ReadTouch(); Vector2 input=move;
        if(Input.GetKey(KeyCode.W)||Input.GetKey(KeyCode.UpArrow))input.y++;if(Input.GetKey(KeyCode.S)||Input.GetKey(KeyCode.DownArrow))input.y--;
        if(Input.GetKey(KeyCode.A)||Input.GetKey(KeyCode.LeftArrow))input.x--;if(Input.GetKey(KeyCode.D)||Input.GetKey(KeyCode.RightArrow))input.x++;
        input=Vector2.ClampMagnitude(input,1); Vector3 dir=new(Mathf.Sin(yaw*Mathf.Deg2Rad)*input.y+Mathf.Cos(yaw*Mathf.Deg2Rad)*input.x,0,Mathf.Cos(yaw*Mathf.Deg2Rad)*input.y-Mathf.Sin(yaw*Mathf.Deg2Rad)*input.x);
        if(player.isGrounded)vertical=jump||Input.GetKeyDown(KeyCode.Space)?7.5f:-1;else vertical+=-18*Time.deltaTime;
        jump=false;player.Move((dir*6+Vector3.up*vertical)*Time.deltaTime);playerRoot.rotation=Quaternion.Euler(0,yaw,0);cam.transform.localRotation=Quaternion.Euler(pitch,0,0);
        for(int i=crystals.Count-1;i>=0;i--){if(crystals[i]==null){crystals.RemoveAt(i);continue;}var c=crystals[i];c.Rotate(0,42*Time.deltaTime,0,Space.World);var p=c.position;p.y=.55f+Mathf.Sin(Time.time*2+p.x)*.18f;c.position=p;}
        if(playerRoot.position.y< -10){playerRoot.position=new Vector3(0,-.18f,9);vertical=0;}
    }
    void ReadTouch()
    {
        for(int i=0;i<Input.touchCount;i++){Touch t=Input.GetTouch(i);if(t.phase==TouchPhase.Began){if(t.position.x<Screen.width*.4f&&moveFinger==-1){moveFinger=t.fingerId;moveOrigin=t.position;}else if(t.position.x>=Screen.width*.4f&&lookFinger==-1){lookFinger=t.fingerId;lookLast=t.position;}}
            if(t.fingerId==moveFinger){move=Vector2.ClampMagnitude((t.position-moveOrigin)/65,1);if(t.phase==TouchPhase.Ended||t.phase==TouchPhase.Canceled){moveFinger=-1;move=Vector2.zero;}}
            if(t.fingerId==lookFinger){if(t.phase==TouchPhase.Moved){Vector2 d=t.position-lookLast;yaw-=d.x*.18f;pitch=Mathf.Clamp(pitch+d.y*.12f,-55,40);lookLast=t.position;}if(t.phase==TouchPhase.Ended||t.phase==TouchPhase.Canceled)lookFinger=-1;}}
    }
    void Collect()
    {
        if(!started)return;Transform nearest=null;float best=3;
        foreach(var c in crystals){if(c==null)continue;float d=Vector3.Distance(playerRoot.position+Vector3.up,c.position);if(d<best){best=d;nearest=c;}}
        if(nearest==null){message.text="Подойди ближе к голубому кристаллу";return;}
        crystals.Remove(nearest);Destroy(nearest.gameObject);found++;counter.text="AETHER • ОСКОЛКИ НЕБА\nКристаллы: "+found+" / "+Total;
        message.text=found>=Total?"Все осколки собраны!":"Кристалл найден — осталось: "+(Total-found);
    }
}
