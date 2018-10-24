// Learn cc.Class:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/class.html
//  - [English] http://www.cocos2d-x.org/docs/creator/en/scripting/class.html
// Learn Attribute:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/reference/attributes.html
//  - [English] http://www.cocos2d-x.org/docs/creator/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/life-cycle-callbacks.html
//  - [English] http://www.cocos2d-x.org/docs/creator/en/scripting/life-cycle-callbacks.html

cc.Class({
    extends: cc.Component,

    properties: {
        tip: {
            default: null,
            type: cc.Label,
        },
        username: {
            default: null,
            type: cc.EditBox,
        },
        password: {
            default: null,
            type: cc.EditBox,
        },
        // foo: {
        //     // ATTRIBUTES:
        //     default: null,        // The default value will be used only when the component attaching
        //                           // to a node for the first time
        //     type: cc.SpriteFrame, // optional, default is typeof default
        //     serializable: true,   // optional, default is true
        // },
        // bar: {
        //     get () {
        //         return this._bar;
        //     },
        //     set (value) {
        //         this._bar = value;
        //     }
        // },
    },

    // LIFE-CYCLE CALLBACKS:

    onLoad () {
        this.tip.node.color = new cc.color(255,0,0,255); 
    },

    start () {

    },

    // update (dt) {},
    login:function(evt){
        var xhr = new XMLHttpRequest();
        xhr.open("post","http://localhost:9231/login",true);
        var obj = this;
        obj.tip.string = "";
        xhr.onreadystatechange = function(){
            if( xhr.readyState == 4){
                if( xhr.status >= 200 && xhr.status < 300 || xhr.status == 304){
                    var msg = JSON.parse(xhr.responseText);
                    if (msg.state == "ok"){
                        cc.director.loadScene("shop");
                    }else{
                        obj.tip.string = "登录失败，请重新输入";
                    }
                }
            }
        };
        var data = JSON.stringify({"user":this.username.string,"pwd":this.password.string});
        console.log(data);
        xhr.send(data);

        // var user = this.node.getComponent("username").string;
        // var pwd = this.node.getComponent("password").string;
        // console.log("user:"+this.username.string);
    }
});
