// ActionScript file

import flash.display.Bitmap;
import flash.events.*;
import flash.text.engine.GroupElement;
import flash.ui.Keyboard;

import mx.collections.ArrayCollection;
import mx.collections.ArrayList;
import mx.controls.Alert;
import mx.core.IVisualElement;
import mx.core.UIComponent;
import mx.events.FlexEvent;

import org.atomsoft.as3.base.FlexNode;
import org.atomsoft.as3.base.event.*;

import spark.components.Group;
import spark.components.HGroup;
import spark.components.HSlider;
import spark.components.List;
import spark.components.RadioButton;
import spark.components.SkinnableContainer;
import spark.components.ToggleButton;
import spark.components.VGroup;
import spark.components.supportClasses.GroupBase;
import spark.layouts.VerticalLayout;
import spark.layouts.supportClasses.LayoutBase;

import worker.Track;
import worker.Worker;
import worker.WorkerTeam;
import worker.util.ProductionManagement;

private var current:FlexNode;
private var currentWorker:Worker;
private var currentTrack:Track;
private static const manager:ProductionManagement = new ProductionManagement();


protected function application1_creationCompleteHandler(event:FlexEvent):void
{

	sysmsg.dataProvider = new ArrayCollection();
	manager.platform = cPanel;
	manager.eventsList = sysmsg;

	var str:String = "西安庆华公司专用,请勿盗版,使用请联系作者QQ:285799123";	
	cPanel.addEventListener(SelectEvent.SELECT,setCurrentNode);
	cPanel.addEventListener(SelectEvent.UNSELECT,unSetCurrentNode);
	
	
}
protected function application1_keyUpHandler(event:KeyboardEvent):void
{
	trace("ctrl:"+event.ctrlKey+"key:"+event.keyCode);
	
}
private var hasMechine:Boolean = false;
protected function radiobutton3_clickHandler(event:MouseEvent):void
{
	var rd:RadioButton = event.currentTarget as RadioButton;
    hasMechine = rd.value;
}

protected function button1_clickHandler(event:MouseEvent):void
{
	
	var w:Worker = new Worker(ProductionManagement.getNextWorkerIndex(),cPanel,manager,hasMechine);
	manager.addWorker(w,this.currentWorker);
	
	this.currentWorker = w;
}


private var humanable:Boolean = false;
protected function togglebutton2_clickHandler(event:MouseEvent):void
{
	var tb:ToggleButton = event.currentTarget as ToggleButton;
	if(tb.selected){
		humanable = true;
		tb.label="人工";
	}else{
		humanable = false;
		tb.label="通道";
	}
   if(this.currentTrack!=null){
	   this.currentTrack.humanable = humanable;
   }
	
}
private var reserse:Boolean = false;
protected function togglebutton3_clickHandler(event:MouseEvent):void
{
	var tb:ToggleButton = event.currentTarget as ToggleButton;
	if(tb.selected){
		reserse = true;
		tb.label="反向";
	}else{
		reserse = false;
		tb.label="正向";
	}
	
	if(this.currentTrack!=null){
		this.currentTrack.reserve = reserse;
	}
}



private var trackType:String = "track-rl";

protected function radiobutton1_clickHandler(event:MouseEvent):void
{
	
	var rd:RadioButton = (event.currentTarget as RadioButton);
	
	this.trackType = rd.value.toString();	
	
}			

protected function button2_clickHandler(event:MouseEvent):void
{
	
	var t:Track = new Track(ProductionManagement.getTrackIndex(),this.trackType,cPanel,reserse,humanable);
	manager.addTrack(t);			
	
}


protected  var _fristWorker:Worker;
protected var _senondWorker:Worker;

protected function setCurrentNode(event:SelectEvent):void
{
	this.current = event.targetWorker;
	if(event.targetWorker is Worker){
		this.currentWorker = event.targetWorker as Worker;
		
		if(this._fristWorker==null){
			this._fristWorker= this.currentWorker;
		}else{
			if(this._senondWorker==null){
				this._senondWorker = this.currentWorker;
			}else{
				this._fristWorker = null;
				this._senondWorker = null;
					
			}
			
			
		}
    manager.addMessage("当前选中 "+(this._fristWorker==null?"无":this._fristWorker)+"<->"+(this._senondWorker==null?"无":this._senondWorker));
		
	}else if(event.targetWorker is Track){
		this.currentTrack = event.targetWorker as  Track;
	}
	
}

protected function button3_clickHandler(event:MouseEvent):void
{
	if(this.current==null)return;	
	manager.removeResource(this.current);
	this.current==null;
	
	
}

protected function unSetCurrentNode(event:SelectEvent):void
{
	if(this.current==event.targetWorker){
		this.current = null;
	}
	
}

protected function button4_clickHandler(event:MouseEvent):void
{
    	
	manager.allot(this.currentWorker,this.currentTrack);
	
}

protected function button5_clickHandler(event:MouseEvent):void
{
	manager.lauchWorkline();   
	uneffitiveAll();
}

private function uneffitiveAll():void
{
	var e:EffectiveEvent = new EffectiveEvent(EffectiveEvent.UNFOCUS);
	for(var i:int=0;i<cPanel.numElements;i++){
		var iv:IVisualElement =	cPanel.getElementAt(i);
		iv.dispatchEvent(e);
	}
	
}

protected function button6_clickHandler(event:MouseEvent):void
{
    if(this.currentWorker==null || this.currentWorker is WorkerTeam) return;
	this.currentWorker.workTime = wtime.value;
	this.currentWorker.workCount = wnum.value;
	this.currentWorker.workName = wname.text;
	this.currentWorker.batchable = bid.selected;
	this.currentWorker.batchCount = bcd.value;
	this.currentWorker.setProductData(underid.value,totalid.value);
	
}



protected function button8_clickHandler(event:MouseEvent):void
{
	this._fristWorker = null;
	this._senondWorker = null;
	uneffitiveAll();
	
}

protected function button7_clickHandler(event:MouseEvent):void
{
     manager.makeFriend(this._fristWorker,this._senondWorker,finterval.value);
	
}

protected function hslider1_changeHandler(event:Event):void
{
	if(this.currentTrack==null)return;
	var hslide:HSlider = event.currentTarget as HSlider; 
	
	this.currentTrack.mcWidth = 1*(mischk.selected?-1:1)* hslide.value;
	
}

protected function button9_clickHandler(event:MouseEvent):void
{
	
	manager.saveScreen();
	
}

protected function button10_clickHandler(event:MouseEvent):void
{
	manager.loadScreen();

}

private function confirmRemoveStore(dlg_obj: Object):void{ 
	if(dlg_obj.detail == Alert.YES){ 
		manager.removeStore();					
	} 
} 
protected function button11_clickHandler(event:MouseEvent):void
{	
	Alert.show("确认删除吗？", "确认", Alert.YES|Alert.NO, null, confirmRemoveStore, null, Alert.NO);	
}
